import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/recommendation_model.dart';
import '../../models/notice_model.dart';
import '../../models/study_group_model.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key});

  @override
  ConsumerState<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedContentType = 'notice';
  String _selectedRecommendationType = 'content_based';
  bool _isLoading = false;
  List<Recommendation> _recommendations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedContentType = 'notice';
            break;
          case 1:
            _selectedContentType = 'study_group';
            break;
          case 2:
            _selectedContentType = 'resource';
            break;
        }
      });
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      List<Recommendation> recommendations;

      switch (_selectedContentType) {
        case 'notice':
          recommendations = await apiService.getNoticeRecommendations(
            recommendationType: _selectedRecommendationType,
            limit: 20,
          );
          break;
        case 'study_group':
          recommendations = await apiService.getStudyGroupRecommendations(
            recommendationType: _selectedRecommendationType,
            limit: 20,
          );
          break;
        case 'resource':
          recommendations = await apiService.getResourceRecommendations(
            recommendationType: _selectedRecommendationType,
            limit: 20,
          );
          break;
        default:
          recommendations = await apiService.getRecommendations(
            contentType: _selectedContentType,
            recommendationType: _selectedRecommendationType,
            limit: 20,
          );
      }

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRecommendations() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recommendations = await apiService.refreshRecommendations(
        contentType: _selectedContentType,
        recommendationType: _selectedRecommendationType,
        limit: 20,
        clearExisting: false,
      );

      setState(() {
        _recommendations = recommendations;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendations refreshed'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissRecommendation(int recommendationId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.dismissRecommendation(recommendationId);

      setState(() {
        _recommendations.removeWhere((r) => r.id == recommendationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendation dismissed'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dismiss: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _navigateToContent(Recommendation recommendation) async {
    // Track view interaction
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.trackInteraction(
        contentType: recommendation.contentType,
        contentId: recommendation.contentId,
        interactionType: 'view',
      );
    } catch (e) {
      // Silently handle errors
    }

    // Navigate to content based on type
    switch (recommendation.contentType) {
      case 'notice':
        context.push('/notices/${recommendation.contentId}');
        break;
      case 'study_group':
        context.push('/study-groups/${recommendation.contentId}');
        break;
      case 'resource':
        // Navigate to resource if available
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedRecommendationType = value;
              });
              _loadRecommendations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'content_based',
                child: Text('Content Based'),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Popular'),
              ),
              const PopupMenuItem(
                value: 'trending',
                child: Text('Trending'),
              ),
            ],
          ),
          IconButton(
            onPressed: _refreshRecommendations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Notices', icon: Icon(Icons.notifications)),
            Tab(text: 'Study Groups', icon: Icon(Icons.group)),
            Tab(text: 'Resources', icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _recommendations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecommendations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _recommendations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.recommend,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Recommendations',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ll show you personalized recommendations here',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.grey600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshRecommendations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendations,
                      child: ResponsiveContainer(
                        maxWidth: Responsive.value(
                          context: context,
                          mobile: double.infinity,
                          tablet: 900,
                          desktop: 1000,
                        ),
                        padding: Responsive.padding(context),
                        child: ListView.builder(
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = _recommendations[index];
                            return _buildRecommendationCard(recommendation);
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToContent(recommendation),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score and type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Recommendation type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(recommendation.recommendationType)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          recommendation.recommendationTypeDisplay ??
                              recommendation.recommendationType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(recommendation.recommendationType),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Score indicator
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(recommendation.score * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.grey900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _dismissRecommendation(recommendation.id),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    color: AppTheme.grey500,
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Content preview
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getContentTypeColor(recommendation.contentType)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getContentTypeIcon(recommendation.contentType),
                      color: _getContentTypeColor(recommendation.contentType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.contentTitle ?? 
                          '${recommendation.contentTypeDisplay ?? recommendation.contentType} #${recommendation.contentId}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.grey900,
                          ),
                        ),
                        if (recommendation.reason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            recommendation.reason!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              // Status indicators
              const SizedBox(height: 12),
              Row(
                children: [
                  if (recommendation.isViewed)
                    _buildStatusChip('Viewed', Icons.visibility, AppTheme.info),
                  if (recommendation.isInteracted)
                    _buildStatusChip(
                      'Interacted',
                      Icons.touch_app,
                      AppTheme.success,
                    ),
                  const Spacer(),
                  // Feedback buttons
                  IconButton(
                    onPressed: () => _submitFeedback(recommendation, 'like'),
                    icon: Icon(
                      recommendation.feedback?['like'] == true
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 20,
                    ),
                    color: AppTheme.success,
                    tooltip: 'Like',
                  ),
                  IconButton(
                    onPressed: () => _submitFeedback(recommendation, 'dislike'),
                    icon: Icon(
                      recommendation.feedback?['dislike'] == true
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      size: 20,
                    ),
                    color: AppTheme.error,
                    tooltip: 'Dislike',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'content_based':
        return AppTheme.primaryColor;
      case 'popular':
        return AppTheme.success;
      case 'trending':
        return AppTheme.warning;
      default:
        return AppTheme.grey600;
    }
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'notice':
        return AppTheme.primaryColor;
      case 'study_group':
        return AppTheme.success;
      case 'resource':
        return AppTheme.info;
      default:
        return AppTheme.grey600;
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'notice':
        return Icons.notifications;
      case 'study_group':
        return Icons.group;
      case 'resource':
        return Icons.folder;
      default:
        return Icons.article;
    }
  }

  Future<void> _submitFeedback(
    Recommendation recommendation,
    String feedbackType,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitRecommendationFeedback(
        contentType: recommendation.contentType,
        contentId: recommendation.contentId,
        recommendationType: recommendation.recommendationType,
        feedbackType: feedbackType,
        feedbackData: {'value': true},
      );

      // Update local state - create a new recommendation with updated feedback
      setState(() {
        final updatedRecommendations = _recommendations.map((r) {
          if (r.id == recommendation.id) {
            return Recommendation(
              id: r.id,
              userId: r.userId,
              contentType: r.contentType,
              contentTypeDisplay: r.contentTypeDisplay,
              contentId: r.contentId,
              contentTitle: r.contentTitle,
              recommendationType: r.recommendationType,
              recommendationTypeDisplay: r.recommendationTypeDisplay,
              score: r.score,
              reason: r.reason,
              isDismissed: r.isDismissed,
              isViewed: r.isViewed,
              isInteracted: r.isInteracted,
              feedback: {
                ...?r.feedback,
                feedbackType: true,
              },
              expiresAt: r.expiresAt,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            );
          }
          return r;
        }).toList();
        _recommendations = updatedRecommendations;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback submitted: $feedbackType'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

