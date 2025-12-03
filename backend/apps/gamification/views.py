"""
Views for gamification app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import (
    Achievement, UserAchievement, UserPoints, PointTransaction,
    Reward, RewardRedemption, UserStreak, Leaderboard
)
from .serializers import (
    AchievementSerializer, UserAchievementSerializer, UserPointsSerializer,
    PointTransactionSerializer, RewardSerializer, RewardRedemptionSerializer,
    UserStreakSerializer, LeaderboardEntrySerializer, UserGamificationStatsSerializer
)
from .services.gamification_service import GamificationService
from .services.achievement_service import AchievementService
from .services.leaderboard_service import LeaderboardService

User = get_user_model()


# Achievements
class AchievementListView(generics.ListAPIView):
    """List all achievements"""
    queryset = Achievement.objects.filter(is_active=True)
    serializer_class = AchievementSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return super().get_queryset()
        except Exception as e:
            import traceback
            print(f"Error in AchievementListView.get_queryset: {e}")
            traceback.print_exc()
            return Achievement.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in AchievementListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class UserAchievementListView(generics.ListAPIView):
    """List user's achievements"""
    serializer_class = UserAchievementSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            unlocked_only = self.request.query_params.get('unlocked_only', 'false').lower() == 'true'
            return AchievementService.get_user_achievements(self.request.user, unlocked_only)
        except Exception as e:
            import traceback
            print(f"Error in UserAchievementListView.get_queryset: {e}")
            traceback.print_exc()
            return UserAchievement.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in UserAchievementListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class AvailableAchievementsView(generics.ListAPIView):
    """Get all available achievements with user progress"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        try:
            # Ensure default achievements exist
            self._ensure_default_achievements()
            
            achievements = AchievementService.get_available_achievements(request.user)
            # Create UserAchievement objects for achievements that don't have one yet
            result = []
            for item in achievements:
                if item['user_achievement']:
                    result.append(item['user_achievement'])
                else:
                    # Create a UserAchievement for locked achievements
                    try:
                        user_achievement, _ = UserAchievement.objects.get_or_create(
                            user=request.user,
                            achievement=item['achievement'],
                            defaults={
                                'progress': 0,
                                'is_unlocked': False
                            }
                        )
                        result.append(user_achievement)
                    except Exception:
                        # Skip if there's an error creating UserAchievement
                        continue
            
            serializer = UserAchievementSerializer(result, many=True)
            return Response(serializer.data)
        except Exception as e:
            import traceback
            print(f"Error in AvailableAchievementsView.get: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def _ensure_default_achievements(self):
        """Create default achievements if none exist"""
        try:
            if Achievement.objects.filter(is_active=True).exists():
                return
        except Exception:
            # Table doesn't exist yet, skip creation
            return
        
        default_achievements = [
            {
                'name': 'First Steps',
                'description': 'Complete your first login to the platform',
                'achievement_type': 'first_login',
                'difficulty': 'bronze',
                'icon': 'first_login',
                'points_reward': 10,
                'requirements': {'count': 1, 'type': 'login'},
            },
            {
                'name': 'Profile Master',
                'description': 'Complete your profile with all required information',
                'achievement_type': 'profile_complete',
                'difficulty': 'bronze',
                'icon': 'profile_complete',
                'points_reward': 20,
                'requirements': {'count': 1, 'type': 'profile'},
            },
            {
                'name': 'Group Creator',
                'description': 'Create your first study group',
                'achievement_type': 'study_group_created',
                'difficulty': 'silver',
                'icon': 'study_group_created',
                'points_reward': 50,
                'requirements': {'count': 1, 'type': 'study_group'},
            },
            {
                'name': 'Team Player',
                'description': 'Join 5 study groups',
                'achievement_type': 'study_group_joined',
                'difficulty': 'silver',
                'icon': 'study_group_joined',
                'points_reward': 75,
                'requirements': {'count': 5, 'type': 'study_group'},
            },
            {
                'name': 'Active Participant',
                'description': 'View 10 notices',
                'achievement_type': 'notice_viewed',
                'difficulty': 'bronze',
                'icon': 'notice_viewed',
                'points_reward': 30,
                'requirements': {'count': 10, 'type': 'notice'},
            },
            {
                'name': 'Voice of Change',
                'description': 'Submit 3 complaints',
                'achievement_type': 'complaint_submitted',
                'difficulty': 'silver',
                'icon': 'complaint_submitted',
                'points_reward': 60,
                'requirements': {'count': 3, 'type': 'complaint'},
            },
            {
                'name': 'Feedback Champion',
                'description': 'Submit 5 feedbacks',
                'achievement_type': 'feedback_submitted',
                'difficulty': 'silver',
                'icon': 'feedback_submitted',
                'points_reward': 80,
                'requirements': {'count': 5, 'type': 'feedback'},
            },
            {
                'name': 'Event Organizer',
                'description': 'Create 3 events',
                'achievement_type': 'event_created',
                'difficulty': 'gold',
                'icon': 'event_created',
                'points_reward': 100,
                'requirements': {'count': 3, 'type': 'event'},
            },
            {
                'name': 'Social Butterfly',
                'description': 'Attend 10 events',
                'achievement_type': 'event_attended',
                'difficulty': 'gold',
                'icon': 'event_attended',
                'points_reward': 120,
                'requirements': {'count': 10, 'type': 'event'},
            },
            {
                'name': 'Daily Dedication',
                'description': 'Maintain a 7-day login streak',
                'achievement_type': 'streak_daily',
                'difficulty': 'gold',
                'icon': 'streak_daily',
                'points_reward': 150,
                'requirements': {'count': 7, 'type': 'streak'},
            },
            {
                'name': 'Point Collector',
                'description': 'Earn 500 points',
                'achievement_type': 'points_milestone',
                'difficulty': 'platinum',
                'icon': 'points_milestone',
                'points_reward': 200,
                'requirements': {'count': 500, 'type': 'points'},
            },
        ]
        
        for achievement_data in default_achievements:
            try:
                Achievement.objects.get_or_create(
                    achievement_type=achievement_data['achievement_type'],
                    defaults=achievement_data
                )
            except Exception:
                # Skip if there's an error
                continue


# Points
class UserPointsView(generics.RetrieveAPIView):
    """Get user's points"""
    serializer_class = UserPointsSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        try:
            points, created = UserPoints.objects.get_or_create(user=self.request.user)
            return points
        except Exception as e:
            import traceback
            print(f"Error in UserPointsView.get_object: {e}")
            traceback.print_exc()
            # Return a default UserPoints object
            from django.db import OperationalError
            if isinstance(e, OperationalError):
                # Table doesn't exist - return a mock object
                class MockUserPoints:
                    def __init__(self, user):
                        self.user = user
                        self.total_points = 0
                        self.available_points = 0
                return MockUserPoints(self.request.user)
            raise
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to handle errors gracefully"""
        try:
            return super().retrieve(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in UserPointsView.retrieve: {e}")
            traceback.print_exc()
            return Response(
                {
                    'user': request.user.id,
                    'total_points': 0,
                    'available_points': 0,
                    'lifetime_points': 0,
                },
                status=status.HTTP_200_OK
            )


class PointTransactionListView(generics.ListAPIView):
    """List user's point transactions"""
    serializer_class = PointTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return PointTransaction.objects.filter(user=self.request.user).order_by('-created_at')
        except Exception as e:
            import traceback
            print(f"Error in PointTransactionListView.get_queryset: {e}")
            traceback.print_exc()
            return PointTransaction.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in PointTransactionListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


