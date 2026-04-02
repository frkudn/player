import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/features/main/cubit/bottom_nav_bar_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';
import 'package:velocity_x/velocity_x.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEMS
// Add / reorder / remove tabs here. All styles share this single list so
// you only ever change it in one place.
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const List<_NavItem> _kItems = [
  _NavItem(HugeIcons.strokeRoundedMusicNote02, 'Audio'),
  _NavItem(HugeIcons.strokeRoundedInternet, 'Online'),
  _NavItem(HugeIcons.strokeRoundedSettings05, 'Settings'),
];

// ─────────────────────────────────────────────────────────────────────────────
// SIZE TOKENS  (navBarSizeIndex: 0=Compact  1=Regular  2=Large)
//
// pillH    — height of floating pill / island / segment / dot row
// pillIcon — icon size for floating styles
// barH     — height of the full-width bottom bar
// barIcon  — icon size for bar style
// railW    — width of the side rail
// railIcon — icon size for rail buttons
// railBtn  — size of each rail button square
// ─────────────────────────────────────────────────────────────────────────────

class _SZ {
  final double pillH, pillIcon, barH, barIcon, railW, railIcon, railBtn;
  const _SZ(this.pillH, this.pillIcon, this.barH, this.barIcon, this.railW,
      this.railIcon, this.railBtn);
}

const List<_SZ> _kSZ = [
  _SZ(46, 19, 58, 19, 52, 18, 38), // 0 — Compact
  _SZ(56, 22, 72, 22, 60, 21, 44), // 1 — Regular (default)
  _SZ(66, 26, 84, 26, 70, 24, 52), // 2 — Large
];

// ─────────────────────────────────────────────────────────────────────────────
// SHARED TAP HELPER
// ─────────────────────────────────────────────────────────────────────────────

