// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    Recommendation(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      contentType: json['content_type'] as String,
      contentTypeDisplay: json['content_type_display'] as String?,
      contentId: (json['content_id'] as num).toInt(),
      contentTitle: json['content_title'] as String?,
      recommendationType: json['recommendation_type'] as String,
      recommendationTypeDisplay: json['recommendation_type_display'] as String?,
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String?,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      isViewed: json['is_viewed'] as bool? ?? false,
      isInteracted: json['is_interacted'] as bool? ?? false,
      feedback: json['feedback'] as Map<String, dynamic>?,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$RecommendationToJson(Recommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'content_type': instance.contentType,
      'content_type_display': instance.contentTypeDisplay,
      'content_id': instance.contentId,
      'content_title': instance.contentTitle,
      'recommendation_type': instance.recommendationType,
      'recommendation_type_display': instance.recommendationTypeDisplay,
      'score': instance.score,
      'reason': instance.reason,
      'is_dismissed': instance.isDismissed,
      'is_viewed': instance.isViewed,
      'is_interacted': instance.isInteracted,
      'feedback': instance.feedback,
      'expires_at': instance.expiresAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

UserPreference _$UserPreferenceFromJson(Map<String, dynamic> json) =>
    UserPreference(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      contentType: json['content_type'] as String,
      contentTypeDisplay: json['content_type_display'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      behaviorPatterns: json['behavior_patterns'] as Map<String, dynamic>?,
      weightPreferences: json['weight_preferences'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UserPreferenceToJson(UserPreference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'content_type': instance.contentType,
      'content_type_display': instance.contentTypeDisplay,
      'preferences': instance.preferences,
      'interests': instance.interests,
      'behavior_patterns': instance.behaviorPatterns,
      'weight_preferences': instance.weightPreferences,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

ContentInteraction _$ContentInteractionFromJson(Map<String, dynamic> json) =>
    ContentInteraction(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      contentType: json['content_type'] as String,
      contentTypeDisplay: json['content_type_display'] as String?,
      contentId: (json['content_id'] as num).toInt(),
      interactionType: json['interaction_type'] as String,
      interactionTypeDisplay: json['interaction_type_display'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$ContentInteractionToJson(ContentInteraction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'content_type': instance.contentType,
      'content_type_display': instance.contentTypeDisplay,
      'content_id': instance.contentId,
      'interaction_type': instance.interactionType,
      'interaction_type_display': instance.interactionTypeDisplay,
      'rating': instance.rating,
      'duration': instance.duration,
      'metadata': instance.metadata,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

PopularItem _$PopularItemFromJson(Map<String, dynamic> json) => PopularItem(
  id: (json['id'] as num).toInt(),
  interactionCount: (json['interaction_count'] as num?)?.toInt(),
  popularityScore: (json['popularity_score'] as num?)?.toDouble(),
  avgRating: (json['avg_rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PopularItemToJson(PopularItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'interaction_count': instance.interactionCount,
      'popularity_score': instance.popularityScore,
      'avg_rating': instance.avgRating,
    };

TrendingItem _$TrendingItemFromJson(Map<String, dynamic> json) => TrendingItem(
  id: (json['id'] as num).toInt(),
  recentInteractions: (json['recent_interactions'] as num?)?.toInt(),
  trendingScore: (json['trending_score'] as num?)?.toDouble(),
  avgRating: (json['avg_rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TrendingItemToJson(TrendingItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recent_interactions': instance.recentInteractions,
      'trending_score': instance.trendingScore,
      'avg_rating': instance.avgRating,
    };
