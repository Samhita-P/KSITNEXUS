import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/feedback_model.dart';
import '../models/study_group_model.dart';
import '../models/notice_model.dart';
import '../models/meeting_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart' as notification_model;
import '../models/chatbot_model.dart';
import '../models/faculty_admin_models.dart';
import '../models/academic_planner_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/two_factor_service.dart';
import '../services/biometric_service.dart';
import '../services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.read(apiServiceProvider)));
final twoFactorServiceProvider = Provider<TwoFactorService>((ref) => TwoFactorService());
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());
final websocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());

// Authentication Providers
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  bool _hasCheckedAuth = false;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    // Don't auto-check auth on initialization
    // Let the splash screen control when to check
  }

  Future<void> _checkAuthStatus() async {
    // Only check auth status if we don't already have a user
    if (state.user != null && state.isAuthenticated) {
      print('User already authenticated, skipping auth check');
      return;
    }
    
    if (_hasCheckedAuth) {
      print('Auth already checked, skipping');
      return;
    }
    
    print('Checking authentication status...');
    state = state.copyWith(isLoading: true);
    _hasCheckedAuth = true;
    
    try {
      // Check if we have stored tokens first
      final hasToken = await _authService.checkAuthStatus();
      if (hasToken) {
        final user = await _authService.getCurrentUser();
        print('Auth check successful, user: ${user.email}');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      } else {
        print('No stored tokens found');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        );
      }
    } catch (e) {
      print('Auth check failed: $e');
      // If getCurrentUser fails, user is not authenticated
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: null, // Don't show error for normal unauthenticated state
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      print('Attempting login for username: $username');
      final user = await _authService.login(username, password);
      print('=== AUTH NOTIFIER - LOGIN SUCCESS ===');
      print('User email: ${user.email}');
      print('User type: ${user.userType}');
      print('isFaculty: ${user.isFaculty}');
      print('isStudent: ${user.isStudent}');
      print('Has student profile: ${user.studentProfile != null}');
      print('Has faculty profile: ${user.facultyProfile != null}');
      print('=====================================');
      
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
      
      print('Auth state updated: isAuthenticated=${state.isAuthenticated}');
      print('Auth state user email: ${state.user?.email}');
      print('Auth state user type: ${state.user?.userType}');
      print('Auth state isFaculty: ${state.user?.isFaculty}');
    } catch (e) {
      print('Login failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _authService.register(
        username: request.username,
        email: request.email,
        password: request.password,
        firstName: request.firstName,
        lastName: request.lastName,
        userType: request.userType,
        phoneNumber: request.phoneNumber,
        usn: request.usn,
      );
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOTP(int userId, String otp) async {
    state = state.copyWith(isLoading: true);
    try {
      final authResponse = await _authService.verifyRegistrationOTP(userId, otp);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
        error: null,
      );
      // Return response data including requires_usn_entry
      return {
        'user': authResponse.user,
        'requires_usn_entry': authResponse.requiresUsnEntry,
      };
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshAuthState() async {
    // Force refresh user data even if already authenticated
    print('Force refreshing auth state...');
    state = state.copyWith(isLoading: true);
    try {
      // Check if we have stored tokens first
      final hasToken = await _authService.checkAuthStatus();
      if (hasToken) {
        final user = await _authService.getCurrentUser();
        print('Auth state refresh successful, user: ${user.email}');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      } else {
        print('No stored tokens found during refresh');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        );
      }
    } catch (e) {
      print('Auth state refresh failed: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: null,
      );
    }
  }
  
  // Public method to check auth status (called by splash screen)
  Future<void> checkAuthStatus() async {
    await _checkAuthStatus();
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfilePicture(String imageUrl) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _authService.updateProfilePicture(imageUrl);
      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> requestOTP(String email, String type) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.requestOTP(email, type);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.verifyOTP(email, otp);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Forgot Password Flow
  Future<Map<String, dynamic>> requestPasswordResetOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _authService.requestPasswordResetOTP(phoneNumber);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOTP(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _authService.verifyPasswordResetOTP(phoneNumber, otp);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword, String confirmPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.resetPassword(resetToken, newPassword, confirmPassword);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Getter for current user
  User? get currentUser => state.user;
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.user,
    this.error,
  });

  factory AuthState.initial() => AuthState(
        isLoading: false,
        isAuthenticated: false,
      );

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

// Complaints Providers
final complaintsProvider = AsyncNotifierProvider<ComplaintsNotifier, List<Complaint>>(() {
  return ComplaintsNotifier();
});

class ComplaintsNotifier extends AsyncNotifier<List<Complaint>> {
  @override
  Future<List<Complaint>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getComplaints();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getComplaints();
    });
  }

  Future<void> createComplaint(ComplaintCreateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createComplaint(request);
    await refresh();
  }

  Future<void> updateComplaint(int id, ComplaintUpdateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateComplaint(id, request);
    await refresh();
  }

  Future<void> markComplaintResolved(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateComplaint(id, ComplaintUpdateRequest(status: 'resolved'));
    await refresh();
  }
}

