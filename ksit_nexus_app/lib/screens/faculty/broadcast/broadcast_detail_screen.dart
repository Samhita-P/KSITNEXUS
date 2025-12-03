import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';
import 'broadcast_engagement_screen.dart';

class BroadcastDetailScreen extends ConsumerStatefulWidget {
  final int broadcastId;
  
  const BroadcastDetailScreen({
    super.key,
    required this.broadcastId,
  });

  @override
  ConsumerState<BroadcastDetailScreen> createState() => _BroadcastDetailScreenState();
}

class _BroadcastDetailScreenState extends ConsumerState<BroadcastDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final broadcastAsync = ref.watch(broadcastProvider(widget.broadcastId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Details'),
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(broadcastProvider(widget.broadcastId));
              ref.refresh(broadcastsProvider);
            },
          ),
        ],
      ),
      body: broadcastAsync.when(
        data: (broadcast) => _buildBroadcastDetail(context, broadcast),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildBroadcastDetail(BuildContext context, Broadcast broadcast) {
    final now = DateTime.now();
    final isScheduled = broadcast.scheduledAt != null && broadcast.scheduledAt!.isAfter(now);
    final isExpired = broadcast.expiresAt != null && broadcast.expiresAt!.isBefore(now);
    final isDraft = !broadcast.isPublished;
    
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1200,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Broadcast Header Card
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getBroadcastTypeColor(broadcast.broadcastType),
                    _getBroadcastTypeColor(broadcast.broadcastType).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getBroadcastTypeColor(broadcast.broadcastType).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          broadcast.broadcastType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          broadcast.priority.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isDraft)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DRAFT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        )
                      else if (isScheduled)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SCHEDULED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        )
                      else if (isExpired)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PUBLISHED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  Text(
                    broadcast.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 22),
                    ),
                  ),
                  if (broadcast.createdByName != null) ...[
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.white70, size: 16),
                        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                        Text(
                          'Created by: ${broadcast.createdByName}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: Responsive.fontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (broadcast.publishedAt != null) ...[
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white70, size: 16),
                        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                        Text(
                          'Published: ${DateFormat('MMM dd, yyyy HH:mm').format(broadcast.publishedAt!)}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: Responsive.fontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Content Section
            Text(
              'Content',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Text(
                  broadcast.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: Responsive.fontSize(context, 16),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            
            if (broadcast.attachments.isNotEmpty) ...[
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              Text(
                'Attachments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${broadcast.attachments.length} attachment(s)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.fontSize(context, 16),
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      ...broadcast.attachments.map((attachment) => Padding(
                        padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 8, tablet: 12)),
                        child: Row(
                          children: [
                            Icon(Icons.attachment, color: AppTheme.primaryColor),
                            SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                            Expanded(
                              child: Text(
                                attachment,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: Responsive.fontSize(context, 14),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Engagement Statistics
            Text(
              'Engagement Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Views',
                            broadcast.viewsCount.toString(),
                            Icons.visibility,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Engaged',
                            broadcast.engagementCount.toString(),
                            Icons.touch_app,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Recipients',
                            broadcast.targetUsersCount?.toString() ?? '0',
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                        SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Engagement Rate',
                            broadcast.engagementRate != null
                                ? '${broadcast.engagementRate!.toStringAsFixed(1)}%'
                                : '0%',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Targeting Information
            Text(
              'Targeting Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Target Audience',
                      _getTargetAudienceLabel(broadcast.targetAudience),
                      Icons.people,
                    ),
                    if (broadcast.targetDepartments.isNotEmpty) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Target Departments',
                        broadcast.targetDepartments.join(', '),
                        Icons.business,
                      ),
                    ],
                    if (broadcast.targetCourses.isNotEmpty) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Target Courses',
                        broadcast.targetCourses.join(', '),
                        Icons.book,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            if (broadcast.scheduledAt != null || broadcast.expiresAt != null) ...[
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              Text(
                'Scheduling',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (broadcast.scheduledAt != null)
                        _buildInfoRow(
                          context,
                          'Scheduled At',
                          DateFormat('MMM dd, yyyy HH:mm').format(broadcast.scheduledAt!),
                          Icons.schedule,
                        ),
                      if (broadcast.expiresAt != null) ...[
                        if (broadcast.scheduledAt != null)
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                        _buildInfoRow(
                          context,
                          'Expires At',
                          DateFormat('MMM dd, yyyy HH:mm').format(broadcast.expiresAt!),
                          Icons.event_busy,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Actions
            if (isDraft) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(broadcastsProvider.notifier).publishBroadcast(broadcast.id);
                      if (mounted) {
                        SuccessSnackbar.show(context, 'Broadcast published successfully!');
                        ref.refresh(broadcastProvider(widget.broadcastId));
                        ref.refresh(broadcastsProvider);
                      }
                    } catch (e) {
                      if (mounted) {
                        ErrorSnackbar.show(context, 'Failed to publish broadcast: ${e.toString()}');
                      }
                    }
                  },
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Broadcast'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.spacing(context, mobile: 16, tablet: 20),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BroadcastEngagementScreen(broadcastId: widget.broadcastId),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Engagement Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.spacing(context, mobile: 16, tablet: 20),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: Responsive.value(context: context, mobile: 28, tablet: 32, desktop: 36)),
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
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grey600,
              fontSize: Responsive.fontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 12),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6)),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ],
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

  String _getTargetAudienceLabel(String audience) {
    switch (audience) {
      case 'all':
        return 'All Users';
      case 'students':
        return 'Students Only';
      case 'faculty':
        return 'Faculty Only';
      case 'staff':
        return 'Staff Only';
      case 'specific':
        return 'Specific Users/Groups';
      default:
        return audience;
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Broadcast',
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
              ref.refresh(broadcastProvider(widget.broadcastId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


