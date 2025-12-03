class Achievement {
  final int? id;
  final String name;
  final String description;
  final String achievementType;
  final String difficulty;
  final String? icon;
  final int pointsReward;
  final bool isActive;
  final Map<String, dynamic>? requirements;

  Achievement({
    this.id,
    required this.name,
    required this.description,
    required this.achievementType,
    required this.difficulty,
    this.icon,
    required this.pointsReward,
    required this.isActive,
    this.requirements,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      achievementType: json['achievement_type'],
      difficulty: json['difficulty'],
      icon: json['icon'],
      pointsReward: safeInt(json['points_reward']),
      isActive: json['is_active'] ?? false,
      requirements: json['requirements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'achievement_type': achievementType,
      'difficulty': difficulty,
      'icon': icon,
      'points_reward': pointsReward,
      'is_active': isActive,
      'requirements': requirements,
    };
  }
}

class UserAchievement {
  final int? id;
  final Achievement achievement;
  final int progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progressPercentage;

  UserAchievement({
    this.id,
    required this.achievement,
    required this.progress,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progressPercentage,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return UserAchievement(
      id: json['id'],
      achievement: Achievement.fromJson(json['achievement']),
      progress: safeInt(json['progress']),
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class UserPoints {
  final int? id;
  final int totalPoints;
  final int currentPoints;
  final int lifetimePoints;

  UserPoints({
    this.id,
    required this.totalPoints,
    required this.currentPoints,
    required this.lifetimePoints,
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return UserPoints(
      id: json['id'],
      totalPoints: safeInt(json['total_points']),
      currentPoints: safeInt(json['current_points']),
      lifetimePoints: safeInt(json['lifetime_points']),
    );
  }
}

class PointTransaction {
  final int? id;
  final int amount;
  final String source;
  final String? description;
  final int balanceAfter;
  final DateTime createdAt;

  PointTransaction({
    this.id,
    required this.amount,
    required this.source,
    this.description,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return PointTransaction(
      id: json['id'],
      amount: safeInt(json['amount']),
      source: json['source'] ?? '',
      description: json['description'],
      balanceAfter: safeInt(json['balance_after']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Reward {
  final int? id;
  final String name;
  final String description;
  final String rewardType;
  final int pointsCost;
  final String? icon;
  final bool isActive;
  final int? stockQuantity;
  final int? redemptionLimit;
  final Map<String, dynamic>? metadata;

  Reward({
    this.id,
    required this.name,
    required this.description,
    required this.rewardType,
    required this.pointsCost,
    this.icon,
    required this.isActive,
    this.stockQuantity,
    this.redemptionLimit,
    this.metadata,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return Reward(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      rewardType: json['reward_type'] ?? '',
      pointsCost: safeInt(json['points_cost']),
      icon: json['icon'],
      isActive: json['is_active'] ?? false,
      stockQuantity: json['stock_quantity'],
      redemptionLimit: json['redemption_limit'],
      metadata: json['metadata'],
    );
  }
}

class RewardRedemption {
  final int? id;
  final Reward reward;
  final int pointsSpent;
  final String status;
  final DateTime redeemedAt;
  final DateTime? fulfilledAt;

  RewardRedemption({
    this.id,
    required this.reward,
    required this.pointsSpent,
    required this.status,
    required this.redeemedAt,
    this.fulfilledAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return RewardRedemption(
      id: json['id'],
      reward: Reward.fromJson(json['reward']),
      pointsSpent: safeInt(json['points_spent']),
      status: json['status'] ?? 'pending',
      redeemedAt: DateTime.parse(json['redeemed_at']),
      fulfilledAt: json['fulfilled_at'] != null
          ? DateTime.parse(json['fulfilled_at'])
          : null,
    );
  }
}

class UserStreak {
  final int? id;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;

  UserStreak({
    this.id,
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return UserStreak(
      id: json['id'],
      currentStreak: safeInt(json['current_streak']),
      longestStreak: safeInt(json['longest_streak']),
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.parse(json['last_login_date'])
          : null,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final Map<String, dynamic> user;
  final int score;
  final int? points;
  final int? achievements;
  final int? streak;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.score,
    this.points,
    this.achievements,
    this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return LeaderboardEntry(
      rank: safeInt(json['rank']),
      user: json['user'] ?? {},
      score: safeInt(json['score']),
      points: json['points'] != null ? safeInt(json['points']) : null,
      achievements: json['achievements'] != null ? safeInt(json['achievements']) : null,
      streak: json['streak'] != null ? safeInt(json['streak']) : null,
    );
  }
}

class UserGamificationStats {
  final int totalPoints;
  final int currentPoints;
  final int lifetimePoints;
  final int currentStreak;
  final int longestStreak;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final double achievementsProgress;

  UserGamificationStats({
    required this.totalPoints,
    required this.currentPoints,
    required this.lifetimePoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.achievementsProgress,
  });

  factory UserGamificationStats.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length; // If it's a list, return its length
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return UserGamificationStats(
      totalPoints: safeInt(json['total_points']),
      currentPoints: safeInt(json['current_points']),
      lifetimePoints: safeInt(json['lifetime_points']),
      currentStreak: safeInt(json['current_streak']),
      longestStreak: safeInt(json['longest_streak']),
      achievementsUnlocked: safeInt(json['achievements_unlocked']),
      achievementsTotal: safeInt(json['achievements_total']),
      achievementsProgress: (json['achievements_progress'] ?? 0.0).toDouble(),
    );
  }
}


