import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import 'add_course_screen.dart';

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCourses();
});

final enrollmentsProvider = FutureProvider<List<CourseEnrollment>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCourseEnrollments();
});

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
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
              ref.invalidate(enrollmentsProvider);
              ref.invalidate(coursesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: enrollmentsAsync.when(
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.school,
              title: 'No Courses',
              message: 'You are not enrolled in any courses yet.',
              action: ElevatedButton.icon(
                onPressed: () => _showAddCourseDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Browse & Enroll in Courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(enrollmentsProvider);
              ref.invalidate(coursesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(context, enrollments[index].course, enrollments[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(enrollmentsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCourseDialog(context, ref),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, CourseEnrollment enrollment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to course detail
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
                      color: _parseColor(course.color),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseCode,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          course.courseName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(enrollment.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      enrollment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(enrollment.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    course.instructorName ?? 'TBA',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.credits} Credits',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Sem ${course.semester}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (enrollment.finalGrade != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.grade, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Grade: ${enrollment.finalGrade}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (enrollment.gradePoints != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${enrollment.gradePoints!.toStringAsFixed(2)} GP)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'enrolled':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.success;
      case 'dropped':
        return AppTheme.error;
      case 'failed':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  void _showAddCourseDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCourseScreen(),
      ),
    ).then((_) {
      // Refresh enrollments and courses when returning
      ref.invalidate(enrollmentsProvider);
      ref.invalidate(coursesProvider);
    });
  }
}

class _AddCourseDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends ConsumerState<_AddCourseDialog> {
  List<Course> _availableCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
  }

  Future<void> _loadAvailableCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final courses = await apiService.getCourses();
      setState(() {
        _availableCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollInCourse(Course course) async {
    if (course.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid course ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.enrollInCourse(course.id!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully enrolled in ${course.courseCode}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh enrollments
        ref.invalidate(enrollmentsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Courses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAvailableCourses,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _availableCourses.isEmpty
                          ? const Center(
                              child: Text('No available courses found.'),
                            )
                          : ListView.builder(
                              itemCount: _availableCourses.length,
                              itemBuilder: (context, index) {
                                final course = _availableCourses[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _parseColor(course.color),
                                      child: Text(
                                        course.courseCode.substring(0, 2).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      course.courseCode,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(course.courseName),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.credit_card, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${course.credits} Credits',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sem ${course.semester}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _enrollInCourse(course),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Enroll'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}


