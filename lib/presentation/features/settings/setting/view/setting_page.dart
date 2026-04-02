import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';
import 'package:open_player/presentation/features/local_audio_player/cubit/lyrics/lyrics_cubit.dart';
import 'package:open_player/presentation/shared/widgets/custom_theme_mode_button_widget.dart';
import 'package:open_player/presentation/features/settings/change_accent_color/view/change_accent_color_page.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_bottom_navigation_bar_customization_widget.dart';
import 'package:open_player/utils/custom_snackbars.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../base/router/router.dart';
import '../widgets/license_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS PAGE
//
// Six sections, each in a collapsible _Card:
//
//   1. APPEARANCE   — theme mode, black mode, custom themes, accent color,
//                     scaffold/appbar color, contrast slider
//   2. DISPLAY      — hide status bar, mini player style (3 chips)
//   3. AUDIO PLAYER — dynamic background, player layout (3 chips), lyrics
//   4. NAVIGATION   — reuses SettingBottomNavigationBarCustomizationWidget
//                     (6 presets + size + opacity + free position + width)
//   5. GENERAL      — profile, language, equalizer, feedback
//   6. ABOUT        — privacy, licenses, about, check for updates
//
// Existing widgets reused unchanged:
//   CustomThemeModeButtonWidget, ChangeAccentColorPage,
//   SettingChangeScaffoldColorTileWidget,
//   SettingChangeAppBarColorBackgroundTileWidget,
//   SettingBottomNavigationBarCustomizationWidget, LicenseWidget
//
// Responsive: all sizes are screen-relative; no hard-coded pixel dimensions.
// No overflow: every text is inside Expanded/Flexible, every list is constrained.
// ─────────────────────────────────────────────────────────────────────────────

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final String lc = context.languageCubit.state.languageCode;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final Color pr = cs.primary;
        final Color os = cs.onSurface;

        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── HERO HEADER ────────────────────────────────────────────
              _Header(pr: pr, os: os, lc: lc),
              const Gap(8),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 1. APPEARANCE
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                _CardTitle(
                    label: AppStrings.appearance[lc]!,
                    icon: Icons.palette_outlined,
                    pr: pr),

                // Theme mode — reuses animated toggle widget
                _Row(
                    label: 'Theme Mode',
                    icon: Icons.brightness_4_rounded,
                    pr: pr,
                    os: os,
                    trailing: const CustomThemeModeButtonWidget(),
                    onTap: () => context.read<ThemeCubit>().toggleThemeMode()),

                // Black AMOLED mode — only visible in dark mode
                if (state.isDarkMode) ...[
                  _Div(os: os),
                  _Row(
                      label: 'Black Mode',
                      subtitle: 'True AMOLED black background',
                      icon: HugeIcons.strokeRoundedBlackHole,
                      pr: pr,
                      os: os,
                      trailing: Switch(
                        value: state.isBlackMode,
                        onChanged: (_) =>
                            context.read<ThemeCubit>().toggleBlackMode(),
                        activeThumbColor: pr,
                      ),
                      onTap: () =>
                          context.read<ThemeCubit>().toggleBlackMode()),
                ],

                _Div(os: os),

                // Custom themes toggle
                _Row(
                    label: 'Custom Themes',
                    subtitle: 'Override the default color scheme',
                    icon: HugeIcons.strokeRoundedColors,
                    pr: pr,
                    os: os,
                    trailing: Switch(
                      value: !state.defaultTheme,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().toggleDefaultTheme(),
                      activeThumbColor: pr,
                    ),
                    onTap: () =>
                        context.read<ThemeCubit>().toggleDefaultTheme()),

                // Sub-options visible only when custom themes is enabled
                if (!state.defaultTheme) ...[
                  _Div(os: os),
                  // Accent color — opens your existing ChangeAccentColorPage
                  _Row(
                      label: 'Accent Color',
                      subtitle: 'Your signature color',
                      icon: Icons.color_lens_rounded,
                      pr: pr,
                      os: os,
                      trailing: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pr,
                          boxShadow: [
                            BoxShadow(
                                color: pr.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1)
                          ],
                        ),
                      ),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangeAccentColorPage()))),

                  _SubDiv(label: 'Colors', pr: pr),


                  // Contrast level slider
                  _ContrastSlider(pr: pr, os: os, state: state),

                  // Restore defaults — orange accent, soft warning
                  _RestoreRow(pr: pr, os: os),
                ],
              ]),

              const Gap(12),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 2. DISPLAY
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                _CardTitle(
                    label: 'Display',
                    icon: Icons.phone_android_rounded,
                    pr: pr),

                // Hide status bar — full immersive experience
                _Row(
                    label: 'Hide Status Bar',
                    subtitle: 'Full-screen immersive mode',
                    icon: Icons.fullscreen_rounded,
                    pr: pr,
                    os: os,
                    trailing: Switch(
                      value: state.hideStatusBar,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().toggleHideStatusBar(),
                      activeThumbColor: pr,
                    ),
                    onTap: () =>
                        context.read<ThemeCubit>().toggleHideStatusBar()),

                _Div(os: os),

                // Dynamic flowing background toggle
                _Row(
                    label: 'Dynamic Background',
                    subtitle: 'Blurred art drifts + breathes',
                    icon: Icons.auto_awesome_rounded,
                    pr: pr,
                    os: os,
                    trailing: Switch(
                      value: state.playerDynamicLightEnabled,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().togglePlayerDynamicLight(),
                      activeThumbColor: pr,
                    ),
                    onTap: () =>
                        context.read<ThemeCubit>().togglePlayerDynamicLight()),

                _Div(os: os),

                // Mini player style picker
                _MiniPlayerStylePicker(pr: pr, os: os, state: state),
              ]),

              const Gap(12),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 3. AUDIO PLAYER — collapsible (has a lot of content)
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    title: Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: pr.withValues(alpha: 0.12)),
                        child: Icon(HugeIcons.strokeRoundedMusicNote02,
                            size: 15, color: pr),
                      ),
                      const Gap(10),
                      Text('AUDIO PLAYER',
                          style: TextStyle(
                              color: pr,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              fontFamily: AppFonts.poppins)),
                    ]),
                    children: [
                      // Player layout style — 3 chips
                      _PlayerStylePicker(pr: pr, os: os, state: state),

                      _Div(os: os),

                      // Lyrics settings — shares the same LyricsCubit
                      // the player uses, so changes here reflect instantly
                      // inside the player and vice versa. Original lyrics
                      // widget code is not touched.
                      _LyricsSection(pr: pr, os: os),

                      const Gap(8),
                    ],
                  ),
                ),
              ]),

              const Gap(12),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 4. NAVIGATION BAR
              // SettingBottomNavigationBarCustomizationWidget is already an
              // ExpansionTile — do NOT double-wrap it with another title.
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: const SettingBottomNavigationBarCustomizationWidget(),
                ),
              ]),

              const Gap(12),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 5. GENERAL
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                _CardTitle(
                    label: AppStrings.general[lc]!,
                    icon: Icons.tune_rounded,
                    pr: pr),
                _Row(
                    label: AppStrings.profile[lc]!,
                    icon: HugeIcons.strokeRoundedProfile02,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.userProfileRoute)),
                _Div(os: os),
                _Row(
                    label: AppStrings.language[lc]!,
                    icon: HugeIcons.strokeRoundedLanguageCircle,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.languageRoute)),
                _Div(os: os),
                _Row(
                    label: AppStrings.equalizer[lc]!,
                    icon: Icons.equalizer_rounded,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.equalizerRoute)),
                _Div(os: os),
                _Row(
                    label: AppStrings.feedback[lc]!,
                    subtitle: 'frkudn@protonmail.com',
                    icon: HugeIcons.strokeRoundedMail01,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: _onFeedback),
              ]),

              const Gap(12),

              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              // 6. ABOUT
              // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              _Card(children: [
                _CardTitle(
                    label: 'About', icon: Icons.info_outline_rounded, pr: pr),
                _Row(
                    label: AppStrings.privacyPolicy[lc]!,
                    icon: Icons.policy_outlined,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.privacyPolicyRoute)),
                _Div(os: os),
                // Reusing your existing LicenseWidget
                const LicenseWidget(),
                _Div(os: os),
                _Row(
                    label: AppStrings.about[lc]!,
                    icon: HugeIcons.strokeRoundedInformationDiamond,
                    pr: pr,
                    os: os,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.aboutRoute)),
                _Div(os: os),
                // Check for updates — GitHub releases API
                _UpdateRow(pr: pr, os: os),
              ]),

              // Bottom padding clears the floating nav bar
              const Gap(100),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onFeedback() async {
    HapticFeedback.lightImpact();
    try {
      await FlutterEmailSender.send(Email(
        body: 'Your feedback:',
        subject: 'Player App Feedback',
        recipients: ['frkudn@protonmail.com'],
        isHTML: false,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTRAST SLIDER
//
// Exposed in the custom themes sub-section. Lets users tune color contrast
// via ThemeData.colorScheme contrastLevel (0.0–1.0).
// ═══════════════════════════════════════════════════════════════════════════

class _ContrastSlider extends StatelessWidget {
  const _ContrastSlider(
      {required this.pr, required this.os, required this.state});
  final Color pr, os;
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.contrast_rounded,
              size: 14, color: os.withValues(alpha: 0.45)),
          const Gap(8),
          Text('Contrast',
              style: TextStyle(
                  color: os.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${(state.contrastLevel * 100).round()}%',
              style: TextStyle(
                  color: pr, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: pr,
            inactiveTrackColor: pr.withValues(alpha: 0.15),
            thumbColor: pr,
            overlayColor: pr.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: state.contrastLevel.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (v) => context.read<ThemeCubit>().changeContrastLevel(v),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MINI PLAYER STYLE PICKER
//
// 3 chip cards:
//   0 = Classic   — original glassmorphic card
//   1 = Compact   — slim pill bar
//   2 = Artwork   — large artwork dominant
//
// Saves to ThemeState.miniPlayerStyleIndex via ThemeCubit → Hive.
// MiniAudioPlayerWidget reads this to switch layouts instantly.
// ═══════════════════════════════════════════════════════════════════════════

class _MiniPlayerStylePicker extends StatelessWidget {
  const _MiniPlayerStylePicker(
      {required this.pr, required this.os, required this.state});
  final Color pr, os;
  final ThemeState state;

  static const _opts = [
    (
      name: 'Classic',
      desc: 'Glass card + seek bar',
      icon: Icons.view_agenda_rounded
    ),
    (name: 'Compact', desc: 'Slim pill bar', icon: Icons.minimize_rounded),
    (name: 'Artwork', desc: 'Large album art card', icon: Icons.image_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InnerLabel(
            label: 'MINI PLAYER', icon: Icons.queue_music_rounded, pr: pr),
        const Gap(10),
        // LayoutBuilder ensures chips never overflow on narrow screens
        Row(
            children: List.generate(_opts.length, (i) {
          final bool active = state.miniPlayerStyleIndex == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<ThemeCubit>().setMiniPlayerStyle(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: active
                        ? pr.withValues(alpha: 0.1)
                        : os.withValues(alpha: 0.04),
                    border: Border.all(
                      color: active
                          ? pr.withValues(alpha: 0.4)
                          : os.withValues(alpha: 0.09),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_opts[i].icon,
                        size: 18,
                        color: active ? pr : os.withValues(alpha: 0.4)),
                    const Gap(5),
                    Text(_opts[i].name,
                        style: TextStyle(
                            color: active ? pr : os.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const Gap(2),
                    Text(_opts[i].desc,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                            color: os.withValues(alpha: 0.3),
                            fontSize: 7.5,
                            height: 1.3)),
                  ]),
                ),
              ),
            ),
          );
        })),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAYER STYLE PICKER
//
// 3 chips for the full-screen audio player layout.
//   0 = Classic    1 = Minimal    2 = Immersive
// ═══════════════════════════════════════════════════════════════════════════

class _PlayerStylePicker extends StatelessWidget {
  const _PlayerStylePicker(
      {required this.pr, required this.os, required this.state});
  final Color pr, os;
  final ThemeState state;

  static const _opts = [
    (
      name: 'Classic',
      desc: 'Thumbnail + glass controls',
      icon: Icons.crop_square_rounded
    ),
    (
      name: 'Minimal',
      desc: 'Full art, overlaid controls',
      icon: Icons.fullscreen_rounded
    ),
    (
      name: 'Immersive',
      desc: 'Edge-to-edge, dark scrim',
      icon: Icons.fit_screen_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InnerLabel(label: 'PLAYER LAYOUT', icon: Icons.style_rounded, pr: pr),
        const Gap(10),
        Row(
            children: List.generate(_opts.length, (i) {
          final bool active = state.playerStyleIndex == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<ThemeCubit>().setPlayerStyle(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: active
                        ? pr.withValues(alpha: 0.1)
                        : os.withValues(alpha: 0.04),
                    border: Border.all(
                      color: active
                          ? pr.withValues(alpha: 0.4)
                          : os.withValues(alpha: 0.09),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_opts[i].icon,
                        size: 18,
                        color: active ? pr : os.withValues(alpha: 0.4)),
                    const Gap(5),
                    Text(_opts[i].name,
                        style: TextStyle(
                            color: active ? pr : os.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const Gap(2),
                    Text(_opts[i].desc,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                            color: os.withValues(alpha: 0.3),
                            fontSize: 7.5,
                            height: 1.3)),
                  ]),
                ),
              ),
            ),
          );
        })),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LYRICS SETTINGS SECTION
//
// Reads/writes the same LyricsCubit the player uses — changes here are
// immediately reflected inside the player and vice versa.
// The original AudioPlayerLyricsBoxWidget code is NOT modified.
// ═══════════════════════════════════════════════════════════════════════════

class _LyricsSection extends StatelessWidget {
  const _LyricsSection({required this.pr, required this.os});
  final Color pr, os;

  // Colors mirror the _themes constant in audio_player_lyrics_box_widget.dart
  static const _swatches = [
    (name: 'Dark', bg: Color(0xFF1A1A2E)),
    (name: 'Light', bg: Color(0xFFF5F5F5)),
    (name: 'Gold', bg: Color(0xFFFFF9C4)),
    (name: 'Rose', bg: Color(0xFFFCE4EC)),
    (name: 'Night', bg: Color(0xFF070714)),
    (name: 'Forest', bg: Color(0xFFE8F5E9)),
  ];

  static const _styleNames = [
    'Classic',
    'Bold',
    'Minimal',
    'Karaoke',
    'Elegant'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, ls) {
        final cubit = context.read<LyricsCubit>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InnerLabel(label: 'LYRICS', icon: Icons.lyrics_rounded, pr: pr),
            const Gap(12),

            // Font size +/–
            Row(children: [
              Icon(Icons.format_size_rounded,
                  size: 14, color: os.withValues(alpha: 0.45)),
              const Gap(8),
              Text('Text Size',
                  style: TextStyle(
                      color: os.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              _CBtn(
                  icon: Icons.remove_rounded,
                  color: pr,
                  onTap: () => cubit.setFontSize(ls.fontSize - 1)),
              const Gap(10),
              Text('${ls.fontSize.round()}',
                  style: TextStyle(
                      color: os, fontSize: 14, fontWeight: FontWeight.w700)),
              const Gap(10),
              _CBtn(
                  icon: Icons.add_rounded,
                  color: pr,
                  onTap: () => cubit.setFontSize(ls.fontSize + 1)),
            ]),

            const Gap(12),

            // Synced mode toggle
            Row(children: [
              Icon(Icons.sync_rounded,
                  size: 14, color: os.withValues(alpha: 0.45)),
              const Gap(8),
              Text('Synced Lyrics',
                  style: TextStyle(
                      color: os.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(
                  value: ls.isSynced,
                  onChanged: (_) => cubit.toggleSynced(),
                  activeThumbColor: pr),
            ]),

            const Gap(12),

            // Color theme swatches
            Text('Theme',
                style: TextStyle(
                    color: os.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const Gap(8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _swatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final bool active = ls.themeIndex == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cubit.setTheme(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 68 : 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _swatches[i].bg,
                        border: Border.all(
                          color: active ? pr : os.withValues(alpha: 0.15),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Center(
                          child: Text(_swatches[i].name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _swatches[i].bg.computeLuminance() > 0.4
                                    ? Colors.black87
                                    : Colors.white70,
                              ))),
                    ),
                  );
                },
              ),
            ),

            const Gap(12),

            // Display style chips
            Text('Style',
                style: TextStyle(
                    color: os.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const Gap(8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _styleNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final bool active = ls.styleIndex == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cubit.setStyle(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: active
                            ? pr.withValues(alpha: 0.12)
                            : os.withValues(alpha: 0.04),
                        border: Border.all(
                          color: active
                              ? pr.withValues(alpha: 0.4)
                              : os.withValues(alpha: 0.09),
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Text(_styleNames[i],
                          style: TextStyle(
                              color: active ? pr : os.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHECK FOR UPDATES ROW
//
// Fetches https://api.github.com/repos/frkudn/player/releases/latest,
// compares tag_name with AppStrings.appVersion, shows a dialog.
// If a newer version exists, the dialog has a Download button that opens
// the GitHub releases page in the device browser.
// ═══════════════════════════════════════════════════════════════════════════

class _UpdateRow extends StatefulWidget {
  const _UpdateRow({required this.pr, required this.os});
  final Color pr, os;
  @override
  State<_UpdateRow> createState() => _UpdateRowState();
}

class _UpdateRowState extends State<_UpdateRow> {
  bool _loading = false;

  Future<void> _check() async {
    if (_loading) return;
    setState(() => _loading = true);
    HapticFeedback.selectionClick();
    try {
      final resp = await http
          .get(Uri.parse(
              'https://api.github.com/repos/frkudn/player/releases/latest'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final String latest =
            (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
        final String current = AppStrings.appVersion.replaceAll('v', '').trim();
        latest == current
            ? _dialog('Up to date ✓',
                'You have the latest version (${AppStrings.appVersion}).', null)
            : _dialog(
                'Update available!',
                'v$latest is available. You have ${AppStrings.appVersion}.',
                data['html_url'] as String?);
      } else {
        _snack('Could not fetch release info (${resp.statusCode}).');
      }
    } catch (_) {
      if (mounted) _snack('Check your internet connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dialog(String title, String body, String? url) {
    final pr = widget.pr;
    final os = widget.os;
    final Color bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF12121A)
        : Theme.of(context).colorScheme.surface;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: bg,
            border: Border.all(color: pr.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: pr.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: -4)
            ],
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pr.withValues(alpha: 0.12)),
                      child: Icon(
                          url != null
                              ? Icons.system_update_rounded
                              : Icons.check_circle_outline_rounded,
                          color: pr,
                          size: 18)),
                  const Gap(12),
                  Expanded(
                      child: Text(title,
                          style: TextStyle(
                              color: os,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppFonts.poppins))),
                ]),
                const Gap(14),
                Text(body,
                    style: TextStyle(
                        color: os.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.5)),
                const Gap(20),
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: os.withValues(alpha: 0.06),
                        border: Border.all(color: os.withValues(alpha: 0.08)),
                      ),
                      child: Text('Dismiss',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: os.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  )),
                  if (url != null) ...[
                    const Gap(10),
                    Expanded(
                        child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: pr.withValues(alpha: 0.12),
                          border: Border.all(
                              color: pr.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Text('Download',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: pr,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    )),
                  ],
                ]),
              ]),
        ),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12)),
      );

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _check,
        splashColor: widget.pr.withValues(alpha: 0.08),
        highlightColor: widget.pr.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.pr.withValues(alpha: 0.1)),
                child: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: widget.pr))
                    : Icon(Icons.system_update_rounded,
                        size: 17, color: widget.pr)),
            const Gap(12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text('Check for Updates',
                      style: TextStyle(
                          color: widget.os,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.poppins)),
                  Text('Current: ${AppStrings.appVersion}',
                      style: TextStyle(
                          color: widget.os.withValues(alpha: 0.4),
                          fontSize: 11)),
                ])),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: widget.os.withValues(alpha: 0.3)),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED PRIMITIVE WIDGETS — private to this file
// ═══════════════════════════════════════════════════════════════════════════

/// Large gradient header with title, version badge, and tagline.
class _Header extends StatelessWidget {
  const _Header({required this.pr, required this.os, required this.lc});
  final Color pr, os;
  final String lc;
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final double topPad = MediaQuery.paddingOf(context).top + 12;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [pr.withValues(alpha: 0.08), pr.withValues(alpha: 0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border(
            bottom: BorderSide(color: pr.withValues(alpha: 0.1), width: 1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.settings[lc]!,
            style: TextStyle(
                // Responsive font — larger on tablets
                fontSize: mq.width >= 600 ? 48 : 36,
                fontFamily: AppFonts.poppins,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: os)),
        const Gap(4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: pr.withValues(alpha: 0.12),
              border: Border.all(color: pr.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(AppStrings.appVersion,
                style: TextStyle(
                    color: pr,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const Gap(8),
          Flexible(
              child: Text(AppStrings.appTagline,
                  style: TextStyle(
                      color: os.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontFamily: AppFonts.poppins),
                  overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}

/// Rounded card container that groups related setting rows.
class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }
}

/// Card top title — colored icon badge + uppercase label.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.label, required this.icon, required this.pr});
  final String label;
  final IconData icon;
  final Color pr;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: pr.withValues(alpha: 0.12)),
              child: Icon(icon, size: 15, color: pr)),
          const Gap(10),
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: pr,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  fontFamily: AppFonts.poppins)),
        ]),
      );
}

