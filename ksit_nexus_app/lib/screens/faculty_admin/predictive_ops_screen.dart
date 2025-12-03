import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/faculty_admin_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final predictiveMetricsProvider = FutureProvider<List<PredictiveMetric>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getPredictiveMetrics();
});

final operationalAlertsProvider = FutureProvider<List<OperationalAlert>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getOperationalAlerts();
});

class PredictiveOpsScreen extends ConsumerWidget {
  const PredictiveOpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(predictiveMetricsProvider);
    final alertsAsync = ref.watch(operationalAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictive Operations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(predictiveMetricsProvider);
              ref.refresh(operationalAlertsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(predictiveMetricsProvider);
          ref.invalidate(operationalAlertsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alerts Section
              Text(
                'Operational Alerts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No active alerts'),
                      ),
                    );
                  }
                  return Column(
                    children: alerts.map((alert) => _buildAlertCard(context, ref, alert)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorDisplayWidget(
                  message: error.toString(),
                  onRetry: () {
                    ref.invalidate(operationalAlertsProvider);
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Metrics Section
              Text(
                'Predictive Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              metricsAsync.when(
                data: (metrics) {
                  if (metrics.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.analytics,
                      title: 'No Metrics',
                      message: 'No predictive metrics available.',
                    );
                  }
                  return Column(
                    children: metrics.map((metric) => _buildMetricCard(context, metric)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorDisplayWidget(
                  message: error.toString(),
                  onRetry: () {
                    ref.invalidate(predictiveMetricsProvider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, OperationalAlert alert) {
    Color severityColor;
    IconData severityIcon;
    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: severityColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                if (!alert.isAcknowledged)
                  TextButton(
                    onPressed: () async {
                      final apiService = ref.read(apiServiceProvider);
                      try {
                        await apiService.acknowledgeAlert(alert.id);
                        ref.invalidate(operationalAlertsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alert acknowledged')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Acknowledge'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(alert.alertType.replaceAll('_', ' ').toUpperCase()),
                  backgroundColor: severityColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(alert.severity.toUpperCase()),
                  backgroundColor: severityColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, PredictiveMetric metric) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.metricType.replaceAll('_', ' ').toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Current',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      metric.value.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (metric.predictedValue != null)
                  Column(
                    children: [
                      Text(
                        'Predicted',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        metric.predictedValue!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (metric.confidence != null)
                  Column(
                    children: [
                      Text(
                        'Confidence',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${(metric.confidence! * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Period: ${_formatDate(metric.periodStart)} - ${_formatDate(metric.periodEnd)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


