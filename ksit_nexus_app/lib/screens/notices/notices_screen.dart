import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../models/notice_model.dart';
import '../../models/faculty_admin_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../services/api_service.dart';
import '../faculty/broadcast/broadcast_detail_screen.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs by default, will be updated in build
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isStudent = authState.user?.isStudent ?? false;
    
    // Update TabController if needed
    // Students: All Notices, Broadcasts
    // Faculty/Admin: All Notices, Create Notice
    final tabCount = isStudent ? 2 : 2;
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }
    
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle back navigation manually to prevent connection errors
          // Navigate to a safe route instead of browser back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final router = GoRouter.of(context);
              final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
              
              if (currentLocation == '/notices' || currentLocation.startsWith('/notices/')) {
                // If on notices page, navigate to faculty dashboard
                context.go('/faculty-dashboard');
              } else {
                // Otherwise, navigate to notices list
                context.go('/notices');
              }
            }
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate based on user role
            final authState = ref.read(authStateProvider);
            if (authState.user?.isStudent ?? false) {
              context.go('/home');
            } else {
              context.go('/faculty-dashboard');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: isStudent 
            ? const [
                Tab(text: 'Notices'),
                Tab(text: 'Broadcasts'),
              ]
            : const [
                Tab(text: 'All Notices'),
                Tab(text: 'Create Notice'),
              ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(noticesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: isStudent 
          ? [
              _buildNoticesListTab(),
              _buildBroadcastsTab(),
            ]
          : [
              _buildNoticesListTab(),
              _buildCreateNoticeTab(),
            ],
      ),
      ),
    );
  }

  Widget _buildNoticesListTab() {
    final noticesAsync = ref.watch(noticesProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: noticesAsync.when(
        data: (notices) {
          // Check if we have valid data
          if (notices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notices found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notice.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.campaign,
                        color: _getPriorityColor(notice.priority),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          notice.content.length > 100
                              ? '${notice.content.substring(0, 100)}...'
                              : notice.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(notice.priority.toUpperCase()),
                              backgroundColor: _getPriorityColor(notice.priority).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _getPriorityColor(notice.priority),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(notice.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.go('/notices/${notice.id}');
                    },
                  ),
                );
              },
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Check if it's a connection error
          final errorString = error.toString().toLowerCase();
          final isConnectionError = errorString.contains('connection refused') ||
              errorString.contains('failed host lookup') ||
              errorString.contains('connection error') ||
              errorString.contains('network is unreachable');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConnectionError ? Icons.cloud_off : Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isConnectionError 
                        ? 'Backend Server Not Available'
                        : 'Failed to load notices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConnectionError
                        ? 'Unable to connect to the server. Please check your internet connection and try again.\n\nIf you\'re testing locally, make sure the backend server is running.'
                        : error.toString(),
                    style: const TextStyle(color: AppTheme.grey600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(noticesProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBroadcastsTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: Consumer(
        builder: (context, ref, child) {
          // For students, fetch all published broadcasts (not just my broadcasts)
          return FutureBuilder<List<Broadcast>>(
            future: ref.read(apiServiceProvider).getBroadcasts(myBroadcasts: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load broadcasts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: AppTheme.grey600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final broadcasts = snapshot.data ?? [];
              
              if (broadcasts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Broadcasts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.grey600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No broadcasts available at the moment',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: Responsive.padding(context),
                  itemCount: broadcasts.length,
                  itemBuilder: (context, index) {
                    final broadcast = broadcasts[index];
                    return _buildBroadcastCard(context, broadcast);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBroadcastCard(BuildContext context, Broadcast broadcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to broadcast detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BroadcastDetailScreen(broadcastId: broadcast.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBroadcastTypeColor(broadcast.broadcastType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      broadcast.broadcastType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBroadcastPriorityColor(broadcast.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      broadcast.priority.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (broadcast.publishedAt != null)
                    Text(
                      _formatDate(broadcast.publishedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                broadcast.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                broadcast.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (broadcast.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attachment, size: 16, color: AppTheme.grey600),
                    const SizedBox(width: 4),
                    Text(
                      '${broadcast.attachments.length} attachment(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBroadcastTypeColor(String type) {
    switch (type) {
      case 'announcement':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      case 'alert':
        return Colors.red;
      case 'news':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBroadcastPriorityColor(String priority) {
    switch (priority) {
      case 'normal':
        return Colors.grey;
      case 'important':
        return Colors.blue;
      case 'urgent':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCreateNoticeTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Create Notice',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create and publish notices for the campus community',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/create-notice'),
              icon: const Icon(Icons.add),
              label: const Text('Create New Notice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.go('/draft-notices');
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('View Drafts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.notifications;
      case 'low':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}