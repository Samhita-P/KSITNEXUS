"""
Leaderboard Service for calculating and managing leaderboards
"""
from typing import List, Dict, Optional
from django.contrib.auth import get_user_model
from django.db.models import Sum, Count, Q, F
from django.utils import timezone
from datetime import timedelta
from apps.gamification.models import Leaderboard, UserPoints, UserAchievement, UserStreak
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class LeaderboardService:
    """Service for managing leaderboards"""
    
    @staticmethod
    def calculate_leaderboard(leaderboard_type: str, period: str = 'all_time', limit: int = 100):
        """Calculate leaderboard for a specific type and period"""
        now = timezone.now()
        period_start = None
        period_end = None
        
        if period == 'daily':
            period_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            period_end = now
        elif period == 'weekly':
            period_start = now - timedelta(days=now.weekday())
            period_start = period_start.replace(hour=0, minute=0, second=0, microsecond=0)
            period_end = now
        elif period == 'monthly':
            period_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            period_end = now
        
        if leaderboard_type == 'points':
            return LeaderboardService._calculate_points_leaderboard(period, period_start, period_end, limit)
        elif leaderboard_type == 'achievements':
            return LeaderboardService._calculate_achievements_leaderboard(period, period_start, period_end, limit)
        elif leaderboard_type == 'streak':
            return LeaderboardService._calculate_streak_leaderboard(period, period_start, period_end, limit)
        elif leaderboard_type == 'overall':
            return LeaderboardService._calculate_overall_leaderboard(period, period_start, period_end, limit)
        else:
            return []
    
    @staticmethod
    def _calculate_points_leaderboard(period, period_start, period_end, limit):
        """Calculate points-based leaderboard"""
        if period == 'all_time':
            users = UserPoints.objects.all().order_by('-total_points')[:limit]
        else:
            # For time-based periods, calculate from transactions
            from apps.gamification.models import PointTransaction
            
            transactions = PointTransaction.objects.filter(
                created_at__gte=period_start,
                created_at__lte=period_end,
                amount__gt=0
            )
            
            user_scores = transactions.values('user').annotate(
                score=Sum('amount')
            ).order_by('-score')[:limit]
            
            user_ids = [item['user'] for item in user_scores]
            users = UserPoints.objects.filter(user_id__in=user_ids).order_by('-total_points')
        
        leaderboard = []
        rank = 1
        for user_points in users:
            leaderboard.append({
                'user': user_points.user,
                'score': user_points.total_points if period == 'all_time' else user_points.total_points,
                'rank': rank,
            })
            rank += 1
        
        return leaderboard
    
    @staticmethod
    def _calculate_achievements_leaderboard(period, period_start, period_end, limit):
        """Calculate achievements-based leaderboard"""
        if period == 'all_time':
            achievements = UserAchievement.objects.filter(is_unlocked=True)
        else:
            achievements = UserAchievement.objects.filter(
                is_unlocked=True,
                unlocked_at__gte=period_start,
                unlocked_at__lte=period_end
            )
        
        user_scores = achievements.values('user').annotate(
            score=Count('id')
        ).order_by('-score')[:limit]
        
        leaderboard = []
        rank = 1
        for item in user_scores:
            user = User.objects.get(id=item['user'])
            leaderboard.append({
                'user': user,
                'score': item['score'],
                'rank': rank,
            })
            rank += 1
        
        return leaderboard
    
    @staticmethod
    def _calculate_streak_leaderboard(period, period_start, period_end, limit):
        """Calculate streak-based leaderboard"""
        streaks = UserStreak.objects.all().order_by('-current_streak')[:limit]
        
        leaderboard = []
        rank = 1
        for streak in streaks:
            leaderboard.append({
                'user': streak.user,
                'score': streak.current_streak,
                'rank': rank,
            })
            rank += 1
        
        return leaderboard
    
    @staticmethod
    def _calculate_overall_leaderboard(period, period_start, period_end, limit):
        """Calculate overall leaderboard (combined score)"""
        # Combine points, achievements, and streak for overall score
        users = User.objects.all()
        scores = []
        
        for user in users:
            try:
                points = user.points.total_points
            except:
                points = 0
            
            try:
                achievements = UserAchievement.objects.filter(user=user, is_unlocked=True).count()
            except:
                achievements = 0
            
            try:
                streak = user.streak.current_streak
            except:
                streak = 0
            
            # Weighted score
            overall_score = (points * 0.5) + (achievements * 100) + (streak * 10)
            
            scores.append({
                'user': user,
                'score': overall_score,
                'points': points,
                'achievements': achievements,
                'streak': streak,
            })
        
        scores.sort(key=lambda x: x['score'], reverse=True)
        
        leaderboard = []
        rank = 1
        for item in scores[:limit]:
            leaderboard.append({
                'user': item['user'],
                'score': item['score'],
                'points': item['points'],
                'achievements': item['achievements'],
                'streak': item['streak'],
                'rank': rank,
            })
            rank += 1
        
        return leaderboard
    
    @staticmethod
    def get_user_rank(user, leaderboard_type: str, period: str = 'all_time'):
        """Get user's rank in a leaderboard"""
        leaderboard = LeaderboardService.calculate_leaderboard(leaderboard_type, period)
        
        for entry in leaderboard:
            if entry['user'].id == user.id:
                return entry['rank']
        
        return None
    
    @staticmethod
    def update_leaderboard_cache(leaderboard_type: str, period: str):
        """Update cached leaderboard entries"""
        leaderboard = LeaderboardService.calculate_leaderboard(leaderboard_type, period)
        
        now = timezone.now()
        period_start = None
        period_end = None
        
        if period == 'daily':
            period_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == 'weekly':
            period_start = now - timedelta(days=now.weekday())
            period_start = period_start.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == 'monthly':
            period_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Clear old entries
        Leaderboard.objects.filter(
            leaderboard_type=leaderboard_type,
            period=period,
            period_start=period_start
        ).delete()
        
        # Create new entries
        for entry in leaderboard:
            Leaderboard.objects.create(
                user=entry['user'],
                leaderboard_type=leaderboard_type,
                period=period,
                score=entry['score'],
                rank=entry['rank'],
                period_start=period_start,
                period_end=period_end or now,
            )

















