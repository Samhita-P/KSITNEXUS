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
import 'add_assignment_screen.dart';

final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getAssignments();
});

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
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
              ref.invalidate(assignmentsProvider);
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'not_started', child: Text('Not Started')),
              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'submitted', child: Text('Submitted')),
              const PopupMenuItem(value: 'graded', child: Text('Graded')),
            ],
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          final filtered = _selectedFilter == 'all'
              ? assignments
              : assignments.where((a) => a.status == _selectedFilter).toList();

          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.assignment,
              title: 'No Assignments',
              message: 'No assignments found.',
              action: ElevatedButton.icon(
                onPressed: () => _showAddAssignmentDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(assignmentsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _buildAssignmentCard(context, filtered[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(assignmentsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssignmentDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddAssignmentDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAssignmentScreen(),
      ),
    ).then((_) {
      // Refresh assignments when returning
      ref.invalidate(assignmentsProvider);
    });
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isOverdue = assignment.isOverdue;
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to assignment detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.error
                          : isSubmitted
                              ? AppTheme.success
                              : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${assignment.course.courseCode} • ${assignment.assignmentType.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${dateFormat.format(assignment.dueDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOverdue ? AppTheme.error : Colors.grey[700],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!isOverdue && !isSubmitted) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${assignment.daysUntilDue} days left)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              if (assignment.score != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.grade, size: 16, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${assignment.score}/${assignment.maxScore}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                    if (assignment.percentageScore != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${assignment.percentageScore!.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(assignment.status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_started':
        return Colors.grey;
      case 'in_progress':
        return AppTheme.accentBlue;
      case 'submitted':
        return AppTheme.primaryColor;
      case 'graded':
        return AppTheme.success;
      case 'late':
        return AppTheme.error;
      case 'missed':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }
}


