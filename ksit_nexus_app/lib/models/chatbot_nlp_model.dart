import 'package:json_annotation/json_annotation.dart';
import 'chatbot_model.dart';

part 'chatbot_nlp_model.g.dart';

/// Entity extracted from user message
@JsonSerializable()
class ChatbotEntity {
  final String type;
  final String value;
  final double confidence;

  ChatbotEntity({
    required this.type,
    required this.value,
    required this.confidence,
  });

  factory ChatbotEntity.fromJson(Map<String, dynamic> json) =>
      _$ChatbotEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotEntityToJson(this);
}

/// Conversation context for multi-turn conversations
@JsonSerializable()
class ConversationContext {
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'context_variables')
  final Map<String, dynamic>? contextVariables;
  @JsonKey(name: 'current_intent')
  final String? currentIntent;
  @JsonKey(name: 'conversation_state')
  final String? conversationState;
  @JsonKey(name: 'detected_entities')
  final List<Map<String, dynamic>>? detectedEntities;
  @JsonKey(name: 'sentiment_score')
  final double? sentimentScore;
  @JsonKey(name: 'sentiment_label')
  final String? sentimentLabel;
  @JsonKey(name: 'conversation_history')
  final List<Map<String, dynamic>>? conversationHistory;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  ConversationContext({
    this.sessionId,
    this.contextVariables,
    this.currentIntent,
    this.conversationState,
    this.detectedEntities,
    this.sentimentScore,
    this.sentimentLabel,
    this.conversationHistory,
    this.isActive,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) =>
      _$ConversationContextFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationContextToJson(this);
}

/// Chatbot user profile for personalization
@JsonSerializable()
class ChatbotUserProfile {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'preferred_language')
  final String? preferredLanguage;
  @JsonKey(name: 'response_style')
  final String? responseStyle;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'total_interactions')
  final int? totalInteractions;
  @JsonKey(name: 'total_sessions')
  final int? totalSessions;
  @JsonKey(name: 'average_rating')
  final double? averageRating;
  @JsonKey(name: 'common_topics')
  final List<String>? commonTopics;
  @JsonKey(name: 'preferred_categories')
  final List<String>? preferredCategories;
  @JsonKey(name: 'is_personalized')
  final bool? isPersonalized;
  @JsonKey(name: 'last_interaction_at')
  final String? lastInteractionAt;

  ChatbotUserProfile({
    this.id,
    this.userId,
    this.preferredLanguage,
    this.responseStyle,
    this.preferences,
    this.totalInteractions,
    this.totalSessions,
    this.averageRating,
    this.commonTopics,
    this.preferredCategories,
    this.isPersonalized,
    this.lastInteractionAt,
  });

  factory ChatbotUserProfile.fromJson(Map<String, dynamic> json) =>
      _$ChatbotUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotUserProfileToJson(this);
}

/// Chatbot action definition
@JsonSerializable()
class ChatbotAction {
  final int id;
  final String name;
  @JsonKey(name: 'action_type')
  final String actionType;
  final String? description;
  @JsonKey(name: 'action_config')
  final Map<String, dynamic>? actionConfig;
  @JsonKey(name: 'required_params')
  final List<String>? requiredParams;
  @JsonKey(name: 'optional_params')
  final List<String>? optionalParams;
  @JsonKey(name: 'execution_function')
  final String? executionFunction;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'usage_count')
  final int? usageCount;
  @JsonKey(name: 'success_count')
  final int? successCount;
  @JsonKey(name: 'failure_count')
  final int? failureCount;
  @JsonKey(name: 'success_rate')
  final double? successRate;

  ChatbotAction({
    required this.id,
    required this.name,
    required this.actionType,
    this.description,
    this.actionConfig,
    this.requiredParams,
    this.optionalParams,
    this.executionFunction,
    this.isActive,
    this.usageCount,
    this.successCount,
    this.failureCount,
    this.successRate,
  });

  factory ChatbotAction.fromJson(Map<String, dynamic> json) =>
      _$ChatbotActionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotActionToJson(this);
}

