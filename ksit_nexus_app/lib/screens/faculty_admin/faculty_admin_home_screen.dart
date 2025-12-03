import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/faculty_admin_models.dart';
import '../../widgets/error_widget.dart';
import '../../providers/data_providers.dart';
import 'case_management_screen.dart';
import 'broadcast_studio_screen.dart';
import 'predictive_ops_screen.dart';

final caseAnalyticsProvider = FutureProvider<CaseAnalytics>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCaseAnalytics();
});

class FacultyAdminHomeScreen extends ConsumerWidget {
  const FacultyAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(caseAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty & Admin Tools'),
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
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildContent(context, ref, analytics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(caseAnalyticsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, CaseAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(caseAnalyticsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildStatsGrid(context, analytics),
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 16),
            
            // Case Management Overview
            _buildCaseOverview(context, analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, CaseAnalytics analytics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Cases',
          '${analytics.totalCases}',
          Icons.folder,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Active Cases',
          '${analytics.activeCases}',
          Icons.work,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Resolved',
          '${analytics.resolvedCases}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Resolution Rate',
          '${analytics.resolutionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              context,
              'Case Management',
              Icons.folder,
              Colors.blue,
              () => context.push('/faculty-admin/cases'),
            ),
            _buildActionCard(
              context,
              'Broadcast Studio',
              Icons.broadcast_on_personal,
              Colors.green,
              () => context.push('/faculty-admin/broadcasts'),
            ),
            _buildActionCard(
              context,
              'Predictive Ops',
              Icons.analytics,
              Colors.purple,
              () => context.push('/faculty-admin/predictive'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseOverview(BuildContext context, CaseAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Case Management Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/faculty-admin/cases'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  context,
                  'On Time',
                  '${analytics.slaMetrics['on_time'] ?? 0}',
                  Colors.green,
                ),
                _buildMiniStat(
                  context,
                  'At Risk',
                  '${analytics.slaMetrics['at_risk'] ?? 0}',
                  Colors.orange,
                ),
                _buildMiniStat(
                  context,
                  'Breached',
                  '${analytics.slaMetrics['breached'] ?? 0}',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}


