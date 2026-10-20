import 'package:flutter/material.dart';

/// Responsive scaffold that adapts between thumb-driven mobile/tablet (<900px)
/// and 2-column counter station desktop/web (>=900px).
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return desktop;
        }
        return mobile;
      },
    );
  }
}
