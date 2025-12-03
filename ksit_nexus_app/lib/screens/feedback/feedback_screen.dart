import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../providers/data_providers.dart';
import '../../models/feedback_model.dart' as feedback_model;
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/image_url_helper.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes to refresh data when switching to My Feedback tab
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // When switching to My Feedback tab (index 1), refresh the data
    if (_tabController.index == 1) {
      // Small delay to ensure tab is fully visible
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          ref.read(feedbacksProvider.notifier).refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Feedback'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Submit Feedback'),
            Tab(text: 'My Feedback'),
            Tab(text: 'Faculty List'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(feedbacksProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitFeedbackTab(),
          _buildMyFeedbackTab(),
          _buildFacultyListTab(),
        ],
      ),
    );
  }

  Widget _buildSubmitFeedbackTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: 700,
        desktop: 800,
      ),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
            child: _FeedbackForm(
              onSubmitted: _handleFeedbackSubmission,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyFeedbackTab() {
    final feedbacksAsync = ref.watch(feedbacksProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: feedbacksAsync.when(
        data: (feedbacks) => feedbacks.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 64,
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No feedback submitted yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: Responsive.padding(context),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  return _FeedbackCard(feedback: feedback);
                },
              ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load feedback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(feedbacksProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFacultyListTab() {
    final facultiesAsync = ref.watch(facultiesProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: facultiesAsync.when(
      data: (faculties) => faculties.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No faculty found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: faculties.length,
              itemBuilder: (context, index) {
                final faculty = faculties[index];
                return _FacultyCard(
                  faculty: faculty,
                  onTap: () => _showFacultyDetails(faculty),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load faculty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(facultiesProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _handleFeedbackSubmission(feedback_model.FeedbackCreateRequest request) async {
    try {
      // Create feedback (this already calls refresh internally)
      await ref.read(feedbacksProvider.notifier).createFeedback(request);
      // Wait a moment for backend to process the submission
      await Future.delayed(const Duration(milliseconds: 500));
      // Force an explicit refresh to ensure we get the latest data
      await ref.read(feedbacksProvider.notifier).refresh();
      // Wait for the state to update
      await Future.delayed(const Duration(milliseconds: 300));
      // Switch to My Feedback tab - this will trigger a rebuild and show the updated data
      _tabController.animateTo(1);
      SuccessSnackbar.show(context, 'Feedback submitted successfully!');
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to submit feedback: ${e.toString()}');
    }
  }

  void _showFacultyDetails(feedback_model.Faculty faculty) {
    showDialog(
      context: context,
      builder: (context) => _FacultyDetailsDialog(faculty: faculty),
    );
  }
}

class _FeedbackForm extends ConsumerStatefulWidget {
  final Function(feedback_model.FeedbackCreateRequest) onSubmitted;

  const _FeedbackForm({required this.onSubmitted});

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  feedback_model.Faculty? _selectedFaculty;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit Faculty Feedback',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your feedback is anonymous and helps improve teaching quality.',
            style: TextStyle(color: AppTheme.grey600),
          ),
          const SizedBox(height: 24),
          
          // Faculty Selection
          FormBuilderDropdown<feedback_model.Faculty>(
            name: 'facultyId',
            decoration: const InputDecoration(
              labelText: 'Select Faculty *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: ref.watch(facultiesProvider).when(
              data: (faculties) => faculties.map((faculty) => DropdownMenuItem(
                value: faculty,
                child: Text(faculty.name),
              )).toList(),
              loading: () => [const DropdownMenuItem(child: Text('Loading...'))],
              error: (_, __) => [const DropdownMenuItem(child: Text('Error loading faculty'))],
            ),
            onChanged: (faculty) {
              setState(() {
                _selectedFaculty = faculty;
              });
            },
            validator: FormBuilderValidators.required(errorText: 'Please select a faculty member'),
          ),
          const SizedBox(height: 16),
          
          // Semester
          FormBuilderDropdown<int>(
            name: 'semester',
            decoration: const InputDecoration(
              labelText: 'Semester *',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: List.generate(8, (index) => index + 1).map((sem) {
              return DropdownMenuItem(
                value: sem,
                child: Text('Semester $sem'),
              );
            }).toList(),
            initialValue: 1,
            validator: FormBuilderValidators.required(errorText: 'Please select a semester'),
          ),
          const SizedBox(height: 24),
          
          // Rating Categories
          Text(
            'Rate the following aspects (1-5 stars)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRatingField('teachingRating', 'Teaching Quality'),
          const SizedBox(height: 16),
          
          _buildRatingField('communicationRating', 'Communication Skills'),
          const SizedBox(height: 16),
          
          _buildRatingField('punctualityRating', 'Punctuality'),
          const SizedBox(height: 16),
          
          _buildRatingField('subjectKnowledgeRating', 'Subject Knowledge'),
          const SizedBox(height: 16),
          
          _buildRatingField('helpfulnessRating', 'Helpfulness'),
          const SizedBox(height: 24),
          
          // Comments
          FormBuilderTextField(
            name: 'comment',
            decoration: const InputDecoration(
              labelText: 'Additional Comments (Optional)',
              prefixIcon: Icon(Icons.comment_outlined),
              hintText: 'Share your thoughts about the faculty...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          
          // Anonymous option
          FormBuilderCheckbox(
            name: 'isAnonymous',
            title: const Text('Submit anonymously (uncheck to track your feedback)'),
            initialValue: false,
          ),
          const SizedBox(height: 24),
          
          LoadingButton(
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingField(String name, String label) {
    return FormBuilderSlider(
      name: name,
      initialValue: 1.0,
      min: 1.0,
      max: 5.0,
      divisions: 4,
      label: label,
      activeColor: AppTheme.primaryColor,
      inactiveColor: AppTheme.grey300,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
      ),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Please rate $label'),
        FormBuilderValidators.min(1, errorText: 'Rating must be at least 1'),
        FormBuilderValidators.max(5, errorText: 'Rating must be at most 5'),
      ]),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // Debug: Print form data
        print("Form data: $formData");
        print("Selected faculty: $_selectedFaculty");
        
        // Helper function to safely get integer rating with default
        int getRating(String key, {int defaultValue = 1}) {
          final value = formData[key];
          if (value == null) return defaultValue;
          if (value is double) return value.round();
          if (value is int) return value;
          if (value is String) {
            final parsed = double.tryParse(value);
            return parsed?.round() ?? defaultValue;
          }
          return defaultValue;
        }
        
        // Helper function to safely get string value
        String? getStringValue(String key) {
          final value = formData[key];
          if (value == null) return null;
          final str = value.toString().trim();
          return str.isEmpty ? null : str;
        }
        
        // Validate required fields
        if (_selectedFaculty == null) {
          ErrorSnackbar.show(context, 'Please select a faculty member');
          return;
        }
        
        // Helper function to safely get integer semester
        int getSemester() {
          final value = formData['semester'];
          if (value == null) return 1;
          if (value is int) return value;
          if (value is String) {
            return int.tryParse(value) ?? 1;
          }
          if (value is double) {
            return value.round();
          }
          return 1;
        }
        
        final request = feedback_model.FeedbackCreateRequest(
          facultyId: _selectedFaculty!.id,
          semester: getSemester(),
          teachingRating: getRating('teachingRating'),
          communicationRating: getRating('communicationRating'),
          punctualityRating: getRating('punctualityRating'),
          subjectKnowledgeRating: getRating('subjectKnowledgeRating'),
          helpfulnessRating: getRating('helpfulnessRating'),
          comment: getStringValue('comment'),
          isAnonymous: formData['isAnonymous'] ?? false,
        );
        
        // Debug: Print the request payload
        print("Feedback request payload: ${request.toJson()}");
        
        widget.onSubmitted(request);
      } catch (e) {
        print("Error in _handleSubmit: $e");
        ErrorSnackbar.show(context, 'Failed to submit feedback: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FeedbackCard extends StatelessWidget {
  final feedback_model.Feedback feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row - Faculty Info and Semester
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 20 : 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.facultyName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feedback.facultyDepartment,
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sem ${feedback.semester}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            
            // Ratings - Responsive Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final crossAxisCount = isSmallScreen ? 2 : (isMobile ? 2 : 4);
                final childAspectRatio = isSmallScreen ? 1.2 : (isMobile ? 1.3 : 0.8);
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isMobile ? 8 : 12,
                  mainAxisSpacing: isMobile ? 8 : 12,
                  children: [
                    _buildRatingItem('Teaching', feedback.teachingRating, isMobile),
                    _buildRatingItem('Communication', feedback.communicationRating, isMobile),
                    _buildRatingItem('Punctuality', feedback.punctualityRating, isMobile),
                    _buildRatingItem('Helpfulness', feedback.helpfulnessRating, isMobile),
                  ],
                );
              },
            ),
            
            if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Comment:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.comment!,
                style: const TextStyle(color: AppTheme.grey800),
              ),
            ],
            
            SizedBox(height: isMobile ? 10 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Submitted ${_formatDate(feedback.submittedAt)}',
                    style: TextStyle(
                      color: AppTheme.grey600,
                      fontSize: isMobile ? 11 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (feedback.isAnonymous)
                  Icon(
                    Icons.visibility_off,
                    size: isMobile ? 14 : 16,
                    color: AppTheme.grey500,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(String label, double rating, bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: AppTheme.grey600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isMobile ? 3 : 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: isMobile ? 14 : 16,
              color: AppTheme.warning,
            );
          }),
        ),
        SizedBox(height: isMobile ? 2 : 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _FacultyCard extends StatelessWidget {
  final feedback_model.Faculty faculty;
  final VoidCallback onTap;

  const _FacultyCard({
    required this.faculty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: ImageUrlHelper.getProfilePictureUrl(faculty.profilePicture) != null
              ? NetworkImage(ImageUrlHelper.getProfilePictureUrl(faculty.profilePicture)!)
              : null,
          child: faculty.profilePicture == null
              ? const Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                )
              : null,
        ),
        title: Text(
          faculty.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faculty.designation),
            Text(
              faculty.department,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grey600,
              ),
            ),
            if (faculty.subjects.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Subjects: ${faculty.subjects.take(2).join(', ')}${faculty.subjects.length > 2 ? '...' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey500,
                ),
              ),
            ],
            if (faculty.averageRating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < faculty.averageRating! ? Icons.star : Icons.star_border,
                      size: 16,
                      color: AppTheme.warning,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${faculty.averageRating!.toStringAsFixed(1)} (${faculty.totalFeedbacks} reviews)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _FacultyDetailsDialog extends StatelessWidget {
  final feedback_model.Faculty faculty;

  const _FacultyDetailsDialog({required this.faculty});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: Text(faculty.name),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: ImageUrlHelper.getProfilePictureUrl(faculty.profilePicture) != null
                            ? NetworkImage(ImageUrlHelper.getProfilePictureUrl(faculty.profilePicture)!)
                            : null,
                        child: faculty.profilePicture == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Center(
                      child: Text(
                        faculty.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Center(
                      child: Text(
                        faculty.designation,
                        style: const TextStyle(
                          color: AppTheme.grey600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildDetailRow('Department', faculty.department),
                    _buildDetailRow('Designation', faculty.designation),
                    _buildDetailRow('Email', faculty.email),
                    if (faculty.subjects.isNotEmpty)
                      _buildDetailRow('Subjects', faculty.subjects.join(', ')),
                    
                    if (faculty.averageRating != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Overall Rating',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < faculty.averageRating! ? Icons.star : Icons.star_border,
                              size: 24,
                              color: AppTheme.warning,
                            );
                          }),
                          const SizedBox(width: 12),
                          Text(
                            '${faculty.averageRating!.toStringAsFixed(1)} out of 5.0',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Based on ${faculty.totalFeedbacks} student feedback${faculty.totalFeedbacks == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppTheme.grey600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.grey700,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.grey800),
            ),
          ),
        ],
      ),
    );
  }
}