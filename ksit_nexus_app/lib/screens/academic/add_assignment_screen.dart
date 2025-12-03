import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../providers/data_providers.dart';
import 'assignments_screen.dart';
import 'courses_screen.dart';

class AddAssignmentScreen extends ConsumerStatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  ConsumerState<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

final coursesListProvider = FutureProvider<List<Course>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  // Try to get enrolled courses first
  try {
    final enrollments = await apiService.getCourseEnrollments();
    if (enrollments.isNotEmpty) {
      return enrollments.map((e) => e.course).toList();
    }
  } catch (e) {
    print('Error loading enrollments: $e');
  }
  // Fallback to all courses
  return await apiService.getCourses();
});

class _AddAssignmentScreenState extends ConsumerState<AddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  
  String _assignmentType = 'homework';
  int? _selectedCourseId;
  DateTime? _dueDate;
  bool _isLoading = false;
  List<Course> _courses = [];
  bool _loadingCourses = true;

  final List<String> _assignmentTypes = [
    'homework',
    'project',
    'lab_report',
    'essay',
    'presentation',
    'quiz',
    'midterm',
    'final',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    // Invalidate provider to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(coursesListProvider);
        _loadCourses();
      }
    });
  }



  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loadingCourses = true;
    });
    
    try {
      final apiService = ref.read(apiServiceProvider);
      // Load enrolled courses first (user's courses)
      try {
        final enrollments = await apiService.getCourseEnrollments();
        if (enrollments.isNotEmpty) {
          final enrolledCourses = enrollments.map((e) => e.course).toList();
          setState(() {
            _courses = enrolledCourses;
            _loadingCourses = false;
          });
          return;
        }
      } catch (e) {
        print('Error loading enrollments: $e');
      }
      
      // Fallback to all available courses
      final allCourses = await apiService.getCourses();
      setState(() {
        _courses = allCourses;
        _loadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _loadingCourses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      final assignmentData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'assignment_type': _assignmentType,
        'course_id': _selectedCourseId,
        'due_date': _dueDate!.toIso8601String(),
        'max_score': int.tryParse(_maxScoreController.text) ?? 100,
        'status': 'not_started',
      };

      await apiService.createAssignment(assignmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch courses provider for real-time updates
    final coursesAsync = ref.watch(coursesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Assignment'),
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
              ref.invalidate(coursesListProvider);
              _loadCourses();
            },
            tooltip: 'Refresh Courses',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title *',
                hintText: 'e.g., Lab Report 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter assignment title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Course Selection
            Builder(
              builder: (context) {
                return coursesAsync.when(
                  data: (courses) {
                    // Update local state with provider data
                    if (mounted && _courses.length != courses.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _courses = courses;
                            _loadingCourses = false;
                          });
                        }
                      });
                    }
                    
                    if (courses.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Course *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                              hintText: 'No courses available',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Please create a course first. Go back and click the + button to add a course.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return DropdownButtonFormField<int>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: courses.map((course) {
                        return DropdownMenuItem<int>(
                          value: course.id,
                          child: Text(
                            '${course.courseCode} - ${course.courseName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a course';
                        }
                        return null;
                      },
                      isExpanded: true,
                      menuMaxHeight: 300,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Course *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.book),
                          errorText: 'Error loading courses',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(coursesListProvider);
                          _loadCourses();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Assignment Type
            DropdownButtonFormField<String>(
              value: _assignmentType,
              decoration: const InputDecoration(
                labelText: 'Assignment Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _assignmentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ').split(' ').map((word) {
                    return word[0].toUpperCase() + word.substring(1);
                  }).join(' ')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _assignmentType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            InkWell(
              onTap: () => _selectDueDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                      : 'Select due date',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Max Score
            TextFormField(
              controller: _maxScoreController,
              decoration: const InputDecoration(
                labelText: 'Maximum Score',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final score = int.tryParse(value);
                  if (score == null || score <= 0) {
                    return 'Please enter a valid score';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Assignment description...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Assignment', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