// Feedback Providers
final feedbacksProvider = AsyncNotifierProvider<FeedbacksNotifier, List<Feedback>>(() {
  return FeedbacksNotifier();
});

class FeedbacksNotifier extends AsyncNotifier<List<Feedback>> {
  @override
  Future<List<Feedback>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getFeedbacks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getFeedbacks();
    });
  }

  Future<void> createFeedback(FeedbackCreateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createFeedback(request);
    await refresh();
  }
}

// Faculty Feedback Providers
final facultyFeedbackProvider = FutureProvider.family<List<Feedback>, int>((ref, facultyId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getFacultyFeedback(facultyId);
});

final facultyFeedbackSummaryProvider = FutureProvider.family<FacultyFeedbackSummary, int>((ref, facultyId) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    return await apiService.getFacultyFeedbackSummary();
  } catch (e) {
    print('Error fetching feedback summary: $e');
    // Return default summary if API doesn't provide it
    return FacultyFeedbackSummary(
      facultyId: facultyId,
      facultyName: '',
      facultyDepartment: '',
      averageOverallRating: 0.0,
      averageTeachingRating: 0.0,
      averageCommunicationRating: 0.0,
      averagePunctualityRating: 0.0,
      averageHelpfulnessRating: 0.0,
      totalFeedbacks: 0,
      semesterFeedbacks: 0,
      recentFeedbacks: [],
      ratingsBySemester: {},
    );
  }
});

// Study Groups Providers
final studyGroupsProvider = AsyncNotifierProvider<StudyGroupsNotifier, List<StudyGroup>>(() {
  return StudyGroupsNotifier();
});

class StudyGroupsNotifier extends AsyncNotifier<List<StudyGroup>> {
  @override
  Future<List<StudyGroup>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getStudyGroups();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getStudyGroups();
    });
  }

  Future<void> createStudyGroup(StudyGroupCreateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createStudyGroup(request);
    await refresh();
  }

  Future<void> joinStudyGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.joinStudyGroup(groupId);
    await refresh();
  }

  Future<void> leaveStudyGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.leaveStudyGroup(groupId);
    await refresh();
  }

  Future<void> reportStudyGroup(int groupId, String issueDescription, String contentToRemove, String warningMessage) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.reportStudyGroup(groupId, issueDescription, contentToRemove, warningMessage);
    await refresh();
  }

  Future<void> closeStudyGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.closeStudyGroup(groupId);
    await refresh();
  }

  Future<void> muteStudyGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.muteStudyGroup(groupId);
    await refresh();
  }

}

// Notices Providers
final noticesProvider = AsyncNotifierProvider<NoticesNotifier, List<Notice>>(() {
  return NoticesNotifier();
});

class NoticesNotifier extends AsyncNotifier<List<Notice>> {
  @override
  Future<List<Notice>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getNotices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getNotices();
    });
  }

  Future<Notice> createNotice(NoticeCreateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    final createdNotice = await apiService.createNotice(request);
    await refresh();
    return createdNotice;
  }
}

// Meetings Providers
final meetingsProvider = AsyncNotifierProvider<MeetingsNotifier, List<Meeting>>(() {
  return MeetingsNotifier();
});

