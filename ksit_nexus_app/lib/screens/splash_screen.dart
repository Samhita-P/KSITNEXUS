import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // Wait for animation to complete (show splash for at least 2 seconds)
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      print('Splash screen: Starting navigation check');
      
      try {
        // Check authentication status
        final authNotifier = ref.read(authStateProvider.notifier);
        
        // Manually trigger auth check (it won't run automatically now)
        await authNotifier.checkAuthStatus();
        
        // Wait a bit for the check to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Now check auth state
        final updatedAuthState = ref.read(authStateProvider);
        print('Current auth state: isLoading=${updatedAuthState.isLoading}, isAuthenticated=${updatedAuthState.isAuthenticated}');
        
        // Wait for loading to complete if still loading
        if (updatedAuthState.isLoading) {
          await Future.delayed(const Duration(milliseconds: 1000));
          final finalAuthState = ref.read(authStateProvider);
          
          if (finalAuthState.isAuthenticated) {
            print('User is authenticated, checking user type');
            final user = finalAuthState.user;
            if (user != null) {
              final userType = user.userType?.toLowerCase()?.trim() ?? '';
              final hasStudentProfile = user.studentProfile != null;
              final hasFacultyProfile = user.facultyProfile != null;
              
              print('Splash - UserType: "$userType", isFaculty: ${user.isFaculty}, isStudent: ${user.isStudent}');
              print('Splash - Has student profile: $hasStudentProfile, Has faculty profile: $hasFacultyProfile');
              
              // Check userType first, then profile existence
              if (userType == 'faculty' || userType == 'admin' || hasFacultyProfile || user.isFaculty) {
                print('Faculty/Admin user, navigating to faculty dashboard');
                if (mounted) context.go('/faculty-dashboard');
              } else {
                print('Student user, navigating to home');
                if (mounted) context.go('/home');
              }
            } else {
              print('User is null, defaulting to home');
              if (mounted) context.go('/home');
            }
          } else {
            print('User is not authenticated, navigating to login');
            if (mounted) context.go('/login');
          }
        } else {
          if (updatedAuthState.isAuthenticated) {
            print('User is authenticated, checking user type');
            final user = updatedAuthState.user;
            if (user != null) {
              final userType = user.userType?.toLowerCase()?.trim() ?? '';
              final hasStudentProfile = user.studentProfile != null;
              final hasFacultyProfile = user.facultyProfile != null;
              
              print('Splash - UserType: "$userType", isFaculty: ${user.isFaculty}, isStudent: ${user.isStudent}');
              print('Splash - Has student profile: $hasStudentProfile, Has faculty profile: $hasFacultyProfile');
              
              // Check userType first, then profile existence
              if (userType == 'faculty' || userType == 'admin' || hasFacultyProfile || user.isFaculty) {
                print('Faculty/Admin user, navigating to faculty dashboard');
                if (mounted) context.go('/faculty-dashboard');
              } else {
                print('Student user, navigating to home');
                if (mounted) context.go('/home');
              }
            } else {
              print('User is null, defaulting to home');
              if (mounted) context.go('/home');
            }
          } else {
            print('User is not authenticated, navigating to login');
            if (mounted) context.go('/login');
          }
        }
      } catch (e) {
        print('Error checking auth state: $e');
        print('Navigating to login as fallback');
        if (mounted) context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueDark,
              AppTheme.accentBlue,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // KSIT Logo Placeholder
                      Builder(
                        builder: (context) {
                          final logoSize = Responsive.value(
                            context: context,
                            mobile: 120.0,
                            tablet: 140.0,
                            desktop: 160.0,
                          );
                          return Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school,
                              size: logoSize * 0.5,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 30, tablet: 36, desktop: 40)),
                      
                      // App Title
                      Text(
                        'KSIT Nexus',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: Responsive.fontSize(context, 36),
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 10, tablet: 12)),
                      
                      // Subtitle
                      Text(
                        'Digital Campus App',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                          fontSize: Responsive.fontSize(context, 20),
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 50, tablet: 56, desktop: 60)),
                      
                      // Loading Indicator
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24)),
                      
                      Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          fontSize: Responsive.fontSize(context, 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}