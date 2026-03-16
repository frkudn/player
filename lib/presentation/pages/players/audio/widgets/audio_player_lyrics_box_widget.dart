import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import 'package:open_player/utils/lrc_parser.dart';

class AudioPlayerLyricsBoxWidget extends HookWidget {
  const AudioPlayerLyricsBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    final fontSize = useState(18.0);
    final isSynced = useState(true);
    final primary = Theme.of(context).colorScheme.primary;

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, state) {
        if (state == null) return nothing;

        return StreamBuilder<int?>(
          stream: state.audioPlayer.currentIndexStream,
          builder: (context, snapshot) {
            final currentIndex =
                snapshot.data ?? state.audioPlayer.currentIndex;
            final rawLyrics = currentIndex != null
                ? (state.audios[currentIndex].lyrics ?? '')
                : '';

            final lrcLines = LrcParser.parse(rawLyrics);
            final hasLrc = lrcLines != null;
            final showSynced = hasLrc && isSynced.value;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                // Fully transparent — sits on top of player BG
                color: Colors.black.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    _TopBar(
                      hasLrc: hasLrc,
                      isSynced: isSynced.value,
                      rawLyrics: rawLyrics,
                      primary: primary,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: rawLyrics));
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Lyrics copied'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      onDecrease: () =>
                          fontSize.value = (fontSize.value - 1).clamp(10, 32),
                      onIncrease: () =>
                          fontSize.value = (fontSize.value + 1).clamp(10, 32),
                      onToggleSync: hasLrc
                          ? () => isSynced.value = !isSynced.value
                          : null,
                    ),
                    Expanded(
                      child: showSynced
                          ? _SyncedLyricsView(
                              lines: lrcLines!,
                              fontSize: fontSize.value,
                              primary: primary,
                              player: state.audioPlayer,
                            )
                          : _PlainLyricsView(
                              lyrics: rawLyrics,
                              fontSize: fontSize.value,
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
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool hasLrc;
  final bool isSynced;
  final String rawLyrics;
  final Color primary;
  final VoidCallback onCopy;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onToggleSync;

  const _TopBar({
    required this.hasLrc,
    required this.isSynced,
    required this.rawLyrics,
    required this.primary,
    required this.onCopy,
    required this.onDecrease,
    required this.onIncrease,
    this.onToggleSync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Row(
        children: [
          // Copy
          _BarIconButton(icon: Icons.copy_rounded, onTap: onCopy),

          const Spacer(),

          // Synced pill — only when LRC detected
          if (hasLrc) ...[
            GestureDetector(
              onTap: onToggleSync,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSynced
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isSynced
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 12,
                      color: isSynced
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Synced',
                      style: TextStyle(
                        color: isSynced
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Font size
          _BarIconButton(
              icon: HugeIcons.strokeRoundedRemove01, onTap: onDecrease),
          _BarIconButton(icon: HugeIcons.strokeRoundedAdd01, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;
  const _BarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      color: Colors.white.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

// ── Plain lyrics ───────────────────────────────────────────────────────────────

class _PlainLyricsView extends StatelessWidget {
  final String lyrics;
  final double fontSize;
  const _PlainLyricsView({required this.lyrics, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final isEmpty = lyrics.trim().isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Text(
        isEmpty ? '♪  No lyrics available' : lyrics,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isEmpty ? Colors.white.withValues(alpha: 0.25) : Colors.white,
          fontSize: fontSize,
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w500,
          height: 1.9,
          shadows: const [
            Shadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Synced lyrics ──────────────────────────────────────────────────────────────

class _SyncedLyricsView extends HookWidget {
  final List<LrcLine> lines;
  final double fontSize;
  final Color primary;
  final dynamic player;

  const _SyncedLyricsView({
    required this.lines,
    required this.fontSize,
    required this.primary,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final activeIndex = useState(0);
    final currentPosition = useState(Duration.zero);

    useEffect(() {
      final sub = player.positionStream.listen((Duration pos) {
        currentPosition.value = pos;

        int idx = 0;
        for (int i = 0; i < lines.length; i++) {
          if (pos >= lines[i].timestamp) {
            idx = i;
          } else {
            break;
          }
        }

        if (idx != activeIndex.value) {
          activeIndex.value = idx;

          // Auto-scroll: keep active line at ~35% from top
          final lineHeight = fontSize * 3.2;
          final viewHeight = scrollController.hasClients
              ? scrollController.position.viewportDimension
              : 300.0;
          final targetOffset = (idx * lineHeight) - (viewHeight * 0.35);

          if (scrollController.hasClients) {
            scrollController.animateTo(
              targetOffset.clamp(
                  0.0, scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
            );
          }
        }
      });
      return sub.cancel;
    }, [lines, fontSize]);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final isActive = index == activeIndex.value;
        final isPast = index < activeIndex.value;
        final isNext = index == activeIndex.value + 1;

        // Inline progress: how far through the current line we are
        double inlineProgress = 0.0;
        if (isActive && index + 1 < lines.length) {
          final lineStart = lines[index].timestamp;
          final lineEnd = lines[index + 1].timestamp;
          final lineDur = lineEnd - lineStart;
          if (lineDur.inMilliseconds > 0) {
            final elapsed = currentPosition.value - lineStart;
            inlineProgress = (elapsed.inMilliseconds / lineDur.inMilliseconds)
                .clamp(0.0, 1.0);
          }
        } else if (isActive) {
          inlineProgress = 1.0;
        }

        return GestureDetector(
          onTap: () {
            player.seek(lines[index].timestamp);
            HapticFeedback.selectionClick();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              vertical: isActive ? 10 : 5,
              horizontal: 4,
            ),
            child: isActive
                ? _ActiveLine(
                    text: lines[index].text,
                    fontSize: fontSize,
                    progress: inlineProgress,
                  )
                : _InactiveLine(
                    text: lines[index].text,
                    fontSize: fontSize,
                    isPast: isPast,
                    isNext: isNext,
                  ),
          ),
        );
      },
    );
  }
}

// ── Active line — Apple Music style inline color fill ─────────────────────────

class _ActiveLine extends StatelessWidget {
  final String text;
  final double fontSize;
  final double progress; // 0.0 → 1.0

  const _ActiveLine({
    required this.text,
    required this.fontSize,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.isEmpty ? '♪' : text;

    return ShaderMask(
      // Inline fill: left portion is bright white, rest is dim white
      shaderCallback: (bounds) => LinearGradient(
        stops: [
          progress,
          (progress + 0.015).clamp(0.0, 1.0),
        ],
        colors: [
          Colors.white, // sung — bright white
          Colors.white.withValues(alpha: 0.28), // upcoming — dim
        ],
      ).createShader(bounds),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white, // ShaderMask overrides this
          fontSize: fontSize + 3,
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w800,
          height: 1.5,
          letterSpacing: -0.3,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.25),
              blurRadius: 20,
            ),
            const Shadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inactive line ──────────────────────────────────────────────────────────────

class _InactiveLine extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isPast;
  final bool isNext;

  const _InactiveLine({
    required this.text,
    required this.fontSize,
    required this.isPast,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.isEmpty ? '♪' : text;

    // Next line is slightly brighter to show "what's coming"
    final opacity = isPast ? 0.22 : (isNext ? 0.55 : 0.38);

    return Text(
      displayText,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: opacity),
        fontSize: fontSize,
        fontFamily: AppFonts.poppins,
        fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
        height: 1.7,
        letterSpacing: -0.1,
        shadows: const [
          Shadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
