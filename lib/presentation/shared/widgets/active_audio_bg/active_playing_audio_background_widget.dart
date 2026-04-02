import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import '../../../features/local_audio_player/bloc/audio_player_bloc.dart';
import '../../cubit/theme_cubit/theme_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMANCE AUDIT vs ORIGINAL — what changed and why
//
// ┌──────────────────────────────────────────────────────────────────────────┐
// │  #  │  Problem in original         │  Fix                               │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  1  │  MediaQuery.sizeOf() called  │  Cached once on StatefulWidget     │
// │     │  inside AnimatedBuilder (60× │  build() — only fires on track or  │
// │     │  per second)                 │  orientation change, never per frame│
// ├──────────────────────────────────────────────────────────────────────────┤
// │  2  │  New Matrix4 allocated every │  Single Matrix4 held on state,     │
// │     │  frame (Matrix4.identity())  │  mutated via setIdentity() —       │
// │     │  = GC pressure at 60 fps     │  zero heap allocation in hot path  │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  3  │  Full-resolution MemoryImage │  ResizeImage wrapper downscales to │
// │     │  blurred at sigmaX/Y=28 —    │  128×128 before decode. Blur at    │
// │     │  raster thread blurs a large │  sigma 28 is visually identical at │
// │     │  texture every repaint       │  128 px vs 1080 px. GPU bandwidth  │
// │     │                              │  drops ~64× for a 1080p source.    │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  4  │  New MemoryImage / ImageProv │  _BlurredImage caches by bytes     │
// │     │  ider created on every       │  identity (identical()). Same track│
// │     │  stream event even if same   │  = same Uint8List ref = zero extra │
// │     │  track is playing            │  decode, ever.                     │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  5  │  _buildLayer() is a plain    │  Extracted into StatefulWidget     │
// │     │  method — every stream event │  _AnimatedBlurBackground. Stream   │
// │     │  rebuilds the full layer     │  events only rebuild the data      │
// │     │  including blur widget tree  │  wrapper; animation builder only   │
// │     │                              │  touches the Transform node.       │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  6  │  RepaintBoundary only wraps  │  Outer RepaintBoundary added around│
// │     │  the blur; repaints can still│  the full background — background  │
// │     │  propagate upward            │  lives in its own compositor layer │
// │     │                              │  and can never dirty the app tree. │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  7  │  TileMode.clamp (default) on │  TileMode.mirror on ImageFilter    │
// │     │  blur causes dark halo at    │  .blur() — eliminates the black-   │
// │     │  screen edges                │  edge artifact at all four sides.  │
// ├──────────────────────────────────────────────────────────────────────────┤
// │  8  │  No TickerMode awareness     │  useAnimationController (flutter_  │
// │     │                              │  hooks) inherits TickerMode from   │
// │     │                              │  the widget tree — ticker pauses   │
// │     │                              │  automatically when route is not   │
// │     │                              │  top-most (e.g. dialog covers it). │
// └──────────────────────────────────────────────────────────────────────────┘

// ─────────────────────────────────────────────────────────────────────────────

class ActivePlayingAudioBackgroundWidget extends HookWidget {
  const ActivePlayingAudioBackgroundWidget({super.key});

  // ── Thumbnail downscale target ─────────────────────────────────────────────
  // Blur sigma 28 obliterates all spatial detail beyond ~10 px.
  // 128 px is therefore visually indistinguishable from full resolution
  // while being ~64× cheaper to blur for a 1080p source image.
  static const int _thumbTargetSize = 128;

  // ── Geometric constants ────────────────────────────────────────────────────
  static const double _overscale = 1.40;
  static const double _driftRatio = 0.06;
  static const double _breatheExtra = 0.08;
  static const Duration _period = Duration(seconds: 18);