void _tap(BuildContext ctx, int i) {
  HapticFeedback.selectionClick();
  ctx.read<BottomNavBarCubit>().changeIndex(index: i);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
//
// Reads both ThemeCubit and BottomNavBarCubit so style/size/position/opacity
// changes all trigger an instant rebuild without any Navigator push.
//
// Style index → layout:
//   0 = Floating Pill      (free position + width)
//   1 = Full-Width Bar     (fixed bottom — position sliders have no effect)
//   2 = Side Rail          (fixed left side — position sliders have no effect)
//   3 = Minimal Dot        (free position + width)
//   4 = Labeled Island     (free position + width)
//   5 = Segmented Bar      (free position + width)
// ─────────────────────────────────────────────────────────────────────────────

class CustomBottomNavBarWidget extends StatelessWidget {
  const CustomBottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Hides the nav bar when the user taps "Hide nav bar" in the online section.
    // OnlineSectionCubit.showNavBar() is called in dispose() of OnlineMusicMainPage
    // so the bar always comes back when the user leaves the online tab.
   
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (ctx, th) =>
              BlocBuilder<BottomNavBarCubit, BottomNavBarState>(
            builder: (ctx2, nav) {
              final int i = nav.index;
              final _SZ sz = _kSZ[th.navBarSizeIndex.clamp(0, 2)];
              final Color p = Color(th.primaryColor);
              final double op = th.navBarOpacity.clamp(0.4, 1.0);

              switch (th.navBarStyleIndex) {
                case 1:
                  return _Bar(i: i, th: th, sz: sz, p: p, op: op);
                case 2:
                  return _Rail(i: i, th: th, sz: sz, p: p, op: op);
                case 3:
                  return _Dot(i: i, th: th, sz: sz, p: p);
                case 4:
                  return _Island(i: i, th: th, sz: sz, p: p, op: op);
                case 5:
                  return _Segment(i: i, th: th, sz: sz, p: p, op: op);
                default:
                  return _Pill(i: i, th: th, sz: sz, p: p, op: op);
              }
            },
          ),
        );
    
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POSITION HELPER
//
// Converts the ThemeState fraction fields into concrete pixel values for use
// inside a Stack (via Positioned). All four floating styles call this.
//
// bottomNavBarPositionFromLeft  — 0.0…0.9 — left edge as fraction of screen w
// bottomNavBarPositionFromBottom — 0.0…0.9 — bottom edge as fraction of screen h
// bottomNavBarWidth             — 0.3…1.0 — bar width as fraction of screen w
//
// The left value is clamped so the bar never overflows the right edge:
//   maxLeft = screenWidth - barWidth
// ─────────────────────────────────────────────────────────────────────────────

class _Pos {
  final double left, bottom, width;
  const _Pos({required this.left, required this.bottom, required this.width});
}

_Pos _resolvePos(ThemeState th, Size mq,
    {double minW = 120, double maxW = 9999}) {
  // Convert fractions to pixels and clamp to safe ranges
  final double w = (mq.width * th.bottomNavBarWidth.clamp(0.3, 1.0))
      .clamp(minW, maxW.clamp(minW, mq.width));

  // Left: keep bar fully on screen
  final double left =
      (mq.width * th.bottomNavBarPositionFromLeft).clamp(0.0, mq.width - w);

  final double bottom = (mq.height * th.bottomNavBarPositionFromBottom)
      .clamp(0.0, mq.height * 0.9);

  return _Pos(left: left, bottom: bottom, width: w);
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 0 — FLOATING PILL
//
// Glassmorphic pill that floats above content.
// Position and width are controlled by the free-position sliders in Settings.
// Default: centered near the bottom of the screen.
// ═══════════════════════════════════════════════════════════════════════════════

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.i,
      required this.th,
      required this.sz,
      required this.p,
      required this.op});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;
  final double op;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    // Cap at 340 dp so the pill never stretches absurdly wide on tablets
    final pos = _resolvePos(th, mq, minW: 160, maxW: 340);

    return Positioned(
      bottom: pos.bottom,
      left: pos.left,
      width: pos.width,
      height: sz.pillH,
      child: Opacity(
        opacity: op,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _kItems.length,
              (j) => _PBtn(
                it: _kItems[j],
                sel: i == j,
                p: p,
                dark: th.isDarkMode,
                sz: sz.pillIcon,
                onTap: () => _tap(context, j),
              ),
            ),
          ),
        ).glassMorphic(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: th.isDarkMode ? Colors.white30 : Colors.black26,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _PBtn extends StatelessWidget {
  const _PBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.sz,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double sz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: sel ? p.withValues(alpha: .18) : Colors.transparent,
          ),
          child: Icon(it.icon,
              size: sz,
              color: sel ? p : (dark ? Colors.white54 : Colors.black45)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 1 — FULL-WIDTH BAR
//
// Standard bottom navigation bar — icon + label, anchored to the very bottom.
// Position sliders do NOT affect this style (it must stay at the bottom edge).
// Opacity slider applies to the background colour only.
// ═══════════════════════════════════════════════════════════════════════════════

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.i,
      required this.th,
      required this.sz,
      required this.p,
      required this.op});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;
  final double op;

  @override
  Widget build(BuildContext ctx) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: sz.barH,
        child: Opacity(
          opacity: op,
          child: Container(
            decoration: BoxDecoration(
              color: th.isDarkMode
                  ? Colors.black.withValues(alpha: .82)
                  : Colors.white.withValues(alpha: .92),
              border: Border(
                top: BorderSide(
                  color: th.isDarkMode ? Colors.white12 : Colors.black12,
                  width: .5,
                ),
              ),
            ),
            child: Row(
              children: List.generate(
                _kItems.length,
                (j) => Expanded(
                  child: _BBtn(
                    it: _kItems[j],
                    sel: i == j,
                    p: p,
                    dark: th.isDarkMode,
                    sz: sz.barIcon,
                    onTap: () => _tap(ctx, j),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _BBtn extends StatelessWidget {
  const _BBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.sz,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double sz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) {
    final c = sel ? p : (dark ? Colors.white54 : Colors.black45);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: sel ? p.withValues(alpha: .12) : Colors.transparent,
            ),
            child: Icon(it.icon, size: sz, color: c),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: c,
            ),
            child: Text(it.label),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 2 — SIDE RAIL
//
// Vertical left-side rail — ideal for tablets in landscape.
// Anchored to the left edge at a fixed vertical center.
// Position sliders do NOT move this style (a rail must be on the side).
// ═══════════════════════════════════════════════════════════════════════════════

class _Rail extends StatelessWidget {
  const _Rail(
      {required this.i,
      required this.th,
      required this.sz,
      required this.p,
      required this.op});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;
  final double op;

  @override
  Widget build(BuildContext ctx) {
    final mq = MediaQuery.sizeOf(ctx);
    return Positioned(
      top: mq.height * .28,
      left: 10,
      width: sz.railW,
      child: Opacity(
        opacity: op,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _kItems.length,
              (j) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _RBtn(
                  it: _kItems[j],
                  sel: i == j,
                  p: p,
                  dark: th.isDarkMode,
                  ico: sz.railIcon,
                  btn: sz.railBtn,
                  onTap: () => _tap(ctx, j),
                ),
              ),
            ),
          ),
        ).glassMorphic(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: th.isDarkMode ? Colors.white24 : Colors.black12,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _RBtn extends StatelessWidget {
  const _RBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.ico,
      required this.btn,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double ico, btn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: btn,
          height: btn,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: sel ? p.withValues(alpha: .18) : Colors.transparent,
            border: sel
                ? Border.all(color: p.withValues(alpha: .3), width: 1)
                : null,
          ),
          child: Icon(it.icon,
              size: ico,
              color: sel ? p : (dark ? Colors.white54 : Colors.black45)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 3 — MINIMAL DOT
//
// Icons only + an animated active-dot indicator below the selected icon.
// Free position and width controlled by Settings sliders.
// ═══════════════════════════════════════════════════════════════════════════════

class _Dot extends StatelessWidget {
  const _Dot(
      {required this.i, required this.th, required this.sz, required this.p});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;

  @override
  Widget build(BuildContext ctx) {
    final mq = MediaQuery.sizeOf(ctx);
    final pos = _resolvePos(th, mq, minW: 120, maxW: 260);

    return Positioned(
      bottom: pos.bottom,
      left: pos.left,
      width: pos.width,
      height: sz.pillH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _kItems.length,
          (j) => _DBtn(
            it: _kItems[j],
            sel: i == j,
            p: p,
            dark: th.isDarkMode,
            sz: sz.pillIcon,
            onTap: () => _tap(ctx, j),
          ),
        ),
      ),
    );
  }
}

class _DBtn extends StatelessWidget {
  const _DBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.sz,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double sz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(it.icon,
                  size: sz,
                  color: sel ? p : (dark ? Colors.white54 : Colors.black38)),
              const SizedBox(height: 5),
              // Active dot — grows from 0 to 16 dp when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                width: sel ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: p,
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 4 — LABELED ISLAND  (Dynamic Island inspired)
//
// Active tab expands to reveal its label with a spring animation.
// Free position and width controlled by Settings sliders.
// ═══════════════════════════════════════════════════════════════════════════════

class _Island extends StatelessWidget {
  const _Island(
      {required this.i,
      required this.th,
      required this.sz,
      required this.p,
      required this.op});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;
  final double op;

  @override
  Widget build(BuildContext ctx) {
    final mq = MediaQuery.sizeOf(ctx);
    final pos = _resolvePos(th, mq, minW: 160, maxW: 360);

    return Positioned(
      bottom: pos.bottom,
      left: pos.left,
      width: pos.width,
      height: sz.pillH,
      child: Opacity(
        opacity: op,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _kItems.length,
              (j) => _IBtn(
                it: _kItems[j],
                sel: i == j,
                p: p,
                dark: th.isDarkMode,
                sz: sz.pillIcon,
                onTap: () => _tap(ctx, j),
              ),
            ),
          ),
        ).glassMorphic(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: th.isDarkMode ? Colors.white30 : Colors.black26,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _IBtn extends StatelessWidget {
  const _IBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.sz,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double sz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: sel ? 14 : 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: sel ? p.withValues(alpha: .16) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it.icon,
                  size: sz,
                  color: sel ? p : (dark ? Colors.white54 : Colors.black45)),
              // Label slides in from 0 width when tab is active
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: sel
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          it.label,
                          style: TextStyle(
                            color: p,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STYLE 5 — SEGMENTED BAR
//
// A filled sliding-indicator moves under the active tab — iOS-style.
// Free position and width controlled by Settings sliders.
// ═══════════════════════════════════════════════════════════════════════════════

class _Segment extends StatelessWidget {
  const _Segment(
      {required this.i,
      required this.th,
      required this.sz,
      required this.p,
      required this.op});
  final int i;
  final ThemeState th;
  final _SZ sz;
  final Color p;
  final double op;

  @override
  Widget build(BuildContext ctx) {
    final mq = MediaQuery.sizeOf(ctx);
    final pos = _resolvePos(th, mq, minW: 200, maxW: 400);
    final double h = sz.barH * .82;
    final double segW = pos.width / _kItems.length;

    return Positioned(
      bottom: pos.bottom,
      left: pos.left,
      width: pos.width,
      height: h,
      child: Opacity(
        opacity: op,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: th.isDarkMode
                ? Colors.white.withValues(alpha: .06)
                : Colors.black.withValues(alpha: .05),
            border: Border.all(
              color: th.isDarkMode ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Sliding fill rectangle — AnimatedPositioned handles movement
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: i * segW + 4,
                top: 4,
                width: segW - 8,
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: p.withValues(alpha: .18),
                    border:
                        Border.all(color: p.withValues(alpha: .3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: p.withValues(alpha: .12),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
              // Icon + label layer on top of the sliding fill
              Row(
                children: List.generate(
                  _kItems.length,
                  (j) => Expanded(
                    child: _SBtn(
                      it: _kItems[j],
                      sel: i == j,
                      p: p,
                      dark: th.isDarkMode,
                      sz: sz.barIcon * .9,
                      onTap: () => _tap(ctx, j),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SBtn extends StatelessWidget {
  const _SBtn(
      {required this.it,
      required this.sel,
      required this.p,
      required this.dark,
      required this.sz,
      required this.onTap});
  final _NavItem it;
  final bool sel, dark;
  final Color p;
  final double sz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) {
    final c = sel ? p : (dark ? Colors.white54 : Colors.black38);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: sel ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(it.icon, size: sz, color: c),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: c,
            ),
            child: Text(it.label),
          ),
        ],
      ),
    );
  }
}