class MeetingsNotifier extends AsyncNotifier<List<Meeting>> {
  @override
  Future<List<Meeting>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getMeetings();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getMeetings();
    });
  }

  Future<void> createMeeting(MeetingCreateRequest request) async {
    print('MeetingsNotifier: Creating meeting with request: ${request.toJson()}');
    final apiService = ref.read(apiServiceProvider);
    final result = await apiService.createMeeting(request);
    print('MeetingsNotifier: Meeting created successfully: ${result.toJson()}');
    await refresh();
  }

  Future<void> updateMeeting(int id, MeetingUpdateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateMeeting(id, request);
    await refresh();
  }

  Future<void> cancelMeeting(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateMeeting(id, MeetingUpdateRequest(status: 'cancelled'));
    await refresh();
  }
}

// Upcoming Meetings Provider
final upcomingMeetingsProvider = AsyncNotifierProvider<UpcomingMeetingsNotifier, List<Meeting>>(() {
  return UpcomingMeetingsNotifier();
});

class UpcomingMeetingsNotifier extends AsyncNotifier<List<Meeting>> {
  @override
  Future<List<Meeting>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getUpcomingMeetings();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getUpcomingMeetings();
    });
  }
}

// Complaint Statistics Provider
final complaintStatsProvider = AsyncNotifierProvider<ComplaintStatsNotifier, Map<String, dynamic>>(() {
  return ComplaintStatsNotifier();
});

class ComplaintStatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getComplaintStats();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getComplaintStats();
    });
  }
}

// Faculty Study Groups Provider
final facultyStudyGroupsProvider = AsyncNotifierProvider.family<FacultyStudyGroupsNotifier, List<StudyGroup>, String>(() {
  return FacultyStudyGroupsNotifier();
});

class FacultyStudyGroupsNotifier extends FamilyAsyncNotifier<List<StudyGroup>, String> {
  @override
  Future<List<StudyGroup>> build(String filter) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getFacultyStudyGroups(filter: filter);
  }

  Future<void> refresh(String filter) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getFacultyStudyGroups(filter: filter);
    });
  }

  Future<void> reportGroup(int groupId, String issueDescription, String contentToRemove, String warningMessage) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.reportStudyGroupAsFaculty(groupId, issueDescription, contentToRemove, warningMessage);
    // Refresh all filters
    ref.invalidate(facultyStudyGroupsProvider);
  }

  Future<void> approveGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.approveStudyGroup(groupId);
    // Refresh all filters
    ref.invalidate(facultyStudyGroupsProvider);
  }

  Future<void> rejectGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.rejectStudyGroup(groupId);
    // Refresh all filters
    ref.invalidate(facultyStudyGroupsProvider);
  }

  Future<void> reopenGroup(int groupId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.reopenStudyGroup(groupId);
    // Refresh all filters
    ref.invalidate(facultyStudyGroupsProvider);
  }
}

// Reservations Providers
final reservationsProvider = AsyncNotifierProvider<ReservationsNotifier, List<Reservation>>(() {
  return ReservationsNotifier();
});

class ReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  @override
  Future<List<Reservation>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getReservations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getReservations();
    });
  }

  Future<void> createReservation(ReservationCreateRequest request) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createReservation(request);
    await refresh();
  }

  Future<void> cancelReservation(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.cancelReservation(id);
    await refresh();
  }
}

// Notifications Providers
final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<notification_model.Notification>>(() {
  return NotificationsNotifier();
});

class NotificationsNotifier extends AsyncNotifier<List<notification_model.Notification>> {
  @override
  Future<List<notification_model.Notification>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getNotifications();
    });
  }

  Future<void> markAsRead(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.markNotificationAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.markAllNotificationsAsRead();
    await refresh();
  }

  Future<void> deleteNotification(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.deleteNotification(id);
    await refresh();
  }
}

// Chatbot Providers
final chatbotSessionsProvider = AsyncNotifierProvider<ChatbotSessionsNotifier, List<ChatbotConversation>>(() {
  return ChatbotSessionsNotifier();
});

class ChatbotSessionsNotifier extends AsyncNotifier<List<ChatbotConversation>> {
  @override
  Future<List<ChatbotConversation>> build() async {
    return [];
  }

