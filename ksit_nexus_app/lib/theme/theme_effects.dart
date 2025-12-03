import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Professional Visual Effects & Animations
/// 
/// This file contains reusable gradient definitions, shadow presets,
/// and animation configurations for the professional college portal design.

class ThemeEffects {
  // ============================
  // Professional Gradient Presets
  // ============================
  
  /// Primary blue gradient (for headers, hero sections)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.primaryBlue,
      AppTheme.primaryBlueLight,
      AppTheme.accentBlue,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Deep navy gradient (for dark sections)
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.primaryBlueDark,
      AppTheme.primaryBlue,
    ],
  );
  
  /// Student-themed gradient (emerald green)
  static const LinearGradient studentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.emeraldGreen,
      AppTheme.emeraldLight,
    ],
  );
  
  /// Faculty-themed gradient (maroon)
  static const LinearGradient facultyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.maroon,
      AppTheme.maroonDark,
    ],
  );
  
  /// Success gradient (for success messages, achievements)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.success,
      AppTheme.emeraldGreen,
    ],
  );
  
  /// Subtle background gradient (for page backgrounds)
  static const LinearGradient subtleBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.lightGray,
      AppTheme.offWhite,
      AppTheme.white,
    ],
  );
  
  /// Shimmer gradient (for loading states)
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFFE5E7EB),
      Color(0xFFF3F4F6),
      Color(0xFFE5E7EB),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Radial gradient (for circular elements, avatars)
  static const RadialGradient primaryRadialGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [
      AppTheme.accentBlue,
      AppTheme.primaryBlue,
      AppTheme.primaryBlueDark,
    ],
  );
  
  /// Glass morphism overlay gradient
  static LinearGradient glassMorphismGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.white.withOpacity(0.25),
      AppTheme.white.withOpacity(0.15),
    ],
  );
  
  // ============================
  // Professional Shadow Presets
  // ============================
  
  /// Soft shadow for cards and containers
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppTheme.shadowLight,
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  /// Medium shadow for elevated elements
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: AppTheme.shadowMedium,
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  /// Large shadow for modals and overlays
  static const List<BoxShadow> largeShadow = [
    BoxShadow(
      color: AppTheme.shadowMedium,
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
  
  /// Hover shadow (slightly elevated)
  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: AppTheme.shadowMedium,
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  /// Inner shadow effect
  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: AppTheme.shadowLight,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
  
  /// Colored shadow for primary buttons
  static List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: AppTheme.primaryBlue.withOpacity(0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  /// Colored shadow for student buttons
  static List<BoxShadow> studentButtonShadow = [
    BoxShadow(
      color: AppTheme.emeraldGreen.withOpacity(0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  /// Colored shadow for faculty buttons
  static List<BoxShadow> facultyButtonShadow = [
    BoxShadow(
      color: AppTheme.maroon.withOpacity(0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  // ============================
  // Animation Curves
  // ============================
  
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve sharpCurve = Curves.easeInOutQuart;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve entranceCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  
  // ============================
  // Animation Durations
  // ============================
  
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 400);
  static const Duration xSlowDuration = Duration(milliseconds: 600);
  
  // ============================
  // Page Transition Builders
  // ============================
  
  /// Fade transition for page navigation
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
  
  /// Slide from right transition
  static Widget slideFromRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(tween.chain(
      CurveTween(curve: smoothCurve),
    ));
    
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
  
  /// Slide from bottom transition
  static Widget slideFromBottomTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(tween.chain(
      CurveTween(curve: smoothCurve),
    ));
    
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
  
  /// Scale transition
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation.drive(Tween(begin: 0.9, end: 1.0).chain(
        CurveTween(curve: smoothCurve),
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
  
  // ============================
  // Shimmer Animation Effect
  // ============================
  
  /// Creates a shimmer animation controller
  static AnimationController createShimmerController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  /// Shimmer effect widget wrapper
  static Widget shimmerEffect({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - controller.value * 2, 0.0),
              end: Alignment(1.0 - controller.value * 2, 0.0),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF9FAFB),
                Color(0xFFE5E7EB),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
  
  // ============================
  // Loading Skeleton Decorations
  // ============================
  
  static BoxDecoration skeletonDecoration = BoxDecoration(
    color: AppTheme.borderGray,
    borderRadius: BorderRadius.circular(8),
  );
  
  static BoxDecoration skeletonCircleDecoration = const BoxDecoration(
    color: AppTheme.borderGray,
    shape: BoxShape.circle,
  );
  
  // ============================
  // Glass Morphism Effect
  // ============================
  
  /// Creates a glass morphism container decoration
  static BoxDecoration glassMorphismDecoration({
    double opacity = 0.2,
    double blur = 10.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.white.withOpacity(opacity),
          AppTheme.white.withOpacity(opacity * 0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? AppTheme.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.shadowLight,
          offset: const Offset(0, 4),
          blurRadius: blur,
        ),
      ],
    );
  }
  
  // ============================
  // Hover Effect Helper
  // ============================
  
  /// Creates a hover transform matrix
  static Matrix4 hoverTransform = Matrix4.identity()..scale(1.02);
  
  /// Creates a pressed transform matrix
  static Matrix4 pressedTransform = Matrix4.identity()..scale(0.98);
  
  // ============================
  // Pulse Animation
  // ============================
  
  /// Creates a pulse animation for notifications/badges
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  // ============================
  // Ripple Effect Colors
  // ============================
  
  static Color get primaryRipple => AppTheme.primaryBlue.withOpacity(0.12);
  static Color get studentRipple => AppTheme.emeraldGreen.withOpacity(0.12);
  static Color get facultyRipple => AppTheme.maroon.withOpacity(0.12);
  static Color get neutralRipple => AppTheme.textSecondary.withOpacity(0.08);
  
  // ============================
  // Border Gradient Decoration
  // ============================
  
  /// Creates a container with gradient border
  static BoxDecoration gradientBorderDecoration({
    required Gradient gradient,
    double borderWidth = 2.0,
    double radius = 12.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        width: borderWidth,
        color: Colors.transparent,
      ),
      gradient: gradient,
    );
  }
  
  // ============================
  // Backdrop Blur Effect
  // ============================
  
  /// Standard blur sigma for backdrop filters
  static const double backdropBlurSigma = 10.0;
  static const double backdropBlurSigmaLight = 5.0;
  static const double backdropBlurSigmaHeavy = 15.0;
  
  // ============================
  // Elevation Shadows (Material Design 3 Inspired)
  // ============================
  
  static List<BoxShadow> getElevationShadow(double elevation) {
    if (elevation <= 0) return [];
    if (elevation <= 1) return softShadow;
    if (elevation <= 3) return mediumShadow;
    if (elevation <= 6) return largeShadow;
    return [
      BoxShadow(
        color: AppTheme.shadowMedium,
        offset: Offset(0, elevation),
        blurRadius: elevation * 3,
        spreadRadius: 0,
      ),
    ];
  }
  
  // ============================
  // Neumorphism Effect (Subtle 3D Effect)
  // ============================
  
  static BoxDecoration neumorphicDecoration({
    Color? baseColor,
    bool isPressed = false,
    double radius = 12.0,
  }) {
    final color = baseColor ?? AppTheme.lightGray;
    
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
    );
  }
  
  // ============================
  // Card Hover Decoration
  // ============================
  
  static BoxDecoration cardHoverDecoration = BoxDecoration(
    color: AppTheme.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.borderGray.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: hoverShadow,
  );
  
  // ============================
  // Gradient Text Style Helper
  // ============================
  
  /// Creates a shader for gradient text
  static Shader createTextGradientShader(Rect bounds, Gradient gradient) {
    return gradient.createShader(bounds);
  }
  
  // ============================
  // Staggered Animation Helper
  // ============================
  
  /// Creates staggered animation intervals for list items
  static Interval getStaggeredInterval(int index, {int totalItems = 10}) {
    final delay = index / totalItems;
    final duration = 1.0 - delay;
    return Interval(
      delay.clamp(0.0, 1.0),
      (delay + duration).clamp(0.0, 1.0),
      curve: smoothCurve,
    );
  }
  
  // ============================
  // Interactive Overlay Colors
  // ============================
  
  /// Primary hover overlay
  static Color get primaryHoverOverlay => AppTheme.primaryBlue.withOpacity(0.08);
  
  /// Primary pressed overlay
  static Color get primaryPressedOverlay => AppTheme.primaryBlue.withOpacity(0.12);
  
  /// Success hover overlay
  static Color get successHoverOverlay => AppTheme.success.withOpacity(0.08);
  
  /// Error hover overlay
  static Color get errorHoverOverlay => AppTheme.error.withOpacity(0.08);
}

/// Extension on AnimationController for common patterns
extension AnimationControllerExtensions on AnimationController {
  /// Repeat with reverse
  TickerFuture repeatWithReverse() {
    return repeat(reverse: true);
  }
  
  /// Animate to end and reset
  Future<void> animateOnce() async {
    await forward();
    reset();
  }
}


