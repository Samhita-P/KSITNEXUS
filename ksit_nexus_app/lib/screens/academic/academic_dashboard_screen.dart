import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import 'courses_screen.dart';
import 'assignments_screen.dart';
import 'grades_screen.dart';
import 'reminders_screen.dart';
import 'add_course_screen.dart';
import 'add_assignment_screen.dart';

class AcademicDashboardScreen extends ConsumerWidget {
  const AcademicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(academicDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Planner'),
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
              ref.invalidate(academicDashboardProvider);
              ref.invalidate(coursesProvider);
              ref.invalidate(assignmentsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) => _buildContent(context, ref, dashboard),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(academicDashboardProvider);
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showAddOptionsDialog(context, ref),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showAddOptionsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.book, color: AppTheme.primaryColor),
              title: const Text('Add Course'),
              subtitle: const Text('Create a new course'),
              onTap: () {
                Navigator.pop(context);
                _showAddCourseDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppTheme.accentBlue),
              title: const Text('Add Assignment'),
              subtitle: const Text('Create a new assignment'),
              onTap: () {
                Navigator.pop(context);
                _showAddAssignmentDialog(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showUpdateGPADialog(BuildContext context, WidgetRef ref, AcademicDashboard dashboard) {
    final gpaController = TextEditingController(
      text: dashboard.currentGpa?.toStringAsFixed(2) ?? '',
    );
    final totalCreditsController = TextEditingController(
      text: dashboard.totalCredits.toString(),
    );
    final completedCreditsController = TextEditingController(
      text: dashboard.completedCredits.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update GPA & Credits'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gpaController,
                decoration: const InputDecoration(
                  labelText: 'Current GPA',
                  hintText: 'e.g., 8.5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: totalCreditsController,
                decoration: const InputDecoration(
                  labelText: 'Total Credits',
                  hintText: 'e.g., 120',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completedCreditsController,
                decoration: const InputDecoration(
                  labelText: 'Completed Credits',
                  hintText: 'e.g., 90',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gpaText = gpaController.text.trim();
              final totalCreditsText = totalCreditsController.text.trim();
              final completedCreditsText = completedCreditsController.text.trim();
              
              double? gpa;
              int? totalCredits;
              int? completedCredits;
              
              if (gpaText.isNotEmpty) {
                gpa = double.tryParse(gpaText);
                if (gpa == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid GPA'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
              }
              
              if (totalCreditsText.isNotEmpty) {
                totalCredits = int.tryParse(totalCreditsText);
                if (totalCredits == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid total credits'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
              }
              
              if (completedCreditsText.isNotEmpty) {
                completedCredits = int.tryParse(completedCreditsText);
                if (completedCredits == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid completed credits'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
              }
              
              // Update the overrides
              await ref.read(gpaOverridesProvider.notifier).updateGPA(
                gpa,
                totalCredits,
                completedCredits,
              );
              
              Navigator.pop(context);
              
              // The dashboard will automatically update because it watches gpaOverridesProvider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('GPA and credits updated successfully!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCourseScreen(),
      ),
    ).then((_) {
      // Refresh dashboard and courses when returning
      ref.invalidate(academicDashboardProvider);
      ref.invalidate(coursesProvider);
      ref.invalidate(enrollmentsProvider);
      // Also invalidate the courses list provider used in add assignment screen
      // This will be done when the screen is accessed
    });
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAssignmentScreen(),
      ),
    ).then((_) {
      // Refresh dashboard and assignments when returning
      ref.invalidate(academicDashboardProvider);
      ref.invalidate(assignmentsProvider);
      ref.invalidate(coursesProvider);
      ref.invalidate(enrollmentsProvider);
    });
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AcademicDashboard dashboard) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(academicDashboardProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPA Card
            _buildGPACard(context, ref, dashboard),
            const SizedBox(height: 16),
            
            // Quick Stats
            _buildQuickStats(context, dashboard),
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 16),
            
            // Upcoming Deadlines Preview
            _buildDeadlinesPreview(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildGPACard(BuildContext context, WidgetRef ref, AcademicDashboard dashboard) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current GPA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () => _showUpdateGPADialog(context, ref, dashboard),
                  tooltip: 'Update GPA & Credits',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dashboard.currentGpa != null
                  ? dashboard.currentGpa!.toStringAsFixed(2)
                  : 'N/A',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, '${dashboard.totalCredits}', 'Total Credits', Colors.white),
                _buildStatItem(context, '${dashboard.completedCredits}', 'Completed', Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AcademicDashboard dashboard) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            Icons.school,
            '${dashboard.enrolledCourses}',
            'Courses',
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            Icons.assignment,
            '${dashboard.activeAssignments}',
            'Active',
            AppTheme.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.book,
                'Courses',
                AppTheme.primaryColor,
                () => context.push('/academic/courses'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.assignment,
                'Assignments',
                AppTheme.accentBlue,
                () => context.push('/academic/assignments'),
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
                Icons.grade,
                'Grades',
                AppTheme.success,
                () => context.push('/academic/grades'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.notifications,
                'Reminders',
                AppTheme.warning,
                () => context.push('/academic/reminders'),
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

  Widget _buildDeadlinesPreview(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Deadlines',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/academic/assignments'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: ref.read(apiServiceProvider).getUpcomingDeadlines(days: 7),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            final data = snapshot.data ?? {};
            final assignments = (data['assignments'] as List?)
                ?.map((json) => Assignment.fromJson(json as Map<String, dynamic>))
                .toList() ?? [];
            
            if (assignments.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No upcoming deadlines'),
                ),
              );
            }
            
            return Column(
              children: assignments.take(3).map((assignment) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: assignment.isOverdue
                          ? AppTheme.error
                          : AppTheme.primaryColor,
                      child: Icon(
                        assignment.isOverdue ? Icons.warning : Icons.assignment,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(assignment.title),
                    subtitle: Text(
                      '${assignment.course.courseCode} • ${assignment.daysUntilDue} days left',
                    ),
                    trailing: Text(
                      assignment.dueDate.toString().split(' ')[0],
                      style: TextStyle(
                        color: assignment.isOverdue ? AppTheme.error : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to assignment detail
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}


