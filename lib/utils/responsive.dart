import 'package:flutter/material.dart';

/// Responsive utility class to handle different screen sizes
class Responsive {
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late bool isSmallPhone;
  static late bool isMediumPhone;
  static late bool isLargePhone;
  static late bool isTablet;
  static late bool isLandscape;

  /// Initialize responsive values
  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Breakpoints for different device sizes
    isSmallPhone = screenWidth < 360;    // Small phones (e.g., iPhone SE)
    isMediumPhone = screenWidth >= 360 && screenWidth < 414;  // Medium phones
    isLargePhone = screenWidth >= 414 && screenWidth < 600;   // Large phones
    isTablet = screenWidth >= 600;       // Tablets
    isLandscape = screenWidth > screenHeight;
  }

  /// Get proportional width (percentage of screen width)
  static double wp(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  /// Get proportional height (percentage of screen height)
  static double hp(double percentage) {
    return blockSizeVertical * percentage;
  }

  /// Get proportional size based on square dimension
  static double sp(double percentage) {
    final square = screenWidth < screenHeight ? screenWidth : screenHeight;
    return (square / 100) * percentage;
  }

  /// Get adaptive font size
  static double fontSize(double size) {
    if (isSmallPhone) return size * 0.85;
    if (isTablet) return size * 1.2;
    return size;
  }

  /// Get adaptive spacing
  static double spacing(double size) {
    if (isSmallPhone) return size * 0.9;
    if (isTablet) return size * 1.15;
    return size;
  }

  /// Get grid cross axis count based on screen size
  static int getGridCrossAxisCount({int defaultCount = 2}) {
    if (isTablet) return defaultCount + 2;
    if (isLargePhone) return defaultCount + 1;
    return defaultCount;
  }

  /// Get child aspect ratio for grid items
  static double getGridChildAspectRatio({double defaultRatio = 0.75}) {
    if (isLandscape) return 1.2;
    if (isSmallPhone) return 0.65;
    return defaultRatio;
  }

  /// Get adaptive container width
  static double getContainerWidth({double? maxWidth, double minWidth = 0}) {
    double width = screenWidth;
    if (maxWidth != null) {
      width = width > maxWidth ? maxWidth : width;
    }
    return width > minWidth ? width : minWidth;
  }

  /// Get adaptive padding
  static EdgeInsets getPadding({
    double all = 0,
    double horizontal = 0,
    double vertical = 0,
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    if (all > 0) {
      horizontal = all;
      vertical = all;
    }

    double scale = 1.0;
    if (isSmallPhone) scale = 0.85;
    else if (isTablet) scale = 1.15;

    return EdgeInsets.only(
      left: (left > 0 ? left : horizontal) * scale,
      top: (top > 0 ? top : vertical) * scale,
      right: (right > 0 ? right : horizontal) * scale,
      bottom: (bottom > 0 ? bottom : vertical) * scale,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    bool isSmallPhone,
    bool isMediumPhone,
    bool isLargePhone,
    bool isTablet,
  ) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return builder(
          context,
          constraints,
          width < 360,      // isSmallPhone
          width >= 360 && width < 414,  // isMediumPhone
          width >= 414 && width < 600,  // isLargePhone
          width >= 600,     // isTablet
        );
      },
    );
  }
}

/// Safe area with adaptive padding
class AdaptiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const AdaptiveSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Padding(
        padding: Responsive.getPadding(horizontal: 16),
        child: child,
      ),
    );
  }
}
