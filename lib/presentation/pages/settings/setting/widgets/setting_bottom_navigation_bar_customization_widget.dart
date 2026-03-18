import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/utils/extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRESET DATA
//
// Each entry describes one of the 4 nav bar styles.
// Index 0-3 maps directly to ThemeState.navBarStyleIndex.
// To add a new preset: add here AND handle the new case in
// custom_bottom_nav_bar_widget.dart.
// ─────────────────────────────────────────────────────────────────────────────

class _Preset {
  final String name;
  final String description;
  final IconData previewIcon; // decorative icon shown on the card
  const _Preset({
    required this.name,
    required this.description,
    required this.previewIcon,
  });
}

const List<_Preset> _kPresets = [
  _Preset(
    name: 'Floating Pill',
    description: 'Centred glassmorphic pill that hovers above content.',
    previewIcon: Icons.radio_button_checked_rounded,
  ),
  _Preset(
    name: 'Full Bar',
    description: 'Standard bottom bar — icon + label, full width.',
    previewIcon: Icons.dock_rounded,
  ),
  _Preset(
    name: 'Side Rail',
    description: 'Vertical left rail. Best for tablets & landscape.',
    previewIcon: Icons.view_sidebar_rounded,
  ),
  _Preset(
    name: 'Minimal',
    description: 'Just icons with an active dot — max screen space.',
    previewIcon: Icons.more_horiz_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
//
// Sits inside an ExpansionTile in SettingCustomizationWidget.
// Uses BlocBuilder so the selected-card highlight stays in sync if ThemeCubit
// emits from somewhere else (e.g. "restore defaults").
// ─────────────────────────────────────────────────────────────────────────────

class SettingBottomNavigationBarCustomizationWidget extends StatelessWidget {
  const SettingBottomNavigationBarCustomizationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String lc = context.languageCubit.state.languageCode;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        AppStrings.bottomNavigationBar[lc]!,
        style: TextStyle(
          fontSize: 14,
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      children: [
        // BlocBuilder scoped only to this section so redraws stay cheap
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            final cs = Theme.of(context).colorScheme;
            final Color primary = cs.primary;
            final Color onSurface = cs.onSurface;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section heading ──────────────────────────────────────
                  _SectionHeader(label: 'Nav Style', primary: primary),
                  const Gap(16),

                  // ── 2 × 2 preset card grid ───────────────────────────────
                  // GridView.count keeps two cards per row on any screen width.
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    // Let the parent SingleChildScrollView handle scrolling
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // childAspectRatio: width / height — tweak for card height
                    childAspectRatio: 1.35,
                    children: List.generate(
                      _kPresets.length,
                      (i) => _PresetCard(
                        index: i,
                        preset: _kPresets[i],
                        isSelected: state.navBarStyleIndex == i,
                        primary: primary,
                        onSurface: onSurface,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<ThemeCubit>().setNavBarStyle(i);
                        },
                      ),
                    ),
                  ),

                  const Gap(20),

                  // ── "Changes are instant" info banner ───────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: primary.withValues(alpha: 0.06),
                      border: Border.all(
                          color: primary.withValues(alpha: 0.15), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: primary.withValues(alpha: 0.6),
                          size: 15,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'Tap a style — the nav bar updates instantly.',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(20),

                  // ── Reset to default button ──────────────────────────────
                  _ResetButton(
                    primary: primary,
                    onSurface: onSurface,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Resets to Style 0 (Floating Pill)
                      context.read<ThemeCubit>().setNavBarStyle(0);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESET CARD
//
// Tappable card showing a preview icon, style name, and description.
// Selected card gets a coloured border + subtle glow shadow.
// ─────────────────────────────────────────────────────────────────────────────

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.index,
    required this.preset,
    required this.isSelected,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  final int index;
  final _Preset preset;
  final bool isSelected;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? primary.withValues(alpha: 0.09)
              : onSurface.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : onSurface.withValues(alpha: 0.09),
            width: isSelected ? 1.5 : 1,
          ),
          // Glow shadow on selected card
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    spreadRadius: -3,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Top row: preview icon + number badge + checkmark ──────────
            Row(
              children: [
                // Circle with the representative icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? primary.withValues(alpha: 0.14)
                        : onSurface.withValues(alpha: 0.07),
                  ),
                  child: Icon(
                    preset.previewIcon,
                    size: 17,
                    color: isSelected
                        ? primary
                        : onSurface.withValues(alpha: 0.38),
                  ),
                ),

                const Spacer(),

                // Numeric badge ("1", "2", "3", "4")
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? primary.withValues(alpha: 0.14)
                        : onSurface.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? primary
                          : onSurface.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Checkmark only visible when this style is active
                if (isSelected) ...[
                  const SizedBox(width: 5),
                  Icon(Icons.check_circle_rounded, color: primary, size: 15),
                ],
              ],
            ),

            // ── Bottom: name + description ─────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: TextStyle(
                    color: isSelected ? primary : onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFonts.poppins,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preset.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.42),
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESET BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onSurface.withValues(alpha: 0.05),
          border:
              Border.all(color: onSurface.withValues(alpha: 0.09), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded,
                color: onSurface.withValues(alpha: 0.45), size: 16),
            const SizedBox(width: 8),
            Text(
              'Reset to Default  (Floating Pill)',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER — thin accent bar + uppercase label
// Matches the visual style used across other settings sections.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.primary});

  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            fontFamily: AppFonts.poppins,
          ),
        ),
      ],
    );
  }
}
