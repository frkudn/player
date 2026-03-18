import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/features/local_audio_player/cubit/lyrics/lyrics_cubit.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';
import 'package:open_player/utils/lrc_parser.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _Theme {
  final String name;
  final Color bg, active, inactive, border;
  const _Theme({
    required this.name,
    required this.bg,
    required this.active,
    required this.inactive,
    required this.border,
  });
}

class _Style {
  final String name, hint;
  const _Style(this.name, this.hint);
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

const List<_Theme> _themes = [
  _Theme(
      name: 'Dark',
      bg: Color(0x3A000000),
      active: Colors.white,
      inactive: Color(0xAAFFFFFF),
      border: Color(0x14FFFFFF)),
  _Theme(
      name: 'Light',
      bg: Color(0xD0FFFFFF),
      active: Color(0xFF111111),
      inactive: Color(0x88111111),
      border: Color(0x14000000)),
  _Theme(
      name: 'Gold',
      bg: Color(0xE8FFF9C4),
      active: Color(0xFF4E342E),
      inactive: Color(0x996D4C41),
      border: Color(0x22F9A825)),
  _Theme(
      name: 'Rose',
      bg: Color(0xE8FCE4EC),
      active: Color(0xFF880E4F),
      inactive: Color(0x99AD1457),
      border: Color(0x22F48FB1)),
  _Theme(
      name: 'Night',
      bg: Color(0xEE070714),
      active: Color(0xFF90CAF9),
      inactive: Color(0x6690CAF9),
      border: Color(0x221565C0)),
  _Theme(
      name: 'Forest',
      bg: Color(0xE8E8F5E9),
      active: Color(0xFF1B5E20),
      inactive: Color(0x99388E3C),
      border: Color(0x2281C784)),
];

const List<_Style> _styles = [
  _Style('Classic', 'Centered, clean'),
  _Style('Bold', 'Large & punchy'),
  _Style('Minimal', 'Subtle & soft'),
  _Style('Karaoke', 'Pill highlight'),
  _Style('Elegant', 'Italic refined'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// Reads prefs from LyricsCubit (survives show/hide — lives in blocProviders).
// ═══════════════════════════════════════════════════════════════════════════════

class AudioPlayerLyricsBoxWidget extends StatelessWidget {
  const AudioPlayerLyricsBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);

    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, lyricsState) {
        final theme = _themes[lyricsState.themeIndex];

        return BlocSelector<AudioPlayerBloc, AudioPlayerState,
            AudioPlayerSuccessState?>(
          selector: (s) => s is AudioPlayerSuccessState ? s : null,
          builder: (context, audioState) {
            if (audioState == null) return nothing;

            return StreamBuilder<int?>(
              stream: audioState.audioPlayer.currentIndexStream,
              builder: (context, snap) {
                final ci = snap.data ?? audioState.audioPlayer.currentIndex;
                final rawLyrics = (ci != null && ci < audioState.audios.length)
                    ? (audioState.audios[ci].lyrics ?? '')
                    : '';
                final lrcLines = LrcParser.parse(rawLyrics);
                final hasLrc = lrcLines != null;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: theme.bg,
                    border: Border.all(color: theme.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        // ── Top bar ────────────────────────────────────────
                        _TopBar(
                          theme: theme,
                          hasLrc: hasLrc,
                          isSynced: lyricsState.isSynced,
                          onSync: hasLrc
                              ? () => context.read<LyricsCubit>().toggleSynced()
                              : null,
                          onSettings: () => _openSheet(context, rawLyrics),
                          onFullscreen: () => _openFullscreen(
                            context,
                            lrcLines: lrcLines,
                            hasLrc: hasLrc,
                            rawLyrics: rawLyrics,
                            player: audioState.audioPlayer,
                            lyricsState: lyricsState,
                          ),
                        ),

                        // ── Lyrics body ────────────────────────────────────
                        // ValueKey on ci: forces complete widget teardown +
                        // fresh scroll/activeIdx whenever song changes.
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey('lyrics_$ci'),
                            child: (hasLrc && lyricsState.isSynced)
                                ? _SyncedView(
                                    lines: lrcLines!,
                                    fontSize: lyricsState.fontSize,
                                    theme: theme,
                                    styleIdx: lyricsState.styleIndex,
                                    player: audioState.audioPlayer,
                                  )
                                : _PlainView(
                                    lyrics: rawLyrics,
                                    fontSize: lyricsState.fontSize,
                                    theme: theme,
                                    styleIdx: lyricsState.styleIndex,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSheet(BuildContext context, String rawLyrics) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Pass the cubit's BuildContext so the sheet can call it
      builder: (_) => BlocProvider.value(
        value: context.read<LyricsCubit>(),
        child: _SettingsSheet(
          rawLyrics: rawLyrics,
          parentCtx: context,
        ),
      ),
    );
  }

  void _openFullscreen(
    BuildContext context, {
    required List<LrcLine>? lrcLines,
    required bool hasLrc,
    required String rawLyrics,
    required dynamic player,
    required LyricsState lyricsState,
  }) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => BlocProvider.value(
        value: context.read<LyricsCubit>(),
        child: _FullscreenPage(
          lrcLines: lrcLines,
          hasLrc: hasLrc,
          rawLyrics: rawLyrics,
          player: player,
          lyricsState: lyricsState,
        ),
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.theme,
    required this.hasLrc,
    required this.isSynced,
    required this.onSettings,
    required this.onFullscreen,
    this.onSync,
  });

  final _Theme theme;
  final bool hasLrc, isSynced;
  final VoidCallback onSettings, onFullscreen;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          if (hasLrc)
            GestureDetector(
              onTap: onSync,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.active.withValues(alpha: isSynced ? 0.12 : 0.04),
                  border: Border.all(
                    color:
                        theme.active.withValues(alpha: isSynced ? 0.35 : 0.1),
                    width: 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isSynced ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                    size: 11,
                    color:
                        theme.active.withValues(alpha: isSynced ? 0.85 : 0.3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSynced ? 'Synced' : 'Plain',
                    style: TextStyle(
                      color:
                          theme.active.withValues(alpha: isSynced ? 0.85 : 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            )
          else
            const SizedBox(width: 4),
          const Spacer(),
          _Btn(
              icon: Icons.tune_rounded, color: theme.active, onTap: onSettings),
          _Btn(
              icon: Icons.open_in_full_rounded,
              color: theme.active,
              onTap: onFullscreen),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNCED VIEW
//
// Scroll behaviour:
//  • GlobalKey per line → real RenderBox position (not estimated heights)
//  • Two postFrameCallbacks: frame1 = list rebuild, frame2 = measure & scroll
//  • positionStream has NO debounce — just_audio emits correct position after
//    seek automatically. Debounce breaks seek because it resets on every emission.
//  • Song change: parent uses ValueKey('lyrics_$ci') so this widget is fully
//    recreated, activeIdx starts at 0, scroll at top. No stale state.
// ═══════════════════════════════════════════════════════════════════════════════

class _SyncedView extends HookWidget {
  const _SyncedView({
    required this.lines,
    required this.fontSize,
    required this.theme,
    required this.styleIdx,
    required this.player,
    this.centered = false,
  });

  final List<LrcLine> lines;
  final double fontSize;
  final _Theme theme;
  final int styleIdx;
  final dynamic player;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = useScrollController();
    final activeIdx = useState(0);

    // One GlobalKey per line. useMemoized regenerates only when line count changes.
    final keys = useMemoized(
      () => List.generate(lines.length, (_) => GlobalKey()),
      [lines.length],
    );

    // Scroll so the active line's center aligns with the viewport's center.
    // Uses real RenderBox positions — never estimated line heights.
    void centerLine(int idx) {
      if (!scrollCtrl.hasClients) return;
      if (idx < 0 || idx >= keys.length) return;

      final keyCtx = keys[idx].currentContext;
      if (keyCtx == null) return;

      final scrollBox = scrollCtrl.position.context.storageContext
          .findRenderObject() as RenderBox?;
      if (scrollBox == null) return;

      final itemBox = keyCtx.findRenderObject() as RenderBox?;
      if (itemBox == null || !itemBox.hasSize) return;

      final itemTopRel =
          itemBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final itemH = itemBox.size.height;
      final viewportH = scrollCtrl.position.viewportDimension;
      final absTop = scrollCtrl.offset + itemTopRel;
      final target = absTop - (viewportH / 2) + (itemH / 2);

      scrollCtrl.animateTo(
        target.clamp(0.0, scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }

    useEffect(() {
      // Binary search O(log n) — finds which line corresponds to a position
      int findActive(Duration pos) {
        int lo = 0, hi = lines.length - 1, result = 0;
        while (lo <= hi) {
          final mid = (lo + hi) ~/ 2;
          if (lines[mid].timestamp <= pos) {
            result = mid;
            lo = mid + 1;
          } else {
            hi = mid - 1;
          }
        }
        return result;
      }

      void applyIndex(int idx) {
        if (idx == activeIdx.value) return;
        activeIdx.value = idx;
        // Frame 1: list rebuilds with new active highlight applied
        // Frame 2: RenderBoxes are stable — safe to measure real positions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            centerLine(idx);
          });
        });
      }

      // Subscribe to position stream.
      // just_audio emits the correct position after seek automatically —
      // no debounce needed (debounce actually broke seek by resetting the
      // timer on every subsequent emission after the seek completed).
      final sub = player.positionStream.listen((Duration pos) {
        applyIndex(findActive(pos));
      });

      // Cleanup when song changes or widget is disposed
      return sub.cancel;
    }, [lines]); // [lines] = re-subscribes when a new song loads

    // Generous vertical padding so first/last lines can scroll to center
    final vPad = centered ? 220.0 : 140.0;

    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.symmetric(vertical: vPad),
      itemCount: lines.length,
      itemBuilder: (_, i) => KeyedSubtree(
        key: keys[i], // anchor for real RenderBox measurement in centerLine()
        child: GestureDetector(
          onTap: () {
            // Tap any line to seek audio to that timestamp
            player.seek(lines[i].timestamp);
            HapticFeedback.selectionClick();
          },
          behavior: HitTestBehavior.opaque,
          child: _LineWidget(
            text: lines[i].text,
            fontSize: fontSize,
            isActive: i == activeIdx.value,
            isPast: i < activeIdx.value,
            isNext: i == activeIdx.value + 1,
            theme: theme,
            styleIdx: styleIdx,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLAIN VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _PlainView extends StatelessWidget {
  const _PlainView({
    required this.lyrics,
    required this.fontSize,
    required this.theme,
    required this.styleIdx,
  });

  final String lyrics;
  final double fontSize;
  final _Theme theme;
  final int styleIdx;

  @override
  Widget build(BuildContext context) {
    final empty = lyrics.trim().isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Text(
        empty ? '♪  No lyrics available' : lyrics,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: empty ? theme.inactive.withValues(alpha: 0.3) : theme.active,
          fontSize: fontSize,
          fontFamily: AppFonts.poppins,
          fontWeight: styleIdx == 1
              ? FontWeight.w700
              : styleIdx == 2
                  ? FontWeight.w300
                  : FontWeight.w500,
          fontStyle: styleIdx == 4 ? FontStyle.italic : FontStyle.normal,
          height: 1.9,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LINE WIDGET — renders a single lyric line in one of 5 styles
// ═══════════════════════════════════════════════════════════════════════════════

class _LineWidget extends StatelessWidget {
  const _LineWidget({
    required this.text,
    required this.fontSize,
    required this.isActive,
    required this.isPast,
    required this.isNext,
    required this.theme,
    required this.styleIdx,
  });

  final String text;
  final double fontSize;
  final bool isActive, isPast, isNext;
  final _Theme theme;
  final int styleIdx;

  @override
  Widget build(BuildContext context) {
    final t = text.isEmpty ? '♪' : text;
    switch (styleIdx) {
      case 1:
        return _bold(t);
      case 2:
        return _minimal(t);
      case 3:
        return _karaoke(t);
      case 4:
        return _elegant(t);
      default:
        return _classic(t);
    }
  }

  // Style 0 — clean centered with subtle pill on active line
  Widget _classic(String t) {
    if (isActive) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.active.withValues(alpha: 0.07),
        ),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.active,
            fontSize: fontSize + 4,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w800,
            height: 1.45,
            letterSpacing: -0.4,
          ),
        ),
      );
    }
    return _inactive(t, fontSize, 1.7, FontWeight.w400,
        blur: isPast ? 1.2 : (isNext ? 0 : 0.6));
  }

  // Style 1 — bold, maximum contrast
  Widget _bold(String t) {
    final op = isActive ? 1.0 : (isPast ? 0.15 : (isNext ? 0.45 : 0.25));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.active.withValues(alpha: op),
          fontSize: isActive ? fontSize + 6 : fontSize + 1,
          fontFamily: AppFonts.poppins,
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }

  // Style 2 — minimal, blurred inactive lines
  Widget _minimal(String t) {
    final op = isActive ? 1.0 : (isPast ? 0.12 : (isNext ? 0.40 : 0.22));
    final blur = isActive ? 0.0 : (isPast ? 1.5 : 0.5);
    Widget w = Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.active.withValues(alpha: op),
        fontSize: isActive ? fontSize + 1 : fontSize - 1,
        fontFamily: AppFonts.poppins,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w300,
        height: 1.6,
        letterSpacing: 0.3,
      ),
    );
    if (blur > 0)
      w = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: w);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: w,
    );
  }

  // Style 3 — karaoke pill around active line
  Widget _karaoke(String t) {
    if (isActive) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: theme.active.withValues(alpha: 0.15),
          border:
              Border.all(color: theme.active.withValues(alpha: 0.25), width: 1),
        ),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.active,
            fontSize: fontSize + 2,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
    return _inactive(t, fontSize, 1.7, FontWeight.w400);
  }

  // Style 4 — elegant italic
  Widget _elegant(String t) {
    if (isActive) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.active,
            fontSize: fontSize + 2,
            fontStyle: FontStyle.italic,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: 0.8,
          ),
        ),
      );
    }
    return _inactive(t, fontSize, 1.7, FontWeight.w300, italic: true, blur: 0);
  }

  // Shared inactive line renderer used by classic and karaoke
  Widget _inactive(String t, double size, double h, FontWeight w,
      {double blur = 0, bool italic = false}) {
    final op = isPast ? 0.18 : (isNext ? 0.52 : 0.28);
    Widget tw = Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.inactive.withValues(alpha: op),
        fontSize: isNext ? size + 1 : size,
        fontFamily: AppFonts.poppins,
        fontWeight: isNext ? FontWeight.w600 : w,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: h,
      ),
    );
    if (blur > 0)
      tw = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: tw);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: tw,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FULLSCREEN PAGE
