import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../complaints/complaints_screen.dart';
import '../feedback/feedback_screen.dart';
import '../study_groups/study_groups_screen.dart';
import '../notices/notices_screen.dart';
import '../reservations/reservations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _switchToNotifications() {
    setState(() {
      _currentIndex = 5; // Notifications tab index
    });
  }

  List<Widget> _buildScreens() {
    return [
      HomeDashboard(onNotificationsPressed: _switchToNotifications),
      const ComplaintsScreen(),
      const StudyGroupsScreen(),
      const NoticesScreen(),
      const ReservationsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreens()[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
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
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Notices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            activeIcon: Icon(Icons.meeting_room),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
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

class HomeDashboard extends ConsumerWidget {
  final VoidCallback? onNotificationsPressed;
  
  const HomeDashboard({
    super.key,
    this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('KSIT Nexus'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationsPressed ?? () {
              // Fallback: navigate to notifications route if callback not provided
              context.go('/notifications');
            },
            tooltip: 'Notifications',
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
                      'Welcome to KSIT Nexus!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 22),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10)),
                    Text(
                      'Your digital campus companion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        fontSize: Responsive.fontSize(context, 16),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              
              // Quick Actions
              Text(
                'Quick Actions',
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
                _buildQuickActionCard(
                  context,
                  icon: Icons.report_problem_outlined,
                  title: 'Complaints',
                  subtitle: 'Report issues anonymously',
                  color: Colors.red,
                  onTap: () {
                    context.go('/complaints');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.star_outline,
                  title: 'Feedback',
                  subtitle: 'Rate your professors',
                  color: Colors.orange,
                  onTap: () {
                    context.go('/feedback');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'Study Groups',
                  subtitle: 'Connect with peers',
                  color: Colors.green,
                  onTap: () {
                    context.go('/study-groups');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.chair_outlined,
                  title: 'Reservations',
                  subtitle: 'Reserve study space',
                  color: Colors.blue,
                  onTap: () {
                    context.go('/reservations');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'Notices',
                  subtitle: 'View announcements',
                  color: Colors.purple,
                  onTap: () {
                    context.go('/notices');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.chat_outlined,
                  title: 'Chatbot',
                  subtitle: 'Get instant help',
                  color: Colors.teal,
                  onTap: () {
                    context.go('/chatbot');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.store_outlined,
                  title: 'Marketplace',
                  subtitle: 'Buy, sell, trade',
                  color: Colors.indigo,
                  onTap: () {
                    context.go('/marketplace');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: 'Rewards',
                  subtitle: 'Earn points & rewards',
                  color: Colors.amber,
                  onTap: () {
                    context.go('/gamification');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Calendar',
                  subtitle: 'View events & schedule',
                  color: Colors.pink,
                  onTap: () {
                    context.go('/calendar');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Academic',
                  subtitle: 'Courses & assignments',
                  color: Colors.blue,
                  onTap: () {
                    context.go('/academic');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.shield_outlined,
                  title: 'Safety',
                  subtitle: 'Emergency & wellbeing',
                  color: Colors.red,
                  onTap: () {
                    context.go('/safety');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.recommend_outlined,
                  title: 'Recommendations',
                  subtitle: 'Personalized suggestions',
                  color: Colors.cyan,
                  onTap: () {
                    context.go('/recommendations');
                  },
                ),
              ],
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Recent Notices
            Text(
              'Recent Notices',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: Responsive.fontSize(context, 20),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
            
            Consumer(
              builder: (context, ref, child) {
                final noticesAsync = ref.watch(noticesProvider);
                
                return noticesAsync.when(
                  data: (notices) {
                    if (notices.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No notices available',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Show only the first 2 notices
                    final recentNotices = notices.take(2).toList();
                    
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: recentNotices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final notice = entry.value;
                            
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    _getNoticeIcon(notice.category),
                                    color: _getNoticeColor(notice.category),
                                  ),
                                  title: Text(
                                    notice.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    notice.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    // Navigate to notice details
                                    context.go('/notices');
                                  },
                                ),
                                if (index < recentNotices.length - 1)
                                  const Divider(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text(
                            'Loading notices...',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load notices',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.refresh(noticesProvider),
                            child: const Text('Retry'),
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

  Widget _buildQuickActionCard(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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

  IconData _getNoticeIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Icons.school_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'general':
        return Icons.info_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _getNoticeColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Colors.blue;
      case 'event':
        return Colors.green;
      case 'exam':
        return Colors.orange;
      case 'announcement':
        return Colors.purple;
      case 'general':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }
}