import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/gamification_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, Map<String, String>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getLeaderboard(
    leaderboardType: params['type']!,
    period: params['period'] ?? 'all_time',
  );
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedType = 'points';
  String _selectedPeriod = 'all_time';

  final Map<String, String> _leaderboardTypes = {
    'points': 'Points',
    'achievements': 'Achievements',
    'streak': 'Streak',
    'overall': 'Overall',
  };

  final Map<String, String> _periods = {
    'all_time': 'All Time',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
  };

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider({
      'type': _selectedType,
      'period': _selectedPeriod,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
              ref.invalidate(leaderboardProvider({
                'type': _selectedType,
                'period': _selectedPeriod,
              }));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Leaderboard Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _leaderboardTypes.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _periods.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Leaderboard List
          Expanded(
            child: leaderboardAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.leaderboard,
                    title: 'No Rankings',
                    message: 'No leaderboard entries found.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(leaderboardProvider({
                      'type': _selectedType,
                      'period': _selectedPeriod,
                    }));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildLeaderboardEntry(context, entries[index], index);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ErrorDisplayWidget(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(leaderboardProvider({
                    'type': _selectedType,
                    'period': _selectedPeriod,
                  }));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(BuildContext context, LeaderboardEntry entry, int index) {
    final isTopThree = entry.rank <= 3;
    final rankIcon = _getRankIcon(entry.rank);
    final rankColor = _getRankColor(entry.rank);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 4 : 1,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
        title: Text(
          '${entry.user['first_name'] ?? ''} ${entry.user['last_name'] ?? ''}'.trim().isEmpty
              ? entry.user['username'] ?? 'User'
              : '${entry.user['first_name'] ?? ''} ${entry.user['last_name'] ?? ''}'.trim(),
          style: TextStyle(
            fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          entry.user['username'] ?? 'User',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: rankColor,
              ),
            ),
            if (entry.points != null || entry.achievements != null || entry.streak != null)
              Text(
                _getScoreDetails(entry),
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

  IconData? _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return null;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getScoreDetails(LeaderboardEntry entry) {
    final parts = <String>[];
    if (entry.points != null) parts.add('${entry.points} pts');
    if (entry.achievements != null) parts.add('${entry.achievements} ach');
    if (entry.streak != null) parts.add('${entry.streak} 🔥');
    return parts.join(' • ');
  }
}


