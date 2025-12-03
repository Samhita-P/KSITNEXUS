from django.contrib import admin
from .models import (
    Achievement, UserAchievement, UserPoints, PointTransaction,
    Reward, RewardRedemption, UserStreak, Leaderboard
)


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ['name', 'achievement_type', 'difficulty', 'points_reward', 'is_active']
    list_filter = ['achievement_type', 'difficulty', 'is_active']
    search_fields = ['name', 'description']
    ordering = ['difficulty', 'points_reward']


@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    list_display = ['user', 'achievement', 'progress', 'is_unlocked', 'unlocked_at']
    list_filter = ['is_unlocked', 'achievement__difficulty', 'achievement__achievement_type']
    search_fields = ['user__username', 'achievement__name']
    readonly_fields = ['unlocked_at']


@admin.register(UserPoints)
class UserPointsAdmin(admin.ModelAdmin):
    list_display = ['user', 'total_points', 'current_points', 'lifetime_points']
    search_fields = ['user__username']
    ordering = ['-total_points']


@admin.register(PointTransaction)
class PointTransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'amount', 'source', 'balance_after', 'created_at']
    list_filter = ['source', 'created_at']
    search_fields = ['user__username', 'description']
    readonly_fields = ['created_at']
    ordering = ['-created_at']


@admin.register(Reward)
class RewardAdmin(admin.ModelAdmin):
    list_display = ['name', 'reward_type', 'points_cost', 'is_active', 'stock_quantity']
    list_filter = ['reward_type', 'is_active']
    search_fields = ['name', 'description']
    ordering = ['points_cost']


@admin.register(RewardRedemption)
class RewardRedemptionAdmin(admin.ModelAdmin):
    list_display = ['user', 'reward', 'points_spent', 'status', 'redeemed_at']
    list_filter = ['status', 'redeemed_at']
    search_fields = ['user__username', 'reward__name']
    readonly_fields = ['redeemed_at']
    ordering = ['-redeemed_at']


@admin.register(UserStreak)
class UserStreakAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_streak', 'longest_streak', 'last_login_date']
    search_fields = ['user__username']
    ordering = ['-current_streak']


@admin.register(Leaderboard)
class LeaderboardAdmin(admin.ModelAdmin):
    list_display = ['user', 'leaderboard_type', 'period', 'score', 'rank']
    list_filter = ['leaderboard_type', 'period']
    search_fields = ['user__username']
    ordering = ['leaderboard_type', 'period', 'rank']

