  Future<ChatbotConversation> createSession() async {
    final apiService = ref.read(apiServiceProvider);
    final session = await apiService.createChatbotSession();
    state = AsyncValue.data([...state.value ?? [], session]);
    return session;
  }

  Future<ChatbotMessage> sendMessage(int conversationId, String message) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.sendChatbotMessage(conversationId, message);
  }
}

// Reading Rooms Provider
final readingRoomsProvider = AsyncNotifierProvider<ReadingRoomsNotifier, List<ReadingRoom>>(() {
  return ReadingRoomsNotifier();
});

class ReadingRoomsNotifier extends AsyncNotifier<List<ReadingRoom>> {
  @override
  Future<List<ReadingRoom>> build() async {
    // Check if user is authenticated before making API calls
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      throw Exception('User not authenticated');
    }
    
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getReadingRooms();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Check if user is authenticated before making API calls
      final authState = ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getReadingRooms();
    });
  }
}

// Faculties Provider
final facultiesProvider = AsyncNotifierProvider<FacultiesNotifier, List<Faculty>>(() {
  return FacultiesNotifier();
});

class FacultiesNotifier extends AsyncNotifier<List<Faculty>> {
  @override
  Future<List<Faculty>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getFaculties();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getFaculties();
    });
  }
}

// User Reservations Provider
final userReservationsProvider = AsyncNotifierProvider<UserReservationsNotifier, List<Reservation>>(() {
  return UserReservationsNotifier();
});

class UserReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  @override
  Future<List<Reservation>> build() async {
    // Check if user is authenticated before making API calls
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      throw Exception('User not authenticated');
    }
    
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getUserReservations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Check if user is authenticated before making API calls
      final authState = ref.read(authStateProvider);
      if (!authState.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getUserReservations();
    });
  }
}

// Room Seats Provider
final roomSeatsProvider = FutureProvider.family<List<Seat>, int>((ref, roomId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRoomSeats(roomId);
});

// User Notifications Provider
final userNotificationsProvider = AsyncNotifierProvider<UserNotificationsNotifier, List<notification_model.Notification>>(() {
  return UserNotificationsNotifier();
});

class UserNotificationsNotifier extends AsyncNotifier<List<notification_model.Notification>> {
  StreamSubscription<Map<String, dynamic>>? _websocketSubscription;
  bool _websocketConnected = false;

