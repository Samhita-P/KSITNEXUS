import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';

class PredictiveAnalyticsScreen extends ConsumerStatefulWidget {
  const PredictiveAnalyticsScreen({super.key});

  @override
  ConsumerState<PredictiveAnalyticsScreen> createState() => _PredictiveAnalyticsScreenState();
}

class _PredictiveAnalyticsScreenState extends ConsumerState<PredictiveAnalyticsScreen> {
  String _metricTypeFilter = 'all'; // all, complaint_volume, response_time, resolution_rate, sla_breach, engagement, resource_utilization

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(predictiveMetricsProvider);
    
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
        title: const Text('Predictive Analytics'),
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
              ref.refresh(predictiveMetricsProvider);
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
                  _buildFilterChip('complaint_volume', 'Volume'),
                  _buildFilterChip('response_time', 'Response'),
                  _buildFilterChip('resolution_rate', 'Resolution'),
                  _buildFilterChip('sla_breach', 'SLA'),
                  _buildFilterChip('engagement', 'Engagement'),
                  _buildFilterChip('resource_utilization', 'Resources'),
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
        child: metricsAsync.when(
          data: (metrics) {
            final filteredMetrics = _filterMetrics(metrics);
            
            if (filteredMetrics.isEmpty) {
              return _buildEmptyState(context);
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(predictiveMetricsProvider);
              },
              child: SingleChildScrollView(
                padding: Responsive.padding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Statistics
                    Text(
                      'Summary Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 18),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    
                    _buildSummaryStats(context, filteredMetrics),
                    
                    SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
                    
                    // Metrics List
                    Text(
                      'Predictive Metrics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 18),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    
                    ...filteredMetrics.map((metric) => _buildMetricCard(context, metric)),
                    
                    SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context, error.toString()),
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _metricTypeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _metricTypeFilter = value;
        });
        // Refresh will happen automatically when _metricTypeFilter changes
        ref.refresh(predictiveMetricsProvider);
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

  List<PredictiveMetric> _filterMetrics(List<PredictiveMetric> metrics) {
    if (_metricTypeFilter == 'all') {
      return metrics;
    }
    return metrics.where((m) => m.metricType == _metricTypeFilter).toList();
  }

  Widget _buildSummaryStats(BuildContext context, List<PredictiveMetric> metrics) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final latestMetrics = metrics.take(4).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.getGridColumns(context, mobile: 2, tablet: 2, desktop: 4),
        crossAxisSpacing: Responsive.spacing(context, mobile: 12, tablet: 16),
        mainAxisSpacing: Responsive.spacing(context, mobile: 12, tablet: 16),
        childAspectRatio: Responsive.value(context: context, mobile: 1.2, tablet: 1.1, desktop: 1.0),
      ),
      itemCount: latestMetrics.length,
      itemBuilder: (context, index) {
        final metric = latestMetrics[index];
        return _buildStatCard(context, metric);
      },
    );
  }

  Widget _buildStatCard(BuildContext context, PredictiveMetric metric) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 6, tablet: 8)),
                  decoration: BoxDecoration(
                    color: _getMetricTypeColor(metric.metricType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMetricTypeIcon(metric.metricType),
                    color: _getMetricTypeColor(metric.metricType),
                    size: Responsive.value(context: context, mobile: 20, tablet: 24, desktop: 28),
                  ),
                ),
                const Spacer(),
                if (metric.confidence != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 6, tablet: 8),
                      vertical: Responsive.spacing(context, mobile: 2, tablet: 4),
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(metric.confidence!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(metric.confidence! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getConfidenceColor(metric.confidence!),
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
            Text(
              _getMetricTypeLabel(metric.metricType),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 14),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
            Text(
              _formatValue(metric.value, metric.metricType),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getMetricTypeColor(metric.metricType),
                fontSize: Responsive.fontSize(context, 20),
              ),
            ),
            if (metric.predictedValue != null) ...[
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppTheme.grey600,
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6)),
                  Text(
                    'Predicted: ${_formatValue(metric.predictedValue!, metric.metricType)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
            Text(
              'Period: ${DateFormat('MMM dd').format(metric.periodStart)} - ${DateFormat('MMM dd, yyyy').format(metric.periodEnd)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grey500,
                fontSize: Responsive.fontSize(context, 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, PredictiveMetric metric) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
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
                    color: _getMetricTypeColor(metric.metricType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMetricTypeLabel(metric.metricType),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getMetricTypeColor(metric.metricType),
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                  ),
                ),
                const Spacer(),
                if (metric.confidence != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                      vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(metric.confidence!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: _getConfidenceColor(metric.confidence!),
                        ),
                        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6)),
                        Text(
                          '${(metric.confidence! * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(metric.confidence!),
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Value',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grey600,
                          fontSize: Responsive.fontSize(context, 12),
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                      Text(
                        _formatValue(metric.value, metric.metricType),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getMetricTypeColor(metric.metricType),
                          fontSize: Responsive.fontSize(context, 24),
                        ),
                      ),
                    ],
                  ),
                ),
                if (metric.predictedValue != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicted Value',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey600,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                        Text(
                          _formatValue(metric.predictedValue!, metric.metricType),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: Responsive.fontSize(context, 24),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
            Divider(),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.grey600),
                SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                Text(
                  'Period: ${DateFormat('MMM dd, yyyy').format(metric.periodStart)} - ${DateFormat('MMM dd, yyyy').format(metric.periodEnd)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey600,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMetricTypeLabel(String metricType) {
    switch (metricType) {
      case 'complaint_volume':
        return 'Complaint Volume';
      case 'response_time':
        return 'Response Time';
      case 'resolution_rate':
        return 'Resolution Rate';
      case 'sla_breach':
        return 'SLA Breach';
      case 'engagement':
        return 'Engagement';
      case 'resource_utilization':
        return 'Resource Utilization';
      default:
        return metricType;
    }
  }

  IconData _getMetricTypeIcon(String metricType) {
    switch (metricType) {
      case 'complaint_volume':
        return Icons.report_problem;
      case 'response_time':
        return Icons.schedule;
      case 'resolution_rate':
        return Icons.check_circle;
      case 'sla_breach':
        return Icons.warning;
      case 'engagement':
        return Icons.touch_app;
      case 'resource_utilization':
        return Icons.memory;
      default:
        return Icons.analytics;
    }
  }

  Color _getMetricTypeColor(String metricType) {
    switch (metricType) {
      case 'complaint_volume':
        return Colors.red;
      case 'response_time':
        return Colors.blue;
      case 'resolution_rate':
        return Colors.green;
      case 'sla_breach':
        return Colors.orange;
      case 'engagement':
        return Colors.teal;
      case 'resource_utilization':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatValue(double value, String metricType) {
    switch (metricType) {
      case 'complaint_volume':
        return value.toStringAsFixed(0);
      case 'response_time':
        return '${value.toStringAsFixed(1)} hrs';
      case 'resolution_rate':
        return '${value.toStringAsFixed(1)}%';
      case 'sla_breach':
        return value.toStringAsFixed(0);
      case 'engagement':
        return '${value.toStringAsFixed(1)}%';
      case 'resource_utilization':
        return '${value.toStringAsFixed(1)}%';
      default:
        return value.toStringAsFixed(2);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
            color: AppTheme.grey400,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'No Predictive Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            'Predictive metrics will appear here once data is available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
              fontSize: Responsive.fontSize(context, 14),
            ),
            textAlign: TextAlign.center,
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
              ref.refresh(predictiveMetricsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

