"""
Serializers for gamification app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Achievement, UserAchievement, UserPoints, PointTransaction,
    Reward, RewardRedemption, UserStreak, Leaderboard
)

User = get_user_model()


class AchievementSerializer(serializers.ModelSerializer):
    """Serializer for Achievement"""
    
    class Meta:
        model = Achievement
        fields = [
            'id', 'name', 'description', 'achievement_type', 'difficulty',
            'icon', 'points_reward', 'is_active', 'requirements',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class UserAchievementSerializer(serializers.ModelSerializer):
    """Serializer for UserAchievement"""
    achievement = AchievementSerializer(read_only=True)
    achievement_id = serializers.IntegerField(write_only=True, required=False)
    progress_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = UserAchievement
        fields = [
            'id', 'user', 'achievement', 'achievement_id',
            'progress', 'is_unlocked', 'unlocked_at',
            'progress_percentage', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at', 'unlocked_at']
    
    def get_progress_percentage(self, obj):
        requirements = obj.achievement.requirements or {}
        required = requirements.get('count', 1)
        if required == 0:
            return 100.0
        return min((obj.progress / required) * 100, 100.0)


class UserPointsSerializer(serializers.ModelSerializer):
    """Serializer for UserPoints"""
    
    class Meta:
        model = UserPoints
        fields = [
            'id', 'user', 'total_points', 'current_points',
            'lifetime_points', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class PointTransactionSerializer(serializers.ModelSerializer):
    """Serializer for PointTransaction"""
    
    class Meta:
        model = PointTransaction
        fields = [
            'id', 'user', 'amount', 'source', 'description',
            'balance_after', 'related_object_type', 'related_object_id',
            'created_at',
        ]
        read_only_fields = ['user', 'created_at']


class RewardSerializer(serializers.ModelSerializer):
    """Serializer for Reward"""
    
    class Meta:
        model = Reward
        fields = [
            'id', 'name', 'description', 'reward_type', 'points_cost',
            'icon', 'is_active', 'stock_quantity', 'redemption_limit',
            'metadata', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class RewardRedemptionSerializer(serializers.ModelSerializer):
    """Serializer for RewardRedemption"""
    reward = RewardSerializer(read_only=True)
    reward_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = RewardRedemption
        fields = [
            'id', 'user', 'reward', 'reward_id', 'points_spent',
            'status', 'redeemed_at', 'fulfilled_at', 'notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'points_spent', 'redeemed_at', 'created_at', 'updated_at']


class UserStreakSerializer(serializers.ModelSerializer):
    """Serializer for UserStreak"""
    
    class Meta:
        model = UserStreak
        fields = [
            'id', 'user', 'current_streak', 'longest_streak',
            'last_login_date', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class LeaderboardEntrySerializer(serializers.ModelSerializer):
    """Serializer for Leaderboard"""
    user = serializers.SerializerMethodField()
    
    class Meta:
        model = Leaderboard
        fields = [
            'id', 'user', 'leaderboard_type', 'period',
            'score', 'rank', 'period_start', 'period_end',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_user(self, obj):
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'first_name': obj.user.first_name,
            'last_name': obj.user.last_name,
        }


class UserGamificationStatsSerializer(serializers.Serializer):
    """Serializer for user gamification statistics"""
    total_points = serializers.IntegerField()
    current_points = serializers.IntegerField()
    lifetime_points = serializers.IntegerField()
    current_streak = serializers.IntegerField()
    longest_streak = serializers.IntegerField()
    achievements_unlocked = serializers.IntegerField()
    achievements_total = serializers.IntegerField()
    achievements_progress = serializers.FloatField()

















