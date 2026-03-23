import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';
import 'package:open_player/utils/extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION BAR CUSTOMIZATION WIDGET
//
// Comprehensive nav bar customization in a single collapsible ExpansionTile:
//
//   STYLE      — 6 preset cards (3×2 grid)
//   SIZE       — 3 size chips (Compact / Regular / Large)
//   OPACITY    — slider (glass-background styles only: 0, 1, 2, 4, 5)
//   POSITION   — horizontal + vertical sliders (free placement anywhere)
//   WIDTH      — width slider (how wide the bar is)
//   RESET      — restores style + position + size + opacity to defaults
//
// All changes are instant and saved to Hive via ThemeCubit.
// BlocBuilder is scoped tightly so only this widget redraws on ThemeState emit.
// ─────────────────────────────────────────────────────────────────────────────

// ── Preset descriptors ─────────────────────────────────────────────────────

class _Preset {
  final String name, description;
  final IconData icon;
  const _Preset(this.name, this.description, this.icon);
}

const List<_Preset> _kPresets = [
  _Preset('Floating Pill', 'Glassmorphic pill hovering above content',
      Icons.radio_button_checked_rounded),
  _Preset('Full Bar', 'Full-width bar with icon + label', Icons.dock_rounded),
  _Preset('Side Rail', 'Vertical left rail — ideal for tablets',
      Icons.view_sidebar_rounded),
  _Preset('Minimal Dot', 'Icons only + animated active dot',
      Icons.more_horiz_rounded),
  _Preset('Labeled Island', 'Active tab expands to reveal its label',
      Icons.blur_on_rounded),
  _Preset('Segmented', 'Sliding fill indicator — iOS feel',
      Icons.view_week_rounded),
];

// Glass-background styles where opacity control is meaningful
const Set<int> _kGlassStyles = {0, 1, 2, 4, 5};