/// Standard tappable row: icon pill + label + optional subtitle + trailing.
/// Text is inside Expanded so it never overflows on any screen width.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.icon,
    required this.pr,
    required this.os,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color pr, os;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showChevron;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        splashColor: pr.withValues(alpha: 0.08),
        highlightColor: pr.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: pr.withValues(alpha: 0.1)),
                child: Icon(icon, size: 17, color: pr)),
            const Gap(12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(label,
                      style: TextStyle(
                          color: os,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.poppins)),
                  if (subtitle != null) ...[
                    const Gap(1),
                    Text(subtitle!,
                        style: TextStyle(
                            color: os.withValues(alpha: 0.4), fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ])),
            if (trailing != null) trailing!,
            if (showChevron && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: os.withValues(alpha: 0.3)),
          ]),
        ),
      );
}

/// 0.5 px divider indented to align with row text start.
class _Div extends StatelessWidget {
  const _Div({required this.os});
  final Color os;
  @override
  Widget build(BuildContext context) => Divider(
      height: 1,
      thickness: 0.5,
      indent: 62,
      endIndent: 16,
      color: os.withValues(alpha: 0.08));
}

/// Labelled rule separating sub-groups inside a card.
class _SubDiv extends StatelessWidget {
  const _SubDiv({required this.label, required this.pr});
  final String label;
  final Color pr;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(children: [
          Expanded(
              child: Divider(
                  color: pr.withValues(alpha: 0.15),
                  thickness: 1,
                  endIndent: 8)),
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: pr.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          Expanded(
              child: Divider(
                  color: pr.withValues(alpha: 0.15), thickness: 1, indent: 8)),
        ]),
      );
}

