// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatbot_nlp_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatbotEntity _$ChatbotEntityFromJson(Map<String, dynamic> json) =>
    ChatbotEntity(
      type: json['type'] as String,
      value: json['value'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$ChatbotEntityToJson(ChatbotEntity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'confidence': instance.confidence,
    };

ConversationContext _$ConversationContextFromJson(Map<String, dynamic> json) =>
    ConversationContext(
      sessionId: json['session_id'] as String?,
      contextVariables: json['context_variables'] as Map<String, dynamic>?,
      currentIntent: json['current_intent'] as String?,
      conversationState: json['conversation_state'] as String?,
      detectedEntities:
          (json['detected_entities'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      sentimentLabel: json['sentiment_label'] as String?,
      conversationHistory:
          (json['conversation_history'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
      isActive: json['is_active'] as bool?,
    );

Map<String, dynamic> _$ConversationContextToJson(
  ConversationContext instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'context_variables': instance.contextVariables,
  'current_intent': instance.currentIntent,
  'conversation_state': instance.conversationState,
  'detected_entities': instance.detectedEntities,
  'sentiment_score': instance.sentimentScore,
  'sentiment_label': instance.sentimentLabel,
  'conversation_history': instance.conversationHistory,
  'is_active': instance.isActive,
};

ChatbotUserProfile _$ChatbotUserProfileFromJson(Map<String, dynamic> json) =>
    ChatbotUserProfile(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      preferredLanguage: json['preferred_language'] as String?,
      responseStyle: json['response_style'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      totalInteractions: (json['total_interactions'] as num?)?.toInt(),
      totalSessions: (json['total_sessions'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      commonTopics:
          (json['common_topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      preferredCategories:
          (json['preferred_categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      isPersonalized: json['is_personalized'] as bool?,
      lastInteractionAt: json['last_interaction_at'] as String?,
    );

Map<String, dynamic> _$ChatbotUserProfileToJson(ChatbotUserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'preferred_language': instance.preferredLanguage,
      'response_style': instance.responseStyle,
      'preferences': instance.preferences,
      'total_interactions': instance.totalInteractions,
      'total_sessions': instance.totalSessions,
      'average_rating': instance.averageRating,
      'common_topics': instance.commonTopics,
      'preferred_categories': instance.preferredCategories,
      'is_personalized': instance.isPersonalized,
      'last_interaction_at': instance.lastInteractionAt,
    };

ChatbotAction _$ChatbotActionFromJson(Map<String, dynamic> json) =>
    ChatbotAction(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String?,
      actionConfig: json['action_config'] as Map<String, dynamic>?,
      requiredParams:
          (json['required_params'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      optionalParams:
          (json['optional_params'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      executionFunction: json['execution_function'] as String?,
      isActive: json['is_active'] as bool?,
      usageCount: (json['usage_count'] as num?)?.toInt(),
      successCount: (json['success_count'] as num?)?.toInt(),
      failureCount: (json['failure_count'] as num?)?.toInt(),
      successRate: (json['success_rate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChatbotActionToJson(ChatbotAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'action_type': instance.actionType,
      'description': instance.description,
      'action_config': instance.actionConfig,
      'required_params': instance.requiredParams,
      'optional_params': instance.optionalParams,
      'execution_function': instance.executionFunction,
      'is_active': instance.isActive,
      'usage_count': instance.usageCount,
      'success_count': instance.successCount,
      'failure_count': instance.failureCount,
      'success_rate': instance.successRate,
    };

ChatbotActionExecution _$ChatbotActionExecutionFromJson(
  Map<String, dynamic> json,
) => ChatbotActionExecution(
  id: (json['id'] as num).toInt(),
  actionId: (json['action_id'] as num).toInt(),
  actionName: json['action_name'] as String,
  actionType: json['action_type'] as String,
  sessionId: json['session_id'] as String,
  userId: (json['user_id'] as num?)?.toInt(),
  parameters: json['parameters'] as Map<String, dynamic>?,
  result: json['result'] as Map<String, dynamic>?,
  status: json['status'] as String?,
  errorMessage: json['error_message'] as String?,
  executionTime: (json['execution_time'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ChatbotActionExecutionToJson(
  ChatbotActionExecution instance,
) => <String, dynamic>{
  'id': instance.id,
  'action_id': instance.actionId,
  'action_name': instance.actionName,
  'action_type': instance.actionType,
  'session_id': instance.sessionId,
  'user_id': instance.userId,
  'parameters': instance.parameters,
  'result': instance.result,
  'status': instance.status,
  'error_message': instance.errorMessage,
  'execution_time': instance.executionTime,
};

EnhancedChatbotResponse _$EnhancedChatbotResponseFromJson(
  Map<String, dynamic> json,
) => EnhancedChatbotResponse(
  response: json['response'] as String,
  confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
  confidence: (json['confidence'] as num?)?.toDouble(),
  relatedQuestions:
      (json['related_questions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
  category: json['category'] as String?,
  sessionId: json['session_id'] as String?,
  messageId: (json['message_id'] as num?)?.toInt(),
  isFallback: json['is_fallback'] as bool?,
  intent: json['intent'] as String?,
  intentConfidence: (json['intent_confidence'] as num?)?.toDouble(),
  entities:
      (json['entities'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
  sentiment: json['sentiment'] as String?,
  sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
  actionResult: json['action_result'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$EnhancedChatbotResponseToJson(
  EnhancedChatbotResponse instance,
) => <String, dynamic>{
  'response': instance.response,
  'confidence_score': instance.confidenceScore,
  'confidence': instance.confidence,
  'related_questions': instance.relatedQuestions,
  'category': instance.category,
  'session_id': instance.sessionId,
  'message_id': instance.messageId,
  'is_fallback': instance.isFallback,
  'intent': instance.intent,
  'intent_confidence': instance.intentConfidence,
  'entities': instance.entities,
  'sentiment': instance.sentiment,
  'sentiment_score': instance.sentimentScore,
  'action_result': instance.actionResult,
};

AnswerQualityMetrics _$AnswerQualityMetricsFromJson(
  Map<String, dynamic> json,
) => AnswerQualityMetrics(
  questionId: (json['question_id'] as num?)?.toInt(),
  totalFeedback: (json['total_feedback'] as num?)?.toInt(),
  averageRating: (json['average_rating'] as num?)?.toDouble(),
  usageCount: (json['usage_count'] as num?)?.toInt(),
  qualityScore: (json['quality_score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AnswerQualityMetricsToJson(
  AnswerQualityMetrics instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'total_feedback': instance.totalFeedback,
  'average_rating': instance.averageRating,
  'usage_count': instance.usageCount,
  'quality_score': instance.qualityScore,
};

ChatbotUserStatistics _$ChatbotUserStatisticsFromJson(
  Map<String, dynamic> json,
) => ChatbotUserStatistics(
  totalInteractions: (json['total_interactions'] as num?)?.toInt(),
  totalSessions: (json['total_sessions'] as num?)?.toInt(),
  averageRating: (json['average_rating'] as num?)?.toDouble(),
  commonTopics:
      (json['common_topics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  preferredCategories:
      (json['preferred_categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  totalSessionsCount: (json['total_sessions_count'] as num?)?.toInt(),
  totalMessagesCount: (json['total_messages_count'] as num?)?.toInt(),
  lastInteractionAt: json['last_interaction_at'] as String?,
);

Map<String, dynamic> _$ChatbotUserStatisticsToJson(
  ChatbotUserStatistics instance,
) => <String, dynamic>{
  'total_interactions': instance.totalInteractions,
  'total_sessions': instance.totalSessions,
  'average_rating': instance.averageRating,
  'common_topics': instance.commonTopics,
  'preferred_categories': instance.preferredCategories,
  'total_sessions_count': instance.totalSessionsCount,
  'total_messages_count': instance.totalMessagesCount,
  'last_interaction_at': instance.lastInteractionAt,
};