# Rewards
class RewardListView(generics.ListAPIView):
    """List available rewards"""
    queryset = Reward.objects.filter(is_active=True)
    serializer_class = RewardSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            # Ensure default rewards exist
            self._ensure_default_rewards()
            return super().get_queryset()
        except Exception as e:
            import traceback
            print(f"Error in RewardListView.get_queryset: {e}")
            traceback.print_exc()
            return Reward.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in RewardListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def _ensure_default_rewards(self):
        """Create default rewards if none exist"""
        try:
            if Reward.objects.filter(is_active=True).exists():
                return
        except Exception:
            # Table doesn't exist yet, skip creation
            return
        
        default_rewards = [
            {
                'name': 'Bronze Badge',
                'description': 'Show off your bronze achievement with this exclusive badge',
                'reward_type': 'badge',
                'points_cost': 100,
                'icon': 'badge',
            },
            {
                'name': 'Silver Badge',
                'description': 'Display your silver achievement with this premium badge',
                'reward_type': 'badge',
                'points_cost': 250,
                'icon': 'badge',
            },
            {
                'name': 'Gold Badge',
                'description': 'Showcase your gold achievement with this elite badge',
                'reward_type': 'badge',
                'points_cost': 500,
                'icon': 'badge',
            },
            {
                'name': 'Cafeteria Discount',
                'description': 'Get 10% off on your next cafeteria purchase',
                'reward_type': 'discount',
                'points_cost': 200,
                'icon': 'discount',
                'metadata': {'discount_percentage': 10, 'valid_for': 'cafeteria'},
            },
            {
                'name': 'Library Priority',
                'description': 'Get priority access to library resources for a week',
                'reward_type': 'privilege',
                'points_cost': 300,
                'icon': 'privilege',
            },
            {
                'name': 'Recognition Certificate',
                'description': 'Receive a digital certificate of recognition',
                'reward_type': 'recognition',
                'points_cost': 400,
                'icon': 'recognition',
            },
            {
                'name': 'Study Group Creator Privilege',
                'description': 'Create unlimited study groups for a month',
                'reward_type': 'privilege',
                'points_cost': 350,
                'icon': 'privilege',
            },
        ]
        
        for reward_data in default_rewards:
            try:
                Reward.objects.get_or_create(
                    name=reward_data['name'],
                    defaults=reward_data
                )
            except Exception:
                # Skip if there's an error
                continue


