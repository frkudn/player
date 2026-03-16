import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import 'package:open_player/utils/lrc_parser.dart';

// ── Theme presets ──────────────────────────────────────────────────────────────

class _LyricsTheme {
  final String name;
  final Color bg;
  final Color activeLine;
  final Color inactiveLine;
  final Color border;

  const _LyricsTheme({
    required this.name,
    required this.bg,
    required this.activeLine,
    required this.inactiveLine,
    required this.border,
  });
}

const _kThemes = [
  _LyricsTheme(
    name: 'Dark',
    bg: Color(0x3A000000),
    activeLine: Colors.white,
    inactiveLine: Color(0xAAFFFFFF),
    border: Color(0x14FFFFFF),
  ),
  _LyricsTheme(
    name: 'Light',
    bg: Color(0xD0FFFFFF),
    activeLine: Color(0xFF111111),
    inactiveLine: Color(0x88111111),
    border: Color(0x14000000),
  ),
  _LyricsTheme(
    name: 'Gold',
    bg: Color(0xE8FFF9C4),
    activeLine: Color(0xFF4E342E),
    inactiveLine: Color(0x996D4C41),
    border: Color(0x22F9A825),
  ),
  _LyricsTheme(
    name: 'Rose',
    bg: Color(0xE8FCE4EC),
    activeLine: Color(0xFF880E4F),
    inactiveLine: Color(0x99AD1457),
    border: Color(0x22F48FB1),
  ),
  _LyricsTheme(
    name: 'Night',
    bg: Color(0xEE070714),
    activeLine: Color(0xFF90CAF9),
    inactiveLine: Color(0x6690CAF9),
    border: Color(0x221565C0),
  ),
  _LyricsTheme(
    name: 'Forest',
    bg: Color(0xE8E8F5E9),
    activeLine: Color(0xFF1B5E20),
    inactiveLine: Color(0x99388E3C),
    border: Color(0x2281C784),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

class AudioPlayerLyricsBoxWidget extends HookWidget {
  const AudioPlayerLyricsBoxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final fontSize = useState(18.0);
    final isSynced = useState(true);
    final themeIdx = useState(0);

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, state) {
        if (state == null) return nothing;

        return StreamBuilder<int?>(
          stream: state.audioPlayer.currentIndexStream,
          builder: (context, snapshot) {
            final ci = snapshot.data ?? state.audioPlayer.currentIndex;
            final rawLyrics = ci != null && ci < state.audios.length
                ? (state.audios[ci].lyrics ?? '')
                : '';

            final lrcLines = LrcParser.parse(rawLyrics);
            final hasLrc = lrcLines != null;
            final showSynced = hasLrc && isSynced.value;
            final theme = _kThemes[themeIdx.value];

            return Container(
              margin: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: theme.bg,
                border: Border.all(color: theme.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    // ── Minimal top bar: only 3 items ──────────────
                    _MinimalTopBar(
                      theme: theme,
                      hasLrc: hasLrc,
                      isSynced: isSynced.value,
                      onToggleSync: hasLrc
                          ? () => isSynced.value = !isSynced.value
                          : null,
                      onMore: () => _showControlsSheet(
                        context: context,
                        theme: theme,
                        themeIdx: themeIdx,
                        fontSize: fontSize,
                        rawLyrics: rawLyrics,
                        lrcLines: lrcLines,
                        ci: ci,
                        state: state,
                        player: state.audioPlayer,
                      ),
                      onFullscreen: () => _openFullscreen(
                        context: context,
                        lrcLines: lrcLines,
                        hasLrc: hasLrc,
                        rawLyrics: rawLyrics,
                        fontSize: fontSize,
                        isSynced: isSynced,
                        themeIdx: themeIdx,
                        player: state.audioPlayer,
                        ci: ci,
                        state: state,
                      ),
                    ),

                    // ── Lyrics ─────────────────────────────────────
                    Expanded(
                      child: showSynced
                          ? _SyncedView(
                              lines: lrcLines!,
                              fontSize: fontSize.value,
                              theme: theme,
                              player: state.audioPlayer,
                            )
                          : _PlainView(
                              lyrics: rawLyrics,
                              fontSize: fontSize.value,
                              theme: theme,
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

  // ── Controls bottom sheet ──────────────────────────────────────────────────
  void _showControlsSheet({
    required BuildContext context,
    required _LyricsTheme theme,
    required ValueNotifier<int> themeIdx,
    required ValueNotifier<double> fontSize,
    required String rawLyrics,
    required List<LrcLine>? lrcLines,
    required int? ci,
    required AudioPlayerSuccessState state,
    required dynamic player,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ControlsSheet(
        theme: theme,
        themeIdx: themeIdx,
        fontSize: fontSize,
        rawLyrics: rawLyrics,
        lrcLines: lrcLines,
        ci: ci,
        state: state,
        player: player,
        parentContext: context,
      ),
    );
  }

  // ── Fullscreen ─────────────────────────────────────────────────────────────
  void _openFullscreen({
    required BuildContext context,
    required List<LrcLine>? lrcLines,
    required bool hasLrc,
    required String rawLyrics,
    required ValueNotifier<double> fontSize,
    required ValueNotifier<bool> isSynced,
    required ValueNotifier<int> themeIdx,
    required dynamic player,
    required int? ci,
    required AudioPlayerSuccessState state,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, anim, _) => _FullscreenPage(
          lrcLines: lrcLines,
          hasLrc: hasLrc,
          rawLyrics: rawLyrics,
          fontSize: fontSize.value,
          isSynced: isSynced.value,
          themeIdx: themeIdx.value,
          player: player,
          ci: ci,
          state: state,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal top bar — only 3 buttons: sync | ··· more | fullscreen
// ─────────────────────────────────────────────────────────────────────────────

class _MinimalTopBar extends StatelessWidget {
  const _MinimalTopBar({
    required this.theme,
    required this.hasLrc,
    required this.isSynced,
    required this.onMore,
    required this.onFullscreen,
    this.onToggleSync,
  });

  final _LyricsTheme theme;
  final bool hasLrc;
  final bool isSynced;
  final VoidCallback onMore;
  final VoidCallback onFullscreen;
  final VoidCallback? onToggleSync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          // Synced pill — left
          if (hasLrc)
            GestureDetector(
              onTap: onToggleSync,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSynced
                      ? theme.activeLine.withValues(alpha: 0.12)
                      : theme.activeLine.withValues(alpha: 0.04),
                  border: Border.all(
                    color: isSynced
                        ? theme.activeLine.withValues(alpha: 0.35)
                        : theme.activeLine.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSynced
                          ? Icons.sync_rounded
                          : Icons.sync_disabled_rounded,
                      size: 11,
                      color: theme.activeLine
                          .withValues(alpha: isSynced ? 0.85 : 0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSynced ? 'Synced' : 'Plain',
                      style: TextStyle(
                        color: theme.activeLine
                            .withValues(alpha: isSynced ? 0.85 : 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Spacer if no LRC
            const SizedBox(width: 4),

          const Spacer(),

          // ··· More controls
          _TinyBtn(
            icon: Icons.tune_rounded,
            color: theme.activeLine,
            onTap: onMore,
          ),

          const SizedBox(width: 2),

          // Fullscreen
          _TinyBtn(
            icon: Icons.open_in_full_rounded,
            color: theme.activeLine,
            onTap: onFullscreen,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controls bottom sheet — font size, themes, copy, edit
// ─────────────────────────────────────────────────────────────────────────────

class _ControlsSheet extends StatelessWidget {
  const _ControlsSheet({
    required this.theme,
    required this.themeIdx,
    required this.fontSize,
    required this.rawLyrics,
    required this.lrcLines,
    required this.ci,
    required this.state,
    required this.player,
    required this.parentContext,
  });

  final _LyricsTheme theme;
  final ValueNotifier<int> themeIdx;
  final ValueNotifier<double> fontSize;
  final String rawLyrics;
  final List<LrcLine>? lrcLines;
  final int? ci;
  final AudioPlayerSuccessState state;
  final dynamic player;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    final cardBg =
        scaffold == Colors.black ? const Color(0xFF0E0E0E) : cs.surface;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Lyrics Settings',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
          ),

          const SizedBox(height: 20),

          // ── Font size ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.format_size_rounded,
                  color: onSurface.withValues(alpha: 0.4), size: 16),
              const SizedBox(width: 10),
              Text('Text Size',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              // − button
              _SheetBtn(
                icon: Icons.remove_rounded,
                primary: primary,
                onTap: () =>
                    fontSize.value = (fontSize.value - 1).clamp(10, 32),
              ),
              const SizedBox(width: 10),
              // value
              SizedBox(
                width: 28,
                child: Text(
                  '${fontSize.value.round()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // + button
              _SheetBtn(
                icon: Icons.add_rounded,
                primary: primary,
                onTap: () =>
                    fontSize.value = (fontSize.value + 1).clamp(10, 32),
              ),
            ],
          ),

          const SizedBox(height: 22),
          Divider(color: onSurface.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 18),

          // ── Theme picker ─────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Theme',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kThemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = _kThemes[i];
                final isActive = themeIdx.value == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    themeIdx.value = i;
                    // Rebuild sheet to reflect new active state
                    (context as Element).markNeedsBuild();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 72 : 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: t.bg,
                      border: Border.all(
                        color: isActive
                            ? primary
                            : t.border.withValues(alpha: 0.4),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: -2,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Color preview dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.activeLine,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.inactiveLine.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t.name,
                          style: TextStyle(
                            color: t.activeLine,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: onSurface.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 16),

          // ── Actions row: Copy | Edit ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.copy_rounded,
                  label: 'Copy Lyrics',
                  color: onSurface,
                  primary: primary,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: rawLyrics));
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      _snackBar('Lyrics copied', Icons.check_rounded),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Lyrics',
                  color: onSurface,
                  primary: primary,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(
                      const Duration(milliseconds: 200),
                      () => showDialog(
                        context: parentContext,
                        barrierColor: Colors.black.withValues(alpha: 0.7),
                        builder: (_) => _EditDialog(
                          initialText: rawLyrics,
                          ci: ci,
                          state: state,
                          primary: primary,
                          cs: cs,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen page
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenPage extends HookWidget {
  const _FullscreenPage({
    required this.lrcLines,
    required this.hasLrc,
    required this.rawLyrics,
    required this.fontSize,
    required this.isSynced,
    required this.themeIdx,
    required this.player,
    required this.ci,
    required this.state,
  });

  final List<LrcLine>? lrcLines;
  final bool hasLrc;
  final String rawLyrics;
  final double fontSize;
  final bool isSynced;
  final int themeIdx;
  final dynamic player;
  final int? ci;
  final AudioPlayerSuccessState state;

  @override
  Widget build(BuildContext context) {
    final localFont = useState(fontSize);
    final localSynced = useState(isSynced);
    final localTheme = useState(themeIdx);
    final showPicker = useState(false);

    final theme = _kThemes[localTheme.value];
    final showSynced = hasLrc && localSynced.value;

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
                // ── Top: close left, small controls right ──────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Close — chevron down, Apple style
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.activeLine.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.activeLine.withValues(alpha: 0.7),
                            size: 22,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Synced toggle
                      if (hasLrc) ...[
                        GestureDetector(
                          onTap: () => localSynced.value = !localSynced.value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: localSynced.value
                                  ? theme.activeLine.withValues(alpha: 0.12)
                                  : theme.activeLine.withValues(alpha: 0.04),
                              border: Border.all(
                                color: localSynced.value
                                    ? theme.activeLine.withValues(alpha: 0.35)
                                    : theme.activeLine.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_rounded,
                                    size: 12,
                                    color: theme.activeLine.withValues(
                                        alpha: localSynced.value ? 0.8 : 0.3)),
                                const SizedBox(width: 4),
                                Text(
                                  localSynced.value ? 'Synced' : 'Plain',
                                  style: TextStyle(
                                    color: theme.activeLine.withValues(
                                        alpha: localSynced.value ? 0.8 : 0.3),
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

                      // Font −
                      _TinyBtn(
                        icon: Icons.text_decrease_rounded,
                        color: theme.activeLine,
                        onTap: () => localFont.value =
                            (localFont.value - 1).clamp(10, 36),
                      ),
                      // Font +
                      _TinyBtn(
                        icon: Icons.text_increase_rounded,
                        color: theme.activeLine,
                        onTap: () => localFont.value =
                            (localFont.value + 1).clamp(10, 36),
                      ),

                      const SizedBox(width: 4),

                      // Theme palette button
                      _TinyBtn(
                        icon: Icons.palette_outlined,
                        color: theme.activeLine,
                        onTap: () => showPicker.value = !showPicker.value,
                      ),
                    ],
                  ),
                ),

                // ── Theme picker strip (collapsible) ───────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: showPicker.value
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: SizedBox(
                            height: 52,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _kThemes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final t = _kThemes[i];
                                final isActive = localTheme.value == i;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    localTheme.value = i;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isActive ? 72 : 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: t.bg,
                                      border: Border.all(
                                        color: isActive
                                            ? t.activeLine
                                            : t.border.withValues(alpha: 0.3),
                                        width: isActive ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.name,
                                        style: TextStyle(
                                          color: t.activeLine,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // ── Lyrics ─────────────────────────────────────────
                Expanded(
                  child: showSynced
                      ? _SyncedView(
                          lines: lrcLines!,
                          fontSize: localFont.value,
                          theme: theme,
                          player: player,
                          centered: true,
                        )
                      : _PlainView(
                          lyrics: rawLyrics,
                          fontSize: localFont.value,
                          theme: theme,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Synced view
// ─────────────────────────────────────────────────────────────────────────────

class _SyncedView extends HookWidget {
  const _SyncedView({
    required this.lines,
    required this.fontSize,
    required this.theme,
    required this.player,
    this.centered = false,
  });

  final List<LrcLine> lines;
  final double fontSize;
  final _LyricsTheme theme;
  final dynamic player;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = useScrollController();
    final activeIdx = useState(0);

    useEffect(() {
      void scrollTo(int idx) {
        if (!scrollCtrl.hasClients) return;
        try {
          final lh = fontSize * 3.6;
          final vh = scrollCtrl.position.viewportDimension;
          final target = (idx * lh) - (vh * 0.40) + (lh / 2);
          scrollCtrl.animateTo(
            target.clamp(0.0, scrollCtrl.position.maxScrollExtent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
      }

      final sub = player.positionStream.listen((Duration pos) {
        int lo = 0, hi = lines.length - 1, idx = 0;
        while (lo <= hi) {
          final mid = (lo + hi) ~/ 2;
          if (lines[mid].timestamp <= pos) {
            idx = mid;
            lo = mid + 1;
          } else {
            hi = mid - 1;
          }
        }
        if (idx != activeIdx.value) {
          activeIdx.value = idx;
          WidgetsBinding.instance.addPostFrameCallback((_) => scrollTo(idx));
        }
      });

      return sub.cancel;
    }, [lines, fontSize]);

    final vh = MediaQuery.sizeOf(context).height;
    final extraPad = centered ? vh * 0.32 : 0.0;

    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.fromLTRB(24, 8 + extraPad, 24, 24 + extraPad),
      itemCount: lines.length,
      itemBuilder: (_, i) {
        final isActive = i == activeIdx.value;
        final isPast = i < activeIdx.value;
        final isNext = i == activeIdx.value + 1;

        return GestureDetector(
          onTap: () {
            player.seek(lines[i].timestamp);
            HapticFeedback.selectionClick();
          },
          behavior: HitTestBehavior.opaque,
          child: _Line(
            text: lines[i].text,
            fontSize: fontSize,
            isActive: isActive,
            isPast: isPast,
            isNext: isNext,
            theme: theme,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plain view
// ─────────────────────────────────────────────────────────────────────────────

class _PlainView extends StatelessWidget {
  const _PlainView({
    required this.lyrics,
    required this.fontSize,
    required this.theme,
  });
  final String lyrics;
  final double fontSize;
  final _LyricsTheme theme;

  @override
  Widget build(BuildContext context) {
    final isEmpty = lyrics.trim().isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Text(
        isEmpty ? '♪  No lyrics available' : lyrics,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isEmpty
              ? theme.inactiveLine.withValues(alpha: 0.3)
              : theme.activeLine,
          fontSize: fontSize,
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w500,
          height: 1.9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single line
// ─────────────────────────────────────────────────────────────────────────────

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    required this.fontSize,
    required this.isActive,
    required this.isPast,
    required this.isNext,
    required this.theme,
  });

  final String text;
  final double fontSize;
  final bool isActive;
  final bool isPast;
  final bool isNext;
  final _LyricsTheme theme;

  @override
  Widget build(BuildContext context) {
    final display = text.isEmpty ? '♪' : text;

    if (isActive) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.activeLine.withValues(alpha: 0.07),
        ),
        child: Text(
          display,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.activeLine,
            fontSize: fontSize + 4,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w800,
            height: 1.4,
            letterSpacing: -0.4,
          ),
        ),
      );
    }

    final opacity = isPast ? 0.18 : (isNext ? 0.52 : 0.28);
    final blur = isPast ? 1.2 : (isNext ? 0.0 : 0.6);

    Widget tw = Text(
      display,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.inactiveLine.withValues(alpha: opacity),
        fontSize: isNext ? fontSize + 1 : fontSize,
        fontFamily: AppFonts.poppins,
        fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
        height: 1.7,
      ),
    );

    if (blur > 0) {
      tw = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: tw,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: tw,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _EditDialog extends HookWidget {
  const _EditDialog({
    required this.initialText,
    required this.ci,
    required this.state,
    required this.primary,
    required this.cs,
  });

  final String initialText;
  final int? ci;
  final AudioPlayerSuccessState state;
  final Color primary;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: initialText);
    final onSurface = cs.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color:
              scaffold == Colors.black ? const Color(0xFF0E0E0E) : cs.surface,
          border: Border.all(color: onSurface.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
              child: Row(
                children: [
                  Text('Edit Lyrics',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: onSurface.withValues(alpha: 0.35), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // LRC banner
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: ctrl,
              builder: (_, val, __) => LrcParser.isLrc(val.text)
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
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
                          child: Text(
                            'LRC format · timestamps will sync',
                            style: TextStyle(
                              color: primary.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: onSurface.withValues(alpha: 0.03),
                    border:
                        Border.all(color: onSurface.withValues(alpha: 0.06)),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      height: 1.7,
                      fontFamily: AppFonts.poppins,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste LRC or plain lyrics...',
                      hintStyle: TextStyle(
                          color: onSurface.withValues(alpha: 0.2),
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _DBtn(
                    label: 'Clear',
                    bg: onSurface.withValues(alpha: 0.05),
                    txtColor: onSurface.withValues(alpha: 0.4),
                    onTap: () => ctrl.clear(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _DBtn(
                      label: 'Save',
                      gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.8)]),
                      txtColor: cs.onPrimary,
                      shadow: primary.withValues(alpha: 0.3),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar('Lyrics saved', Icons.check_circle_rounded),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable pieces ──────────────────────────────────────────────────────

class _TinyBtn extends StatelessWidget {
  const _TinyBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
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

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.icon,
    required this.primary,
    required this.onTap,
  });
  final IconData icon;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
            border: Border.all(color: primary.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: primary, size: 16),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.primary,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.05),
            border: Border.all(color: color.withValues(alpha: 0.08), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      );
}

class _DBtn extends StatelessWidget {
  const _DBtn({
    required this.label,
    required this.txtColor,
    required this.onTap,
    this.bg,
    this.gradient,
    this.shadow,
  });
  final String label;
  final Color txtColor;
  final VoidCallback onTap;
  final Color? bg;
  final Gradient? gradient;
  final Color? shadow;

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
                ? [
                    BoxShadow(
                      color: shadow!,
                      blurRadius: 10,
                      spreadRadius: -3,
                    )
                  ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txtColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
        ),
      );
}

SnackBar _snackBar(String msg, IconData icon) => SnackBar(
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
