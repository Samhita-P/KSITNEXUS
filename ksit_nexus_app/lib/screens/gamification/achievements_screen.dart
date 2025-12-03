import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/gamification_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final userAchievementsProvider = FutureProvider<List<UserAchievement>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getAvailableAchievements();
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
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
              ref.invalidate(userAchievementsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.emoji_events,
              title: 'No Achievements',
              message: 'No achievements available yet.',
            );
          }

          final unlocked = achievements.where((a) => a.isUnlocked).toList();
          final locked = achievements.where((a) => !a.isUnlocked).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userAchievementsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unlocked.isNotEmpty) ...[
                  Text(
                    'Unlocked (${unlocked.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...unlocked.map((achievement) => _buildAchievementCard(context, achievement)),
                  const SizedBox(height: 24),
                ],
                if (locked.isNotEmpty) ...[
                  Text(
                    'Locked (${locked.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...locked.map((achievement) => _buildAchievementCard(context, achievement)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(userAchievementsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, UserAchievement userAchievement) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.isUnlocked;

    Color difficultyColor;
    switch (achievement.difficulty) {
      case 'bronze':
        difficultyColor = Colors.brown;
        break;
      case 'silver':
        difficultyColor = Colors.grey;
        break;
      case 'gold':
        difficultyColor = Colors.amber;
        break;
      case 'platinum':
        difficultyColor = Colors.blue;
        break;
      default:
        difficultyColor = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isUnlocked ? difficultyColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon != null ? _getIcon(achievement.icon!) : Icons.emoji_events,
                color: isUnlocked ? Colors.white : Colors.grey[600],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey[600],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.difficulty.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUnlocked ? null : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (!isUnlocked) ...[
                    LinearProgressIndicator(
                      value: userAchievement.progressPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(difficultyColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userAchievement.progressPercentage.toStringAsFixed(0)}% Complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${achievement.pointsReward} pts',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'first_login':
        return Icons.login;
      case 'profile_complete':
        return Icons.person;
      case 'study_group_created':
        return Icons.group_add;
      case 'study_group_joined':
        return Icons.group;
      case 'complaint_submitted':
        return Icons.report;
      case 'feedback_submitted':
        return Icons.feedback;
      case 'event_created':
        return Icons.event;
      case 'event_attended':
        return Icons.event_available;
      case 'streak_daily':
        return Icons.local_fire_department;
      case 'points_milestone':
        return Icons.stars;
      default:
        return Icons.emoji_events;
    }
  }
}


