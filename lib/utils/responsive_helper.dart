import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Device type enum
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  // Screen size helpers
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static bool isTabletOrDesktop(BuildContext context) => !isMobile(context);

  static bool isMobileOrTablet(BuildContext context) => !isDesktop(context);

  // Responsive values
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
    );
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive grid count
  static int getGridCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive spacing
  static double getSpacing(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive width for cards/containers
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile(context)) {
      return screenWidth - 32; // Full width with margins
    } else if (isTablet(context)) {
      return screenWidth * 0.7; // 70% of screen width
    } else {
      return 400; // Fixed width for desktop
    }
  }

  // Responsive height
  static double responsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  // Responsive width
  static double responsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  // Safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Orientation helpers
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Responsive layout builder
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile;
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }

  // Responsive column count for grids
  static int getColumnCount(BuildContext context, double itemWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = responsivePadding(context).horizontal;
    final availableWidth = screenWidth - padding;
    final spacing = getSpacing(context);

    int columns = (availableWidth / (itemWidth + spacing)).floor();
    return columns < 1 ? 1 : columns;
  }

  // Responsive card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    return responsiveValue(context, mobile: 1.2, tablet: 1.4, desktop: 1.6);
  }

  // Responsive container constraints
  static BoxConstraints getContainerConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: responsiveValue(
        context,
        mobile: double.infinity,
        tablet: 800,
        desktop: 1200,
      ),
    );
  }

  // Responsive cross axis count for grids
  static int getCrossAxisCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive flex values
  static int getFlexValue(
    BuildContext context, {
    int mobile = 1,
    int tablet = 1,
    int desktop = 1,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive main axis alignment
  static MainAxisAlignment getMainAxisAlignment(
    BuildContext context, {
    MainAxisAlignment mobile = MainAxisAlignment.center,
    MainAxisAlignment? tablet,
    MainAxisAlignment? desktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Responsive card width with constraints
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile(context)) {
      return screenWidth - 32; // Full width with margins
    } else if (isTablet(context)) {
      return (screenWidth - 48) / 2; // Two columns with spacing
    } else {
      return (screenWidth - 64) / 3; // Three columns with spacing
    }
  }

  // Responsive dialog width
  static double getDialogWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 500,
      desktop: 600,
    );
  }

  // Responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: MediaQuery.of(context).size.width * 0.8,
      tablet: 300,
      desktop: 350,
    );
  }
}

// Device type enum
enum DeviceType { mobile, tablet, desktop }

// Responsive extension for BuildContext
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isTabletOrDesktop => ResponsiveHelper.isTabletOrDesktop(this);
  bool get isMobileOrTablet => ResponsiveHelper.isMobileOrTablet(this);

  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  EdgeInsets get responsivePadding => ResponsiveHelper.responsivePadding(this);
  double get responsiveSpacing => ResponsiveHelper.getSpacing(this);

  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) =>
      ResponsiveHelper.responsiveValue(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
