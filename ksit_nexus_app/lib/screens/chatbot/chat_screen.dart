import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/chatbot_model.dart';
import '../../models/chatbot_nlp_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? initialQuestion;
  
  const ChatScreen({
    super.key,
    this.sessionId,
    this.initialQuestion,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatbotMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  String? _currentSessionId;
  List<ChatbotQuestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  bool _justSentMessage = false;
  ConversationContext? _conversationContext;
  Map<String, EnhancedChatbotResponse> _messageNlpData = {}; // Store NLP data for each message

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _initializeChat();
    _messageController.addListener(_onTextChanged);
    // Send initial question if provided
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
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
              context.go('/chatbot');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // TRUE REFRESH: Reload chat session and refresh all chatbot data
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Refresh chatbot-related providers
                ref.refresh(chatbotCategoriesProvider);
                ref.refresh(chatbotQuestionsProvider);
                ref.refresh(userChatbotSessionsProvider);
                
                // Reload conversation context if session exists
                if (_currentSessionId != null) {
                  final apiService = ref.read(apiServiceProvider);
                  try {
                    final context = await apiService.getConversationContext(_currentSessionId!);
                    setState(() {
                      _conversationContext = context;
                    });
                  } catch (e) {
                    // If session doesn't exist or error, reinitialize chat
                    _currentSessionId = null;
                    setState(() {
                      _messages.clear();
                      _messageNlpData.clear();
                      _conversationContext = null;
                      _initializeChat();
                    });
                  }
                } else {
                  // No session, just reinitialize
                  setState(() {
                    _messages.clear();
                    _messageNlpData.clear();
                    _conversationContext = null;
                    _initializeChat();
                  });
                }
              } catch (e) {
                // On error, at least reinitialize the chat
                setState(() {
                  _messages.clear();
                  _messageNlpData.clear();
                  _conversationContext = null;
                  _initializeChat();
                });
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showContextInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Context Info',
          ),
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: ResponsiveContainer(
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
            // Messages List
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: Responsive.padding(context),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
            
            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
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
              Icons.smart_toy,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hi! I\'m your AI Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about campus life, academics, or get help with the app!',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Quick Questions
          _buildQuickQuestions(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      'How do I book a seat?',
      'Where is the library?',
      'How to submit a complaint?',
      'What are the exam dates?',
      'How to join a study group?',
    ];

    return Column(
      children: [
        Text(
          'Quick Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickQuestions.map((question) {
            return ActionChip(
              label: Text(question),
              onPressed: () => _sendMessage(question),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(color: AppTheme.primaryColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    final isUser = message.messageType == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.grey900,
                      fontSize: 16,
                    ),
                  ),
                  
                  // Display NLP information for bot messages
                  if (!isUser && message.messageType == 'bot') ...[
                    _buildNlpInfo(message),
                  ],
                  
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isUser ? Colors.white70 : AppTheme.grey500,
                          fontSize: 12,
                        ),
                      ),
                      // Confidence score indicator
                      if (!isUser && message.confidence != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (message.confidence! > 0.7
                                ? Colors.green
                                : message.confidence! > 0.4
                                    ? Colors.orange
                                    : Colors.red).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(message.confidence! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: message.confidence! > 0.7
                                  ? Colors.green
                                  : message.confidence! > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Feedback buttons for bot messages
                  if (!isUser && message.messageType == 'bot') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _rateMessage(message, true),
                          icon: const Icon(Icons.thumb_up, size: 16),
                          color: AppTheme.success,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        IconButton(
                          onPressed: () => _rateMessage(message, false),
                          icon: const Icon(Icons.thumb_down, size: 16),
                          color: AppTheme.error,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.grey400.withOpacity(0.3 + (0.7 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        // Question Suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          suggestion.question,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        
        // Input Field
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppTheme.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppTheme.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(_messageController.text),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _initializeChat() {
    // Add welcome message
    _messages.add(ChatbotMessage(
      id: 1,
      sessionId: _currentSessionId ?? 'default',
      message: 'Hello! I\'m your AI assistant. How can I help you today?',
      content: 'Hello! I\'m your AI assistant. How can I help you today?',
      messageType: 'bot',
      sender: 'bot',
      sentAt: DateTime.now(),
      createdAt: DateTime.now(),
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // Hide suggestions when sending message and set flag
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
      _justSentMessage = true;
    });

    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    final userMessage = ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sessionId: _currentSessionId ?? 'default',
      message: text.trim(),
      content: text.trim(),
      messageType: 'user',
      sender: 'user',
      sentAt: DateTime.now(),
      createdAt: DateTime.now(),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Use the enhanced API service to send message with NLP
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.sendEnhancedChatbotMessage(
        message: text.trim(),
        sessionId: _currentSessionId,
      );
      
      // Update session ID if provided
      if (response.sessionId != null) {
        _currentSessionId = response.sessionId;
        
        // Fetch conversation context if session ID is available
        _fetchConversationContext(response.sessionId!);
      }
      
      final botMessage = ChatbotMessage(
        id: response.messageId ?? DateTime.now().millisecondsSinceEpoch,
        sessionId: _currentSessionId ?? response.sessionId ?? 'default',
        message: response.response,
        content: response.response,
        messageType: 'bot',
        sender: 'bot',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        isUser: false,
        response: response.response,
        confidence: response.effectiveConfidence,
        relatedQuestions: response.relatedQuestions?.map((q) {
          return ChatbotQuestion(
            id: q['id'] as int? ?? 0,
            category: q['category']?.toString() ?? 'General',
            question: q['question']?.toString() ?? '',
            answer: q['answer']?.toString() ?? '',
            keywords: (q['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
            tags: (q['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
            isActive: true,
            priority: 0,
            usageCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList(),
      );

      setState(() {
        _messages.add(botMessage);
        // Store NLP data for this message
        _messageNlpData[botMessage.id.toString()] = response;
        _isLoading = false;
        _isTyping = false;
      });

      _scrollToBottom();
      
      // Show action result if available
      if (response.actionResult != null) {
        _showActionResult(response.actionResult!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
  
  Widget _buildNlpInfo(ChatbotMessage message) {
    final nlpData = _messageNlpData[message.id.toString()];
    if (nlpData == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Sentiment indicator
        if (nlpData.sentiment != null) ...[
          Row(
            children: [
              Icon(
                nlpData.sentiment == 'positive' 
                    ? Icons.sentiment_satisfied
                    : nlpData.sentiment == 'negative'
                        ? Icons.sentiment_dissatisfied
                        : Icons.sentiment_neutral,
                size: 16,
                color: nlpData.sentiment == 'positive'
                    ? Colors.green
                    : nlpData.sentiment == 'negative'
                        ? Colors.red
                        : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                nlpData.sentiment!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: nlpData.sentiment == 'positive'
                      ? Colors.green
                      : nlpData.sentiment == 'negative'
                          ? Colors.red
                          : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        // Intent and confidence
        if (nlpData.intent != null && nlpData.intentConfidence != null) ...[
          Row(
            children: [
              Text(
                'Intent: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey600,
                ),
              ),
              Text(
                nlpData.intent!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(nlpData.intentConfidence! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        // Entities
        if (nlpData.entities != null && nlpData.entities!.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: nlpData.entities!.map((entity) {
              return Chip(
                label: Text(
                  '${entity['type']}: ${entity['value']}',
                  style: const TextStyle(fontSize: 10),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
        
        // Confidence score (shown in message footer, so not duplicated here)
        // The confidence score is already displayed in the message footer
      ],
    );
  }
  
  Future<void> _fetchConversationContext(String sessionId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final context = await apiService.getConversationContext(sessionId);
      setState(() {
        _conversationContext = context;
      });
    } catch (e) {
      // Silently handle errors
    }
  }
  
  void _showContextInfo() {
    if (_conversationContext == null && _currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation context available')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Context'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_conversationContext != null) ...[
                if (_conversationContext!.sessionId != null)
                  Text('Session ID: ${_conversationContext!.sessionId}'),
                const SizedBox(height: 8),
                if (_conversationContext!.currentIntent != null)
                  Text('Current Intent: ${_conversationContext!.currentIntent}'),
                if (_conversationContext!.conversationState != null)
                  Text('State: ${_conversationContext!.conversationState}'),
                if (_conversationContext!.sentimentLabel != null)
                  Text('Sentiment: ${_conversationContext!.sentimentLabel}'),
                if (_conversationContext!.detectedEntities != null && _conversationContext!.detectedEntities!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Entities:'),
                  ..._conversationContext!.detectedEntities!.map((e) {
                    return Text('  - ${e['type']}: ${e['value']}');
                  }),
                ],
              ] else if (_currentSessionId != null) ...[
                Text('Session ID: $_currentSessionId'),
                const SizedBox(height: 8),
                const Text('Context data not available yet.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showActionResult(Map<String, dynamic> actionResult) {
    if (actionResult['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actionResult['data']?['message']?.toString() ?? 'Action executed successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actionResult['error']?.toString() ?? 'Action execution failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _generateBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('book') && message.contains('seat')) {
      return 'To book a seat, go to the Reservations section and select a room. You can choose from available seats and book them for your preferred time slot.';
    } else if (message.contains('library')) {
      return 'The library is located on the 2nd floor of the main building. It\'s open from 8 AM to 8 PM on weekdays and 9 AM to 5 PM on weekends.';
    } else if (message.contains('complaint')) {
      return 'You can submit a complaint through the Complaints section. Click on "Submit Complaint" and fill out the form with details about your issue.';
    } else if (message.contains('exam')) {
      return 'Exam dates are usually announced 2-3 weeks in advance. Check the Notices section for the latest exam schedule and updates.';
    } else if (message.contains('study group')) {
      return 'To join a study group, go to the Study Groups section and browse available groups. You can also create your own group and invite others to join.';
    } else if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! I\'m here to help you with any questions about campus life, academics, or using the app. What would you like to know?';
    } else {
      return 'I understand you\'re asking about "$userMessage". Let me help you with that. Could you provide more specific details so I can give you a better answer?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _rateMessage(ChatbotMessage message, bool isHelpful) {
    // TODO: Implement message rating API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHelpful ? 'Thanks for your feedback!' : 'Thanks for your feedback!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _clearChat() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (shouldClear == true) {
      // Clear conversation context if session ID is available
      if (_currentSessionId != null) {
        try {
          final apiService = ref.read(apiServiceProvider);
          await apiService.clearConversationContext(_currentSessionId!);
        } catch (e) {
          // Silently handle errors
        }
      }
      
      setState(() {
        _messages.clear();
        _messageNlpData.clear();
        _conversationContext = null;
        _initializeChat();
      });
    }
  }

  void _onTextChanged() {
    final text = _messageController.text.trim();
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Reset the flag when user starts typing again
    if (text.isNotEmpty) {
      _justSentMessage = false;
    }
    
    if (text.length >= 2 && !_justSentMessage) {
      // Add debounce to prevent too many API calls
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_justSentMessage) {
          _loadSuggestions(text);
        }
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _suggestions.clear();
      });
    }
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final suggestions = await apiService.getQuestionSuggestions(query: query);
      
      if (mounted) {
        // Filter out the current question from suggestions
        final filteredSuggestions = suggestions.where((suggestion) {
          return suggestion.question.toLowerCase() != query.toLowerCase();
        }).toList();
        
        setState(() {
          _suggestions = filteredSuggestions;
          _showSuggestions = filteredSuggestions.isNotEmpty;
          _justSentMessage = false; // Reset the flag
        });
      }
    } catch (e) {
      // Silently handle errors for suggestions
      if (mounted) {
        setState(() {
          _showSuggestions = false;
          _suggestions.clear();
          _justSentMessage = false; // Reset the flag
        });
      }
    }
  }

  void _selectSuggestion(ChatbotQuestion suggestion) {
    // Clear suggestions immediately
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
      _justSentMessage = true;
    });
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    _sendMessage(suggestion.question);
  }
}