  @override
  Future<List<notification_model.Notification>> build() async {
    final apiService = ref.read(apiServiceProvider);
    final notifications = await apiService.getUserNotifications();
    
    // Connect to WebSocket for real-time updates
    _connectWebSocket();
    
    // Listen to WebSocket stream for new notifications
    _listenToWebSocket();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _dispose();
    });
    
    return notifications;
  }

  void _connectWebSocket() {
    if (_websocketConnected) return;
    
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      
      if (user?.id != null) {
        final webSocketService = ref.read(webSocketServiceProvider);
        webSocketService.connectNotifications(user!.id!);
        _websocketConnected = true;
        print('Connected to notification WebSocket for user ${user.id}');
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  void _listenToWebSocket() {
    if (_websocketSubscription != null) return;
    
    try {
      final webSocketService = ref.read(webSocketServiceProvider);
      _websocketSubscription = webSocketService.notificationController.stream.listen(
        (data) {
          if (data['type'] == 'notification' && data['notification'] != null) {
            _handleRealtimeNotification(data['notification']);
          }
        },
        onError: (error) {
          print('WebSocket notification error: $error');
        },
      );
    } catch (e) {
      print('Error listening to WebSocket: $e');
    }
  }

  void _handleRealtimeNotification(Map<String, dynamic> notificationData) {
    try {
      // Convert WebSocket notification format to Notification model format
      // WebSocket sends: id (string), title, message, type, is_read, created_at
      final notificationJson = {
        'id': int.tryParse(notificationData['id'].toString()) ?? 0,
        'title': notificationData['title'] as String? ?? '',
        'message': notificationData['message'] as String? ?? '',
        'type': notificationData['type'] as String? ?? 'general',
        'category': notificationData['type'] as String? ?? 'general',
        'notification_type': notificationData['type'] as String? ?? 'general',
        'priority': notificationData['priority'] as String? ?? 'medium',
        'is_read': notificationData['is_read'] as bool? ?? false,
        'is_sent': true,
        'created_at': notificationData['created_at'] as String? ?? DateTime.now().toIso8601String(),
        'data': notificationData['data'] as Map<String, dynamic>? ?? {},
      };
      
      // Convert to Notification model
      final notification = notification_model.Notification.fromJson(notificationJson);
      
      // Get current state
      final currentState = state;
      if (currentState.hasValue) {
        final currentNotifications = List<notification_model.Notification>.from(currentState.value!);
        
        // Check if notification already exists (avoid duplicates)
        final exists = currentNotifications.any((n) => n.id == notification.id);
        if (!exists) {
          // Add new notification at the beginning
          currentNotifications.insert(0, notification);
          
          // Update state with new list
          state = AsyncValue.data(currentNotifications);
          print('New real-time notification received: ${notification.title}');
        }
      } else {
        // If state is loading or error, just refresh
        refresh();
      }
    } catch (e) {
      print('Error handling real-time notification: $e');
      print('Notification data: $notificationData');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getUserNotifications();
    });
  }

  Future<void> markAsRead(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.markNotificationAsRead(id);
    
    // Update local state immediately
    final currentState = state;
    if (currentState.hasValue) {
      final updatedNotifications = currentState.value!.map<notification_model.Notification>((n) {
        if (n.id == id) {
          return notification_model.Notification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            category: n.category,
            notificationType: n.notificationType,
            priority: n.priority,
            isRead: true,
            isSent: n.isSent,
            createdAt: n.createdAt,
            data: n.data,
            userId: n.userId,
            userName: n.userName,
            readAt: n.readAt,
            sentAt: n.sentAt,
            imageUrl: n.imageUrl,
            actionUrl: n.actionUrl,
            actionText: n.actionText,
          );
        }
        return n;
      }).toList();
      state = AsyncValue.data(updatedNotifications);
    }
    
    await refresh();
  }

  Future<void> markAllAsRead() async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.markAllNotificationsAsRead();
    
    // Update local state immediately
    final currentState = state;
    if (currentState.hasValue) {
      final updatedNotifications = currentState.value!.map<notification_model.Notification>((n) {
        return notification_model.Notification(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          category: n.category,
          notificationType: n.notificationType,
          priority: n.priority,
          isRead: true,
          isSent: n.isSent,
          createdAt: n.createdAt,
          data: n.data,
          userId: n.userId,
          userName: n.userName,
          readAt: n.readAt,
          sentAt: n.sentAt,
          imageUrl: n.imageUrl,
          actionUrl: n.actionUrl,
          actionText: n.actionText,
        );
      }).toList();
      state = AsyncValue.data(updatedNotifications);
    }
    
    await refresh();
  }

  Future<void> deleteNotification(int id) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.deleteNotification(id);
    
    // Update local state immediately
    final currentState = state;
    if (currentState.hasValue) {
      final updatedNotifications = currentState.value!.where((n) => n.id != id).toList();
      state = AsyncValue.data(updatedNotifications);
    }
    
    await refresh();
  }

  void _dispose() {
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
  }
}

// Chatbot Categories Provider
final chatbotCategoriesProvider = AsyncNotifierProvider<ChatbotCategoriesNotifier, List<ChatbotCategory>>(() {
  return ChatbotCategoriesNotifier();
});

class ChatbotCategoriesNotifier extends AsyncNotifier<List<ChatbotCategory>> {
  @override
  Future<List<ChatbotCategory>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getChatbotCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getChatbotCategories();
    });
  }
}

// Chatbot Questions Provider
final chatbotQuestionsProvider = AsyncNotifierProvider<ChatbotQuestionsNotifier, List<ChatbotQuestion>>(() {
  return ChatbotQuestionsNotifier();
});

class ChatbotQuestionsNotifier extends AsyncNotifier<List<ChatbotQuestion>> {
  @override
  Future<List<ChatbotQuestion>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getChatbotFAQs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getChatbotFAQs();
    });
  }
}