// ── Main widget ────────────────────────────────────────────────────────────

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
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            final cs = Theme.of(context).colorScheme;
            final Color pr = cs.primary;
            final Color os = cs.onSurface;
            final cubit = context.read<ThemeCubit>();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── STYLE GRID (3 × 2) ──────────────────────────────────
                  _SectionLabel(
                      label: 'STYLE', icon: Icons.style_rounded, pr: pr),
                  const Gap(12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _kPresets.length,
                    itemBuilder: (_, i) {
                      final bool active = state.navBarStyleIndex == i;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          cubit.setNavBarStyle(i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: active
                                ? pr.withValues(alpha: 0.09)
                                : os.withValues(alpha: 0.04),
                            border: Border.all(
                              color: active
                                  ? pr.withValues(alpha: 0.45)
                                  : os.withValues(alpha: 0.09),
                              width: active ? 1.5 : 1,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: pr.withValues(alpha: 0.14),
                                      blurRadius: 10,
                                      spreadRadius: -3,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: active
                                        ? pr.withValues(alpha: 0.14)
                                        : os.withValues(alpha: 0.07),
                                  ),
                                  child: Icon(_kPresets[i].icon,
                                      size: 14,
                                      color: active
                                          ? pr
                                          : os.withValues(alpha: 0.35)),
                                ),
                                const Spacer(),
                                if (active)
                                  Icon(Icons.check_circle_rounded,
                                      color: pr, size: 13)
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: os.withValues(alpha: 0.06),
                                    ),
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            color: os.withValues(alpha: 0.3),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700)),
                                  ),
                              ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_kPresets[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: active ? pr : os,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: AppFonts.poppins)),
                                    const SizedBox(height: 2),
                                    Text(_kPresets[i].description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: os.withValues(alpha: 0.35),
                                            fontSize: 7.5,
                                            height: 1.3)),
                                  ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Gap(20),

                  // ── SIZE CHIPS ───────────────────────────────────────────
                  _SectionLabel(
                      label: 'SIZE', icon: Icons.format_size_rounded, pr: pr),
                  const Gap(12),
                  Row(
                      children: List.generate(3, (i) {
                    const labels = ['Compact', 'Regular', 'Large'];
                    const icons = [
                      Icons.compress_rounded,
                      Icons.crop_square_rounded,
                      Icons.expand_rounded,
                    ];
                    final bool active = state.navBarSizeIndex == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cubit.setNavBarSize(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icons[i],
                                      size: 16,
                                      color: active
                                          ? pr
                                          : os.withValues(alpha: 0.4)),
                                  const SizedBox(height: 4),
                                  Text(labels[i],
                                      style: TextStyle(
                                          color: active
                                              ? pr
                                              : os.withValues(alpha: 0.5),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          ),
                        ),
                      ),
                    );
                  })),

                  // ── OPACITY (glass styles only) ──────────────────────────
                  if (_kGlassStyles.contains(state.navBarStyleIndex)) ...[
                    const Gap(20),
                    _SectionLabel(
                        label: 'OPACITY', icon: Icons.opacity_rounded, pr: pr),
                    const Gap(10),
                    _SliderTile(
                      label: 'Background opacity',
                      valueLabel: '${(state.navBarOpacity * 100).round()}%',
                      min: 0.4,
                      max: 1.0,
                      divisions: 12,
                      value: state.navBarOpacity.clamp(0.4, 1.0),
                      pr: pr,
                      os: os,
                      minLabel: '40%',
                      maxLabel: '100%',
                      onChanged: (v) => cubit.setNavBarOpacity(v),
                    ),
                  ],

                  const Gap(20),

                  // ── POSITION (free placement) ────────────────────────────
                  // Exposes the existing bottomNavBarPositionFromLeft and
                  // bottomNavBarPositionFromBottom Hive fields via sliders.
                  // Users can place the nav bar exactly where they want it.
                  _SectionLabel(
                      label: 'FREE POSITION',
                      icon: Icons.open_with_rounded,
                      pr: pr),
                  const Gap(4),
                  Text(
                    'Move the nav bar anywhere on the screen',
                    style: TextStyle(
                        color: os.withValues(alpha: 0.4), fontSize: 11),
                  ),
                  const Gap(10),

                  // Horizontal position (left ↔ right)
                  _SliderTile(
                    label: 'Horizontal position',
                    valueLabel:
                        '${(state.bottomNavBarPositionFromLeft * 100).round()}%',
                    min: 0.0,
                    max: 0.9,
                    divisions: 90,
                    value: state.bottomNavBarPositionFromLeft.clamp(0.0, 0.9),
                    pr: pr,
                    os: os,
                    minLabel: 'Left',
                    maxLabel: 'Right',
                    onChanged: (v) => cubit.setNavBarPositionX(v),
                  ),

                  const Gap(8),

                  // Vertical position (bottom ↔ top)
                  _SliderTile(
                    label: 'Vertical position',
                    valueLabel:
                        '${(state.bottomNavBarPositionFromBottom * 100).round()}%',
                    min: 0.0,
                    max: 0.9,
                    divisions: 90,
                    value: state.bottomNavBarPositionFromBottom.clamp(0.0, 0.9),
                    pr: pr,
                    os: os,
                    minLabel: 'Bottom',
                    maxLabel: 'Top',
                    onChanged: (v) => cubit.setNavBarPositionY(v),
                  ),

                  const Gap(20),

                  // ── WIDTH ────────────────────────────────────────────────
                  _SectionLabel(
                      label: 'WIDTH', icon: Icons.swap_horiz_rounded, pr: pr),
                  const Gap(10),
                  _SliderTile(
                    label: 'Nav bar width',
                    valueLabel: '${(state.bottomNavBarWidth * 100).round()}%',
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    value: state.bottomNavBarWidth.clamp(0.3, 1.0),
                    pr: pr,
                    os: os,
                    minLabel: 'Narrow',
                    maxLabel: 'Full',
                    onChanged: (v) => cubit.setNavBarWidth(v),
                  ),

                  const Gap(20),

                  // ── INFO BANNER ──────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: pr.withValues(alpha: 0.06),
                      border: Border.all(color: pr.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: pr.withValues(alpha: 0.6), size: 13),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'All changes apply instantly and are saved automatically.',
                          style: TextStyle(
                              color: os.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ),
                    ]),
                  ),

                  const Gap(14),

                  // ── RESET ────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cubit.setNavBarStyle(0);
                      cubit.setNavBarSize(1);
                      cubit.setNavBarOpacity(0.9);
                      cubit.setNavBarPositionX(0.1);
                      cubit.setNavBarPositionY(0.05);
                      cubit.setNavBarWidth(0.8);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: os.withValues(alpha: 0.05),
                        border: Border.all(color: os.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: os.withValues(alpha: 0.4), size: 15),
                            const SizedBox(width: 8),
                            Text('Reset nav bar to defaults',
                                style: TextStyle(
                                    color: os.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// SHARED PRIMITIVES (private to this file)
// ═══════════════════════════════════════════════════════════════════════════

/// Small labeled section header used inside the expansion tile.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
      {required this.label, required this.icon, required this.pr});
  final String label;
  final IconData icon;
  final Color pr;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 14,
          decoration:
              BoxDecoration(color: pr, borderRadius: BorderRadius.circular(2)),
        ),
        const Gap(8),
        Icon(icon, size: 13, color: pr.withValues(alpha: 0.7)),
        const Gap(5),
        Text(label,
            style: TextStyle(
                color: pr,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                fontFamily: AppFonts.poppins)),
      ]);
}

/// Labeled slider with min/max labels and a live value readout.
/// Uses [SliderTheme] to tint the track with the primary color.
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.pr,
    required this.os,
    required this.onChanged,
    required this.minLabel,
    required this.maxLabel,
  });

  final String label, valueLabel, minLabel, maxLabel;
  final double min, max, value;
  final int divisions;
  final Color pr, os;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: os.withValues(alpha: 0.04),
        border: Border.all(color: os.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: TextStyle(
                  color: os.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(valueLabel,
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
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel,
                  style:
                      TextStyle(color: os.withValues(alpha: 0.3), fontSize: 9)),
              Text(maxLabel,
                  style:
                      TextStyle(color: os.withValues(alpha: 0.3), fontSize: 9)),
            ],
          ),
        ),
      ]),
    );
  }
}
