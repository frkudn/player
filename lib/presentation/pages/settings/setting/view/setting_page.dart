import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/presentation/common/widgets/custom_theme_mode_button_widget.dart';
import 'package:open_player/presentation/pages/settings/change_accent_color/view/change_accent_color_page.dart';
import 'package:open_player/presentation/pages/settings/setting/widgets/setting_bottom_navigation_bar_customization_widget.dart';
import 'package:open_player/presentation/pages/settings/setting/widgets/setting_change_app_bar_color_background_tile_widget.dart';
import 'package:open_player/presentation/pages/settings/setting/widgets/setting_change_scaffold_color_tile_widget.dart';
import 'package:open_player/utils/custom_snackbars.dart';
import 'package:open_player/utils/extensions.dart';
import '../../../../../base/router/router.dart';
import '../widgets/license_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS PAGE
//
// Design: Refined card-based layout with grouped sections — iOS-inspired but
// with personality through the primary-color accent system.
//
// Bugs fixed vs old version:
//  • EdgeInsets.symmetric(horizontal: 0.05) was pixel values → now proper dp
//  • Column + Gap(mqHeight*0.2) caused overflow → now ListView
//  • context.themeCubit.state outside BlocBuilder → now all reads inside builders
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

    // BlocBuilder wraps the entire page so ANY ThemeState change
    // (dark mode, accent, black mode) immediately reflects here.
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final Color primary = cs.primary;
        final Color onSurface = cs.onSurface;

        return Scaffold(
          // ListView replaces Column so the page is always scrollable
          // and never overflows regardless of content height.
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── HERO HEADER ──────────────────────────────────────────
              _SettingsHeader(primary: primary, onSurface: onSurface, lc: lc),

              const Gap(8),

              // ── APPEARANCE CARD ──────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionTitle(
                    label: AppStrings.appearance[lc]!,
                    icon: Icons.palette_outlined,
                    primary: primary,
                  ),

                  // Theme mode toggle row
                  _SettingRow(
                    label: 'Theme Mode',
                    icon: Icons.brightness_4_rounded,
                    primary: primary,
                    onSurface: onSurface,
                    trailing: const CustomThemeModeButtonWidget(),
                    onTap: () => context.read<ThemeCubit>().toggleThemeMode(),
                  ),

                  // Black mode — only visible in dark mode
                  if (state.isDarkMode)
                    _SettingRow(
                      label: 'Black Mode',
                      subtitle: 'True AMOLED black background',
                      icon: HugeIcons.strokeRoundedBlackHole,
                      primary: primary,
                      onSurface: onSurface,
                      trailing: Switch(
                        value: state.isBlackMode,
                        onChanged: (_) =>
                            context.read<ThemeCubit>().toggleBlackMode(),
                        activeThumbColor: primary,
                      ),
                      onTap: () => context.read<ThemeCubit>().toggleBlackMode(),
                    ),

                  // Custom themes toggle
                  _SettingRow(
                    label: 'Custom Themes',
                    subtitle: 'Override default color scheme',
                    icon: HugeIcons.strokeRoundedColors,
                    primary: primary,
                    onSurface: onSurface,
                    trailing: Switch(
                      value: !state.defaultTheme,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().toggleDefaultTheme(),
                      activeThumbColor: primary,
                    ),
                    onTap: () =>
                        context.read<ThemeCubit>().toggleDefaultTheme(),
                  ),

                  // Change accent colour — only when custom themes enabled
                  if (!state.defaultTheme) ...[
                    _SettingRow(
                      label: 'Accent Color',
                      subtitle: 'Pick your signature colour',
                      icon: Icons.color_lens_rounded,
                      primary: primary,
                      onSurface: onSurface,
                      trailing: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChangeAccentColorPage()),
                      ),
                    ),

                    // ── Customization sub-section ─────────────────────
                    _SubSectionDivider(
                        label: 'Customization', primary: primary),

                    // Scaffold colour
                    SettingChangeScaffoldColorTileWidget(),

                    // AppBar colour
                    SettingChangeAppBarColorBackgroundTileWidget(),

                    // Nav bar style
                    SettingBottomNavigationBarCustomizationWidget(),

                    // Restore defaults — only visible when not on defaults
                    if (!state.defaultTheme)
                      _RestoreDefaultRow(
                          primary: primary, onSurface: onSurface),
                  ],
                ],
              ),

              const Gap(12),

              // ── GENERAL CARD ──────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionTitle(
                    label: AppStrings.general[lc]!,
                    icon: Icons.tune_rounded,
                    primary: primary,
                  ),

                  // Profile
                  _SettingRow(
                    label: AppStrings.profile[lc]!,
                    icon: HugeIcons.strokeRoundedProfile02,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.userProfileRoute),
                  ),

                  _Divider(onSurface: onSurface),

                  // Language
                  _SettingRow(
                    label: AppStrings.language[lc]!,
                    icon: HugeIcons.strokeRoundedLanguageCircle,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.languageRoute),
                  ),

                  _Divider(onSurface: onSurface),

                  // Equalizer
                  _SettingRow(
                    label: AppStrings.equalizer[lc]!,
                    icon: Icons.equalizer_rounded,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.equalizerRoute),
                  ),

                  _Divider(onSurface: onSurface),

                  // Feedback
                  _SettingRow(
                    label: AppStrings.feedback[lc]!,
                    subtitle: 'frkudn@protonmail.com',
                    icon: HugeIcons.strokeRoundedMail01,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: _feedBackButtonOnTap,
                  ),
                ],
              ),

              const Gap(12),

              // ── ABOUT CARD ───────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionTitle(
                    label: 'About',
                    icon: Icons.info_outline_rounded,
                    primary: primary,
                  ),

                  // Privacy policy
                  _SettingRow(
                    label: AppStrings.privacyPolicy[lc]!,
                    icon: Icons.policy_outlined,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.privacyPolicyRoute),
                  ),

                  _Divider(onSurface: onSurface),

                  // Licenses
                  const LicenseWidget(),

                  _Divider(onSurface: onSurface),

                  // About app
                  _SettingRow(
                    label: AppStrings.about[lc]!,
                    icon: HugeIcons.strokeRoundedInformationDiamond,
                    primary: primary,
                    onSurface: onSurface,
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.aboutRoute),
                  ),
                ],
              ),

              // Bottom padding — space for the floating nav bar
              const Gap(100),
            ],
          ),
        );
      },
    );
  }

  // ── Email feedback ─────────────────────────────────────────────────────────
  Future<void> _feedBackButtonOnTap() async {
    HapticFeedback.lightImpact();
    try {
      final Email email = Email(
        body: 'Your feedback:',
        subject: 'Player App Feedback',
        recipients: ['frkudn@protonmail.com'],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open email: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
//
// Full-width gradient header with Settings title, app version, and a
// tagline. Uses the primary colour for depth — feels custom, not stock.
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.primary,
    required this.onSurface,
    required this.lc,
  });

  final Color primary;
  final Color onSurface;
  final String lc;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    // Top padding accounts for status bar height
    final double topPad = MediaQuery.paddingOf(context).top + 12;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      decoration: BoxDecoration(
        // Subtle gradient tint — adds depth without fighting the rest of the UI
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large settings title — strong typographic anchor
          Text(
            AppStrings.settings[lc]!,
            style: TextStyle(
              fontSize: mq.width >= 600 ? 48 : 36,
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: onSurface,
            ),
          ),

          const Gap(4),

          // App tagline — subtle secondary info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: primary.withValues(alpha: 0.12),
                  border: Border.all(
                      color: primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  AppStrings.appVersion,
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Gap(8),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontFamily: AppFonts.poppins,
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
// SECTION CARD
//
// Wraps a group of settings rows in a rounded card with a subtle border.
// Provides consistent horizontal padding and visual grouping.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

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
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
//
// Compact coloured-icon + uppercase label row used at the top of each card.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.icon,
    required this.primary,
  });

  final String label;
  final IconData icon;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 15, color: primary),
          ),
          const Gap(10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              fontFamily: AppFonts.poppins,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTING ROW
//
// The core building block — icon, label, optional subtitle, optional trailing.
// GestureDetector wraps the entire row for a large tap target.
// Ink ripple through InkWell for tactile feedback.
// ─────────────────────────────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onSurface,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Icon in a small pill container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 17, color: primary),
            ),

            const Gap(12),

            // Label + optional subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.poppins,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget (switch, colour dot, etc.) or chevron
            if (trailing != null) trailing!,
            if (showChevron && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-SECTION DIVIDER
//
// Thin labelled divider used to separate groups within the same card.
// ─────────────────────────────────────────────────────────────────────────────

class _SubSectionDivider extends StatelessWidget {
  const _SubSectionDivider({required this.label, required this.primary});

  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: primary.withValues(alpha: 0.15),
              thickness: 1,
              endIndent: 8,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primary.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          Expanded(
            child: Divider(
              color: primary.withValues(alpha: 0.15),
              thickness: 1,
              indent: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESTORE DEFAULTS ROW
//
// Only shown when the user has customised the theme.
// Styled as a soft warning action — not destructive red, just a nudge.
// ─────────────────────────────────────────────────────────────────────────────

class _RestoreDefaultRow extends StatelessWidget {
  const _RestoreDefaultRow({
    required this.primary,
    required this.onSurface,
  });

  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ThemeCubit>().restoreDefaultSetting();
        AppCustomSnackBars.normalSuccess('Restored to default settings');
      },
      splashColor: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.orange.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.settings_backup_restore_rounded,
                size: 17,
                color: Colors.orange,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restore to Defaults',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Reset all customizations',
                    style: TextStyle(
                      color: Colors.orange.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.orange.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THIN DIVIDER  — used between rows inside a card
// ─────────────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.onSurface});

  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 62, // aligns with text start (icon 34 + gap 12 + margin 16)
      endIndent: 16,
      color: onSurface.withValues(alpha: 0.08),
    );
  }
}
