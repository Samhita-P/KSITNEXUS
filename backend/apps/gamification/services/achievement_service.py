"""
Achievement Service for managing achievements
"""
from typing import List, Optional
from django.contrib.auth import get_user_model
from apps.gamification.models import Achievement, UserAchievement
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class AchievementService:
    """Service for managing achievements"""
    
    @staticmethod
    def get_user_achievements(user, unlocked_only: bool = False):
        """Get all achievements for a user"""
        queryset = UserAchievement.objects.filter(user=user).select_related('achievement')
        
        if unlocked_only:
            queryset = queryset.filter(is_unlocked=True)
        
        return queryset.order_by('-unlocked_at', 'achievement__difficulty')
    
    @staticmethod
    def get_available_achievements(user):
        """Get all available achievements with user progress"""
        achievements = Achievement.objects.filter(is_active=True).order_by('difficulty', 'points_reward')
        result = []
        
        for achievement in achievements:
            try:
                user_achievement = UserAchievement.objects.get(user=user, achievement=achievement)
                result.append({
                    'achievement': achievement,
                    'user_achievement': user_achievement,
                    'progress_percentage': (
                        user_achievement.progress / (achievement.requirements.get('count', 1) or 1) * 100
                    ) if achievement.requirements.get('count') else 0,
                })
            except UserAchievement.DoesNotExist:
                result.append({
                    'achievement': achievement,
                    'user_achievement': None,
                    'progress_percentage': 0,
                })
        
        return result
    
    @staticmethod
    def get_recent_achievements(user, limit: int = 5):
        """Get recently unlocked achievements"""
        return UserAchievement.objects.filter(
            user=user,
            is_unlocked=True
        ).select_related('achievement').order_by('-unlocked_at')[:limit]
    
    @staticmethod
    def get_achievement_progress(user, achievement_id: int):
        """Get progress for a specific achievement"""
        try:
            achievement = Achievement.objects.get(id=achievement_id)
            user_achievement = UserAchievement.objects.get(user=user, achievement=achievement)
            
            requirements = achievement.requirements or {}
            required_count = requirements.get('count', 1)
            
            return {
                'achievement': achievement,
                'user_achievement': user_achievement,
                'progress': user_achievement.progress,
                'required': required_count,
                'progress_percentage': (user_achievement.progress / required_count * 100) if required_count > 0 else 0,
                'is_unlocked': user_achievement.is_unlocked,
            }
        except (Achievement.DoesNotExist, UserAchievement.DoesNotExist):
            return None

















