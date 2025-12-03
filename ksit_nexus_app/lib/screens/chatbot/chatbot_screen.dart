import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/chatbot_model.dart';
import 'chat_screen.dart';
import 'faq_screen.dart';
import 'chat_history_screen.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
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
              ref.refresh(chatbotCategoriesProvider);
              ref.refresh(popularQuestionsProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => context.push('/chatbot/profile'),
            icon: const Icon(Icons.person),
            tooltip: 'Chatbot Profile',
          ),
          IconButton(
            onPressed: _openChatHistory,
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Chat', icon: Icon(Icons.chat)),
            Tab(text: 'FAQ', icon: Icon(Icons.help)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildFaqTab(),
          _buildCategoriesTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: 900,
        desktop: 1000,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: Column(
        children: [
          // Quick Start Card
          Container(
            margin: EdgeInsets.all(Responsive.spacing(context)),
            padding: EdgeInsets.all(Responsive.spacing(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'AI Assistant Ready',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ask me anything about campus life, academics, or get help with the app!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey700,
                ),
              ),
            ],
          ),
        ),
          
          // Start Chat Button
          Padding(
            padding: Responsive.horizontalPadding(context),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                'Start New Chat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
          // Popular Questions
          Expanded(
            child: _buildPopularQuestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularQuestions() {
    return Consumer(
      builder: (context, ref, child) {
        final popularQuestionsAsync = ref.watch(popularQuestionsProvider);
        
        return popularQuestionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return _buildEmptyState();
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Popular Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: Responsive.horizontalPadding(context),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return _buildQuestionCard(question);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildQuestionCard(ChatbotQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _askQuestion(question.question),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.grey400,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(chatbotCategoriesProvider);
        
        return categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return _buildEmptyState();
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Quick Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(category);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildCategoryCard(ChatbotCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _openCategoryQuestions(category),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getCategoryIcon(category.icon),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description ?? 'No description available',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.grey400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTab() {
    return const FaqScreen();
  }

  Widget _buildCategoriesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(chatbotCategoriesProvider);
        
        return categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(category);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            'No Categories Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chatbot categories will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
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
            'Error Loading Categories',
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
            onPressed: () => ref.refresh(chatbotCategoriesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.help_outline;
    
    switch (iconName.toLowerCase()) {
      case 'academic':
        return Icons.school;
      case 'campus':
        return Icons.location_city;
      case 'library':
        return Icons.library_books;
      case 'hostel':
        return Icons.home;
      case 'exams':
        return Icons.quiz;
      case 'fees':
        return Icons.payment;
      case 'transport':
        return Icons.directions_bus;
      case 'sports':
        return Icons.sports;
      case 'events':
        return Icons.event;
      case 'general':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _startNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  void _openCategoryQuestions(ChatbotCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaqScreen(category: category),
      ),
    );
  }

  void _openChatHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );
  }

  void _askQuestion(String question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(initialQuestion: question),
      ),
    ).then((_) {
      // After returning from chat screen, you could refresh popular questions
      ref.refresh(popularQuestionsProvider);
    });
  }
}