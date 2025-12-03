import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/gamification_models.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'rewards_screen.dart';
import 'points_history_screen.dart';

final gamificationStatsProvider = FutureProvider<UserGamificationStats>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getUserGamificationStats();
});

class GamificationHomeScreen extends ConsumerWidget {
  const GamificationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gamificationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(gamificationStatsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(gamificationStatsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserGamificationStats stats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gamificationStatsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview Card
            _buildStatsCard(context, stats),
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 16),
            
            // Achievements Preview
            _buildAchievementsPreview(context, stats),
            const SizedBox(height: 16),
            
            // Leaderboard Preview
            _buildLeaderboardPreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, UserGamificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${stats.totalPoints}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${stats.currentPoints}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.local_fire_department,
                    '${stats.currentStreak}',
                    'Day Streak',
                    AppTheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.emoji_events,
                    '${stats.achievementsUnlocked}',
                    'Achievements',
                    AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.achievementsProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.achievementsProgress.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.emoji_events,
                'Achievements',
                AppTheme.warning,
                () => context.push('/gamification/achievements'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.leaderboard,
                'Leaderboard',
                AppTheme.primaryColor,
                () => context.push('/gamification/leaderboard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.card_giftcard,
                'Rewards',
                AppTheme.success,
                () => context.push('/gamification/rewards'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.history,
                'Points History',
                AppTheme.accentBlue,
                () => context.push('/gamification/points-history'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context, UserGamificationStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/gamification/achievements'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAchievementBadge(context, '${stats.achievementsUnlocked}', 'Unlocked'),
              _buildAchievementBadge(context, '${stats.achievementsTotal - stats.achievementsUnlocked}', 'Remaining'),
              _buildAchievementBadge(context, '${stats.achievementsTotal}', 'Total'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Rankings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/gamification/leaderboard'),
              child: const Text('View Leaderboard'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLeaderboardType(context, 'Points', Icons.stars),
                _buildLeaderboardType(context, 'Achievements', Icons.emoji_events),
                _buildLeaderboardType(context, 'Streak', Icons.local_fire_department),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardType(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () => context.push('/gamification/leaderboard'),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