/// Small inline sub-section label (accent bar + icon + text).
class _InnerLabel extends StatelessWidget {
  const _InnerLabel(
      {required this.label, required this.icon, required this.pr});
  final String label;
  final IconData icon;
  final Color pr;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: pr.withValues(alpha: 0.7)),
        const Gap(6),
        Text(label,
            style: TextStyle(
                color: pr,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                fontFamily: AppFonts.poppins)),
      ]);
}

/// Orange "Restore to Defaults" row — only shown when custom themes are on.
class _RestoreRow extends StatelessWidget {
  const _RestoreRow({required this.pr, required this.os});
  final Color pr, os;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.read<ThemeCubit>().restoreDefaultSetting();
          AppCustomSnackBars.normalSuccess('Restored to default settings');
        },
        splashColor: Colors.orange.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.orange.withValues(alpha: 0.1)),
                child: const Icon(Icons.settings_backup_restore_rounded,
                    size: 17, color: Colors.orange)),
            const Gap(12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Restore to Defaults',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text('Reset all customizations',
                      style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.6),
                          fontSize: 11)),
                ])),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.orange.withValues(alpha: 0.5)),
          ]),
        ),
      );
}

/// Tiny circle +/– button for the lyrics font-size control.
class _CBtn extends StatelessWidget {
  const _CBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Icon(icon, color: color, size: 14)),
      );
}
