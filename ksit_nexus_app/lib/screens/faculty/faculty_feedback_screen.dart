import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../models/feedback_model.dart' as feedback_model;

class FacultyFeedbackScreen extends ConsumerStatefulWidget {
  const FacultyFeedbackScreen({super.key});

  @override
  ConsumerState<FacultyFeedbackScreen> createState() => _FacultyFeedbackScreenState();
}

class _FacultyFeedbackScreenState extends ConsumerState<FacultyFeedbackScreen> {
  String _filterStatus = 'all'; // all, recent, semester

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final facultyId = authState.user?.id;
    
    if (facultyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Feedback'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view feedback'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/faculty-dashboard');
            }
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('My Feedback'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(facultyFeedbackProvider(facultyId));
              ref.refresh(facultyFeedbackSummaryProvider(facultyId));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('recent', 'Recent'),
                _buildFilterChip('semester', 'This Semester'),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: double.infinity,
          desktop: 1400,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: Column(
          children: [
            // Feedback Summary Card - Shrink to fit
            Flexible(
              fit: FlexFit.loose,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35, // Max 35% of screen height
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final summaryAsync = ref.watch(facultyFeedbackSummaryProvider(facultyId));
                    
                    return summaryAsync.when(
                      data: (summary) => _buildSummaryCard(context, summary),
                      loading: () => _buildLoadingSummaryCard(context),
                      error: (error, stack) => _buildErrorSummaryCard(context, error.toString()),
                    );
                  },
                ),
              ),
            ),
            
            // Feedback List
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final feedbackAsync = ref.watch(facultyFeedbackProvider(facultyId));
                  
                  return feedbackAsync.when(
                    data: (feedbacks) {
                      final filteredFeedbacks = _filterFeedbacks(feedbacks);
                      
                      if (filteredFeedbacks.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.refresh(facultyFeedbackProvider(facultyId));
                          ref.refresh(facultyFeedbackSummaryProvider(facultyId));
                        },
                        child: ListView.builder(
                          padding: Responsive.padding(context),
                          itemCount: filteredFeedbacks.length,
                          itemBuilder: (context, index) {
                            return _buildFeedbackCard(context, filteredFeedbacks[index]);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => _buildErrorState(context, error.toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<feedback_model.Feedback> _filterFeedbacks(List<feedback_model.Feedback> feedbacks) {
    switch (_filterStatus) {
      case 'recent':
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return feedbacks.where((f) => f.submittedAt.isAfter(thirtyDaysAgo)).toList();
      case 'semester':
        // Filter by current semester (assuming semester is stored as string like "2024-2025-1")
        return feedbacks; // TODO: Implement semester filtering
      default:
        return feedbacks;
    }
  }

  Widget _buildSummaryCard(BuildContext context, feedback_model.FacultyFeedbackSummary summary) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
        vertical: Responsive.spacing(context, mobile: 2, tablet: 4, desktop: 6),
      ),
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.value(context: context, mobile: 12, tablet: 14, desktop: 16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Feedback Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.value(context: context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 2, tablet: 3, desktop: 4)),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  context,
                  'Overall Rating',
                  summary.averageOverallRating.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 2, tablet: 3, desktop: 4)),
              Expanded(
                child: _buildSummaryStat(
                  context,
                  'Total Feedback',
                  summary.totalFeedbacks.toString(),
                  Icons.feedback_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 1, tablet: 1.5, desktop: 2)),
          Row(
            children: [
              Expanded(
                child: _buildRatingBar(
                  context,
                  'Teaching',
                  summary.averageTeachingRating,
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 1, tablet: 1.5, desktop: 2)),
              Expanded(
                child: _buildRatingBar(
                  context,
                  'Communication',
                  summary.averageCommunicationRating,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 1, tablet: 1.5, desktop: 2)),
          Row(
            children: [
              Expanded(
                child: _buildRatingBar(
                  context,
                  'Punctuality',
                  summary.averagePunctualityRating,
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 1, tablet: 1.5, desktop: 2)),
              Expanded(
                child: _buildRatingBar(
                  context,
                  'Helpfulness',
                  summary.averageHelpfulnessRating,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 3, tablet: 5, desktop: 6)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(Responsive.value(context: context, mobile: 10, tablet: 12, desktop: 12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: Colors.white, 
            size: Responsive.value(context: context, mobile: 14, tablet: 18, desktop: 20),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 0.5, tablet: 1, desktop: 2)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.value(context: context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 0.5, tablet: 0.5, desktop: 1)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontSize: Responsive.value(context: context, mobile: 6.5, tablet: 7.5, desktop: 8.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, String label, double rating) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 1.5, tablet: 3, desktop: 4)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(Responsive.value(context: context, mobile: 6, tablet: 8, desktop: 8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.value(context: context, mobile: 7.5, tablet: 8.5, desktop: 9.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 1.5, tablet: 2, desktop: 2.5)),
              Text(
                rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.value(context: context, mobile: 7.5, tablet: 8.5, desktop: 9.5),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 0.5, tablet: 1.5, desktop: 1.5)),
          LinearProgressIndicator(
            value: rating / 5.0,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: Responsive.value(context: context, mobile: 1.5, tablet: 2.0, desktop: 2.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSummaryCard(BuildContext context) {
    return Container(
      margin: Responsive.padding(context),
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorSummaryCard(BuildContext context, String error) {
    return Container(
      margin: Responsive.padding(context),
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          SizedBox(height: Responsive.spacing(context)),
          Text(
            'Failed to load summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, feedback_model.Feedback feedback) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(feedback.overallRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        feedback.overallRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(feedback.submittedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
            if (feedback.courseName != null && feedback.courseName!.isNotEmpty) ...[
              Text(
                feedback.courseName!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
            ],
            Row(
              children: [
                _buildRatingItem(context, 'Teaching', feedback.teachingRating),
                SizedBox(width: Responsive.spacing(context)),
                _buildRatingItem(context, 'Communication', feedback.communicationRating),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
            Row(
              children: [
                _buildRatingItem(context, 'Punctuality', feedback.punctualityRating),
                SizedBox(width: Responsive.spacing(context)),
                _buildRatingItem(context, 'Helpfulness', feedback.helpfulnessRating),
              ],
            ),
            if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              Container(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comment',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
                    Text(
                      feedback.comment!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppTheme.grey600),
                SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                Text(
                  feedback.isAnonymous ? 'Anonymous' : feedback.studentName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
                if (feedback.semester.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Semester: ${feedback.semester}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(BuildContext context, String label, double rating) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grey600,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.round() ? Icons.star : Icons.star_border,
                  size: 16,
                  color: index < rating.round() ? Colors.amber : AppTheme.grey400,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.blue;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 64, color: AppTheme.grey400),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'No Feedback Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            'You haven\'t received any feedback yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final authState = ref.read(authStateProvider);
    final facultyId = authState.user?.id;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Feedback',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Padding(
            padding: Responsive.horizontalPadding(context),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          ElevatedButton(
            onPressed: () {
              if (facultyId != null) {
                ref.refresh(facultyFeedbackProvider(facultyId));
                ref.refresh(facultyFeedbackSummaryProvider(facultyId));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

