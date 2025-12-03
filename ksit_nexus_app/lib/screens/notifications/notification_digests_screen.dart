/// Notification digests screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_widget.dart' as error_widget;
import '../../widgets/empty_state.dart';

final appLogger = Logger('NotificationDigestsScreen');

class NotificationDigestsScreen extends ConsumerStatefulWidget {
  const NotificationDigestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationDigestsScreen> createState() => _NotificationDigestsScreenState();
}

class _NotificationDigestsScreenState extends ConsumerState<NotificationDigestsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _digests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDigests();
  }

  Future<void> _loadDigests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final digests = await _apiService.getDigests();
      setState(() {
        _digests = digests;
      });
    } catch (e) {
      appLogger.error('Error loading digests: $e');
      setState(() {
        _error = 'Failed to load digests';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateDailyDigest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.generateDailyDigest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily digest generated successfully')),
        );
        await _loadDigests();
      }
    } catch (e) {
      appLogger.error('Error generating daily digest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateWeeklyDigest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.generateWeeklyDigest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly digest generated successfully')),
        );
        await _loadDigests();
      }
    } catch (e) {
      appLogger.error('Error generating weekly digest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markDigestAsRead(int id) async {
    try {
      await _apiService.markDigestAsRead(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digest marked as read')),
        );
        await _loadDigests();
      }
    } catch (e) {
      appLogger.error('Error marking digest as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Digests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/notifications');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDigests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? error_widget.ErrorDisplayWidget(
                message: _error!,
                onRetry: _loadDigests,
              )
            : _digests.isEmpty
                ? EmptyStateWidget(
                    message: 'No digests available',
                    icon: Icons.inbox,
                    action: ElevatedButton.icon(
                      onPressed: _generateDailyDigest,
                      icon: const Icon(Icons.add),
                      label: const Text('Generate Daily Digest'),
                    ),
                  )
                : Column(
                    children: [
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateDailyDigest,
                                icon: const Icon(Icons.today),
                                label: const Text('Generate Daily'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateWeeklyDigest,
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Generate Weekly'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Digests list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _digests.length,
                          itemBuilder: (context, index) {
                            final digest = _digests[index];
                            final isRead = digest['is_read'] ?? false;
                            final frequency = digest['frequency'] ?? 'daily';
                            final notificationCount = digest['notification_count'] ?? 0;
                            final unreadCount = digest['unread_count'] ?? 0;
                            final periodStart = digest['period_start'];
                            final periodEnd = digest['period_end'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRead
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                  child: Icon(
                                    frequency == 'daily'
                                        ? Icons.today
                                        : Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  digest['title'] ?? 'Digest',
                                  style: TextStyle(
                                    fontWeight:
                                        isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${notificationCount} notification(s)',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (periodStart != null && periodEnd != null)
                                      Text(
                                        '${_formatDate(periodStart)} - ${_formatDate(periodEnd)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    if (digest['summary'] != null)
                                      Text(
                                        digest['summary'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (unreadCount > 0)
                                      Chip(
                                        label: Text('$unreadCount'),
                                        backgroundColor: Theme.of(context).primaryColor,
                                        labelStyle: const TextStyle(color: Colors.white),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                      ),
                                      onPressed: () => _markDigestAsRead(digest['id']),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to digest detail
                                  // TODO: Implement digest detail screen
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

