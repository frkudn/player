import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/utils/extensions.dart';

class SettingBottomNavigationBarCustomizationWidget extends StatelessWidget {
  const SettingBottomNavigationBarCustomizationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String lc         = context.languageCubit.state.languageCode;
    final ThemeState state  = context.themeCubit.state;
    final cs                = Theme.of(context).colorScheme;
    final primary           = cs.primary;
    final onSurface         = cs.onSurface;
    final surfaceTint       = cs.surfaceContainerHighest;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        AppStrings.bottomNavigationBar[lc]!,
        style: TextStyle(
          fontSize: 14,
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── POSITION ────────────────────────────────────────────────
              _SectionHeader(label: 'Position', primary: primary),
              const Gap(12),

              // Hint text
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primary.withValues(alpha: 0.07),
                  border: Border.all(
                      color: primary.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: primary.withValues(alpha: 0.6), size: 15),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Drag the circle or tap arrows to reposition',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Arrow buttons grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ArrowButton(
                    icon: CupertinoIcons.arrow_left_circle_fill,
                    label: 'Left',
                    primary: primary,
                    onSurface: onSurface,
                    onTap: () => context
                        .read<ThemeCubit>()
                        .changeBottomNavBarPositionLeft(),
                  ),
                  _ArrowButton(
                    icon: CupertinoIcons.arrow_right_circle_fill,
                    label: 'Right',
                    primary: primary,
                    onSurface: onSurface,
                    onTap: () => context
                        .read<ThemeCubit>()
                        .changeBottomNavBarPositionRight(),
                  ),
                  _ArrowButton(
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    label: 'Up',
                    primary: primary,
                    onSurface: onSurface,
                    onTap: () => context
                        .read<ThemeCubit>()
                        .changeBottomNavBarPositionTop(),
                  ),
                  _ArrowButton(
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    label: 'Down',
                    primary: primary,
                    onSurface: onSurface,
                    onTap: () => context
                        .read<ThemeCubit>()
                        .changeBottomNavBarPositionBottom(),
                  ),
                ],
              ),

              const Gap(20),

              // Draggable circle — YOUR original gesture logic untouched
              Center(
                child: GestureDetector(
                  onHorizontalDragStart: (_) => context
                      .read<ThemeCubit>()
                      .enableHoldBottomNavBarCirclePositionButton(),
                  onHorizontalDragEnd: (_) => context
                      .read<ThemeCubit>()
                      .disableHoldBottomNavBarCirclePositionButton(),
                  onVerticalDragStart: (_) => context
                      .read<ThemeCubit>()
                      .enableHoldBottomNavBarCirclePositionButton(),
                  onVerticalDragEnd: (_) => context
                      .read<ThemeCubit>()
                      .disableHoldBottomNavBarCirclePositionButton(),
                  onHorizontalDragUpdate: (d) {
                    log('Horizontal drag: ${d.delta.dx}');
                    if (d.delta.dx > 0) {
                      context
                          .read<ThemeCubit>()
                          .changeBottomNavBarPositionRight();
                    } else {
                      context
                          .read<ThemeCubit>()
                          .changeBottomNavBarPositionLeft();
                    }
                  },
                  onVerticalDragUpdate: (d) {
                    log('Vertical drag: ${d.delta.dy}');
                    if (d.delta.dy > 0) {
                      context
                          .read<ThemeCubit>()
                          .changeBottomNavBarPositionBottom();
                    } else {
                      context
                          .read<ThemeCubit>()
                          .changeBottomNavBarPositionTop();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: state.isHoldBottomNavBarCirclePositionButton
                        ? 100
                        : 60,
                    height: state.isHoldBottomNavBarCirclePositionButton
                        ? 100
                        : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isHoldBottomNavBarCirclePositionButton
                          ? primary.withValues(alpha: 0.12)
                          : Color(state.primaryColor),
                      border: Border.all(
                        color: state.isHoldBottomNavBarCirclePositionButton
                            ? primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNavigation01,
                        color: state.isHoldBottomNavBarCirclePositionButton
                            ? primary
                            : Theme.of(context).colorScheme.onPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              const Gap(28),
              Divider(color: onSurface.withValues(alpha: 0.07)),
              const Gap(20),

              // ── SIZE ─────────────────────────────────────────────────────
              _SectionHeader(label: 'Size', primary: primary),
              const Gap(16),

              _SizeControlRow(
                label: 'Width',
                icon: Icons.swap_horiz_rounded,
                primary: primary,
                onSurface: onSurface,
                surfaceTint: surfaceTint,
                onIncrease: () =>
                    context.read<ThemeCubit>().increaseBottomNavBarWidth(),
                onDecrease: () =>
                    context.read<ThemeCubit>().decreaseBottomNavBarWidth(),
              ),

              const Gap(12),

              _SizeControlRow(
                label: 'Height',
                icon: Icons.swap_vert_rounded,
                primary: primary,
                onSurface: onSurface,
                surfaceTint: surfaceTint,
                onIncrease: () =>
                    context.read<ThemeCubit>().increaseBottomNavBarHeight(),
                onDecrease: () =>
                    context.read<ThemeCubit>().decreaseBottomNavBarHeight(),
              ),

              const Gap(28),
              Divider(color: onSurface.withValues(alpha: 0.07)),
              const Gap(20),

              // ── TRANSFORM ────────────────────────────────────────────────
              _SectionHeader(label: 'Transform', primary: primary),
              const Gap(16),

              // Rotation row — YOUR original logic untouched
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: surfaceTint,
                  border: Border.all(
                      color: onSurface.withValues(alpha: 0.06), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rotate_90_degrees_cw_rounded,
                        color: onSurface.withValues(alpha: 0.5), size: 18),
                    const Gap(10),
                    Text(
                      'Rotation',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _IconActionButton(
                      icon: Icons.rotate_left_rounded,
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updateBottomNavigationBarRotationToLeft(),
                    ),
                    const Gap(10),
                    _IconActionButton(
                      icon: Icons.rotate_right_rounded,
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .updateBottomNavigationBarRotationToRight(),
                    ),
                  ],
                ),
              ),

              const Gap(28),
              Divider(color: onSurface.withValues(alpha: 0.07)),
              const Gap(20),

              // ── RESET ────────────────────────────────────────────────────
              _SectionHeader(label: 'Reset to Default', primary: primary),
              const Gap(14),

              Row(
                children: [
                  Expanded(
                    child: _ResetButton(
                      label: 'Position',
                      icon: HugeIcons.strokeRoundedNavigation01,
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .resetToDefaultBottomNavBarPosition(),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _ResetButton(
                      label: 'Size',
                      icon: HugeIcons.strokeRoundedResize01,
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .resetToDefaultBottomNavBarHeightAndWidth(),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _ResetButton(
                      label: 'Rotation',
                      icon: Icons.rotate_90_degrees_cw_sharp,
                      primary: primary,
                      onSurface: onSurface,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .resetToDefaultBottomNavBarRotation(),
                    ),
                  ),
                ],
              ),

              const Gap(8),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color primary;
  const _SectionHeader({required this.label, required this.primary});

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

// ── Arrow position button ─────────────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
              border: Border.all(
                  color: primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: primary, size: 26),
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Size control row ──────────────────────────────────────────────────────────

class _SizeControlRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final Color onSurface;
  final Color surfaceTint;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _SizeControlRow({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onSurface,
    required this.surfaceTint,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: surfaceTint,
        border: Border.all(
            color: onSurface.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: onSurface.withValues(alpha: 0.5), size: 18),
          const Gap(10),
          Text(
            label,
            style: TextStyle(
              color: onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _IconActionButton(
            icon: Icons.remove_rounded,
            primary: primary,
            onSurface: onSurface,
            onTap: onDecrease,
          ),
          const Gap(10),
          _IconActionButton(
            icon: Icons.add_rounded,
            primary: primary,
            onSurface: onSurface,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

// ── Icon action button (+ / - / rotate) ──────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.12),
          border: Border.all(
              color: primary.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: primary, size: 18),
      ),
    );
  }
}

// ── Reset button ──────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  const _ResetButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onSurface.withValues(alpha: 0.05),
          border: Border.all(
              color: onSurface.withValues(alpha: 0.08), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onSurface.withValues(alpha: 0.5), size: 20),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}