// Receives LyricsCubit via BlocProvider.value — same instance as the player page.
// ═══════════════════════════════════════════════════════════════════════════════

class _FullscreenPage extends StatelessWidget {
  const _FullscreenPage({
    required this.lrcLines,
    required this.hasLrc,
    required this.rawLyrics,
    required this.player,
    required this.lyricsState,
  });

  final List<LrcLine>? lrcLines;
  final bool hasLrc;
  final String rawLyrics;
  final dynamic player;
  final LyricsState lyricsState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, state) {
        final theme = _themes[state.themeIndex];
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Blurred + tinted backdrop
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: theme.bg.withValues(alpha: 0.94),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          // Close chevron
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.active.withValues(alpha: 0.1),
                              ),
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: theme.active.withValues(alpha: 0.7),
                                  size: 22),
                            ),
                          ),

                          const Spacer(),

                          // Synced toggle
                          if (hasLrc) ...[
                            GestureDetector(
                              onTap: () =>
                                  context.read<LyricsCubit>().toggleSynced(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: theme.active.withValues(
                                      alpha: state.isSynced ? 0.12 : 0.04),
                                  border: Border.all(
                                    color: theme.active.withValues(
                                        alpha: state.isSynced ? 0.35 : 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_rounded,
                                        size: 12,
                                        color: theme.active.withValues(
                                            alpha: state.isSynced ? 0.8 : 0.3)),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.isSynced ? 'Synced' : 'Plain',
                                      style: TextStyle(
                                        color: theme.active.withValues(
                                            alpha: state.isSynced ? 0.8 : 0.3),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Font size controls
                          _Btn(
                            icon: Icons.text_decrease_rounded,
                            color: theme.active,
                            onTap: () => context
                                .read<LyricsCubit>()
                                .setFontSize(state.fontSize - 1),
                          ),
                          _Btn(
                            icon: Icons.text_increase_rounded,
                            color: theme.active,
                            onTap: () => context
                                .read<LyricsCubit>()
                                .setFontSize(state.fontSize + 1),
                          ),

                          // Theme/style palette toggle
                          _FullscreenPaletteBtn(theme: theme),
                        ],
                      ),
                    ),

                    // ── Collapsible theme + style pickers ──────────────────
                    _FullscreenPickers(theme: theme, state: state),

                    const SizedBox(height: 8),

                    // ── Lyrics body ────────────────────────────────────────
                    Expanded(
                      child: (hasLrc && state.isSynced)
                          ? _SyncedView(
                              lines: lrcLines!,
                              fontSize: state.fontSize,
                              theme: theme,
                              styleIdx: state.styleIndex,
                              player: player,
                              centered: true,
                            )
                          : _PlainView(
                              lyrics: rawLyrics,
                              fontSize: state.fontSize,
                              theme: theme,
                              styleIdx: state.styleIndex,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Palette toggle button with local state for showing/hiding pickers
class _FullscreenPaletteBtn extends HookWidget {
  const _FullscreenPaletteBtn({required this.theme});
  final _Theme theme;

  @override
  Widget build(BuildContext context) {
    final show = useState(false);
    return _Btn(
      icon: Icons.palette_outlined,
      color: theme.active,
      onTap: () => show.value = !show.value,
    );
  }
}

// Separate widget so AnimatedSize can see its own state
class _FullscreenPickers extends HookWidget {
  const _FullscreenPickers({required this.theme, required this.state});
  final _Theme theme;
  final LyricsState state;

  @override
  Widget build(BuildContext context) {
    final showPick = useState(false);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: showPick.value
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  // Color theme row
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final active = state.themeIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<LyricsCubit>().setTheme(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 72 : 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _themes[i].bg,
                              border: Border.all(
                                color: active
                                    ? _themes[i].active
                                    : _themes[i].border.withValues(alpha: 0.3),
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(_themes[i].name,
                                  style: TextStyle(
                                    color: _themes[i].active,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Style row
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _styles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final active = state.styleIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<LyricsCubit>().setStyle(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.active
                                  .withValues(alpha: active ? 0.18 : 0.05),
                              border: Border.all(
                                color: theme.active
                                    .withValues(alpha: active ? 0.5 : 0.1),
                              ),
                            ),
                            child: Text(_styles[i].name,
                                style: TextStyle(
                                  color: theme.active
                                      .withValues(alpha: active ? 0.9 : 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS SHEET
// Uses BlocBuilder<LyricsCubit> — rebuilds reactively on every cubit emit.
// No ValueNotifier hacks needed — cubit is the single source of truth.
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.rawLyrics,
    required this.parentCtx,
  });

  final String rawLyrics;
  final BuildContext parentCtx;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, state) {
        final cubit = context.read<LyricsCubit>();
        final cs = Theme.of(context).colorScheme;
        final primary = cs.primary;
        final onSurface = cs.onSurface;
        final bg = Theme.of(context).scaffoldBackgroundColor == Colors.black
            ? const Color(0xFF0E0E0E)
            : cs.surface;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: onSurface.withValues(alpha: 0.06)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, ctrl) => SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                      child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),

                  Text('Lyrics Settings',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),

                  const SizedBox(height: 20),

                  // ── Font size ─────────────────────────────────────────────
                  _Label('Text Size', onSurface),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.format_size_rounded,
                        color: onSurface.withValues(alpha: 0.4), size: 16),
                    const Spacer(),
                    _CircleBtn(
                      icon: Icons.remove_rounded,
                      color: primary,
                      onTap: () => cubit.setFontSize(state.fontSize - 1),
                    ),
                    const SizedBox(width: 12),
                    // Text rebuilds via BlocBuilder — always shows current value
                    Text('${state.fontSize.round()}',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(width: 12),
                    _CircleBtn(
                      icon: Icons.add_rounded,
                      color: primary,
                      onTap: () => cubit.setFontSize(state.fontSize + 1),
                    ),
                  ]),

                  const SizedBox(height: 22),
                  Divider(color: onSurface.withValues(alpha: 0.06)),
                  const SizedBox(height: 16),

                  // ── Color themes ──────────────────────────────────────────
                  _Label('Color Theme', onSurface),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final t = _themes[i];
                        final active = state.themeIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cubit.setTheme(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 76 : 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: t.bg,
                              border: Border.all(
                                color: active
                                    ? primary
                                    : t.border.withValues(alpha: 0.4),
                                width: active ? 2 : 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                          color: primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: -2)
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _Dot(t.active),
                                    const SizedBox(width: 4),
                                    _Dot(t.inactive.withValues(alpha: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(t.name,
                                    style: TextStyle(
                                      color: t.active,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),
                  Divider(color: onSurface.withValues(alpha: 0.06)),
                  const SizedBox(height: 16),

                  // ── Display styles ────────────────────────────────────────
                  _Label('Display Style', onSurface),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _styles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final active = state.styleIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cubit.setStyle(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: active
                                  ? primary.withValues(alpha: 0.1)
                                  : onSurface.withValues(alpha: 0.04),
                              border: Border.all(
                                color: active
                                    ? primary.withValues(alpha: 0.4)
                                    : onSurface.withValues(alpha: 0.08),
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_styles[i].name,
                                    style: TextStyle(
                                      color: active
                                          ? primary
                                          : onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 3),
                                Text(_styles[i].hint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onSurface.withValues(alpha: 0.35),
                                      fontSize: 9,
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),
                  Divider(color: onSurface.withValues(alpha: 0.06)),
                  const SizedBox(height: 16),

                  // ── Copy + Edit ───────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: _ActionBtn(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: rawLyrics));
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(parentCtx).showSnackBar(
                            _snack('Lyrics copied', Icons.check_rounded));
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _ActionBtn(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          () => showDialog(
                            context: parentCtx,
                            barrierColor: Colors.black.withValues(alpha: 0.7),
                            builder: (_) => _EditDialog(
                              initial: rawLyrics,
                              primary: primary,
                              cs: cs,
                            ),
                          ),
                        );
                      },
                    )),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _EditDialog extends HookWidget {
  const _EditDialog({
    required this.initial,
    required this.primary,
    required this.cs,
  });

  final String initial;
  final Color primary;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: initial);
    final os = cs.onSurface;
    final bg = Theme.of(context).scaffoldBackgroundColor == Colors.black
        ? const Color(0xFF0E0E0E)
        : cs.surface;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: bg,
          border: Border.all(color: os.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
            child: Row(children: [
              Text('Edit Lyrics',
                  style: TextStyle(
                    color: os,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded,
                    color: os.withValues(alpha: 0.35), size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),

          // LRC detection banner
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (_, val, __) => LrcParser.isLrc(val.text)
                ? Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: primary.withValues(alpha: 0.07),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.18)),
                    ),
                    child: Row(children: [
                      Icon(Icons.sync_rounded,
                          color: primary.withValues(alpha: 0.7), size: 12),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text('LRC format · timestamps will sync',
                            style: TextStyle(
                              color: primary.withValues(alpha: 0.75),
                              fontSize: 11,
                            )),
                      ),
                    ]),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 10),

          // Text editor
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: os.withValues(alpha: 0.03),
                border: Border.all(color: os.withValues(alpha: 0.06)),
              ),
              child: TextField(
                controller: ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: os,
                  fontSize: 13,
                  height: 1.7,
                  fontFamily: AppFonts.poppins,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste LRC or plain lyrics...',
                  hintStyle:
                      TextStyle(color: os.withValues(alpha: 0.2), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          )),

          const SizedBox(height: 12),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              _SaveBtn(
                label: 'Clear',
                bg: os.withValues(alpha: 0.05),
                txt: os.withValues(alpha: 0.4),
                onTap: () => ctrl.clear(),
              ),
              const SizedBox(width: 10),
              Expanded(
                  flex: 2,
                  child: _SaveBtn(
                    label: 'Save',
                    gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.8)]),
                    txt: cs.onPrimary,
                    shadow: primary.withValues(alpha: 0.3),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          _snack('Lyrics saved', Icons.check_circle_rounded));
                    },
                  )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        color: color.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(5),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      );
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color primary, onSurface;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: onSurface.withValues(alpha: 0.05),
            border: Border.all(color: onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
          ]),
        ),
      );
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({
    required this.label,
    required this.txt,
    required this.onTap,
    this.bg,
    this.gradient,
    this.shadow,
  });
  final String label;
  final Color txt;
  final VoidCallback onTap;
  final Color? bg, shadow;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: gradient == null ? bg : null,
            gradient: gradient,
            boxShadow: shadow != null
                ? [BoxShadow(color: shadow!, blurRadius: 10, spreadRadius: -3)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txt,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        color: color.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ));
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

SnackBar _snack(String msg, IconData icon) => SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(color: Colors.white)),
      ]),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: const Duration(seconds: 2),
    );