// Category Questions Provider
final categoryQuestionsProvider = AsyncNotifierProvider.family<CategoryQuestionsNotifier, List<ChatbotQuestion>, int?>(() {
  return CategoryQuestionsNotifier();
});

class CategoryQuestionsNotifier extends FamilyAsyncNotifier<List<ChatbotQuestion>, int?> {
  @override
  Future<List<ChatbotQuestion>> build(int? categoryId) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getChatbotQuestions(categoryId: categoryId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getChatbotQuestions(categoryId: arg);
    });
  }
}

// User Chatbot Sessions Provider
final userChatbotSessionsProvider = AsyncNotifierProvider<UserChatbotSessionsNotifier, List<ChatbotConversation>>(() {
  return UserChatbotSessionsNotifier();
});

class UserChatbotSessionsNotifier extends AsyncNotifier<List<ChatbotConversation>> {
  @override
  Future<List<ChatbotConversation>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getUserChatbotSessions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getUserChatbotSessions();
    });
  }
}

// Question Suggestions Provider
final questionSuggestionsProvider = AsyncNotifierProvider.family<QuestionSuggestionsNotifier, List<ChatbotQuestion>, String>(() {
  return QuestionSuggestionsNotifier();
});

class QuestionSuggestionsNotifier extends FamilyAsyncNotifier<List<ChatbotQuestion>, String> {
  @override
  Future<List<ChatbotQuestion>> build(String query) async {
    if (query.isEmpty) return [];
    
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getQuestionSuggestions(query: query);
  }

  Future<void> updateQuery(String newQuery) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (newQuery.isEmpty) return <ChatbotQuestion>[];
      
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getQuestionSuggestions(query: newQuery);
    });
  }
}

// Chatbot Response Provider
final chatbotResponseProvider = StateNotifierProvider<ChatbotResponseNotifier, AsyncValue<ChatbotResponse?>>((ref) {
  return ChatbotResponseNotifier(ref.read(apiServiceProvider));
});

class ChatbotResponseNotifier extends StateNotifier<AsyncValue<ChatbotResponse?>> {
  final ApiService _apiService;

  ChatbotResponseNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String message,
    String? sessionId,
    int? categoryId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _apiService.sendChatbotMessageWithFAQ(
        message: message,
        sessionId: sessionId,
        categoryId: categoryId,
      );
    });
  }

  void clearResponse() {
    state = const AsyncValue.data(null);
  }
}

// Popular Questions Provider
final popularQuestionsProvider = AsyncNotifierProvider<PopularQuestionsNotifier, List<ChatbotQuestion>>(() {
  return PopularQuestionsNotifier();
});

class PopularQuestionsNotifier extends AsyncNotifier<List<ChatbotQuestion>> {
  @override
  Future<List<ChatbotQuestion>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getPopularQuestions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getPopularQuestions();
    });
  }
}

// FAQ Search Provider
final faqSearchProvider = AsyncNotifierProvider.family<FAQSearchNotifier, List<ChatbotQuestion>, String>(() {
  return FAQSearchNotifier();
});

class FAQSearchNotifier extends FamilyAsyncNotifier<List<ChatbotQuestion>, String> {
  @override
  Future<List<ChatbotQuestion>> build(String query) async {
    if (query.isEmpty) return [];
    
    final apiService = ref.read(apiServiceProvider);
    return await apiService.searchFAQ(query: query);
  }

  Future<void> updateQuery(String newQuery) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (newQuery.isEmpty) return <ChatbotQuestion>[];
      
      final apiService = ref.read(apiServiceProvider);
      return await apiService.searchFAQ(query: newQuery);
    });
  }
}

// Broadcast Providers
final broadcastsProvider = AsyncNotifierProvider<BroadcastsNotifier, List<Broadcast>>(() {
  return BroadcastsNotifier();
});

class BroadcastsNotifier extends AsyncNotifier<List<Broadcast>> {
  bool _myBroadcastsOnly = true; // Default to showing only faculty's broadcasts
  String? _filterType;