class RewardRedemptionCreateView(generics.CreateAPIView):
    """Redeem a reward"""
    serializer_class = RewardRedemptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        reward_id = self.request.data.get('reward_id')
        if not reward_id:
            raise ValueError("reward_id is required")
        
        redemption = GamificationService.redeem_reward(self.request.user, reward_id)
        serializer.instance = redemption


class UserRewardRedemptionsView(generics.ListAPIView):
    """List user's reward redemptions"""
    serializer_class = RewardRedemptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return RewardRedemption.objects.filter(user=self.request.user).order_by('-redeemed_at')
        except Exception as e:
            import traceback
            print(f"Error in UserRewardRedemptionsView.get_queryset: {e}")
            traceback.print_exc()
            return RewardRedemption.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in UserRewardRedemptionsView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


# Streak
class UserStreakView(generics.RetrieveAPIView):
    """Get user's streak"""
    serializer_class = UserStreakSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        try:
            streak, created = UserStreak.objects.get_or_create(user=self.request.user)
            return streak
        except Exception as e:
            import traceback
            print(f"Error in UserStreakView.get_object: {e}")
            traceback.print_exc()
            from django.db import OperationalError
            if isinstance(e, OperationalError):
                # Table doesn't exist - return a mock object
                class MockUserStreak:
                    def __init__(self, user):
                        self.user = user
                        self.current_streak = 0
                        self.longest_streak = 0
                        self.last_activity_date = None
                return MockUserStreak(self.request.user)
            raise
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to handle errors gracefully"""
        try:
            return super().retrieve(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in UserStreakView.retrieve: {e}")
            traceback.print_exc()
            return Response(
                {
                    'user': request.user.id,
                    'current_streak': 0,
                    'longest_streak': 0,
                    'last_activity_date': None,
                },
                status=status.HTTP_200_OK
            )


# Leaderboards
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def leaderboard(request, leaderboard_type, period='all_time'):
    """Get leaderboard"""
    try:
        limit = int(request.query_params.get('limit', 100))
        leaderboard_data = LeaderboardService.calculate_leaderboard(leaderboard_type, period, limit)
        
        # Serialize
        result = []
        for entry in leaderboard_data:
            result.append({
                'rank': entry['rank'],
                'user': {
                    'id': entry['user'].id,
                    'username': entry['user'].username,
                    'first_name': entry['user'].first_name,
                    'last_name': entry['user'].last_name,
                },
                'score': entry['score'],
                'points': entry.get('points'),
                'achievements': entry.get('achievements'),
                'streak': entry.get('streak'),
            })
        
        return Response(result)
    except Exception as e:
        import traceback
        print(f"Error in leaderboard view: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_rank(request, leaderboard_type, period='all_time'):
    """Get user's rank in leaderboard"""
    rank = LeaderboardService.get_user_rank(request.user, leaderboard_type, period)
    
    if rank is None:
        return Response({'rank': None, 'message': 'User not found in leaderboard'})
    
    return Response({'rank': rank})


# Stats
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_stats(request):
    """Get user's gamification stats"""
    try:
        stats = GamificationService.get_user_stats(request.user)
        serializer = UserGamificationStatsSerializer(stats)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in user_stats view: {e}")
        traceback.print_exc()
        return Response(
            {
                'total_points': 0,
                'current_streak': 0,
                'longest_streak': 0,
                'achievements_unlocked': 0,
                'rewards_redeemed': 0,
                'rank': None,
            },
            status=status.HTTP_200_OK
        )


# Actions
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def trigger_achievement_check(request):
    """Manually trigger achievement check for a specific type"""
    achievement_type = request.data.get('achievement_type')
    metadata = request.data.get('metadata', {})
    
    if not achievement_type:
        return Response(
            {'error': 'achievement_type is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    unlocked = GamificationService.check_and_unlock_achievements(
        request.user,
        achievement_type,
        metadata
    )
    
    serializer = UserAchievementSerializer(unlocked, many=True)
    return Response({
        'unlocked_count': len(unlocked),
        'unlocked_achievements': serializer.data,
    })


