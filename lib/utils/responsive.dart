import 'package:flutter/material.dart';

/// Breakpoint configuration for responsive layouts.
///
/// Customize these values to match your design system.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints({
    this.mobileMax = 649,
    this.tabletMax = 1099,
  }) : assert(mobileMax < tabletMax, 'mobileMax must be less than tabletMax');

  final double mobileMax;
  final double tabletMax;

  static const ResponsiveBreakpoints defaults = ResponsiveBreakpoints();
}

/// Represents the current screen type derived from window width.
enum ScreenType { mobile, tablet, desktop }

/// Provides responsive utilities via [InheritedWidget].
///
/// Wrap your app (or a sub-tree) with [ResponsiveProvider] so that
/// descendant widgets can call [ResponsiveProvider.of] without requiring
/// a [BuildContext] to traverse [MediaQuery] on every call.
///
/// ```dart
/// ResponsiveProvider(
///   breakpoints: ResponsiveBreakpoints(mobileMax: 600, tabletMax: 1024),
///   child: MyApp(),
/// )
/// ```
class ResponsiveProvider extends InheritedWidget {
  const ResponsiveProvider({
    super.key,
    required super.child,
    this.breakpoints = ResponsiveBreakpoints.defaults,
  });

  final ResponsiveBreakpoints breakpoints;

  static ResponsiveBreakpoints of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ResponsiveProvider>();
    return provider?.breakpoints ?? ResponsiveBreakpoints.defaults;
  }

  @override
  bool updateShouldNotify(ResponsiveProvider oldWidget) =>
      breakpoints.mobileMax != oldWidget.breakpoints.mobileMax ||
      breakpoints.tabletMax != oldWidget.breakpoints.tabletMax;
}

/// Extension on [BuildContext] for ergonomic responsive checks.
///
/// ```dart
/// if (context.isMobile) { ... }
/// context.screenType; // ScreenType.tablet
/// context.responsiveValue(mobile: 12.0, tablet: 16.0, desktop: 20.0);
/// ```
extension ResponsiveContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;
  ResponsiveBreakpoints get _bp => ResponsiveProvider.of(this);

  /// Returns the current [ScreenType].
  ScreenType get screenType {
    final w = _width;
    if (w <= _bp.mobileMax) return ScreenType.mobile;
    if (w <= _bp.tabletMax) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// Returns `true` when the screen is tablet **or** desktop.
  bool get isTabletOrLarger => !isMobile;

  /// Returns `true` when the screen is mobile **or** tablet.
  bool get isMobileOrTablet => !isDesktop;

  /// Picks a value based on the current screen type.
  ///
  /// [tablet] and [desktop] fall back to [mobile] when omitted.
  ///
  /// ```dart
  /// final padding = context.responsiveValue(
  ///   mobile: 8.0,
  ///   tablet: 16.0,
  ///   desktop: 24.0,
  /// );
  /// ```
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }
}

/// A widget that renders different layouts depending on screen width.
///
/// [tablet] is optional and falls back to [mobile] when not provided.
///
/// ```dart
/// Responsive(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),   // optional
///   desktop: DesktopLayout(),
/// )
/// ```
class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  // ── Static helpers (use extension methods on BuildContext when possible) ──

  static bool isMobile(BuildContext context) => context.isMobile;
  static bool isTablet(BuildContext context) => context.isTablet;
  static bool isDesktop(BuildContext context) => context.isDesktop;

  @override
  Widget build(BuildContext context) {
    return switch (context.screenType) {
      ScreenType.desktop => desktop,
      ScreenType.tablet => tablet ?? mobile,
      ScreenType.mobile => mobile,
    };
  }
}

/// A builder variant that exposes [ScreenType] and screen dimensions
/// for fine-grained control inside the build callback.
///
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenType, size) {
///     final columns = screenType == ScreenType.desktop ? 4 : 2;
///     return GridView.count(crossAxisCount: columns, ...);
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ScreenType screenType,
    Size size,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return builder(context, context.screenType, size);
  }
}

/// A widget that shows [child] only on the specified [targets].
///
/// ```dart
/// ResponsiveVisibility(
///   targets: {ScreenType.mobile, ScreenType.tablet},
///   child: BottomNavigationBar(...),
/// )
/// ```
class ResponsiveVisibility extends StatelessWidget {
  const ResponsiveVisibility({
    super.key,
    required this.child,
    required this.targets,
    this.replacement = const SizedBox.shrink(),
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
  });

  final Widget child;
  final Set<ScreenType> targets;

  /// Widget rendered when [child] is hidden. Defaults to [SizedBox.shrink].
  final Widget replacement;

  final bool maintainState;
  final bool maintainAnimation;
  final bool maintainSize;

  @override
  Widget build(BuildContext context) {
    final visible = targets.contains(context.screenType);
    if (maintainSize) {
      return Visibility(
        visible: visible,
        maintainState: maintainState,
        maintainAnimation: maintainAnimation,
        maintainSize: true,
        replacement: replacement,
        child: child,
      );
    }
    return visible ? child : replacement;
  }
}
