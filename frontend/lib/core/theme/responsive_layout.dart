import 'package:flutter/material.dart';

/// Responsive scaffold and breakpoint helper that adapts across:
/// - Mobile Portrait (phones upright: 1-column thumb reach, bottom nav)
/// - Mobile Landscape (phones sideways on counter stands: 2-column POS, slim rail)
/// - Tablet Portrait & Landscape (768px-1200px)
/// - Desktop / Web Widescreen (1200px+)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  /// True if current orientation is landscape (width > height)
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// True if current orientation is portrait (height >= width)
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// True for short height landscape screens (e.g. mobile phones sideways, height < 520)
  static bool isShortLandscape(BuildContext context) =>
      isLandscape(context) && MediaQuery.of(context).size.height < 520;

  /// Standard desktop check (>= 900)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Standard mobile check (< 900)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  /// Determines if a 2-column POS cashier station should be rendered.
  /// True on widescreen desktop (>= 850), or any landscape screen with sufficient width (>= 560).
  static bool showTwoPaneStation(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isLandscapeMode = media.orientation == Orientation.landscape;
    return width >= 850 || (isLandscapeMode && width >= 560);
  }

  /// Determines if a NavigationRail should be used instead of a BottomNavigationBar.
  /// Used in landscape mode (width >= 560) or on wide desktop screens (width >= 850)
  /// to save precious vertical space.
  static bool useNavigationRail(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isLandscapeMode = media.orientation == Orientation.landscape;
    return width >= 850 || (isLandscapeMode && width >= 560);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final isLandscapeMode = media.orientation == Orientation.landscape;

        // Desktop / 2-column cashier station breakpoint
        if (constraints.maxWidth >= 900 || (isLandscapeMode && constraints.maxWidth >= 560)) {
          return desktop;
        }

        if (tablet != null && constraints.maxWidth >= 600) {
          return tablet!;
        }

        return mobile;
      },
    );
  }
}