  @override
  Future<List<Broadcast>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getBroadcasts(
      type: _filterType,
      myBroadcasts: _myBroadcastsOnly ? true : null,
    );
  }

  Future<void> refresh({bool? myBroadcasts, String? type}) async {
    if (myBroadcasts != null) {
      _myBroadcastsOnly = myBroadcasts;
    }
    if (type != null) {
      _filterType = type;
    } else if (type == null && _filterType != null) {
      // If type is explicitly set to null, clear the filter
      _filterType = null;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getBroadcasts(
        type: _filterType,
        myBroadcasts: _myBroadcastsOnly ? true : null,
      );
    });
  }

  Future<Broadcast> createBroadcast(Map<String, dynamic> data) async {
    final apiService = ref.read(apiServiceProvider);
    final broadcast = await apiService.createBroadcast(data);
    await refresh(myBroadcasts: _myBroadcastsOnly);
    return broadcast;
  }

  Future<Broadcast> publishBroadcast(int broadcastId) async {
    final apiService = ref.read(apiServiceProvider);
    final broadcast = await apiService.publishBroadcast(broadcastId);
    await refresh(myBroadcasts: _myBroadcastsOnly);
    return broadcast;
  }
}

final broadcastProvider = FutureProvider.family<Broadcast, int>((ref, broadcastId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBroadcast(broadcastId);
});

// Case Management Providers
final casesProvider = AsyncNotifierProvider<CasesNotifier, List<Case>>(() {
  return CasesNotifier();
});

class CasesNotifier extends AsyncNotifier<List<Case>> {
  bool _myCasesOnly = true; // Default to showing only faculty's cases
  String? _statusFilter;
  String? _priorityFilter;

  @override
  Future<List<Case>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getCases(
      status: _statusFilter,
      priority: _priorityFilter,
      myCases: _myCasesOnly ? true : null,
    );
  }

  Future<void> refresh({bool? myCases, String? status, String? priority}) async {
    if (myCases != null) {
      _myCasesOnly = myCases;
    }
    if (status != null) {
      _statusFilter = status;
    } else if (status == null && _statusFilter != null) {
      _statusFilter = null;
    }
    if (priority != null) {
      _priorityFilter = priority;
    } else if (priority == null && _priorityFilter != null) {
      _priorityFilter = null;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getCases(
        status: _statusFilter,
        priority: _priorityFilter,
        myCases: _myCasesOnly ? true : null,
      );
    });
  }

  Future<Case> createCase(Map<String, dynamic> data) async {
    final apiService = ref.read(apiServiceProvider);
    final case_ = await apiService.createCase(data);
    await refresh(myCases: _myCasesOnly);
    return case_;
  }

  Future<Case> updateCase(int caseId, Map<String, dynamic> data) async {
    final apiService = ref.read(apiServiceProvider);
    final case_ = await apiService.updateCase(caseId, data);
    await refresh(myCases: _myCasesOnly);
    return case_;
  }
}

final caseProvider = FutureProvider.family<Case, int>((ref, caseId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCase(caseId);
});

final caseUpdatesProvider = FutureProvider.family<List<CaseUpdate>, int>((ref, caseId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCaseUpdates(caseId);
});

final caseAnalyticsProvider = FutureProvider<CaseAnalytics>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCaseAnalytics();
});

final casesAtRiskProvider = FutureProvider<List<Case>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCasesAtRisk();
});

// Predictive Operations Providers
final predictiveMetricsProvider = FutureProvider<List<PredictiveMetric>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final metrics = await apiService.getPredictiveMetrics();
    return metrics;
  } catch (e) {
    // Return empty list on error - let the UI show empty state
    return [];
  }
});


final predictiveMetricsByTypeProvider = FutureProvider.family<List<PredictiveMetric>, String>((ref, metricType) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getPredictiveMetrics(metricType: metricType);
});

final operationalAlertsProvider = AsyncNotifierProvider<OperationalAlertsNotifier, List<OperationalAlert>>(() {
  return OperationalAlertsNotifier();
});

class OperationalAlertsNotifier extends AsyncNotifier<List<OperationalAlert>> {
  String? _severityFilter;
  bool? _isAcknowledgedFilter;

