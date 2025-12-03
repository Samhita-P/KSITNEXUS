import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/chatbot_model.dart';

class FaqScreen extends ConsumerStatefulWidget {
  final ChatbotCategory? category;
  
  const FaqScreen({
    super.key,
    this.category,
  });

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'FAQ'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chatbot');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(chatbotQuestionsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: double.infinity,
          desktop: 1000,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: Responsive.padding(context),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // FAQ List
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final questionsAsync = ref.watch(categoryQuestionsProvider(widget.category?.id));
                
                return questionsAsync.when(
                  data: (questions) {
                    final filteredQuestions = _filterQuestions(questions);
                    
                    if (filteredQuestions.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return ListView.builder(
                      padding: Responsive.horizontalPadding(context),
                      itemCount: filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final question = filteredQuestions[index];
                        return _buildQuestionCard(question);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(error.toString()),
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  List<ChatbotQuestion> _filterQuestions(List<ChatbotQuestion> questions) {
    var filtered = questions;
    
    // Filter by search query only (category filtering is done by the provider)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((q) {
        return q.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               q.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               q.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildQuestionCard(ChatbotQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: question.keywords.isNotEmpty
            ? Wrap(
                spacing: 4,
                runSpacing: 4,
                children: question.keywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _rateQuestion(question, true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Helpful'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _rateQuestion(question, false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('Not Helpful'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _copyAnswer(question.answer),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    
    if (widget.category != null) {
      title = 'No Questions in ${widget.category!.name}';
      subtitle = 'No questions available for this category';
      icon = Icons.help_outline;
    } else if (_searchQuery.isNotEmpty) {
      title = 'No Results Found';
      subtitle = 'Try searching with different keywords';
      icon = Icons.search_off;
    } else {
      title = 'No FAQ Available';
      subtitle = 'Frequently asked questions will appear here';
      icon = Icons.help_outline;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading FAQ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(chatbotQuestionsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _rateQuestion(ChatbotQuestion question, bool isHelpful) {
    // TODO: Implement question rating API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHelpful ? 'Thanks for your feedback!' : 'Thanks for your feedback!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _copyAnswer(String answer) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer copied to clipboard'),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}