/// Chatbot action execution result
@JsonSerializable()
class ChatbotActionExecution {
  final int id;
  @JsonKey(name: 'action_id')
  final int actionId;
  @JsonKey(name: 'action_name')
  final String actionName;
  @JsonKey(name: 'action_type')
  final String actionType;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'user_id')
  final int? userId;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? result;
  final String? status;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'execution_time')
  final double? executionTime;

  ChatbotActionExecution({
    required this.id,
    required this.actionId,
    required this.actionName,
    required this.actionType,
    required this.sessionId,
    this.userId,
    this.parameters,
    this.result,
    this.status,
    this.errorMessage,
    this.executionTime,
  });

  factory ChatbotActionExecution.fromJson(Map<String, dynamic> json) =>
      _$ChatbotActionExecutionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotActionExecutionToJson(this);
}

/// Enhanced chatbot response with NLP information
@JsonSerializable()
class EnhancedChatbotResponse {
  final String response;
  @JsonKey(name: 'confidence_score')
  final double? confidenceScore;
  @JsonKey(name: 'confidence')
  final double? confidence; // Backend also returns 'confidence'
  @JsonKey(name: 'related_questions')
  final List<Map<String, dynamic>>? relatedQuestions;
  final String? category;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'message_id')
  final int? messageId;
  @JsonKey(name: 'is_fallback')
  final bool? isFallback;
  final String? intent;
  @JsonKey(name: 'intent_confidence')
  final double? intentConfidence;
  final List<Map<String, dynamic>>? entities;
  final String? sentiment;
  @JsonKey(name: 'sentiment_score')
  final double? sentimentScore;
  @JsonKey(name: 'action_result')
  final Map<String, dynamic>? actionResult;

  EnhancedChatbotResponse({
    required this.response,
    this.confidenceScore,
    this.confidence,
    this.relatedQuestions,
    this.category,
    this.sessionId,
    this.messageId,
    this.isFallback,
    this.intent,
    this.intentConfidence,
    this.entities,
    this.sentiment,
    this.sentimentScore,
    this.actionResult,
  });

  factory EnhancedChatbotResponse.fromJson(Map<String, dynamic> json) =>
      _$EnhancedChatbotResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnhancedChatbotResponseToJson(this);
  
  // Helper method to get confidence score (checks both fields)
  double get effectiveConfidence => confidenceScore ?? confidence ?? 0.0;
}

/// Answer quality metrics
@JsonSerializable()
class AnswerQualityMetrics {
  @JsonKey(name: 'question_id')
  final int? questionId;
  @JsonKey(name: 'total_feedback')
  final int? totalFeedback;
  @JsonKey(name: 'average_rating')
  final double? averageRating;
  @JsonKey(name: 'usage_count')
  final int? usageCount;
  @JsonKey(name: 'quality_score')
  final double? qualityScore;

  AnswerQualityMetrics({
    this.questionId,
    this.totalFeedback,
    this.averageRating,
    this.usageCount,
    this.qualityScore,
  });

  factory AnswerQualityMetrics.fromJson(Map<String, dynamic> json) =>
      _$AnswerQualityMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$AnswerQualityMetricsToJson(this);
}

/// User statistics
@JsonSerializable()
class ChatbotUserStatistics {
  @JsonKey(name: 'total_interactions')
  final int? totalInteractions;
  @JsonKey(name: 'total_sessions')
  final int? totalSessions;
  @JsonKey(name: 'average_rating')
  final double? averageRating;
  @JsonKey(name: 'common_topics')
  final List<String>? commonTopics;
  @JsonKey(name: 'preferred_categories')
  final List<String>? preferredCategories;
  @JsonKey(name: 'total_sessions_count')
  final int? totalSessionsCount;
  @JsonKey(name: 'total_messages_count')
  final int? totalMessagesCount;
  @JsonKey(name: 'last_interaction_at')
  final String? lastInteractionAt;

  ChatbotUserStatistics({
    this.totalInteractions,
    this.totalSessions,
    this.averageRating,
    this.commonTopics,
    this.preferredCategories,
    this.totalSessionsCount,
    this.totalMessagesCount,
    this.lastInteractionAt,
  });

  factory ChatbotUserStatistics.fromJson(Map<String, dynamic> json) =>
      _$ChatbotUserStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotUserStatisticsToJson(this);
}

