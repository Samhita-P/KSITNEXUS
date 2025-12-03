import 'package:flutter/material.dart';

/// Professional College Portal Theme Constants
/// 
/// This file contains additional styling constants and helper utilities
/// that complement the main AppTheme for custom widget styling.
/// All values follow the professional academic design system.

class ThemeConstants {
  // ============================
  // Spacing Constants
  // ============================
  
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacing2XL = 48.0;
  static const double spacing3XL = 64.0;
  
  // ============================
  // Border Radius Constants
  // ============================
  
  static const double radiusSM = 6.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radius2XL = 24.0;
  static const double radiusFull = 9999.0;
  
  // Border Radius Objects
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadius2XL => BorderRadius.circular(radius2XL);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);
  
  // ============================
  // Elevation Constants
  // ============================
  
  static const double elevationNone = 0.0;
  static const double elevationSoft = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXL = 12.0;
  static const double elevation2XL = 16.0;
  
  // ============================
  // Icon Size Constants
  // ============================
  
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 32.0;
  static const double icon2XL = 40.0;
  static const double icon3XL = 48.0;
  
  // ============================
  // Animation Duration Constants
  // ============================
  
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationXSlow = Duration(milliseconds: 600);
  
  // ============================
  // Animation Curves
  // ============================
  
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.easeOutBack;
  static const Curve curveSharp = Curves.easeInOutQuart;
  
  // ============================
  // Opacity Constants
  // ============================
  
  static const double opacityDisabled = 0.38;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;
  static const double opacityFocus = 0.12;
  static const double opacitySelected = 0.16;
  static const double opacityDivider = 0.12;
  
  // ============================
  // Line Height Constants
  // ============================
  
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;
  
  // ============================
  // Letter Spacing Constants
  // ============================
  
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingXWide = 1.0;
  
  // ============================
  // Breakpoint Constants (for responsive design)
  // ============================
  
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointLargeDesktop = 1440.0;
  
  // ============================
  // Container Max Width Constants
  // ============================
  
  static const double containerSM = 640.0;
  static const double containerMD = 768.0;
  static const double containerLG = 1024.0;
  static const double containerXL = 1280.0;
  static const double container2XL = 1536.0;
  
  // ============================
  // Z-Index Constants (for layering)
  // ============================
  
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 1000;
  static const int zIndexSticky = 1020;
  static const int zIndexFixed = 1030;
  static const int zIndexModalBackdrop = 1040;
  static const int zIndexModal = 1050;
  static const int zIndexPopover = 1060;
  static const int zIndexTooltip = 1070;
  
  // ============================
  // Button Height Constants
  // ============================
  
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 48.0;
  static const double buttonHeightLG = 56.0;
  static const double buttonHeightXL = 64.0;
  
  // ============================
  // Input Field Height Constants
  // ============================
  
  static const double inputHeightSM = 40.0;
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;
  
  // ============================
  // AppBar Height Constants
  // ============================
  
  static const double appBarHeightStandard = 56.0;
  static const double appBarHeightLarge = 64.0;
  static const double appBarHeightXL = 72.0;
  
  // ============================
  // Bottom Navigation Bar Height
  // ============================
  
  static const double bottomNavBarHeight = 64.0;
  static const double bottomNavBarHeightCompact = 56.0;
  
  // ============================
  // Sidebar Width Constants
  // ============================
  
  static const double sidebarWidthCompact = 200.0;
  static const double sidebarWidthStandard = 260.0;
  static const double sidebarWidthWide = 300.0;
  
  // ============================
  // Grid Gap Constants
  // ============================
  
  static const double gridGapXS = 8.0;
  static const double gridGapSM = 12.0;
  static const double gridGapMD = 16.0;
  static const double gridGapLG = 24.0;
  static const double gridGapXL = 32.0;
  
  // ============================
  // Avatar Size Constants
  // ============================
  
  static const double avatarSizeXS = 24.0;
  static const double avatarSizeSM = 32.0;
  static const double avatarSizeMD = 40.0;
  static const double avatarSizeLG = 48.0;
  static const double avatarSizeXL = 64.0;
  static const double avatarSize2XL = 80.0;
  static const double avatarSize3XL = 96.0;
  
  // ============================
  // Badge Size Constants
  // ============================
  
  static const double badgeSizeSM = 16.0;
  static const double badgeSizeMD = 20.0;
  static const double badgeSizeLG = 24.0;
  
  // ============================
  // Divider Thickness Constants
  // ============================
  
  static const double dividerThin = 1.0;
  static const double dividerMedium = 2.0;
  static const double dividerThick = 4.0;
  
  // ============================
  // Border Width Constants
  // ============================
  
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthXThick = 3.0;
  
  // ============================
  // Padding Presets for Common Components
  // ============================
  
  // Card Padding
  static EdgeInsets get cardPaddingSM => const EdgeInsets.all(spacingMD);
  static EdgeInsets get cardPaddingMD => const EdgeInsets.all(spacingLG);
  static EdgeInsets get cardPaddingLG => const EdgeInsets.all(spacingXL);
  
  // List Item Padding
  static EdgeInsets get listItemPadding => 
      const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD);
  static EdgeInsets get listItemPaddingCompact => 
      const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM);
  
  // Button Padding
  static EdgeInsets get buttonPaddingSM => 
      const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM);
  static EdgeInsets get buttonPaddingMD => 
      const EdgeInsets.symmetric(horizontal: spacingXL, vertical: spacingMD);
  static EdgeInsets get buttonPaddingLG => 
      const EdgeInsets.symmetric(horizontal: spacing2XL, vertical: spacingLG);
  
  // Input Padding
  static EdgeInsets get inputPadding => 
      const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD);
  static EdgeInsets get inputPaddingLarge => 
      const EdgeInsets.symmetric(horizontal: spacingXL, vertical: spacingLG);
  
  // Page Padding
  static EdgeInsets get pagePadding => const EdgeInsets.all(spacingXL);
  static EdgeInsets get pagePaddingMobile => const EdgeInsets.all(spacingMD);
  static EdgeInsets get pagePaddingTablet => const EdgeInsets.all(spacingLG);
  
  // Section Padding
  static EdgeInsets get sectionPadding => 
      const EdgeInsets.symmetric(vertical: spacing2XL, horizontal: spacingXL);
  static EdgeInsets get sectionPaddingCompact => 
      const EdgeInsets.symmetric(vertical: spacingXL, horizontal: spacingLG);
  
  // ============================
  // Helper Methods
  // ============================
  
  /// Returns appropriate spacing based on device size
  static double responsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return spacingSM;
    if (width < breakpointTablet) return spacingMD;
    if (width < breakpointDesktop) return spacingLG;
    return spacingXL;
  }
  
  /// Returns appropriate container max width based on device size
  static double responsiveContainerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return width;
    if (width < breakpointTablet) return containerSM;
    if (width < breakpointDesktop) return containerMD;
    if (width < breakpointLargeDesktop) return containerLG;
    return containerXL;
  }
  
  /// Checks if the current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointTablet;
  }
  
  /// Checks if the current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointTablet && width < breakpointDesktop;
  }
  
  /// Checks if the current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
  
  /// Returns appropriate number of columns for grid based on device size
  static int responsiveGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return 1;
    if (width < breakpointTablet) return 2;
    if (width < breakpointDesktop) return 3;
    return 4;
  }
  
  /// Returns responsive font size multiplier
  static double responsiveFontMultiplier(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return 0.9;
    if (width < breakpointTablet) return 0.95;
    return 1.0;
  }
  
  /// Adds horizontal padding based on screen size
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return const EdgeInsets.symmetric(horizontal: spacingMD);
    if (width < breakpointTablet) return const EdgeInsets.symmetric(horizontal: spacingLG);
    if (width < breakpointDesktop) return const EdgeInsets.symmetric(horizontal: spacingXL);
    return const EdgeInsets.symmetric(horizontal: spacing2XL);
  }
  
  /// Returns safe area padding that respects notches and system UI
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Returns bottom safe area padding (useful for bottom sheets)
  static double safeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// Returns top safe area padding (useful for status bar)
  static double safeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
}

