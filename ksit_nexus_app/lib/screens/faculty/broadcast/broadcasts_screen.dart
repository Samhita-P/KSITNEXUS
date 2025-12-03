import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';
import 'create_broadcast_screen.dart';
import 'broadcast_detail_screen.dart';

class BroadcastsScreen extends ConsumerStatefulWidget {
  const BroadcastsScreen({super.key});

  @override
  ConsumerState<BroadcastsScreen> createState() => _BroadcastsScreenState();
}

class _BroadcastsScreenState extends ConsumerState<BroadcastsScreen> {
  String _filterType = 'all'; // all, announcement, event, alert, news, maintenance
  bool _myBroadcastsOnly = true;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/faculty-dashboard');
            }
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Studio'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBroadcastScreen(),
                ),
              ).then((_) {
                // Refresh after creating a broadcast
                ref.refresh(broadcastsProvider);
              });
            },
          ),
          IconButton(
            icon: Icon(_myBroadcastsOnly ? Icons.person : Icons.people),
            onPressed: () {
              setState(() {
                _myBroadcastsOnly = !_myBroadcastsOnly;
              });
              ref.read(broadcastsProvider.notifier).refresh(myBroadcasts: _myBroadcastsOnly);
            },
            tooltip: _myBroadcastsOnly ? 'Show All Broadcasts' : 'Show My Broadcasts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(broadcastsProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Responsive.value(context: context, mobile: 48, tablet: 52, desktop: 56)),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('announcement', 'Announcements'),
                  _buildFilterChip('event', 'Events'),
                  _buildFilterChip('alert', 'Alerts'),
                  _buildFilterChip('news', 'News'),
                  _buildFilterChip('maintenance', 'Maintenance'),
                ],
              ),
            ),
          ),
        ),
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
        child: Consumer(
          builder: (context, ref, child) {
            final broadcastsAsync = ref.watch(broadcastsProvider);
            
            return broadcastsAsync.when(
              data: (broadcasts) {
                final filteredBroadcasts = _filterBroadcasts(broadcasts);
                
                if (filteredBroadcasts.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(broadcastsProvider);
                  },
                  child: ListView.builder(
                    padding: Responsive.padding(context),
                    itemCount: filteredBroadcasts.length,
                    itemBuilder: (context, index) {
                      return _buildBroadcastCard(context, filteredBroadcasts[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error.toString()),
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
        ref.read(broadcastsProvider.notifier).refresh(type: value == 'all' ? null : value);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 4, tablet: 8),
          vertical: Responsive.spacing(context, mobile: 8, tablet: 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.fontSize(context, 12),
          ),
        ),
      ),
    );
  }

  List<Broadcast> _filterBroadcasts(List<Broadcast> broadcasts) {
    if (_filterType == 'all') {
      return broadcasts;
    }
    return broadcasts.where((b) => b.broadcastType == _filterType).toList();
  }

  Widget _buildBroadcastCard(BuildContext context, Broadcast broadcast) {
    final now = DateTime.now();
    final isScheduled = broadcast.scheduledAt != null && broadcast.scheduledAt!.isAfter(now);
    final isExpired = broadcast.expiresAt != null && broadcast.expiresAt!.isBefore(now);
    final isDraft = !broadcast.isPublished;
    
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BroadcastDetailScreen(broadcastId: broadcast.id),
            ),
          ).then((_) {
            ref.refresh(broadcastsProvider);
          });
        },
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: _getBroadcastTypeColor(broadcast.broadcastType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      broadcast.broadcastType.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(broadcast.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      broadcast.priority.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isDraft)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'DRAFT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isScheduled)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SCHEDULED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isExpired)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'EXPIRED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PUBLISHED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Text(
                broadcast.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
              Text(
                broadcast.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (broadcast.attachments.isNotEmpty) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Row(
                  children: [
                    Icon(Icons.attachment, size: 16, color: AppTheme.grey600),
                    SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                    Text(
                      '${broadcast.attachments.length} attachment(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                        fontSize: Responsive.fontSize(context, 12),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              Row(
                children: [
                  if (broadcast.targetUsersCount != null) ...[
                    _buildStatChip(
                      context,
                      '${broadcast.targetUsersCount}',
                      'Recipients',
                      Icons.people_outline,
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  ],
                  _buildStatChip(
                    context,
                    '${broadcast.viewsCount}',
                    'Views',
                    Icons.visibility_outlined,
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  _buildStatChip(
                    context,
                    '${broadcast.engagementCount}',
                    'Engaged',
                    Icons.touch_app_outlined,
                  ),
                  if (broadcast.engagementRate != null) ...[
                    SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                    _buildStatChip(
                      context,
                      '${broadcast.engagementRate!.toStringAsFixed(0)}%',
                      'Rate',
                      Icons.trending_up,
                    ),
                  ],
                ],
              ),
              if (broadcast.publishedAt != null) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                    SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                    Text(
                      'Published: ${_formatDateTime(broadcast.publishedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                        fontSize: Responsive.fontSize(context, 12),
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

  Widget _buildStatChip(BuildContext context, String value, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.grey600),
        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6)),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grey600,
            fontSize: Responsive.fontSize(context, 12),
          ),
        ),
      ],
    );
  }

  Color _getBroadcastTypeColor(String broadcastType) {
    switch (broadcastType) {
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

  Color _getPriorityColor(String priority) {
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

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
            color: AppTheme.grey400,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'No Broadcasts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            _myBroadcastsOnly 
                ? 'You haven\'t created any broadcasts yet'
                : 'No broadcasts available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
              fontSize: Responsive.fontSize(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBroadcastScreen(),
                ),
              ).then((_) {
                ref.refresh(broadcastsProvider);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Broadcast'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, mobile: 20, tablet: 24),
                vertical: Responsive.spacing(context, mobile: 12, tablet: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
            color: AppTheme.error,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Broadcasts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Padding(
            padding: Responsive.horizontalPadding(context),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey600,
                fontSize: Responsive.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          ElevatedButton(
            onPressed: () {
              ref.refresh(broadcastsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


