import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/deep_link_service.dart';
import 'providers/data_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/usn_entry_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/faculty/faculty_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/complaints/complaints_screen.dart';
import 'screens/feedback/feedback_screen.dart';
import 'screens/study_groups/study_groups_screen.dart';
import 'screens/study_groups/study_group_detail_wrapper.dart';
import 'screens/notices/notices_screen.dart';
import 'screens/notices/create_notice_screen.dart';
import 'screens/notices/notice_detail_screen.dart';
import 'screens/notices/draft_notices_screen.dart';
import 'screens/reservations/reservations_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/notifications/quiet_hours_screen.dart';
import 'screens/notifications/notification_digests_screen.dart';
import 'screens/notifications/notification_tiers_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
import 'screens/chatbot/chatbot_profile_screen.dart';
import 'screens/test/test_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/calendar/create_event_screen.dart';
import 'screens/calendar/event_detail_screen.dart';
import 'screens/calendar/google_calendar_settings_screen.dart';
import 'screens/recommendations/recommendation_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/gamification/gamification_home_screen.dart';
import 'screens/gamification/achievements_screen.dart';
import 'screens/gamification/leaderboard_screen.dart';
import 'screens/gamification/rewards_screen.dart';
import 'screens/gamification/points_history_screen.dart';
import 'screens/academic/academic_dashboard_screen.dart';
import 'screens/academic/courses_screen.dart';
import 'screens/academic/assignments_screen.dart';
import 'screens/academic/grades_screen.dart';
import 'screens/academic/reminders_screen.dart';
import 'screens/marketplace/marketplace_home_screen.dart';
import 'screens/marketplace/books_screen.dart';
import 'screens/marketplace/lost_found_screen.dart';
import 'screens/marketplace/my_listings_screen.dart';
import 'screens/marketplace/favorites_screen.dart';
import 'screens/faculty_admin/faculty_admin_home_screen.dart';
import 'screens/faculty_admin/case_management_screen.dart';
import 'screens/faculty_admin/broadcast_studio_screen.dart';
import 'screens/faculty_admin/predictive_ops_screen.dart';
import 'screens/safety_wellbeing/safety_wellbeing_home_screen.dart';
import 'screens/safety_wellbeing/emergency_alerts_screen.dart';
import 'screens/safety_wellbeing/counseling_services_screen.dart';
import 'screens/safety_wellbeing/anonymous_check_in_screen.dart';
import 'screens/safety_wellbeing/safety_resources_screen.dart';
import 'screens/meetings/schedule_meeting_screen.dart';
import 'models/calendar_event_model.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
    print('📡 API Base URL: ${dotenv.env['API_BASE_URL'] ?? 'Not set'}');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('📝 Make sure .env file exists in ksit_nexus_app/ directory');
    print('📝 Copy .env.example to .env and update API_BASE_URL');
  }
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // Initialize Deep Link Service
  await deepLinkService.initialize();
  
  // Initialize Notification Service
  try {
    await NotificationService.initialize();
    print('✅ Notification service initialized successfully');
  } catch (e) {
    print('⚠️ Error initializing notification service: $e');
  }
  
  runApp(
    const ProviderScope(
      child: KSITNexusApp(),
    ),
  );
}

class KSITNexusApp extends ConsumerWidget {
  const KSITNexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Force light mode - ignore themeModeProvider and system settings
    // final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'KSIT Nexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // Keep for compatibility but won't be used
      themeMode: ThemeMode.light, // Force light mode always
      routerConfig: router,
    );
  }
}

