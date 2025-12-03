/// Models for Awards & Recognition

class AwardCategory {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final bool isActive;
  final int order;
  final int? awardsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  AwardCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.color,
    required this.isActive,
    required this.order,
    this.awardsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AwardCategory.fromJson(Map<String, dynamic> json) {
    return AwardCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      isActive: json['is_active'],
      order: json['order'],
      awardsCount: json['awards_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Award {
  final int id;
  final String name;
  final String awardType;
  final int? categoryId;
  final String? categoryName;
  final String description;
  final String? criteria;
  final String? icon;
  final String? badgeImageUrl;
  final int pointsValue;
  final bool isActive;
  final bool isFeatured;
  final int? userAwardsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Award({
    required this.id,
    required this.name,
    required this.awardType,
    this.categoryId,
    this.categoryName,
    required this.description,
    this.criteria,
    this.icon,
    this.badgeImageUrl,
    required this.pointsValue,
    required this.isActive,
    required this.isFeatured,
    this.userAwardsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      id: json['id'],
      name: json['name'],
      awardType: json['award_type'],
      categoryId: json['category'],
      categoryName: json['category_name'],
      description: json['description'],
      criteria: json['criteria'],
      icon: json['icon'],
      badgeImageUrl: json['badge_image_url'],
      pointsValue: json['points_value'],
      isActive: json['is_active'],
      isFeatured: json['is_featured'],
      userAwardsCount: json['user_awards_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UserAward {
  final int id;
  final int awardId;
  final String? awardName;
  final String? awardType;
  final int userId;
  final String? userName;
  final int? awardedById;
  final String? awardedByName;
  final DateTime awardedAt;
  final String? reason;
  final String? certificateUrl;
  final bool isPublic;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAward({
    required this.id,
    required this.awardId,
    this.awardName,
    this.awardType,
    required this.userId,
    this.userName,
    this.awardedById,
    this.awardedByName,
    required this.awardedAt,
    this.reason,
    this.certificateUrl,
    required this.isPublic,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAward.fromJson(Map<String, dynamic> json) {
    return UserAward(
      id: json['id'],
      awardId: json['award'],
      awardName: json['award_name'],
      awardType: json['award_type'],
      userId: json['user'],
      userName: json['user_name'],
      awardedById: json['awarded_by'],
      awardedByName: json['awarded_by_name'],
      awardedAt: DateTime.parse(json['awarded_at']),
      reason: json['reason'],
      certificateUrl: json['certificate_url'],
      isPublic: json['is_public'],
      isFeatured: json['is_featured'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class RecognitionPost {
  final int id;
  final String title;
  final String postType;
  final String content;
  final String? featuredImageUrl;
  final List<int> recognizedUserIds;
  final List<String>? recognizedUsersNames;
  final int? relatedAwardId;
  final String? relatedAwardName;
  final int? createdById;
  final String? createdByName;
  final bool isPublished;
  final DateTime? publishedAt;
  final int viewsCount;
  final int likesCount;
  final bool? isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecognitionPost({
    required this.id,
    required this.title,
    required this.postType,
    required this.content,
    this.featuredImageUrl,
    required this.recognizedUserIds,
    this.recognizedUsersNames,
    this.relatedAwardId,
    this.relatedAwardName,
    this.createdById,
    this.createdByName,
    required this.isPublished,
    this.publishedAt,
    required this.viewsCount,
    required this.likesCount,
    this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecognitionPost.fromJson(Map<String, dynamic> json) {
    return RecognitionPost(
      id: json['id'],
      title: json['title'],
      postType: json['post_type'],
      content: json['content'],
      featuredImageUrl: json['featured_image_url'],
      recognizedUserIds: List<int>.from(json['recognized_users'] ?? []),
      recognizedUsersNames: json['recognized_users_names'] != null
          ? List<String>.from(json['recognized_users_names'])
          : null,
      relatedAwardId: json['related_award'],
      relatedAwardName: json['related_award_name'],
      createdById: json['created_by'],
      createdByName: json['created_by_name'],
      isPublished: json['is_published'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      viewsCount: json['views_count'],
      likesCount: json['likes_count'],
      isLiked: json['is_liked'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AwardNomination {
  final int id;
  final String nominationId;
  final int awardId;
  final String? awardName;
  final int nomineeId;
  final String? nomineeName;
  final int nominatedById;
  final String? nominatedByName;
  final String status;
  final String nominationReason;
  final List<Map<String, dynamic>> supportingEvidence;
  final int? reviewedById;
  final String? reviewedByName;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AwardNomination({
    required this.id,
    required this.nominationId,
    required this.awardId,
    this.awardName,
    required this.nomineeId,
    this.nomineeName,
    required this.nominatedById,
    this.nominatedByName,
    required this.status,
    required this.nominationReason,
    required this.supportingEvidence,
    this.reviewedById,
    this.reviewedByName,
    this.reviewNotes,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AwardNomination.fromJson(Map<String, dynamic> json) {
    return AwardNomination(
      id: json['id'],
      nominationId: json['nomination_id'],
      awardId: json['award'],
      awardName: json['award_name'],
      nomineeId: json['nominee'],
      nomineeName: json['nominee_name'],
      nominatedById: json['nominated_by'],
      nominatedByName: json['nominated_by_name'],
      status: json['status'],
      nominationReason: json['nomination_reason'],
      supportingEvidence: List<Map<String, dynamic>>.from(json['supporting_evidence'] ?? []),
      reviewedById: json['reviewed_by'],
      reviewedByName: json['reviewed_by_name'],
      reviewNotes: json['review_notes'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AwardCeremony {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? location;
  final bool isVirtual;
  final String? virtualLink;
  final List<int> awardIds;
  final List<String>? awardsList;
  final int? createdById;
  final String? createdByName;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AwardCeremony({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.location,
    required this.isVirtual,
    this.virtualLink,
    required this.awardIds,
    this.awardsList,
    this.createdById,
    this.createdByName,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AwardCeremony.fromJson(Map<String, dynamic> json) {
    return AwardCeremony(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      location: json['location'],
      isVirtual: json['is_virtual'],
      virtualLink: json['virtual_link'],
      awardIds: List<int>.from(json['awards'] ?? []),
      awardsList: json['awards_list'] != null
          ? List<String>.from(json['awards_list'])
          : null,
      createdById: json['created_by'],
      createdByName: json['created_by_name'],
      isPublished: json['is_published'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UserAwardsSummary {
  final int totalAwards;
  final Map<String, int> byType;
  final List<Map<String, dynamic>> featuredAwards;
  final List<Map<String, dynamic>> recentAwards;

  UserAwardsSummary({
    required this.totalAwards,
    required this.byType,
    required this.featuredAwards,
    required this.recentAwards,
  });

  factory UserAwardsSummary.fromJson(Map<String, dynamic> json) {
    return UserAwardsSummary(
      totalAwards: json['total_awards'],
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      featuredAwards: List<Map<String, dynamic>>.from(json['featured_awards'] ?? []),
      recentAwards: List<Map<String, dynamic>>.from(json['recent_awards'] ?? []),
    );
  }
}

















