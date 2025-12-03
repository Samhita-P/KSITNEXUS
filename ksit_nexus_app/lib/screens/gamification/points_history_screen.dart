import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/gamification_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final pointTransactionsProvider = FutureProvider<List<PointTransaction>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getPointTransactions();
});

final userPointsProvider = FutureProvider<UserPoints>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getUserPoints();
});

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(pointTransactionsProvider);
    final pointsAsync = ref.watch(userPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Points History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/gamification');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pointTransactionsProvider);
              ref.invalidate(userPointsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Points Summary
          pointsAsync.when(
            data: (points) => Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  Text(
                    'Total Points',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${points.totalPoints}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPointsStat(context, 'Available', '${points.currentPoints}', Colors.white),
                      _buildPointsStat(context, 'Lifetime', '${points.lifetimePoints}', Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 120),
            error: (_, __) => const SizedBox(),
          ),
          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.history,
                    title: 'No Transactions',
                    message: 'You haven\'t earned or spent any points yet.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pointTransactionsProvider);
                    ref.invalidate(userPointsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(context, transactions[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ErrorDisplayWidget(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(pointTransactionsProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, PointTransaction transaction) {
    final isPositive = transaction.amount > 0;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isPositive ? AppTheme.success : AppTheme.error).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPositive ? Icons.add_circle : Icons.remove_circle,
            color: isPositive ? AppTheme.success : AppTheme.error,
          ),
        ),
        title: Text(
          transaction.description ?? _getSourceLabel(transaction.source),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          dateFormat.format(transaction.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${transaction.amount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPositive ? AppTheme.success : AppTheme.error,
              ),
            ),
            Text(
              'Balance: ${transaction.balanceAfter}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'achievement':
        return 'Achievement Unlocked';
      case 'daily_login':
        return 'Daily Login Bonus';
      case 'study_group_activity':
        return 'Study Group Activity';
      case 'complaint_submission':
        return 'Complaint Submitted';
      case 'feedback_submission':
        return 'Feedback Submitted';
      case 'event_creation':
        return 'Event Created';
      case 'event_attendance':
        return 'Event Attended';
      case 'social_interaction':
        return 'Social Interaction';
      case 'content_contribution':
        return 'Content Contribution';
      case 'milestone':
        return 'Milestone Reached';
      case 'reward_redemption':
        return 'Reward Redemption';
      default:
        return source.replaceAll('_', ' ').toUpperCase();
    }
  }
}


