"""
Gamification Service for managing achievements, points, and rewards
"""
from typing import List, Optional, Dict
from django.contrib.auth import get_user_model
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
from apps.gamification.models import (
    Achievement, UserAchievement, UserPoints, PointTransaction,
    Reward, RewardRedemption, UserStreak, Leaderboard
)
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class GamificationService:
    """Main service for gamification features"""
    
    @staticmethod
    def initialize_user_achievements(user):
        """Initialize all achievements for a new user"""
        achievements = Achievement.objects.filter(is_active=True)
        for achievement in achievements:
            UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0, 'is_unlocked': False}
            )
    
    @staticmethod
    def check_and_unlock_achievements(user, achievement_type: str, metadata: Optional[Dict] = None):
        """Check if user qualifies for any achievements and unlock them"""
        achievements = Achievement.objects.filter(
            achievement_type=achievement_type,
            is_active=True
        )
        
        unlocked = []
        for achievement in achievements:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0, 'is_unlocked': False}
            )
            
            if user_achievement.is_unlocked:
                continue
            
            # Update progress based on achievement requirements
            progress_updated = GamificationService._update_achievement_progress(
                user_achievement, achievement, metadata
            )
            
            if progress_updated and GamificationService._check_achievement_unlocked(user_achievement, achievement):
                user_achievement.unlock()
                unlocked.append(user_achievement)
        
        return unlocked
    
    @staticmethod
    def _update_achievement_progress(user_achievement, achievement, metadata):
        """Update achievement progress"""
        requirements = achievement.requirements or {}
        required_count = requirements.get('count', 1)
        
        # Get current count based on achievement type
        current_count = GamificationService._get_current_count(
            user_achievement.user,
            achievement.achievement_type,
            metadata
        )
        
        user_achievement.progress = min(current_count, required_count)
        user_achievement.save()
        
        return current_count >= required_count
    
    @staticmethod
    def _get_current_count(user, achievement_type, metadata):
        """Get current count for achievement type"""
        if achievement_type == 'study_group_created':
            from apps.study_groups.models import StudyGroup
            return StudyGroup.objects.filter(created_by=user).count()
        elif achievement_type == 'study_group_joined':
            from apps.study_groups.models import GroupMembership
            return GroupMembership.objects.filter(user=user).count()
        elif achievement_type == 'complaint_submitted':
            from apps.complaints.models import Complaint
            return Complaint.objects.filter(complaint_id__startswith=f'CMP_{user.id}').count()
        elif achievement_type == 'feedback_submitted':
            from apps.feedback.models import Feedback
            return Feedback.objects.filter(user=user).count()
        elif achievement_type == 'event_created':
            from apps.calendars.models import CalendarEvent
            return CalendarEvent.objects.filter(created_by=user).count()
        elif achievement_type == 'points_milestone':
            try:
                points = user.points
                return points.total_points
            except UserPoints.DoesNotExist:
                return 0
        elif achievement_type == 'streak_daily':
            try:
                return user.streak.current_streak
            except UserStreak.DoesNotExist:
                return 0
        else:
            return metadata.get('count', 0) if metadata else 0
    
    @staticmethod
    def _check_achievement_unlocked(user_achievement, achievement):
        """Check if achievement should be unlocked"""
        requirements = achievement.requirements or {}
        required_count = requirements.get('count', 1)
        return user_achievement.progress >= required_count
    
    @staticmethod
    def award_points_for_action(user, action_type: str, amount: int, description: str = None):
        """Award points for a specific action"""
        return UserPoints.award_points(user, amount, action_type, description)
    
    @staticmethod
    def get_user_stats(user):
        """Get comprehensive user gamification stats"""
        try:
            points = user.points
        except UserPoints.DoesNotExist:
            points = UserPoints.objects.create(user=user)
        
        try:
            streak = user.streak
        except UserStreak.DoesNotExist:
            streak = UserStreak.objects.create(user=user)
        
        achievements = UserAchievement.objects.filter(user=user)
        unlocked_count = achievements.filter(is_unlocked=True).count()
        total_achievements = Achievement.objects.filter(is_active=True).count()
        
        return {
            'total_points': points.total_points,
            'current_points': points.current_points,
            'lifetime_points': points.lifetime_points,
            'current_streak': streak.current_streak,
            'longest_streak': streak.longest_streak,
            'achievements_unlocked': unlocked_count,
            'achievements_total': total_achievements,
            'achievements_progress': (unlocked_count / total_achievements * 100) if total_achievements > 0 else 0,
        }
    
    @staticmethod
    def redeem_reward(user, reward_id: int):
        """Redeem a reward for points"""
        try:
            reward = Reward.objects.get(id=reward_id, is_active=True)
        except Reward.DoesNotExist:
            raise ValueError("Reward not found or inactive")
        
        try:
            points = user.points
        except UserPoints.DoesNotExist:
            points = UserPoints.objects.create(user=user)
        
        if points.current_points < reward.points_cost:
            raise ValueError("Insufficient points")
        
        # Check redemption limit
        if reward.redemption_limit:
            user_redemptions = RewardRedemption.objects.filter(
                user=user,
                reward=reward,
                status__in=['pending', 'approved', 'fulfilled']
            ).count()
            
            if user_redemptions >= reward.redemption_limit:
                raise ValueError("Redemption limit reached")
        
        # Check stock
        if reward.stock_quantity is not None:
            total_redemptions = RewardRedemption.objects.filter(
                reward=reward,
                status__in=['pending', 'approved', 'fulfilled']
            ).count()
            
            if total_redemptions >= reward.stock_quantity:
                raise ValueError("Reward out of stock")
        
        # Deduct points
        points.current_points -= reward.points_cost
        points.save()
        
        # Create redemption
        redemption = RewardRedemption.objects.create(
            user=user,
            reward=reward,
            points_spent=reward.points_cost,
            status='pending'
        )
        
        # Create transaction record
        PointTransaction.objects.create(
            user=user,
            amount=-reward.points_cost,
            source='reward_redemption',
            description=f"Redeemed: {reward.name}",
            balance_after=points.total_points,
            related_object_type='reward_redemption',
            related_object_id=redemption.id,
        )
        
        return redemption

















