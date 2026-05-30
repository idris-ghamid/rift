import 'package:flutter/material.dart';

/// Layout engine for responsive layouts across different screen sizes
class LayoutEngine {
  // Breakpoints (in logical pixels)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get layout type based on screen width
  static LayoutType getLayoutType(double width) {
    if (width < mobileBreakpoint) {
      return LayoutType.mobile;
    } else if (width < desktopBreakpoint) {
      return LayoutType.tablet;
    } else {
      return LayoutType.desktop;
    }
  }

  /// Get column count based on screen width
  static int getColumnCount(double width) {
    final type = getLayoutType(width);
    switch (type) {
      case LayoutType.mobile:
        return 1;
      case LayoutType.tablet:
        return 2;
      case LayoutType.desktop:
        return 3;
    }
  }

  /// Get spacing based on screen width
  static double getSpacing(double width) {
    final type = getLayoutType(width);
    switch (type) {
      case LayoutType.mobile:
        return 12.0;
      case LayoutType.tablet:
        return 16.0;
      case LayoutType.desktop:
        return 20.0;
    }
  }

  /// Get font scale based on screen width
  static double getFontScale(double width) {
    final type = getLayoutType(width);
    switch (type) {
      case LayoutType.mobile:
        return 1.0;
      case LayoutType.tablet:
        return 1.05;
      case LayoutType.desktop:
        return 1.1;
    }
  }

  /// Get padding based on screen width
  static EdgeInsets getPadding(double width) {
    final type = getLayoutType(width);
    switch (type) {
      case LayoutType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case LayoutType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case LayoutType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  /// Get card height based on screen width
  static double getCardHeight(double width) {
    final type = getLayoutType(width);
    switch (type) {
      case LayoutType.mobile:
        return 120.0;
      case LayoutType.tablet:
        return 140.0;
      case LayoutType.desktop:
        return 160.0;
    }
  }

  /// Build responsive grid
  static Widget buildResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final width = MediaQuery.of(context).size.width;
    final columnCount = getColumnCount(width);
    final spacing = crossAxisSpacing ?? getSpacing(width);
    final mainSpacing = mainAxisSpacing ?? getSpacing(width);

    if (columnCount == 1) {
      // Mobile: Use ListView
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(height: mainSpacing),
        itemBuilder: (_, index) => children[index],
      );
    } else {
      // Tablet/Desktop: Use GridView
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: mainSpacing,
          childAspectRatio: 2.5,
        ),
        itemCount: children.length,
        itemBuilder: (_, index) => children[index],
      );
    }
  }

  /// Build responsive list
  static Widget buildResponsiveList({
    required BuildContext context,
    required List<Widget> children,
    double? spacing,
  }) {
    final width = MediaQuery.of(context).size.width;
    final itemSpacing = spacing ?? getSpacing(width);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
      itemBuilder: (_, index) => children[index],
    );
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    final type = getLayoutType(width);

    switch (type) {
      case LayoutType.mobile:
        return mobile;
      case LayoutType.tablet:
        return tablet ?? mobile;
      case LayoutType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Layout type enum
enum LayoutType {
  mobile, // < 600px
  tablet, // 600-1200px
  desktop, // > 1200px
}
