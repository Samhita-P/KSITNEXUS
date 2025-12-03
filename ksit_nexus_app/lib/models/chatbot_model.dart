import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class ChatbotCategory {
  final int id;
  final String name;
  final String description;
  final String? icon;
  final bool isActive;
  final int order;

  ChatbotCategory({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.isActive,
    required this.order,
  });

  factory ChatbotCategory.fromJson(Map<String, dynamic> json) {
    return ChatbotCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
      isActive: json['is_active'] as bool,
      order: json['order'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'is_active': isActive,
      'order': order,
    };
  }
}

@JsonSerializable()
class ChatbotQuestion {
  final int id;
  final String category; // Changed from ChatbotCategory to String
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> tags;
  final bool isActive;
  final int priority; // Changed from order to priority
  final int usageCount; // Changed from confidence to usageCount
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatbotQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.tags,
    required this.isActive,
    required this.priority,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatbotQuestion.fromJson(Map<String, dynamic> json) {
    // Handle category field - it might be a string or an object
    String categoryName = 'General';
    if (json['category'] != null) {
      if (json['category'] is String) {
        categoryName = json['category'] as String;
      } else if (json['category'] is Map) {
        categoryName = (json['category'] as Map)['name']?.toString() ?? 'General';
      }
    }
    
    return ChatbotQuestion(
      id: json['id'] as int? ?? 0,
      category: categoryName,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'keywords': keywords,
      'tags': tags,
      'is_active': isActive,
      'priority': priority,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class ChatbotSession {
  final String id;
  final String sessionId; // Add sessionId property
  final int? userId;
  final String? userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? endedAt; // Add endedAt property
  final bool isActive;
  final List<ChatbotMessage> messages;

  ChatbotSession({
    required this.id,
    required this.sessionId,
    this.userId,
    this.userName,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
    required this.isActive,
    required this.messages,
  });

  factory ChatbotSession.fromJson(Map<String, dynamic> json) {
    return ChatbotSession(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      isActive: json['is_active'] as bool,
      messages: json['messages'] != null 
          ? (json['messages'] as List).map((e) => ChatbotMessage.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }
}

@JsonSerializable()
class ChatbotMessage {
  final int id;
  final String sessionId;
  final String message;
  final String content; // Add content property
  final String messageType;
  final String sender;
  final DateTime sentAt;
  final DateTime createdAt; // Add createdAt property
  final bool isUser;
  final String? response;
  final double? confidence;
  final List<ChatbotQuestion>? relatedQuestions;

  ChatbotMessage({
    required this.id,
    required this.sessionId,
    required this.message,
    required this.content,
    required this.messageType,
    required this.sender,
    required this.sentAt,
    required this.createdAt,
    required this.isUser,
    this.response,
    this.confidence,
    this.relatedQuestions,
  });

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id'] as int,
      sessionId: json['session_id'] as String,
      message: json['message'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String,
      sender: json['sender'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isUser: json['is_user'] as bool,
      response: json['response'] as String?,
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
      relatedQuestions: json['related_questions'] != null 
          ? (json['related_questions'] as List).map((e) => ChatbotQuestion.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'message': message,
      'content': content,
      'message_type': messageType,
      'sender': sender,
      'sent_at': sentAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_user': isUser,
      'response': response,
      'confidence': confidence,
      'related_questions': relatedQuestions?.map((e) => e.toJson()).toList(),
    };
  }

  bool get isBot => !isUser;
  bool get hasResponse => response != null && response!.isNotEmpty;
  bool get hasRelatedQuestions => relatedQuestions != null && relatedQuestions!.isNotEmpty;
}

@JsonSerializable()
class ChatbotFeedback {
  final int id;
  final String sessionId;
  final int messageId;
  final int? userId;
  final String? userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ChatbotFeedback({
    required this.id,
    required this.sessionId,
    required this.messageId,
    this.userId,
    this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ChatbotFeedback.fromJson(Map<String, dynamic> json) {
    return ChatbotFeedback(
      id: json['id'] as int,
      sessionId: json['session_id'] as String,
      messageId: json['message_id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'message_id': messageId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
  bool get isNeutral => rating == 3;
}

@JsonSerializable()
class ChatbotAnalytics {
  final int totalSessions;
  final int totalMessages;
  final int totalUsers;
  final double averageSessionDuration;
  final double averageMessagesPerSession;
  final double averageRating;
  final Map<String, int> messagesByCategory;
  final Map<String, int> messagesByType;
  final List<ChatbotQuestion> mostAskedQuestions;
  final List<ChatbotQuestion> leastAskedQuestions;
  final Map<String, double> confidenceDistribution;

  ChatbotAnalytics({
    required this.totalSessions,
    required this.totalMessages,
    required this.totalUsers,
    required this.averageSessionDuration,
    required this.averageMessagesPerSession,
    required this.averageRating,
    required this.messagesByCategory,
    required this.messagesByType,
    required this.mostAskedQuestions,
    required this.leastAskedQuestions,
    required this.confidenceDistribution,
  });

  factory ChatbotAnalytics.fromJson(Map<String, dynamic> json) {
    return ChatbotAnalytics(
      totalSessions: json['total_sessions'] as int,
      totalMessages: json['total_messages'] as int,
      totalUsers: json['total_users'] as int,
      averageSessionDuration: (json['average_session_duration'] as num).toDouble(),
      averageMessagesPerSession: (json['average_messages_per_session'] as num).toDouble(),
      averageRating: (json['average_rating'] as num).toDouble(),
      messagesByCategory: Map<String, int>.from(json['messages_by_category'] as Map),
      messagesByType: Map<String, int>.from(json['messages_by_type'] as Map),
      mostAskedQuestions: (json['most_asked_questions'] as List).map((e) => ChatbotQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      leastAskedQuestions: (json['least_asked_questions'] as List).map((e) => ChatbotQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      confidenceDistribution: Map<String, double>.from(json['confidence_distribution'] as Map),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_messages': totalMessages,
      'total_users': totalUsers,
      'average_session_duration': averageSessionDuration,
      'average_messages_per_session': averageMessagesPerSession,
      'average_rating': averageRating,
      'messages_by_category': messagesByCategory,
      'messages_by_type': messagesByType,
      'most_asked_questions': mostAskedQuestions.map((e) => e.toJson()).toList(),
      'least_asked_questions': leastAskedQuestions.map((e) => e.toJson()).toList(),
      'confidence_distribution': confidenceDistribution,
    };
  }
}

@JsonSerializable()
class ChatbotQuery {
  final String message;
  final String? sessionId;
  final int? categoryId;

  ChatbotQuery({
    required this.message,
    this.sessionId,
    this.categoryId,
  });

  factory ChatbotQuery.fromJson(Map<String, dynamic> json) {
    return ChatbotQuery(
      message: json['message'] as String,
      sessionId: json['session_id'] as String?,
      categoryId: json['category_id'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'session_id': sessionId,
      'category_id': categoryId,
    };
  }
}

@JsonSerializable()
class ChatbotResponse {
  final String response;
  final double confidence;
  final String? category;
  final List<ChatbotQuestion>? relatedQuestions;
  final String? sessionId;
  final bool isFallback;

  ChatbotResponse({
    required this.response,
    required this.confidence,
    this.category,
    this.relatedQuestions,
    this.sessionId,
    required this.isFallback,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      response: json['response']?.toString() ?? 'I apologize, but I could not process your request. Please try again.',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString(),
      relatedQuestions: json['related_questions'] != null 
          ? (json['related_questions'] as List).map((e) => ChatbotQuestion.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      sessionId: json['session_id']?.toString(),
      isFallback: json['is_fallback'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'confidence': confidence,
      'category': category,
      'related_questions': relatedQuestions?.map((e) => e.toJson()).toList(),
      'session_id': sessionId,
      'is_fallback': isFallback,
    };
  }

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;
}

@JsonSerializable()
class ChatbotMessageCreateRequest {
  final String message;
  final String messageType;
  final String? sessionId;

  ChatbotMessageCreateRequest({
    required this.message,
    required this.messageType,
    this.sessionId,
  });

  factory ChatbotMessageCreateRequest.fromJson(Map<String, dynamic> json) {
    return ChatbotMessageCreateRequest(
      message: json['message'] as String,
      messageType: json['message_type'] as String,
      sessionId: json['session_id'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'message_type': messageType,
      'session_id': sessionId,
    };
  }
}

@JsonSerializable()
class ChatbotFeedbackCreateRequest {
  final String sessionId;
  final int messageId;
  final int rating;
  final String? comment;

  ChatbotFeedbackCreateRequest({
    required this.sessionId,
    required this.messageId,
    required this.rating,
    this.comment,
  });

  factory ChatbotFeedbackCreateRequest.fromJson(Map<String, dynamic> json) {
    return ChatbotFeedbackCreateRequest(
      sessionId: json['session_id'] as String,
      messageId: json['message_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'message_id': messageId,
      'rating': rating,
      'comment': comment,
    };
  }
}

@JsonSerializable()
class ChatbotQuestionCreateRequest {
  final int categoryId;
  final String question;
  final String answer;
  final List<String> keywords;
  final double confidence;
  final int order;

  ChatbotQuestionCreateRequest({
    required this.categoryId,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.confidence,
    required this.order,
  });

  factory ChatbotQuestionCreateRequest.fromJson(Map<String, dynamic> json) {
    return ChatbotQuestionCreateRequest(
      categoryId: json['category_id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      keywords: (json['keywords'] as List).map((e) => e as String).toList(),
      confidence: (json['confidence'] as num).toDouble(),
      order: json['order'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'question': question,
      'answer': answer,
      'keywords': keywords,
      'confidence': confidence,
      'order': order,
    };
  }
}

@JsonSerializable()
class ChatbotConversation {
  final int id;
  final int userId;
  final String userName;
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final List<ChatbotMessage> messages;

  ChatbotConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.messages,
  });

  factory ChatbotConversation.fromJson(Map<String, dynamic> json) {
    return ChatbotConversation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      sessionId: json['session_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      isActive: json['is_active'] as bool,
      messages: json['messages'] != null 
          ? (json['messages'] as List).map((e) => ChatbotMessage.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'session_id': sessionId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }
}

@JsonSerializable()
class ChatbotStats {
  final int totalConversations;
  final int activeConversations;
  final int totalMessages;
  final double averageMessagesPerConversation;
  final double averageResponseTime;
  final int totalFeedback;
  final double averageRating;
  final double helpfulPercentage;
  final List<String> topQuestions;
  final Map<String, int> conversationsByCategory;

  ChatbotStats({
    required this.totalConversations,
    required this.activeConversations,
    required this.totalMessages,
    required this.averageMessagesPerConversation,
    required this.averageResponseTime,
    required this.totalFeedback,
    required this.averageRating,
    required this.helpfulPercentage,
    required this.topQuestions,
    required this.conversationsByCategory,
  });

  factory ChatbotStats.fromJson(Map<String, dynamic> json) {
    return ChatbotStats(
      totalConversations: json['total_conversations'] as int,
      activeConversations: json['active_conversations'] as int,
      totalMessages: json['total_messages'] as int,
      averageMessagesPerConversation: (json['average_messages_per_conversation'] as num).toDouble(),
      averageResponseTime: (json['average_response_time'] as num).toDouble(),
      totalFeedback: json['total_feedback'] as int,
      averageRating: (json['average_rating'] as num).toDouble(),
      helpfulPercentage: (json['helpful_percentage'] as num).toDouble(),
      topQuestions: (json['top_questions'] as List).map((e) => e as String).toList(),
      conversationsByCategory: Map<String, int>.from(json['conversations_by_category'] as Map),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_conversations': totalConversations,
      'active_conversations': activeConversations,
      'total_messages': totalMessages,
      'average_messages_per_conversation': averageMessagesPerConversation,
      'average_response_time': averageResponseTime,
      'total_feedback': totalFeedback,
      'average_rating': averageRating,
      'helpful_percentage': helpfulPercentage,
      'top_questions': topQuestions,
      'conversations_by_category': conversationsByCategory,
    };
  }
}