  @override
  Future<List<OperationalAlert>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getOperationalAlerts(
      severity: _severityFilter,
      isAcknowledged: _isAcknowledgedFilter,
    );
  }

  Future<void> refresh({String? severity, bool? isAcknowledged}) async {
    if (severity != null) {
      _severityFilter = severity;
    } else if (severity == null && _severityFilter != null) {
      _severityFilter = null;
    }
    if (isAcknowledged != null) {
      _isAcknowledgedFilter = isAcknowledged;
    } else if (isAcknowledged == null && _isAcknowledgedFilter != null) {
      _isAcknowledgedFilter = null;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getOperationalAlerts(
        severity: _severityFilter,
        isAcknowledged: _isAcknowledgedFilter,
      );
    });
  }

  Future<OperationalAlert> acknowledgeAlert(int alertId) async {
    final apiService = ref.read(apiServiceProvider);
    final alert = await apiService.acknowledgeAlert(alertId);
    await refresh();
    return alert;
  }
}

// Academic Planner Providers
// State provider for manual GPA/Credits overrides
final gpaOverridesProvider = StateNotifierProvider<GPAOverridesNotifier, GPAOverrides>((ref) {
  return GPAOverridesNotifier();
});

class GPAOverrides {
  final double? gpa;
  final int? totalCredits;
  final int? completedCredits;

  GPAOverrides({
    this.gpa,
    this.totalCredits,
    this.completedCredits,
  });

  GPAOverrides copyWith({
    double? gpa,
    int? totalCredits,
    int? completedCredits,
  }) {
    return GPAOverrides(
      gpa: gpa ?? this.gpa,
      totalCredits: totalCredits ?? this.totalCredits,
      completedCredits: completedCredits ?? this.completedCredits,
    );
  }
}

class GPAOverridesNotifier extends StateNotifier<GPAOverrides> {
  GPAOverridesNotifier() : super(GPAOverrides()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gpa = prefs.getDouble('manual_gpa');
      final totalCredits = prefs.getInt('manual_total_credits');
      final completedCredits = prefs.getInt('manual_completed_credits');
      
      if (gpa != null || totalCredits != null || completedCredits != null) {
        state = GPAOverrides(
          gpa: gpa,
          totalCredits: totalCredits,
          completedCredits: completedCredits,
        );
      }
    } catch (e) {
      print('Error loading GPA overrides: $e');
    }
  }

  Future<void> updateGPA(double? gpa, int? totalCredits, int? completedCredits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (gpa != null) {
        await prefs.setDouble('manual_gpa', gpa);
      } else {
        await prefs.remove('manual_gpa');
      }
      
      if (totalCredits != null) {
        await prefs.setInt('manual_total_credits', totalCredits);
      } else {
        await prefs.remove('manual_total_credits');
      }
      
      if (completedCredits != null) {
        await prefs.setInt('manual_completed_credits', completedCredits);
      } else {
        await prefs.remove('manual_completed_credits');
      }
      
      state = GPAOverrides(
        gpa: gpa,
        totalCredits: totalCredits,
        completedCredits: completedCredits,
      );
    } catch (e) {
      print('Error saving GPA overrides: $e');
    }
  }

  Future<void> clearOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('manual_gpa');
      await prefs.remove('manual_total_credits');
      await prefs.remove('manual_completed_credits');
      state = GPAOverrides();
    } catch (e) {
      print('Error clearing GPA overrides: $e');
    }
  }
}

final academicDashboardProvider = FutureProvider<AcademicDashboard>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final dashboard = await apiService.getAcademicDashboard();
  
  // Apply manual overrides if they exist
  final overrides = ref.watch(gpaOverridesProvider);
  
  return AcademicDashboard(
    enrolledCourses: dashboard.enrolledCourses,
    activeAssignments: dashboard.activeAssignments,
    overdueAssignments: dashboard.overdueAssignments,
    upcomingDeadlines: dashboard.upcomingDeadlines,
    currentGpa: overrides.gpa ?? dashboard.currentGpa,
    totalCredits: overrides.totalCredits ?? dashboard.totalCredits,
    completedCredits: overrides.completedCredits ?? dashboard.completedCredits,
  );
});