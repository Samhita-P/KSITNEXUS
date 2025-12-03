import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/notification_model.dart' as notification_model;
import 'notification_preferences_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(userNotificationsProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
          IconButton(
            onPressed: _openPreferences,
            icon: const Icon(Icons.settings),
            tooltip: 'Notification preferences',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: Responsive.isMobile(context), // Scrollable on mobile
          tabAlignment: Responsive.isMobile(context) ? TabAlignment.start : TabAlignment.center,
          labelStyle: TextStyle(
            fontSize: Responsive.value(
              context: context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: Responsive.value(
              context: context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
          ),
          tabs: [
            Tab(
              text: 'All',
              icon: Icon(
                Icons.notifications,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
            Tab(
              text: Responsive.isMobile(context) ? 'Groups' : 'Study Groups',
              icon: Icon(
                Icons.group,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
            Tab(
              text: 'Complaints',
              icon: Icon(
                Icons.report,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
            Tab(
              text: Responsive.isMobile(context) ? 'Reserve' : 'Reservations',
              icon: Icon(
                Icons.bookmark,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
            Tab(
              text: 'Notices',
              icon: Icon(
                Icons.campaign,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
            Tab(
              text: 'System',
              icon: Icon(
                Icons.info,
                size: Responsive.value(
                  context: context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList('all'),
          _buildNotificationsList('study_group'),
          _buildNotificationsList('complaint'),
          _buildNotificationsList('reservation'),
          _buildNotificationsList('notice'),
          _buildNotificationsList('general'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String category) {
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
          final notificationsAsync = ref.watch(userNotificationsProvider);
          
          return notificationsAsync.when(
          data: (notifications) {
            final filteredNotifications = _filterNotifications(notifications, category);
            
            if (filteredNotifications.isEmpty) {
              return _buildEmptyState(category);
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(userNotificationsProvider);
              },
              child: ListView.builder(
                padding: Responsive.padding(context),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = filteredNotifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
        },
      ),
    );
  }

  List<notification_model.Notification> _filterNotifications(List<notification_model.Notification> notifications, String category) {
    if (category == 'all') return notifications;
    
    return notifications.where((n) => n.notificationType == category).toList();
  }

  Widget _buildNotificationCard(notification_model.Notification notification) {
    final isMobile = Responsive.isMobile(context);
    
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.value(
          context: context,
          mobile: 6,
          tablet: 8,
          desktop: 8,
        ),
      ),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: notification.isRead 
                ? null 
                : Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: Responsive.padding(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and time
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.value(
                            context: context,
                            mobile: 6,
                            tablet: 8,
                            desktop: 8,
                          ),
                          vertical: Responsive.value(
                            context: context,
                            mobile: 3,
                            tablet: 4,
                            desktop: 4,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(notification.notificationType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTypeLabel(notification.notificationType),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.value(
                              context: context,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: Responsive.value(
                            context: context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      SizedBox(width: Responsive.value(
                        context: context,
                        mobile: 6,
                        tablet: 8,
                        desktop: 8,
                      )),
                      Container(
                        width: Responsive.value(
                          context: context,
                          mobile: 6,
                          tablet: 7,
                          desktop: 8,
                        ),
                        height: Responsive.value(
                          context: context,
                          mobile: 6,
                          tablet: 7,
                          desktop: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Responsive.value(
                  context: context,
                  mobile: 10,
                  tablet: 12,
                  desktop: 12,
                )),
                
                // Title
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: Responsive.value(
                      context: context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                    color: notification.isRead ? AppTheme.grey700 : AppTheme.grey900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.value(
                  context: context,
                  mobile: 6,
                  tablet: 8,
                  desktop: 8,
                )),
                
                // Message
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: Responsive.value(
                      context: context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: AppTheme.grey600,
                    height: 1.4,
                  ),
                  maxLines: isMobile ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Priority indicator
                if (notification.priority == 'high' || notification.priority == 'urgent') ...[
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 6,
                    tablet: 8,
                    desktop: 8,
                  )),
                  Row(
                    children: [
                      Icon(
                        notification.priority == 'urgent' ? Icons.priority_high : Icons.warning,
                        size: Responsive.value(
                          context: context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        color: notification.priority == 'urgent' ? AppTheme.error : AppTheme.warning,
                      ),
                      SizedBox(width: Responsive.value(
                        context: context,
                        mobile: 3,
                        tablet: 4,
                        desktop: 4,
                      )),
                      Flexible(
                        child: Text(
                          notification.priority.toUpperCase(),
                          style: TextStyle(
                            color: notification.priority == 'urgent' ? AppTheme.error : AppTheme.warning,
                            fontSize: Responsive.value(
                              context: context,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Action buttons
                if (notification.data?.isNotEmpty == true) ...[
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 12,
                  )),
                  Row(
                    children: [
                      if (notification.data?.containsKey('action_url') == true)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => _handleNotificationAction(notification),
                            icon: Icon(
                              Icons.open_in_new,
                              size: Responsive.value(
                                context: context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16,
                              ),
                            ),
                            label: Text(
                              isMobile ? 'View' : 'View Details',
                              style: TextStyle(
                                fontSize: Responsive.value(
                                  context: context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.value(
                                  context: context,
                                  mobile: 8,
                                  tablet: 12,
                                  desktop: 16,
                                ),
                                vertical: Responsive.value(
                                  context: context,
                                  mobile: 4,
                                  tablet: 6,
                                  desktop: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _deleteNotification(notification),
                        icon: Icon(
                          Icons.delete_outline,
                          size: Responsive.value(
                            context: context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 20,
                          ),
                        ),
                        color: AppTheme.grey500,
                        tooltip: 'Delete notification',
                        padding: EdgeInsets.all(Responsive.value(
                          context: context,
                          mobile: 4,
                          tablet: 8,
                          desktop: 8,
                        )),
                        constraints: BoxConstraints(
                          minWidth: Responsive.value(
                            context: context,
                            mobile: 32,
                            tablet: 40,
                            desktop: 48,
                          ),
                          minHeight: Responsive.value(
                            context: context,
                            mobile: 32,
                            tablet: 40,
                            desktop: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    String title;
    String subtitle;
    IconData icon;
    
    switch (category) {
      case 'study_group':
        title = 'No Study Group Notifications';
        subtitle = 'Updates about your study groups will appear here';
        icon = Icons.group_outlined;
        break;
      case 'complaint':
        title = 'No Complaint Updates';
        subtitle = 'Updates about your complaints will appear here';
        icon = Icons.report_outlined;
        break;
      case 'reservation':
        title = 'No Reservation Notifications';
        subtitle = 'Updates about your bookings will appear here';
        icon = Icons.bookmark_outline;
        break;
      case 'notice':
        title = 'No Notice Notifications';
        subtitle = 'New notices and announcements will appear here';
        icon = Icons.campaign_outlined;
        break;
      case 'general':
        title = 'No System Notifications';
        subtitle = 'System updates and general notifications will appear here';
        icon = Icons.info_outline;
        break;
      default:
        title = 'No Notifications';
        subtitle = 'Your notifications will appear here';
        icon = Icons.notifications_outlined;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(userNotificationsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'study_group':
        return AppTheme.primaryColor;
      case 'complaint':
        return AppTheme.warning;
      case 'reservation':
        return AppTheme.success;
      case 'notice':
        return AppTheme.info;
      case 'general':
        return AppTheme.grey600;
      default:
        return AppTheme.grey500;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'study_group':
        return 'Study Group';
      case 'complaint':
        return 'Complaint';
      case 'reservation':
        return 'Reservation';
      case 'notice':
        return 'Notice';
      case 'general':
        return 'System';
      default:
        return 'General';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _markAsRead(notification_model.Notification notification) async {
    if (!notification.isRead) {
      try {
        await ref.read(userNotificationsProvider.notifier).markAsRead(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as read')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error marking as read: $e')),
          );
        }
      }
    }
  }

  void _markAllAsRead() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text('Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(userNotificationsProvider.notifier).markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error marking all as read: $e')),
                  );
                }
              }
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(notification_model.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(userNotificationsProvider.notifier).deleteNotification(notification.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting notification: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(notification_model.Notification notification) {
    // TODO: Implement notification action handling
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening notification details...')),
    );
  }

  void _openPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }
}