// Router Configuration
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.uri.path;
      
      print('Router redirect called for: $location, isAuthenticated: ${authState.isAuthenticated}');
      
      // Always allow splash screen
      if (location == '/splash') {
        return null;
      }
      
      // Always allow login and registration screens
      if (location == '/login' || 
          location == '/register' || 
          location == '/forgot-password' ||
          location == '/otp-verification' ||
          location == '/usn-entry' ||
          location == '/reset-password') {
        return null;
      }
      
      // For all other routes, check authentication
      // But don't redirect if we're still loading (let splash screen handle it)
      if (authState.isLoading) {
        // If loading and not on splash, go to splash
        if (location != '/splash') {
          return '/splash';
        }
        return null;
      }
      
      // If not authenticated and trying to access protected route, go to login
      // BUT: Don't redirect if we're navigating from a valid route (back navigation)
      // This prevents redirecting to login when pressing back button
      if (!authState.isAuthenticated) {
        // Allow navigation to faculty dashboard even if not authenticated
        // This handles cases where back navigation might temporarily lose auth state
        if (location == '/faculty-dashboard') {
          return null;
        }
        
        if (location != '/login' && location != '/splash' && location != '/otp-verification' && location != '/usn-entry') {
          return '/login';
        }
        return null;
      }
      
      // Authenticated - allow access to all routes
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final userId = int.tryParse(state.uri.queryParameters['userId'] ?? '0') ?? 0;
          final phoneNumber = state.uri.queryParameters['phoneNumber'] ?? '';
          final purpose = state.uri.queryParameters['purpose'] ?? 'registration';
          final userType = state.uri.queryParameters['userType'];
          return OTPVerificationScreen(
            userId: userId,
            phoneNumber: phoneNumber,
            purpose: purpose,
            userType: userType,
          );
        },
      ),
      GoRoute(
        path: '/usn-entry',
        builder: (context, state) {
          final userId = int.tryParse(state.uri.queryParameters['userId'] ?? '0') ?? 0;
          return USNEntryScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final resetToken = args['resetToken'] as String? ?? '';
          final userId = args['userId'] as int? ?? 0;
          return ResetPasswordScreen(
            resetToken: resetToken,
            userId: userId,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/faculty-dashboard',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/complaints',
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/study-groups',
        builder: (context, state) => const StudyGroupsScreen(),
      ),
      GoRoute(
        path: '/study-groups/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return StudyGroupDetailRouteWrapper(groupId: id);
        },
      ),
      GoRoute(
        path: '/notices',
        builder: (context, state) => const NoticesScreen(),
      ),
      GoRoute(
        path: '/notices/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return NoticeDetailScreen(noticeId: id);
        },
      ),
      GoRoute(
        path: '/draft-notices',
        builder: (context, state) => const DraftNoticesScreen(),
      ),
      GoRoute(
        path: '/create-notice',
        builder: (context, state) {
          // Check if user is a student and redirect if so
          final container = ProviderScope.containerOf(context);
          final authState = container.read(authStateProvider);
          if (authState.user?.isStudent == true) {
            return const NoticesScreen();
          }
          return const CreateNoticeScreen();
        },
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/chatbot/profile',
        builder: (context, state) => const ChatbotProfileScreen(),
      ),
      GoRoute(
        path: '/quiet-hours',
        builder: (context, state) => const QuietHoursScreen(),
      ),
      GoRoute(
        path: '/digests',
        builder: (context, state) => const NotificationDigestsScreen(),
      ),
      GoRoute(
        path: '/tiers',
        builder: (context, state) => const NotificationTiersScreen(),
      ),
      GoRoute(
        path: '/test',
        builder: (context, state) => const TestScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/calendar/events/create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final selectedDate = extra?['selectedDate'] as DateTime?;
          return CreateEventScreen(selectedDate: selectedDate);
        },
      ),
      GoRoute(
        path: '/calendar/events/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/calendar/events/:id/edit',
        builder: (context, state) {
          final event = state.extra as CalendarEvent?;
          return CreateEventScreen(event: event);
        },
      ),
      GoRoute(
        path: '/calendar/google-settings',
        builder: (context, state) => const GoogleCalendarSettingsScreen(),
      ),
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const RecommendationScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      // Gamification routes
      GoRoute(
        path: '/gamification',
        builder: (context, state) => const GamificationHomeScreen(),
      ),
      GoRoute(
        path: '/gamification/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/gamification/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/gamification/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/gamification/points-history',
        builder: (context, state) => const PointsHistoryScreen(),
      ),
      // Academic Planner routes
      GoRoute(
        path: '/academic',
        builder: (context, state) => const AcademicDashboardScreen(),
      ),
      GoRoute(
        path: '/academic/courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/academic/assignments',
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: '/academic/grades',
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: '/academic/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      // Marketplace routes
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplaceHomeScreen(),
      ),
      GoRoute(
        path: '/marketplace/books',
        builder: (context, state) => const BooksScreen(),
      ),
      GoRoute(
        path: '/marketplace/lost-found',
        builder: (context, state) => const LostFoundScreen(),
      ),
      GoRoute(
        path: '/marketplace/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/marketplace/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      // Faculty & Admin Tools routes
      GoRoute(
        path: '/faculty-admin',
        builder: (context, state) => const FacultyAdminHomeScreen(),
      ),
      GoRoute(
        path: '/faculty-admin/cases',
        builder: (context, state) => const CaseManagementScreen(),
      ),
      GoRoute(
        path: '/faculty-admin/broadcasts',
        builder: (context, state) => const BroadcastStudioScreen(),
      ),
      GoRoute(
        path: '/faculty-admin/predictive',
        builder: (context, state) => const PredictiveOpsScreen(),
      ),
      // Safety & Wellbeing routes
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyWellbeingHomeScreen(),
      ),
      GoRoute(
        path: '/safety/emergency',
        builder: (context, state) => const EmergencyAlertsScreen(),
      ),
      GoRoute(
        path: '/safety/counseling',
        builder: (context, state) => const CounselingServicesScreen(),
      ),
      GoRoute(
        path: '/safety/check-in',
        builder: (context, state) => const AnonymousCheckInScreen(),
      ),
      GoRoute(
        path: '/safety/resources',
        builder: (context, state) => const SafetyResourcesScreen(),
      ),
      // Meetings route
      GoRoute(
        path: '/meetings',
        builder: (context, state) => const ScheduleMeetingScreen(),
      ),
    ],
  );
  
  // Set router in deep link service
  deepLinkService.setRouter(router);
  
  return router;
});