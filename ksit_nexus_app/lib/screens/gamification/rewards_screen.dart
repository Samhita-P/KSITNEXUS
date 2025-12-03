import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/gamification_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final rewardsProvider = FutureProvider<List<Reward>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRewards();
});

final userPointsProvider = FutureProvider<UserPoints>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getUserPoints();
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final pointsAsync = ref.watch(userPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
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
              ref.invalidate(rewardsProvider);
              ref.invalidate(userPointsProvider);
            },
            tooltip: 'Refresh',
          ),
          pointsAsync.when(
            data: (points) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${points.currentPoints}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: rewardsAsync.when(
        data: (rewards) {
          if (rewards.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.card_giftcard,
              title: 'No Rewards',
              message: 'No rewards available at the moment.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rewardsProvider);
              ref.invalidate(userPointsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                return _buildRewardCard(context, ref, rewards[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(rewardsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, WidgetRef ref, Reward reward) {
    final pointsAsync = ref.watch(userPointsProvider);
    final canAfford = pointsAsync.maybeWhen(
      data: (points) => points.currentPoints >= reward.pointsCost,
      orElse: () => false,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reward.icon != null ? _getRewardIcon(reward.icon!) : Icons.card_giftcard,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRewardTypeColor(reward.rewardType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reward.rewardType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRewardTypeColor(reward.rewardType),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.pointsCost}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: canAfford ? AppTheme.primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (reward.stockQuantity != null)
                      Text(
                        '${reward.stockQuantity} left',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reward.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? () => _redeemReward(context, ref, reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text(canAfford ? 'Redeem Now' : 'Insufficient Points'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRewardTypeColor(String type) {
    switch (type) {
      case 'badge':
        return AppTheme.warning;
      case 'discount':
        return AppTheme.success;
      case 'privilege':
        return AppTheme.primaryColor;
      case 'recognition':
        return AppTheme.accentBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardIcon(String iconName) {
    switch (iconName) {
      case 'badge':
        return Icons.workspace_premium;
      case 'discount':
        return Icons.local_offer;
      case 'privilege':
        return Icons.star;
      default:
        return Icons.card_giftcard;
    }
  }

  Future<void> _redeemReward(BuildContext context, WidgetRef ref, Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text('Are you sure you want to redeem "${reward.name}" for ${reward.pointsCost} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.redeemReward(reward.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward "${reward.name}" redeemed successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      ref.invalidate(rewardsProvider);
      ref.invalidate(userPointsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error redeeming reward: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}


