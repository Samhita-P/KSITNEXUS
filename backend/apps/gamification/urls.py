from django.urls import path
from . import views

urlpatterns = [
    # Achievements
    path('achievements/', views.AchievementListView.as_view(), name='achievement-list'),
    path('achievements/user/', views.UserAchievementListView.as_view(), name='user-achievement-list'),
    path('achievements/available/', views.AvailableAchievementsView.as_view(), name='available-achievements'),
    
    # Points
    path('points/', views.UserPointsView.as_view(), name='user-points'),
    path('points/transactions/', views.PointTransactionListView.as_view(), name='point-transactions'),
    
    # Rewards
    path('rewards/', views.RewardListView.as_view(), name='reward-list'),
    path('rewards/redeem/', views.RewardRedemptionCreateView.as_view(), name='redeem-reward'),
    path('rewards/my-redemptions/', views.UserRewardRedemptionsView.as_view(), name='user-redemptions'),
    
    # Streak
    path('streak/', views.UserStreakView.as_view(), name='user-streak'),
    
    # Leaderboards
    path('leaderboard/<str:leaderboard_type>/', views.leaderboard, name='leaderboard'),
    path('leaderboard/<str:leaderboard_type>/<str:period>/', views.leaderboard, name='leaderboard-period'),
    path('leaderboard/<str:leaderboard_type>/rank/', views.user_rank, name='user-rank'),
    path('leaderboard/<str:leaderboard_type>/<str:period>/rank/', views.user_rank, name='user-rank-period'),
    
    # Stats
    path('stats/', views.user_stats, name='user-gamification-stats'),
    
    # Actions
    path('check-achievements/', views.trigger_achievement_check, name='check-achievements'),
]

















