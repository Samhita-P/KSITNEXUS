import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final remindersProvider = FutureProvider<List<AcademicReminder>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getAcademicReminders();
});

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Reminders'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/academic');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(remindersProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          final active = reminders.where((r) => !r.isCompleted).toList();
          final completed = reminders.where((r) => r.isCompleted).toList();

          if (reminders.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications,
              title: 'No Reminders',
              message: 'You don\'t have any academic reminders yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(remindersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  Text(
                    'Active Reminders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...active.map((reminder) => _buildReminderCard(context, ref, reminder)),
                  const SizedBox(height: 24),
                ],
                if (completed.isNotEmpty) ...[
                  Text(
                    'Completed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completed.map((reminder) => _buildReminderCard(context, ref, reminder)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(remindersProvider);
          },
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, AcademicReminder reminder) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final isOverdue = reminder.isOverdue && !reminder.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? AppTheme.error
              : reminder.isCompleted
                  ? AppTheme.success
                  : _getPriorityColor(reminder.priority),
          child: Icon(
            reminder.isCompleted ? Icons.check : Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description != null) ...[
              Text(reminder.description!),
              const SizedBox(height: 4),
            ],
            Text(
              dateFormat.format(reminder.reminderDate),
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? AppTheme.error : Colors.grey[600],
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (reminder.course != null)
              Text(
                reminder.course!.courseCode,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: reminder.isCompleted
            ? const Icon(Icons.check_circle, color: AppTheme.success)
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  try {
                    await ref.read(apiServiceProvider).completeReminder(reminder.id!);
                    ref.invalidate(remindersProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppTheme.error;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppTheme.warning;
      case 'low':
        return AppTheme.accentBlue;
      default:
        return AppTheme.primaryColor;
    }
  }
}


