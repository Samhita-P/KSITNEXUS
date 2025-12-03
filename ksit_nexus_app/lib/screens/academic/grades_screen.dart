import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final gradesProvider = FutureProvider<List<Grade>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getGrades();
});

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
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
              ref.invalidate(gradesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: gradesAsync.when(
        data: (grades) {
          if (grades.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.grade,
              title: 'No Grades',
              message: 'No grades available yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gradesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                return _buildGradeCard(context, grades[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(gradesProvider);
          },
        ),
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, Grade grade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getGradeColor(grade.grade).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  grade.grade ?? 'N/A',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(grade.grade),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.course.courseCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    grade.course.courseName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (grade.semester != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Semester ${grade.semester} • ${grade.academicYear ?? ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (grade.percentage != null)
                  Text(
                    '${grade.percentage!.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(grade.grade),
                    ),
                  ),
                if (grade.gradePoints != null)
                  Text(
                    '${grade.gradePoints!.toStringAsFixed(2)} GP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    switch (grade.toUpperCase()) {
      case 'S':
        return Colors.amber;
      case 'A':
        return AppTheme.success;
      case 'B':
        return AppTheme.primaryColor;
      case 'C':
        return AppTheme.accentBlue;
      case 'D':
        return AppTheme.warning;
      case 'E':
        return Colors.orange;
      case 'F':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }
}


