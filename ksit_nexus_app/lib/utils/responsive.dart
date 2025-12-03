import 'package:flutter/material.dart';

/// Device screen size breakpoints
class Breakpoints {
  // Mobile: 0-599
  static const double mobile = 600;
  
  // Tablet: 600-1023
  static const double tablet = 1024;
  
  // Desktop/Laptop: 1024-1439
  static const double desktop = 1440;
  
  // Large Desktop/PC: 1440+
  static const double largeDesktop = 1920;
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive utility class for adaptive layouts
class Responsive {
  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }
  
  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }
  
  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }
  
  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }
  
  /// Check if current device is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.largeDesktop;
  }
  
  /// Get responsive value based on device type
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Get responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.1;
      case DeviceType.desktop:
        return baseSize * 1.15;
      case DeviceType.largeDesktop:
        return baseSize * 1.2;
    }
  }
  
  /// Get responsive padding
  static EdgeInsets padding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    return EdgeInsets.all(paddingValue);
  }
  
  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    return EdgeInsets.symmetric(horizontal: paddingValue);
  }
  
  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    return EdgeInsets.symmetric(vertical: paddingValue);
  }
  
  /// Get max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    return value(
      context: context,
      mobile: double.infinity,
      tablet: 768,
      desktop: 1200,
      largeDesktop: 1400,
    );
  }
  
  /// Get grid column count
  static int getGridColumns(BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return value(
      context: context,
      mobile: mobile ?? 2,
      tablet: tablet ?? 3,
      desktop: desktop ?? 4,
      largeDesktop: largeDesktop ?? 5,
    );
  }
  
  /// Get responsive spacing
  static double spacing(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return value(
      context: context,
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 12.0,
      desktop: desktop ?? 16.0,
      largeDesktop: largeDesktop ?? 20.0,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout widget with different layouts for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveMaxWidth = maxWidth ?? Responsive.getMaxContentWidth(context);
    final responsivePadding = padding ?? Responsive.horizontalPadding(context);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
        padding: responsivePadding,
        alignment: centerContent ? Alignment.center : null,
        child: child,
      ),
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = Responsive.getGridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      largeDesktop: largeDesktopColumns,
    );
    
    final gridSpacing = spacing ?? Responsive.spacing(context);
    final gridRunSpacing = runSpacing ?? Responsive.spacing(context);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: gridSpacing,
      mainAxisSpacing: gridRunSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      children: children,
    );
  }
}

/// Responsive padding wrapper
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final double? largeDesktop;
  final bool horizontal;
  final bool vertical;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.horizontal = false,
    this.vertical = false,
  });
  
  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    
    if (horizontal) {
      padding = Responsive.horizontalPadding(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        largeDesktop: largeDesktop,
      );
    } else if (vertical) {
      padding = Responsive.verticalPadding(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        largeDesktop: largeDesktop,
      );
    } else {
      padding = Responsive.padding(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        largeDesktop: largeDesktop,
      );
    }
    
    return Padding(
      padding: padding,
      child: child,
    );
  }
}











