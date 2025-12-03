import 'package:json_annotation/json_annotation.dart';

part 'recommendation_model.g.dart';

/// Recommendation model
@JsonSerializable()
class Recommendation {
  final int id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'content_type_display')
  final String? contentTypeDisplay;
  @JsonKey(name: 'content_id')
  final int contentId;
  @JsonKey(name: 'content_title')
  final String? contentTitle;
  @JsonKey(name: 'recommendation_type')
  final String recommendationType;
  @JsonKey(name: 'recommendation_type_display')
  final String? recommendationTypeDisplay;
  final double score;
  final String? reason;
  @JsonKey(name: 'is_dismissed')
  final bool isDismissed;
  @JsonKey(name: 'is_viewed')
  final bool isViewed;
  @JsonKey(name: 'is_interacted')
  final bool isInteracted;
  final Map<String, dynamic>? feedback;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Recommendation({
    required this.id,
    this.userId,
    required this.contentType,
    this.contentTypeDisplay,
    required this.contentId,
    this.contentTitle,
    required this.recommendationType,
    this.recommendationTypeDisplay,
    required this.score,
    this.reason,
    this.isDismissed = false,
    this.isViewed = false,
    this.isInteracted = false,
    this.feedback,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}

/// User preference model
@JsonSerializable()
class UserPreference {
  final int id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'content_type_display')
  final String? contentTypeDisplay;
  final Map<String, dynamic>? preferences;
  final List<String>? interests;
  @JsonKey(name: 'behavior_patterns')
  final Map<String, dynamic>? behaviorPatterns;
  @JsonKey(name: 'weight_preferences')
  final Map<String, dynamic>? weightPreferences;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  UserPreference({
    required this.id,
    this.userId,
    required this.contentType,
    this.contentTypeDisplay,
    this.preferences,
    this.interests,
    this.behaviorPatterns,
    this.weightPreferences,
    this.createdAt,
    this.updatedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferenceToJson(this);
}

/// Content interaction model
@JsonSerializable()
class ContentInteraction {
  final int id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'content_type_display')
  final String? contentTypeDisplay;
  @JsonKey(name: 'content_id')
  final int contentId;
  @JsonKey(name: 'interaction_type')
  final String interactionType;
  @JsonKey(name: 'interaction_type_display')
  final String? interactionTypeDisplay;
  final int? rating;
  final int? duration;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  ContentInteraction({
    required this.id,
    this.userId,
    required this.contentType,
    this.contentTypeDisplay,
    required this.contentId,
    required this.interactionType,
    this.interactionTypeDisplay,
    this.rating,
    this.duration,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory ContentInteraction.fromJson(Map<String, dynamic> json) =>
      _$ContentInteractionFromJson(json);

  Map<String, dynamic> toJson() => _$ContentInteractionToJson(this);
}

/// Popular item model
@JsonSerializable()
class PopularItem {
  final int id;
  @JsonKey(name: 'interaction_count')
  final int? interactionCount;
  @JsonKey(name: 'popularity_score')
  final double? popularityScore;
  @JsonKey(name: 'avg_rating')
  final double? avgRating;

  PopularItem({
    required this.id,
    this.interactionCount,
    this.popularityScore,
    this.avgRating,
  });

  factory PopularItem.fromJson(Map<String, dynamic> json) =>
      _$PopularItemFromJson(json);

  Map<String, dynamic> toJson() => _$PopularItemToJson(this);
}

/// Trending item model
@JsonSerializable()
class TrendingItem {
  final int id;
  @JsonKey(name: 'recent_interactions')
  final int? recentInteractions;
  @JsonKey(name: 'trending_score')
  final double? trendingScore;
  @JsonKey(name: 'avg_rating')
  final double? avgRating;

  TrendingItem({
    required this.id,
    this.recentInteractions,
    this.trendingScore,
    this.avgRating,
  });

  factory TrendingItem.fromJson(Map<String, dynamic> json) =>
      _$TrendingItemFromJson(json);

  Map<String, dynamic> toJson() => _$TrendingItemToJson(this);
}

