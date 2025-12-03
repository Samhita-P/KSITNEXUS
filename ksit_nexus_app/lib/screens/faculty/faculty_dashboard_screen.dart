import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'faculty_complaints_review_screen.dart';
import 'faculty_study_groups_screen.dart';
import 'faculty_feedback_screen.dart';
import 'broadcast/broadcasts_screen.dart';
import 'cases/cases_screen.dart';
import 'predictive/predictive_analytics_screen.dart';
import 'predictive/operational_alerts_screen.dart';
import '../notices/notices_screen.dart';
import '../notices/create_notice_screen.dart';
import '../meetings/schedule_meeting_screen.dart';
import '../profile/profile_screen.dart';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    FacultyHomeDashboard(onNavigate: (index) {
      setState(() {
        _currentIndex = index;
      });
    }),
    const FacultyComplaintsReviewScreen(), // Review Student Queries (Index 1)
    const FacultyStudyGroupsScreen(), // Study Group Moderation (Index 2)
    const FacultyFeedbackScreen(), // View Feedback (Index 3)
    const BroadcastsScreen(), // Broadcast Studio (Index 4)
    const CasesScreen(), // Case Management (Index 5)
    const PredictiveAnalyticsScreen(), // Predictive Analytics (Index 6)
    const OperationalAlertsScreen(), // Operational Alerts (Index 7)
    const NoticesScreen(), // View Announcements/Notices (Index 8)
    const ScheduleMeetingScreen(), // Schedule a Meeting (Index 9)
    const ProfileScreen(), // Profile (Index 10)
  ];

  int _getBottomNavIndex() {
    // Map screen indices to bottom nav indices
    if (_currentIndex == 0) return 0; // Home
    if (_currentIndex == 1) return 1; // Queries
    if (_currentIndex == 2) return 2; // Groups
    if (_currentIndex == 3) return 3; // Feedback
    if (_currentIndex == 11) return 4; // Profile
    return 0; // Default to Home for screens not in bottom nav
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getBottomNavIndex(),
        onTap: (index) {
          setState(() {
            // Map bottom nav indices to screen indices
            if (index == 0) {
              _currentIndex = 0; // Home
            } else if (index == 1) {
              _currentIndex = 1; // Queries
            } else if (index == 2) {
              _currentIndex = 2; // Groups
            } else if (index == 3) {
              _currentIndex = 3; // Feedback
            } else if (index == 4) {
              _currentIndex = 11; // Profile
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.grey600,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Queries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            activeIcon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FacultyHomeDashboard extends ConsumerWidget {
  final Function(int) onNavigate;
  
  const FacultyHomeDashboard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh all dashboard data
              ref.refresh(upcomingMeetingsProvider);
              ref.refresh(complaintStatsProvider);
              ref.refresh(broadcastsProvider);
              ref.refresh(casesProvider);
              ref.refresh(operationalAlertsProvider);
              // Refresh faculty feedback summary if user has faculty profile
              final user = ref.read(authStateProvider).user;
              if (user?.facultyProfile != null) {
                ref.refresh(facultyFeedbackSummaryProvider(user!.facultyProfile!.id));
              }
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'logout':
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: double.infinity,
          desktop: 1400,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 20, tablet: 28, desktop: 32)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.displayName ?? 'Faculty'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 22),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10)),
                    Text(
                      'Faculty Dashboard - Manage academic activities',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        fontSize: Responsive.fontSize(context, 16),
                      ),
                    ),
                  if (user?.facultyProfile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${user!.facultyProfile!.department} • ${user.facultyProfile!.designation}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Urgent Alerts Widget
            _buildUrgentAlertsWidget(context, ref),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Faculty Features
            Text(
              'Faculty Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: Responsive.fontSize(context, 20),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.getGridColumns(
                context,
                mobile: 2,
                tablet: 3,
                desktop: 4,
                largeDesktop: 5,
              ),
              crossAxisSpacing: Responsive.spacing(context),
              mainAxisSpacing: Responsive.spacing(context),
              childAspectRatio: Responsive.value(
                context: context,
                mobile: 1.2,
                tablet: 1.1,
                desktop: 1.0,
              ),
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.event_outlined,
                  title: 'Schedule Meeting',
                  subtitle: 'Schedule faculty meetings',
                  color: Colors.blue,
                  onTap: () {
                    // Switch to the schedule meeting tab in the faculty dashboard
                    onNavigate(9); // Index 9 is the schedule meeting screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.report_problem_outlined,
                  title: 'Review Student Queries',
                  subtitle: 'Handle student complaints',
                  color: Colors.red,
                  onTap: () {
                    // Switch to the complaints review tab in the faculty dashboard
                    onNavigate(1); // Index 1 is the complaints review screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'Study Group Moderation',
                  subtitle: 'Moderate study groups',
                  color: Colors.green,
                  onTap: () {
                    // Switch to the study groups tab in the faculty dashboard
                    onNavigate(2); // Index 2 is the study groups screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'View Feedback',
                  subtitle: 'View student feedback',
                  color: Colors.orange,
                  onTap: () {
                    // Switch to the feedback tab in the faculty dashboard
                    onNavigate(3); // Index 3 is the feedback screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.broadcast_on_personal_outlined,
                  title: 'Broadcast Studio',
                  subtitle: 'Create and manage broadcasts',
                  color: Colors.teal,
                  onTap: () {
                    // Switch to the broadcast tab in the faculty dashboard
                    onNavigate(4); // Index 4 is the broadcast screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Case Management',
                  subtitle: 'Manage and track cases',
                  color: Colors.indigo,
                  onTap: () {
                    // Switch to the cases tab in the faculty dashboard
                    onNavigate(5); // Index 5 is the cases screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Predictive Analytics',
                  subtitle: 'View predictive metrics',
                  color: Colors.purple,
                  onTap: () {
                    // Switch to the predictive analytics tab in the faculty dashboard
                    onNavigate(6); // Index 6 is the predictive analytics screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Operational Alerts',
                  subtitle: 'View and manage alerts',
                  color: Colors.red,
                  onTap: () {
                    // Switch to the operational alerts tab in the faculty dashboard
                    onNavigate(7); // Index 7 is the operational alerts screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'View Notices',
                  subtitle: 'View all announcements',
                  color: Colors.blueGrey,
                  onTap: () {
                    // Switch to the notices tab in the faculty dashboard
                    onNavigate(8); // Index 8 is the notices screen
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Create Notice',
                  subtitle: 'Create new announcement',
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to create notice screen
                    context.push('/notices/create');
                  },
                ),
              ],
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Upcoming Faculty Meeting
            Text(
              'Upcoming Faculty Meeting',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final upcomingMeetingsAsync = ref.watch(upcomingMeetingsProvider);
                
                return upcomingMeetingsAsync.when(
                  data: (meetings) {
                    if (meetings.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                color: Colors.grey[400],
                                size: Responsive.value(context: context, mobile: 40, tablet: 48, desktop: 56),
                              ),
                              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                              Text(
                                'No upcoming meetings scheduled',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: Responsive.fontSize(context, 14),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final nextMeeting = meetings.first;
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: AppTheme.primaryColor,
                                  size: Responsive.value(context: context, mobile: 24, tablet: 28, desktop: 32),
                                ),
                                SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nextMeeting.title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: Responsive.fontSize(context, 16),
                                        ),
                                      ),
                                      SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                                      Text(
                                        '${nextMeeting.location ?? 'Location TBD'} • ${_formatMeetingTime(nextMeeting.scheduledDate)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                          fontSize: Responsive.fontSize(context, 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (nextMeeting.description != null && nextMeeting.description!.isNotEmpty) ...[
                              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                              Text(
                                'Agenda: ${nextMeeting.description}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: Responsive.fontSize(context, 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Row(
                        children: [
                          SizedBox(
                            width: Responsive.value(context: context, mobile: 24, tablet: 28, desktop: 32),
                            height: Responsive.value(context: context, mobile: 24, tablet: 28, desktop: 32),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: Text(
                              'Loading upcoming meetings...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: Responsive.fontSize(context, 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: Responsive.value(context: context, mobile: 40, tablet: 48, desktop: 56),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load meetings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Statistics Section
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: Responsive.fontSize(context, 20),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
            
            // Complaint Statistics
            Text(
              'Student Complaint Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final complaintStatsAsync = ref.watch(complaintStatsProvider);
                
                return complaintStatsAsync.when(
                  data: (stats) {
                    final totalComplaints = stats['total_complaints'] ?? 0;
                    final resolvedComplaints = stats['resolved_complaints'] ?? 0;
                    final pendingComplaints = stats['pending_complaints'] ?? 0;
                    final inProgressComplaints = stats['in_progress_complaints'] ?? 0;
                    
                    final resolutionRate = totalComplaints > 0 
                        ? ((resolvedComplaints / totalComplaints) * 100).round()
                        : 0;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.report_problem_outlined,
                                title: 'Total Complaints',
                                value: totalComplaints.toString(),
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.check_circle_outline,
                                title: 'Resolved',
                                value: resolvedComplaints.toString(),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.pending_outlined,
                                title: 'Pending',
                                value: pendingComplaints.toString(),
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.trending_up,
                                title: 'Resolution Rate',
                                value: '$resolutionRate%',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        
                        if (inProgressComplaints > 0) ...[
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  icon: Icons.work_outline,
                                  title: 'In Progress',
                                  value: inProgressComplaints.toString(),
                                  color: Colors.purple,
                                ),
                              ),
                              SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                              const Expanded(child: SizedBox()), // Empty space for alignment
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Complaints'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Resolved'),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Pending'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Resolution Rate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load complaint statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Feedback Statistics
            Text(
              'Feedback Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final facultyId = authState.user?.id;
                
                if (facultyId == null) {
                  return const SizedBox.shrink();
                }
                
                final feedbackSummaryAsync = ref.watch(facultyFeedbackSummaryProvider(facultyId));
                
                return feedbackSummaryAsync.when(
                  data: (summary) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.feedback_outlined,
                                title: 'Total Feedback',
                                value: summary.totalFeedbacks.toString(),
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.star,
                                title: 'Average Rating',
                                value: summary.averageOverallRating.toStringAsFixed(1),
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.school_outlined,
                                title: 'This Semester',
                                value: summary.semesterFeedbacks.toString(),
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.trending_up,
                                title: 'Teaching Rating',
                                value: summary.averageTeachingRating.toStringAsFixed(1),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Feedback'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Average Rating'),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'This Semester'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Teaching Rating'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load feedback statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Broadcast Statistics
            Text(
              'Broadcast Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final broadcastsAsync = ref.watch(broadcastsProvider);
                
                return broadcastsAsync.when(
                  data: (broadcasts) {
                    // Filter to only show faculty's broadcasts
                    final myBroadcasts = broadcasts;
                    final totalBroadcasts = myBroadcasts.length;
                    final publishedBroadcasts = myBroadcasts.where((b) => b.isPublished).length;
                    final draftBroadcasts = myBroadcasts.where((b) => !b.isPublished).length;
                    final totalViews = myBroadcasts.fold<int>(
                      0,
                      (sum, broadcast) => sum + broadcast.viewsCount,
                    );
                    final totalEngagements = myBroadcasts.fold<int>(
                      0,
                      (sum, broadcast) => sum + broadcast.engagementCount,
                    );
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.broadcast_on_personal,
                                title: 'Total Broadcasts',
                                value: totalBroadcasts.toString(),
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.publish,
                                title: 'Published',
                                value: publishedBroadcasts.toString(),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.drafts,
                                title: 'Drafts',
                                value: draftBroadcasts.toString(),
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.visibility,
                                title: 'Total Views',
                                value: totalViews.toString(),
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Broadcasts'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Published'),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Drafts'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Views'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load broadcast statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Case Statistics
            Text(
              'Case Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final casesAsync = ref.watch(casesProvider);
                
                return casesAsync.when(
                  data: (cases) {
                    final myCases = cases;
                    final totalCases = myCases.length;
                    final activeCases = myCases.where((c) => c.status == 'new' || c.status == 'assigned' || c.status == 'in_progress').length;
                    final resolvedCases = myCases.where((c) => c.status == 'resolved').length;
                    final atRiskCases = myCases.where((c) => c.slaStatus == 'at_risk' || c.slaStatus == 'breached').length;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.folder,
                                title: 'Total Cases',
                                value: totalCases.toString(),
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.inbox,
                                title: 'Active Cases',
                                value: activeCases.toString(),
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.check_circle,
                                title: 'Resolved',
                                value: resolvedCases.toString(),
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.warning,
                                title: 'At Risk',
                                value: atRiskCases.toString(),
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Cases'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Active Cases'),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Resolved'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'At Risk'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load case statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Operational Alerts Statistics
            Text(
              'Operational Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Consumer(
              builder: (context, ref, child) {
                final alertsAsync = ref.watch(operationalAlertsProvider);
                
                return alertsAsync.when(
                  data: (alerts) {
                    final totalAlerts = alerts.length;
                    final unacknowledgedAlerts = alerts.where((a) => !a.isAcknowledged).length;
                    final criticalAlerts = alerts.where((a) => a.severity == 'critical').length;
                    final warningAlerts = alerts.where((a) => a.severity == 'warning').length;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.notifications,
                                title: 'Total Alerts',
                                value: totalAlerts.toString(),
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.notifications_active,
                                title: 'Unacknowledged',
                                value: unacknowledgedAlerts.toString(),
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.error,
                                title: 'Critical',
                                value: criticalAlerts.toString(),
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.warning,
                                title: 'Warning',
                                value: warningAlerts.toString(),
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Total Alerts'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Unacknowledged'),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Critical'),
                          ),
                          SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: _buildLoadingStatCard(context, 'Warning'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          Text(
                            'Failed to load alert statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[600],
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                          Text(
                            'Please try again later',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: Responsive.value(context: context, mobile: 44, tablet: 48, desktop: 52),
                height: Responsive.value(context: context, mobile: 44, tablet: 48, desktop: 52),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.value(context: context, mobile: 22, tablet: 24, desktop: 26),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 10, tablet: 12)),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: Responsive.fontSize(context, 11),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: Responsive.value(context: context, mobile: 28, tablet: 32, desktop: 36),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: Responsive.fontSize(context, 12),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: Responsive.value(context: context, mobile: 28, tablet: 32, desktop: 36),
            height: Responsive.value(context: context, mobile: 28, tablet: 32, desktop: 36),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            '...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: Responsive.fontSize(context, 12),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatMeetingTime(DateTime scheduledDate) {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(scheduledDate)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${_formatTime(scheduledDate)}';
    } else if (difference.inDays < 7) {
      return '${_formatWeekday(scheduledDate.weekday)} ${_formatTime(scheduledDate)}';
    } else {
      return '${scheduledDate.day}/${scheduledDate.month} ${_formatTime(scheduledDate)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  Widget _buildUrgentAlertsWidget(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(operationalAlertsProvider);
    
    return alertsAsync.when(
      data: (alerts) {
        // Show only critical and unacknowledged warning alerts
        final urgentAlerts = alerts.where((a) => 
          !a.isAcknowledged && (a.severity == 'critical' || a.severity == 'warning')
        ).take(3).toList();
        
        if (urgentAlerts.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: Responsive.value(context: context, mobile: 24, tablet: 28),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  Expanded(
                    child: Text(
                      'Urgent Alerts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                        fontSize: Responsive.fontSize(context, 18),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigate(7), // Navigate to alerts screen
                    child: const Text('View All'),
                  ),
                ],
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              ...urgentAlerts.map((alert) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 8, tablet: 12)),
                child: InkWell(
                  onTap: () {
                    if (alert.relatedCase != null) {
                      onNavigate(5); // Navigate to cases screen
                    } else {
                      onNavigate(7); // Navigate to alerts screen
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSeverityColor(alert.severity).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(alert.severity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.fontSize(context, 14),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6)),
                              Text(
                                alert.message,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.grey600,
                                  fontSize: Responsive.fontSize(context, 12),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}