/// Extension on BuildContext for easy access to theme constants
extension ThemeConstantsExtension on BuildContext {
  /// Quick access to ThemeConstants
  ThemeConstants get constants => ThemeConstants();
  
  /// Check if mobile device
  bool get isMobile => ThemeConstants.isMobile(this);
  
  /// Check if tablet device
  bool get isTablet => ThemeConstants.isTablet(this);
  
  /// Check if desktop device
  bool get isDesktop => ThemeConstants.isDesktop(this);
  
  /// Get responsive spacing
  double get responsiveSpacing => ThemeConstants.responsiveSpacing(this);
  
  /// Get responsive container width
  double get responsiveContainerWidth => ThemeConstants.responsiveContainerWidth(this);
  
  /// Get responsive grid columns
  int get responsiveGridColumns => ThemeConstants.responsiveGridColumns(this);
  
  /// Get responsive font multiplier
  double get responsiveFontMultiplier => ThemeConstants.responsiveFontMultiplier(this);
  
  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding => ThemeConstants.responsiveHorizontalPadding(this);
  
  /// Get safe area padding
  EdgeInsets get safeAreaPadding => ThemeConstants.safeAreaPadding(this);
  
  /// Get bottom safe area
  double get safeAreaBottom => ThemeConstants.safeAreaBottom(this);
  
  /// Get top safe area
  double get safeAreaTop => ThemeConstants.safeAreaTop(this);
}

/// Professional decoration presets for common container patterns
class DecorationPresets {
  /// Card decoration with soft shadow
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return BoxDecoration(
      color: color ?? const Color(0xFFFFFFFF),
      borderRadius: ThemeConstants.borderRadiusLG,
      border: Border.all(
        color: borderColor ?? const Color(0xFFE5E7EB).withOpacity(0.3),
        width: borderWidth ?? 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          offset: Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  /// Elevated card decoration with medium shadow
  static BoxDecoration elevatedCardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? const Color(0xFFFFFFFF),
      borderRadius: ThemeConstants.borderRadiusLG,
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  /// Gradient background decoration
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
    );
  }
  
  /// Bordered container decoration
  static BoxDecoration borderedDecoration({
    Color? borderColor,
    double? borderWidth,
    double? radius,
  }) {
    return BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(radius ?? ThemeConstants.radiusMD),
      border: Border.all(
        color: borderColor ?? const Color(0xFFE5E7EB),
        width: borderWidth ?? 1.5,
      ),
    );
  }
  
  /// Input field decoration
  static BoxDecoration inputDecoration({
    Color? backgroundColor,
    Color? borderColor,
    bool isFocused = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? const Color(0xFFFFFFFF),
      borderRadius: ThemeConstants.borderRadiusMD,
      border: Border.all(
        color: isFocused 
            ? const Color(0xFF1E3A8A) 
            : (borderColor ?? const Color(0xFFE5E7EB)),
        width: isFocused ? 2.5 : 1.5,
      ),
    );
  }
}