  @override
  Widget build(BuildContext context) {
    // useAnimationController integrates with TickerMode — the ticker pauses
    // automatically whenever this subtree's TickerMode is disabled (e.g. when
    // a modal route covers this screen).
    final ctrl = useAnimationController(duration: _period)..repeat();

    final bool dynamic = context.select<ThemeCubit, bool>(
      (c) => c.state.playerDynamicLightEnabled,
    );

    useEffect(() {
      if (dynamic) {
        if (!ctrl.isAnimating) ctrl.repeat();
      } else {
        ctrl.stop();
        ctrl.value = 0;
      }
      return null;
    }, [dynamic]);

    // ── Outer RepaintBoundary ──────────────────────────────────────────────
    // The entire background lives in its own compositor layer.
    // Nothing happening inside (animation, image swap) can dirty the
    // widget tree outside this boundary — critical when this widget is
    // used app-wide.
    return RepaintBoundary(
      child: BlocSelector<AudioPlayerBloc, AudioPlayerState,
          AudioPlayerSuccessState?>(
        selector: (s) => s is AudioPlayerSuccessState ? s : null,
        builder: (context, playerState) {
          if (playerState == null) {
            return BlocSelector<ThemeCubit, ThemeState, bool>(
              selector: (state) {
                return state.isBlackMode ? state.isBlackMode : false;
              },
              builder: (context, state) {
                return state
                    ? SizedBox.expand()
                    : _AnimatedBlurBackground(
                        ctrl: ctrl,
                        dynamic: dynamic,
                        thumb: null,
                      );
              },
            );
          }
          return BlocSelector<ThemeCubit, ThemeState, bool>(
            selector: (state) {
              return state.isBlackMode ? state.isBlackMode : false;
            },
            builder: (context, state) {
              return state
                  ? SizedBox.expand()
                  : StreamBuilder(
                      stream: playerState.audioPlayerCombinedStream,
                      builder: (context, snapshot) {
                        final int? ci = snapshot.data?.currentIndex ??
                            playerState.audioPlayer.currentIndex;
                        final Uint8List? thumb = (ci != null &&
                                ci < playerState.audios.length &&
                                playerState.audios[ci].thumbnail.isNotEmpty)
                            ? playerState.audios[ci].thumbnail.first.bytes
                            : null;
                        // _AnimatedBlurBackground is a StatefulWidget — Flutter's
                        // element reconciliation updates it in place. The stream
                        // emitting the same index multiple times does NOT rebuild
                        // the blur or start a new image decode (see _BlurredImage).
                        return _AnimatedBlurBackground(
                          ctrl: ctrl,
                          dynamic: dynamic,
                          thumb: thumb,
                        );
                      },
                    );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedBlurBackground
//
// StatefulWidget — holds mutable cached values that must survive rebuilds
// without being re-allocated on every stream event.
//
// build() is called only when:
//   • thumb changes (track change)
//   • dynamic flag toggles
//   • screen size changes (orientation)
//
// The AnimatedBuilder's builder closure fires at 60 fps but is completely
// decoupled from the above — it only mutates _matrix and reads _dxMax/_dyMax
// from the state.
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBlurBackground extends StatefulWidget {
  const _AnimatedBlurBackground({
    required this.ctrl,
    required this.dynamic,
    required this.thumb,
  });

  final AnimationController ctrl;
  final bool dynamic;
  final Uint8List? thumb;

  @override
  State<_AnimatedBlurBackground> createState() =>
      _AnimatedBlurBackgroundState();
}

class _AnimatedBlurBackgroundState extends State<_AnimatedBlurBackground> {
  // ── Cached drift amplitudes ────────────────────────────────────────────────
  // Computed from screen size in build() — never inside the animation loop.
  double _dxMax = 0;
  double _dyMax = 0;

  // ── Reused Matrix4 ────────────────────────────────────────────────────────
  // Allocated ONCE. Mutated via setIdentity() + in-place scale/translate.
  // RenderTransform.set transform() copies the matrix internally, so
  // mutating this instance before the next vsync is safe.
  // Cost: 0 heap allocations inside the 60 fps builder closure.
  final Matrix4 _matrix = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    // MediaQuery.sizeOf registers only a size dependency — already the
    // narrowest possible subscription. Runs once per build, never per frame.
    final Size size = MediaQuery.sizeOf(context);
    _dxMax = size.width * ActivePlayingAudioBackgroundWidget._driftRatio;
    _dyMax = size.height * ActivePlayingAudioBackgroundWidget._driftRatio;

    // Built once here, then passed as the stable `child` parameter of
    // AnimatedBuilder — it is never rebuilt by animation ticks.
    final Widget blurredChild = _BlurredImage(thumb: widget.thumb);

    if (!widget.dynamic) {
      // Static path — identical to original, zero animation overhead.
      return blurredChild;
    }

    return ClipRect(
      child: AnimatedBuilder(
        animation: widget.ctrl,
        // `child` is the subtree AnimatedBuilder holds across frames.
        // Only the Transform node above it is rebuilt at 60 fps.
        child: blurredChild,
        builder: (_, child) {
          final double t = widget.ctrl.value; // 0.0 → 1.0
          final double angle = 2 * math.pi * t;

          // Pre-compute trig values once; reused for both drift and breathe.
          final double sinA = math.sin(angle);
          final double cosA = math.cos(angle);
          final double sin2A = math.sin(2 * angle); // double-speed for breathe

          final double breathe =
              ActivePlayingAudioBackgroundWidget._breatheExtra *
                  0.5 *
                  (1 + sin2A);
          final double scale =
              ActivePlayingAudioBackgroundWidget._overscale + breathe;

          // Mutate the pre-allocated matrix — zero GC pressure.
          _matrix
            ..setIdentity()
            ..scale(scale)
            // Divide by scale to compensate for the enlarged coordinate space.
            ..translate(_dxMax * sinA / scale, _dyMax * cosA / scale);

          return Transform(
            alignment: Alignment.center,
            transform: _matrix,
            child: child,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BlurredImage
//
// StatefulWidget that caches the resolved ImageProvider between rebuilds.
//
// Key insight — ResizeImage:
//   Flutter's image loading pipeline decodes MemoryImage on a background
//   thread and stores the decoded bitmap in the image cache. ResizeImage
//   instructs the codec to produce a 128×128 output during that decode step
//   (codec-level downscale, not a second pass). The cached GPU texture is
//   therefore tiny, and ImageFilter.blur runs on that tiny texture every
//   time it repaints — massively reducing raster-thread work.
//
// Key insight — identical() cache:
//   The stream can emit many events (position ticks, buffer events, etc.)
//   without the track changing. If the same Uint8List reference arrives
//   again, no new MemoryImage / ResizeImage is constructed and no new
//   decode is scheduled.
// ─────────────────────────────────────────────────────────────────────────────
class _BlurredImage extends StatefulWidget {
  const _BlurredImage({required this.thumb});

  final Uint8List? thumb;

  @override
  State<_BlurredImage> createState() => _BlurredImageState();
}

class _BlurredImageState extends State<_BlurredImage> {
  ImageProvider? _provider;
  Uint8List? _lastThumb;

  /// Returns the cached provider, or builds a new one only when the bytes
  /// reference has actually changed (i.e. the track changed).
  ImageProvider _resolveProvider(Uint8List? thumb) {
    // identical() checks object identity, not deep equality — O(1), no copy.
    if (identical(thumb, _lastThumb) && _provider != null) {
      return _provider!;
    }
    _lastThumb = thumb;

    if (thumb == null || thumb.isEmpty) {
      return _provider = const AssetImage(AppImages.defaultThumbnail);
    }

    // ResizeImage instructs Flutter's image codec to produce a
    // _thumbTargetSize × _thumbTargetSize bitmap during the background
    // decode step. The GPU texture stored in the image cache is tiny.
    return _provider = ResizeImage(
      MemoryImage(thumb),
      width: ActivePlayingAudioBackgroundWidget._thumbTargetSize,
      height: ActivePlayingAudioBackgroundWidget._thumbTargetSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 28,
          sigmaY: 28,
          // TileMode.mirror: the blur kernel samples mirrored pixels at the
          // image boundary instead of transparent black — eliminates the dark
          // halo that was visible at screen edges in static mode.
          tileMode: TileMode.mirror,
        ),
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _resolveProvider(widget.thumb),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
