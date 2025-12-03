import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================
  // Professional College Portal Color Palette
  // ============================
  
  // Primary Blue Tones (Professional Academic Blues)
  static const Color primaryBlue = Color(0xFF1E3A8A);        // Deep Navy Blue
  static const Color primaryBlueDark = Color(0xFF0F172A);    // Darkest Navy
  static const Color primaryBlueLight = Color(0xFF2563EB);   // Royal Blue
  static const Color accentBlue = Color(0xFF3B82F6);         // Bright Academic Blue
  static const Color skyBlue = Color(0xFF60A5FA);            // Sky Blue
  static const Color lightBlue = Color(0xFFDEEBFF);          // Very Light Blue
  
  // Academic Complementary Colors
  static const Color emeraldGreen = Color(0xFF047857);       // Student Accent
  static const Color emeraldLight = Color(0xFF059669);       // Light Emerald
  static const Color maroon = Color(0xFF7C2D12);             // Faculty Accent
  static const Color maroonDark = Color(0xFF641E16);         // Dark Maroon
  
  // Neutral Professional Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFBFC);
  static const Color lightGray = Color(0xFFF9FAFB);          // Background
  static const Color surfaceWhite = Color(0xFFFFFFFF);       // Card Surface
  static const Color borderGray = Color(0xFFE5E7EB);         // Border Color
  static const Color dividerGray = Color(0xFFD1D5DB);
  
  // Grey Scale (for backwards compatibility with existing code)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);        // Primary Text
  static const Color textSecondary = Color(0xFF4B5563);      // Secondary Text
  static const Color textTertiary = Color(0xFF6B7280);       // Tertiary Text
  static const Color textLight = Color(0xFF9CA3AF);          // Light Text
  
  // Status Colors (Professional Tones)
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Hover and Interactive States
  static const Color hoverBlue = Color(0xFFEFF6FF);
  static const Color hoverGray = Color(0xFFF3F4F6);
  static const Color activeBlue = Color(0xFF1E40AF);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x0D000000);        // 5% opacity
  static const Color shadowMedium = Color(0x1A000000);       // 10% opacity
  static const Color shadowDark = Color(0x33000000);         // 20% opacity

  // Primary color for easy access
  static const Color primaryColor = primaryBlue;

  // ============================
  // Professional Light Theme
  // ============================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: white,
        primaryContainer: lightBlue,
        onPrimaryContainer: primaryBlueDark,
        secondary: accentBlue,
        onSecondary: white,
        secondaryContainer: hoverBlue,
        onSecondaryContainer: primaryBlue,
        tertiary: emeraldGreen,
        onTertiary: white,
        tertiaryContainer: successLight,
        onTertiaryContainer: emeraldGreen,
        error: error,
        onError: white,
        errorContainer: errorLight,
        onErrorContainer: error,
        surface: surfaceWhite,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: borderGray,
        outlineVariant: dividerGray,
        shadow: shadowMedium,
        scrim: shadowDark,
        inverseSurface: textPrimary,
        onInverseSurface: white,
        inversePrimary: skyBlue,
        surfaceTint: primaryBlue,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: lightGray,
      
      // ============================
      // Typography System
      // ============================
      textTheme: TextTheme(
        // Display Styles (Extra Large Headings) - Serif
        displayLarge: GoogleFonts.merriweather(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: primaryBlue,
        ),
        displayMedium: GoogleFonts.merriweather(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: primaryBlue,
        ),
        displaySmall: GoogleFonts.merriweather(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: 1.3,
          color: primaryBlue,
        ),
        
        // Headline Styles (Section Headers) - Serif
        headlineLarge: GoogleFonts.merriweather(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.3,
          color: primaryBlue,
        ),
        headlineMedium: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: primaryBlue,
        ),
        headlineSmall: GoogleFonts.merriweather(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: primaryBlue,
        ),
        
        // Title Styles (Card Headers, Labels) - Sans Serif
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
          color: textSecondary,
        ),
        
        // Body Styles (Content Text) - Sans Serif
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.6,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.6,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.5,
          color: textTertiary,
        ),
        
        // Label Styles (Buttons, Small Labels) - Sans Serif
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.4,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: textTertiary,
        ),
      ),
      
      // ============================
      // AppBar Theme (Professional Header)
      // ============================
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: 16,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: white,
        ),
        iconTheme: const IconThemeData(
          color: white,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: white,
          size: 24,
        ),
      ),
      
      // ============================
      // Button Themes (Modern & Professional)
      // ============================
      
      // Elevated Buttons (Primary Actions)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 2,
          shadowColor: shadowMedium,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return white.withOpacity(0.1);
              }
              if (states.contains(WidgetState.pressed)) {
                return white.withOpacity(0.2);
              }
              return null;
            },
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return borderGray;
              }
              if (states.contains(WidgetState.hovered)) {
                return primaryBlueLight;
              }
              if (states.contains(WidgetState.pressed)) {
                return activeBlue;
              }
              return primaryBlue;
            },
          ),
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) return 4;
              if (states.contains(WidgetState.pressed)) return 1;
              return 2;
            },
          ),
        ),
      ),
      
      // Outlined Buttons (Secondary Actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return hoverBlue;
              }
              if (states.contains(WidgetState.pressed)) {
                return lightBlue;
              }
              return null;
            },
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: borderGray, width: 2);
              }
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: primaryBlueLight, width: 2);
              }
              return BorderSide(color: primaryBlue, width: 2);
            },
          ),
        ),
      ),
      
      // Text Buttons (Tertiary Actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(80, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return hoverBlue;
              }
              if (states.contains(WidgetState.pressed)) {
                return lightBlue;
              }
              return null;
            },
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: white,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // ============================
      // Input Field Theme (Modern Forms)
      // ============================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        
        // Border Styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerGray, width: 1.5),
        ),
        
        // Label & Hint Styles
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.25,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
          letterSpacing: 0.25,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textLight,
          letterSpacing: 0.25,
        ),
        helperStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: error,
        ),
        
        // Icon Styles
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        iconColor: textSecondary,
      ),
      
      // ============================
      // Card Theme (Professional Cards)
      // ============================
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: shadowLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderGray.withOpacity(0.3), width: 1),
        ),
        color: surfaceWhite,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      
      // ============================
      // Dialog Theme
      // ============================
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: surfaceWhite,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primaryBlue,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.6,
        ),
      ),
      
      // ============================
      // Bottom Sheet Theme
      // ============================
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: surfaceWhite,
        clipBehavior: Clip.antiAlias,
      ),
      
      // ============================
      // Bottom Navigation Bar Theme
      // ============================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textTertiary,
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // ============================
      // Navigation Rail Theme (For Desktop/Tablet)
      // ============================
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceWhite,
        elevation: 4,
        selectedIconTheme: const IconThemeData(
          color: primaryBlue,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: textTertiary,
          size: 24,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        indicatorColor: hoverBlue,
      ),
      
      // ============================
      // Drawer Theme (Sidebar)
      // ============================
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        width: 280,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      
      // ============================
      // ListTile Theme
      // ============================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        minLeadingWidth: 40,
      ),
      
      // ============================
      // Chip Theme
      // ============================
      chipTheme: ChipThemeData(
        backgroundColor: hoverGray,
        selectedColor: primaryBlue,
        disabledColor: dividerGray,
        deleteIconColor: textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderGray, width: 1),
        ),
        elevation: 0,
        pressElevation: 2,
      ),
      
      // ============================
      // Divider Theme
      // ============================
      dividerTheme: const DividerThemeData(
        color: dividerGray,
        thickness: 1,
        space: 24,
        indent: 0,
        endIndent: 0,
      ),
      
      // ============================
      // Switch Theme
      // ============================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return dividerGray;
            }
            if (states.contains(WidgetState.selected)) {
              return white;
            }
            return white;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return borderGray;
            }
            if (states.contains(WidgetState.selected)) {
              return primaryBlue;
            }
            return textLight;
          },
        ),
      ),
      
      // ============================
      // Checkbox Theme
      // ============================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return borderGray;
            }
            if (states.contains(WidgetState.selected)) {
              return primaryBlue;
            }
            return Colors.transparent;
          },
        ),
        checkColor: WidgetStateProperty.all(white),
        side: const BorderSide(color: borderGray, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // ============================
      // Radio Theme
      // ============================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return borderGray;
            }
            if (states.contains(WidgetState.selected)) {
              return primaryBlue;
            }
            return textLight;
          },
        ),
      ),
      
      // ============================
      // Slider Theme
      // ============================
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: borderGray,
        thumbColor: primaryBlue,
        overlayColor: hoverBlue,
        valueIndicatorColor: primaryBlue,
        valueIndicatorTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      
      // ============================
      // Progress Indicator Theme
      // ============================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: borderGray,
        circularTrackColor: borderGray,
      ),
      
      // ============================
      // Snackbar Theme
      // ============================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // ============================
      // Tab Bar Theme
      // ============================
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryBlue, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderGray,
      ),
      
      // ============================
      // Tooltip Theme
      // ============================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        verticalOffset: 12,
      ),
      
      // ============================
      // Badge Theme
      // ============================
      badgeTheme: BadgeThemeData(
        backgroundColor: error,
        textColor: white,
        textStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        alignment: AlignmentDirectional.topEnd,
      ),
      
      // ============================
      // Bottom App Bar Theme
      // ============================
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: surfaceWhite,
        elevation: 12,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        height: 64,
      ),
      
      // ============================
      // Icon Theme
      // ============================
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: primaryBlue,
        size: 24,
      ),
      
      // ============================
      // Expansion Tile Theme
      // ============================
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: surfaceWhite,
        collapsedBackgroundColor: surfaceWhite,
        textColor: textPrimary,
        collapsedTextColor: textSecondary,
        iconColor: primaryBlue,
        collapsedIconColor: textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // ============================
      // Data Table Theme
      // ============================
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(primaryBlue),
        dataRowColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return hoverBlue;
            }
            if (states.contains(WidgetState.hovered)) {
              return hoverGray;
            }
            return surfaceWhite;
          },
        ),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: white,
          letterSpacing: 0.5,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        dividerThickness: 1,
        decoration: BoxDecoration(
          border: Border.all(color: borderGray, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  // ============================
  // Professional Dark Theme
  // ============================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: skyBlue,
        onPrimary: primaryBlueDark,
        primaryContainer: primaryBlueDark,
        onPrimaryContainer: skyBlue,
        secondary: accentBlue,
        onSecondary: primaryBlueDark,
        secondaryContainer: primaryBlueDark,
        onSecondaryContainer: accentBlue,
        tertiary: emeraldLight,
        onTertiary: primaryBlueDark,
        tertiaryContainer: emeraldGreen,
        onTertiaryContainer: emeraldLight,
        error: error,
        onError: white,
        errorContainer: error,
        onErrorContainer: white,
        surface: const Color(0xFF1F2937),
        onSurface: const Color(0xFFF9FAFB),
        onSurfaceVariant: const Color(0xFFD1D5DB),
        outline: const Color(0xFF4B5563),
        outlineVariant: const Color(0xFF374151),
        shadow: shadowDark,
        scrim: shadowDark,
        inverseSurface: const Color(0xFFF9FAFB),
        onInverseSurface: primaryBlueDark,
        inversePrimary: primaryBlue,
        surfaceTint: skyBlue,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFF111827),
      
      // Typography (same as light theme)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.merriweather(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: skyBlue,
        ),
        displayMedium: GoogleFonts.merriweather(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: skyBlue,
        ),
        displaySmall: GoogleFonts.merriweather(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: 1.3,
          color: skyBlue,
        ),
        headlineLarge: GoogleFonts.merriweather(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.3,
          color: skyBlue,
        ),
        headlineMedium: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: skyBlue,
        ),
        headlineSmall: GoogleFonts.merriweather(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: skyBlue,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
          color: const Color(0xFFF9FAFB),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.4,
          color: const Color(0xFFF9FAFB),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
          color: const Color(0xFFD1D5DB),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.6,
          color: const Color(0xFFF9FAFB),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.6,
          color: const Color(0xFFD1D5DB),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.5,
          color: const Color(0xFF9CA3AF),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.4,
          color: const Color(0xFFF9FAFB),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: const Color(0xFFD1D5DB),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: const Color(0xFF9CA3AF),
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: skyBlue,
        elevation: 0,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: 16,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: skyBlue,
        ),
        iconTheme: IconThemeData(
          color: skyBlue,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: skyBlue,
          size: 24,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          foregroundColor: primaryBlueDark,
          elevation: 2,
          shadowColor: shadowDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: skyBlue,
          side: const BorderSide(color: skyBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: skyBlue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(80, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: primaryBlueDark,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B5563), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: skyBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFD1D5DB),
          letterSpacing: 0.25,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: skyBlue,
          letterSpacing: 0.25,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9CA3AF),
          letterSpacing: 0.25,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF4B5563).withOpacity(0.3), width: 1),
        ),
        color: const Color(0xFF1F2937),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFF1F2937),
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: skyBlue,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFD1D5DB),
          height: 1.6,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: const Color(0xFF1F2937),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        selectedItemColor: skyBlue,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF4B5563),
        thickness: 1,
        space: 24,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF374151);
            }
            if (states.contains(WidgetState.selected)) {
              return primaryBlueDark;
            }
            return const Color(0xFF9CA3AF);
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF1F2937);
            }
            if (states.contains(WidgetState.selected)) {
              return skyBlue;
            }
            return const Color(0xFF4B5563);
          },
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF374151);
            }
            if (states.contains(WidgetState.selected)) {
              return skyBlue;
            }
            return Colors.transparent;
          },
        ),
        checkColor: WidgetStateProperty.all(primaryBlueDark),
        side: const BorderSide(color: Color(0xFF4B5563), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFD1D5DB),
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: skyBlue,
        size: 24,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF374151),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF9FAFB),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }
  
  // ============================
  // Additional Helper Methods for Custom Widgets
  // ============================
  
  // Student-specific color variants (Emerald accent)
  static Color get studentPrimary => emeraldGreen;
  static Color get studentLight => emeraldLight;
  static Color get studentBackground => successLight;
  
  // Faculty-specific color variants (Maroon accent)
  static Color get facultyPrimary => maroon;
  static Color get facultyDark => maroonDark;
  static Color get facultyLight => const Color(0xFFFEE2E2);
  
  // Shadow presets for custom widgets
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: shadowLight,
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get shadowMediumList => [
    BoxShadow(
      color: shadowMedium,
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: shadowMedium,
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
  
  // Gradient presets
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueLight, accentBlue],
  );
  
  static LinearGradient get studentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldGreen, emeraldLight],
  );
  
  static LinearGradient get facultyGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [maroon, maroonDark],
  );
}
