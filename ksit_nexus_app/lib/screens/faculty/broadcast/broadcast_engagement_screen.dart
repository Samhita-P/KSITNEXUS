import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';

class BroadcastEngagementScreen extends ConsumerWidget {
  final int broadcastId;
  
  const BroadcastEngagementScreen({
    super.key,
    required this.broadcastId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastAsync = ref.watch(broadcastProvider(broadcastId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engagement Details'),
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
              ref.refresh(broadcastProvider(broadcastId));
            },
          ),
        ],
      ),
      body: broadcastAsync.when(
        data: (broadcast) => _buildEngagementDetails(context, broadcast),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildEngagementDetails(BuildContext context, Broadcast broadcast) {
    return ResponsiveContainer(
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
            // Summary Card
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
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
                    broadcast.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 20),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryStat(
                          context,
                          'Total Recipients',
                          broadcast.targetUsersCount?.toString() ?? '0',
                          Icons.people,
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Expanded(
                        child: _buildSummaryStat(
                          context,
                          'Views',
                          broadcast.viewsCount.toString(),
                          Icons.visibility,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryStat(
                          context,
                          'Engaged',
                          broadcast.engagementCount.toString(),
                          Icons.touch_app,
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Expanded(
                        child: _buildSummaryStat(
                          context,
                          'Engagement Rate',
                          broadcast.engagementRate != null
                              ? '${broadcast.engagementRate!.toStringAsFixed(1)}%'
                              : '0%',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Engagement Metrics
            Text(
              'Engagement Metrics',
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
                    _buildMetricRow(
                      context,
                      'View Rate',
                      broadcast.targetUsersCount != null && broadcast.targetUsersCount! > 0
                          ? '${((broadcast.viewsCount / broadcast.targetUsersCount!) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      Icons.visibility,
                      Colors.blue,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildMetricRow(
                      context,
                      'Engagement Rate',
                      broadcast.engagementRate != null
                          ? '${broadcast.engagementRate!.toStringAsFixed(1)}%'
                          : '0%',
                      Icons.touch_app,
                      Colors.green,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildMetricRow(
                      context,
                      'Total Views',
                      broadcast.viewsCount.toString(),
                      Icons.visibility_outlined,
                      Colors.purple,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildMetricRow(
                      context,
                      'Total Engagements',
                      broadcast.engagementCount.toString(),
                      Icons.touch_app_outlined,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                        Text(
                          'Engagement Tracking',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    Text(
                      'Engagement is tracked when users view the broadcast. The engagement rate is calculated based on the number of users who have viewed the broadcast out of the total number of recipients.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grey600,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                    ),
                    if (broadcast.publishedAt != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Divider(),
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.grey600, size: 16),
                          SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                          Text(
                            'Published: ${DateFormat('MMM dd, yyyy HH:mm').format(broadcast.publishedAt!)}',
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
            
            SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: Responsive.value(context: context, mobile: 28, tablet: 32, desktop: 36)),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 18),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontSize: Responsive.fontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 8, tablet: 12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: Responsive.fontSize(context, 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Engagement',
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
              // Refresh will be handled by the provider
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


