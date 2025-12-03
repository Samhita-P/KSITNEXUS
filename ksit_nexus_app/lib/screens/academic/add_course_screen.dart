import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/academic_planner_models.dart';
import '../../providers/data_providers.dart';
import 'courses_screen.dart';

class AddCourseScreen extends ConsumerStatefulWidget {
  const AddCourseScreen({super.key});

  @override
  ConsumerState<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends ConsumerState<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditsController = TextEditingController(text: '3');
  final _academicYearController = TextEditingController();
  
  String _courseType = 'core';
  int _semester = 1;
  String _color = '#3b82f6';
  bool _isLoading = false;

  final List<String> _courseTypes = ['core', 'elective', 'lab', 'project', 'seminar', 'workshop'];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];
  final List<Color> _colorOptions = [
    const Color(0xFF3b82f6), // Blue
    const Color(0xFF10b981), // Green
    const Color(0xFFf59e0b), // Amber
    const Color(0xFFef4444), // Red
    const Color(0xFF8b5cf6), // Purple
    const Color(0xFFec4899), // Pink
    const Color(0xFF06b6d4), // Cyan
    const Color(0xFF84cc16), // Lime
  ];

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Set default academic year
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = now.year + 1;
    _academicYearController.text = '$currentYear-$nextYear';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      final courseData = {
        'course_code': _courseCodeController.text.trim().toUpperCase(),
        'course_name': _courseNameController.text.trim(),
        'course_type': _courseType,
        'credits': int.parse(_creditsController.text),
        'semester': _semester,
        'academic_year': _academicYearController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _color,
      };

      final createdCourse = await apiService.createCourse(courseData);

      // Auto-enroll the user in the course they just created
      if (createdCourse.id != null) {
        try {
          await apiService.enrollInCourse(createdCourse.id!);
        } catch (e) {
          print('Note: Could not auto-enroll in course: $e');
          // Continue even if enrollment fails
        }
      }

      if (mounted) {
        // Invalidate all related providers to refresh data
        ref.invalidate(coursesProvider);
        ref.invalidate(enrollmentsProvider);
        ref.invalidate(academicDashboardProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created and enrolled successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating course: ${e.toString()}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Course'),
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
              ref.invalidate(coursesProvider);
              ref.invalidate(enrollmentsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Course Code
            TextFormField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course Code *',
                hintText: 'e.g., CS101',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter course code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Course Name
            TextFormField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name *',
                hintText: 'e.g., Introduction to Computer Science',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter course name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Course Type
            DropdownButtonFormField<String>(
              value: _courseType,
              decoration: const InputDecoration(
                labelText: 'Course Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _courseTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type[0].toUpperCase() + type.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _courseType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Credits
            TextFormField(
              controller: _creditsController,
              decoration: const InputDecoration(
                labelText: 'Credits *',
                hintText: 'e.g., 3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter credits';
                }
                final credits = int.tryParse(value);
                if (credits == null || credits < 1 || credits > 10) {
                  return 'Credits must be between 1 and 10';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Semester
            DropdownButtonFormField<int>(
              value: _semester,
              decoration: const InputDecoration(
                labelText: 'Semester *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: _semesters.map((sem) {
                return DropdownMenuItem(
                  value: sem,
                  child: Text('Semester $sem'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _semester = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Academic Year
            TextFormField(
              controller: _academicYearController,
              decoration: const InputDecoration(
                labelText: 'Academic Year *',
                hintText: 'e.g., 2024-2025',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter academic year';
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
                hintText: 'Course description...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Color Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((color) {
                    final isSelected = _color == '#${color.value.toRadixString(16).substring(2)}';
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _color = '#${color.value.toRadixString(16).substring(2)}';
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                  : const Text('Create Course', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

