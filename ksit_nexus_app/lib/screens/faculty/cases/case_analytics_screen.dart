import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';
import 'case_detail_screen.dart';
import 'package:intl/intl.dart';

class CaseAnalyticsScreen extends ConsumerWidget {
  const CaseAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(caseAnalyticsProvider);
    final casesAtRiskAsync = ref.watch(casesAtRiskProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Analytics'),
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
              ref.refresh(caseAnalyticsProvider);
              ref.refresh(casesAtRiskProvider);
            },
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
              // Summary Statistics
              analyticsAsync.when(
                data: (analytics) => _buildSummaryStats(context, analytics),
                loading: () => _buildLoadingStats(context),
                error: (error, stack) => _buildErrorState(context, error.toString()),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              
              // SLA Metrics
              analyticsAsync.when(
                data: (analytics) => _buildSLAMetrics(context, analytics),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              
              // Cases by Priority
              analyticsAsync.when(
                data: (analytics) => _buildPriorityStats(context, analytics),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              
              // Cases by Status
              analyticsAsync.when(
                data: (analytics) => _buildStatusStats(context, analytics),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              
              // Cases at Risk
              Text(
                'Cases at Risk',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              
              casesAtRiskAsync.when(
                data: (cases) {
                  if (cases.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                        child: Center(
                          child: Text(
                            'No cases at risk',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.grey600,
                              fontSize: Responsive.fontSize(context, 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: cases.map((case_) => _buildAtRiskCaseCard(context, case_)).toList(),
                  );
                },
                loading: () => _buildLoadingCard(context),
                error: (error, stack) => _buildErrorCard(context, error.toString()),
              ),
              
              SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, CaseAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Cases',
                analytics.totalCases.toString(),
                Icons.folder,
                Colors.blue,
              ),
            ),
            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Expanded(
              child: _buildStatCard(
                context,
                'Active Cases',
                analytics.activeCases.toString(),
                Icons.inbox,
                Colors.orange,
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
                'Resolved Cases',
                analytics.resolvedCases.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Expanded(
              child: _buildStatCard(
                context,
                'Resolution Rate',
                '${analytics.resolutionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSLAMetrics(BuildContext context, CaseAnalytics analytics) {
    final slaMetrics = analytics.slaMetrics;
    final onTime = slaMetrics['on_time'] ?? 0;
    final atRisk = slaMetrics['at_risk'] ?? 0;
    final breached = slaMetrics['breached'] ?? 0;
    final onTimeRate = slaMetrics['on_time_rate'] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SLA Metrics',
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
                        'On Time',
                        onTime.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'At Risk',
                        atRisk.toString(),
                        Icons.warning,
                        Colors.orange,
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
                        'Breached',
                        breached.toString(),
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'On Time Rate',
                        '${onTimeRate.toStringAsFixed(1)}%',
                        Icons.trending_up,
                        Colors.blue,
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
                        'Avg Resolution',
                        '${analytics.avgResolutionHours.toStringAsFixed(1)} hours',
                        Icons.schedule,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityStats(BuildContext context, CaseAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cases by Priority',
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
              children: analytics.byPriority.map((item) {
                final priority = item['priority'] ?? 'unknown';
                final count = item['count'] ?? 0;
                return Padding(
                  padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getPriorityColor(priority),
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 14),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.fontSize(context, 18),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStats(BuildContext context, CaseAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cases by Status',
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
              children: analytics.byStatus.map((item) {
                final status = item['status'] ?? 'unknown';
                final count = item['count'] ?? 0;
                return Padding(
                  padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 14),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.fontSize(context, 18),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtRiskCaseCard(BuildContext context, Case case_) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(caseId: case_.id),
            ),
          );
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
                      color: case_.slaStatus == 'breached' ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      case_.slaStatus == 'breached' ? 'BREACHED' : 'AT RISK',
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
                      color: _getPriorityColor(case_.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      case_.priority.toUpperCase(),
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
                case_.caseId,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 14),
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Text(
                case_.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              if (case_.slaBreachTime != null) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.red),
                    SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                    Text(
                      'SLA Breach: ${_formatDateTime(case_.slaBreachTime!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: Responsive.value(context: context, mobile: 32, tablet: 40, desktop: 48)),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: Responsive.fontSize(context, 24),
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
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 8, tablet: 12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      case 'critical':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.yellow.shade700;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
        Row(
          children: [
            Expanded(child: _buildLoadingCard(context)),
            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Expanded(child: _buildLoadingCard(context)),
          ],
        ),
        SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
        Row(
          children: [
            Expanded(child: _buildLoadingCard(context)),
            SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Expanded(child: _buildLoadingCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Text(
              'Error loading cases at risk',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.error,
                fontSize: Responsive.fontSize(context, 16),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grey600,
                fontSize: Responsive.fontSize(context, 12),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            'Error Loading Analytics',
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

