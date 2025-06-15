import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getGridChildAspectRatio(BuildContext context, {
    double mobile = 1.0,
    double tablet = 1.1,
    double desktop = 1.2,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 16;
    return 20;
  }

  static TextStyle? getResponsiveTextStyle(
    BuildContext context,
    TextTheme textTheme,
  ) {
    if (isMobile(context)) return textTheme.bodyMedium;
    if (isTablet(context)) return textTheme.bodyLarge;
    return textTheme.titleSmall;
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing,
    this.padding,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final childAspectRatio = ResponsiveHelper.getGridChildAspectRatio(context);
    final gridSpacing = spacing ?? ResponsiveHelper.getResponsiveSpacing(context);

    return GridView.count(
      shrinkWrap: shrinkWrap,
      physics: physics,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: gridSpacing,
      mainAxisSpacing: gridSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      children: children,
    );
  }
} 