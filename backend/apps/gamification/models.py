"""
Gamification models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class Achievement(TimestampedModel):
    """Achievement definition"""
    
    ACHIEVEMENT_TYPES = [
        ('first_login', 'First Login'),
        ('profile_complete', 'Profile Complete'),
        ('study_group_created', 'Study Group Created'),
        ('study_group_joined', 'Study Group Joined'),
        ('notice_viewed', 'Notice Viewed'),
        ('complaint_submitted', 'Complaint Submitted'),
        ('feedback_submitted', 'Feedback Submitted'),
        ('event_created', 'Event Created'),
        ('event_attended', 'Event Attended'),
        ('streak_daily', 'Daily Streak'),
        ('streak_weekly', 'Weekly Streak'),
        ('points_milestone', 'Points Milestone'),
        ('social_contributor', 'Social Contributor'),
        ('academic_excellence', 'Academic Excellence'),
        ('community_helper', 'Community Helper'),
    ]
    
    DIFFICULTY_LEVELS = [
        ('bronze', 'Bronze'),
        ('silver', 'Silver'),
        ('gold', 'Gold'),
        ('platinum', 'Platinum'),
    ]
    
    name = models.CharField(max_length=200)
    description = models.TextField()
    achievement_type = models.CharField(max_length=50, choices=ACHIEVEMENT_TYPES)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_LEVELS, default='bronze')
    icon = models.CharField(max_length=100, blank=True, null=True)
    points_reward = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    requirements = models.JSONField(
        default=dict,
        blank=True,
        help_text='Requirements to unlock this achievement (e.g., {"count": 10, "type": "study_groups"})'
    )
    
    class Meta:
        verbose_name = 'Achievement'
        verbose_name_plural = 'Achievements'
        ordering = ['difficulty', 'points_reward']
        indexes = [
            models.Index(fields=['achievement_type', 'is_active']),
            models.Index(fields=['difficulty']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_difficulty_display()})"


class UserAchievement(TimestampedModel):
    """User's earned achievements"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE, related_name='user_achievements')
    progress = models.IntegerField(default=0, help_text='Current progress towards achievement')
    is_unlocked = models.BooleanField(default=False)
    unlocked_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'User Achievement'
        verbose_name_plural = 'User Achievements'
        unique_together = [['user', 'achievement']]
        indexes = [
            models.Index(fields=['user', 'is_unlocked']),
            models.Index(fields=['achievement', 'is_unlocked']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.achievement.name}"
    
    def unlock(self):
        """Unlock the achievement"""
        if not self.is_unlocked:
            self.is_unlocked = True
            self.unlocked_at = timezone.now()
            self.save()
            
            # Award points
            UserPoints.award_points(
                self.user,
                self.achievement.points_reward,
                'achievement',
                f"Achievement unlocked: {self.achievement.name}"
            )


class UserPoints(TimestampedModel):
    """User points system"""
    
    POINT_SOURCES = [
        ('achievement', 'Achievement'),
        ('daily_login', 'Daily Login'),
        ('study_group_activity', 'Study Group Activity'),
        ('complaint_submission', 'Complaint Submission'),
        ('feedback_submission', 'Feedback Submission'),
        ('event_creation', 'Event Creation'),
        ('event_attendance', 'Event Attendance'),
        ('social_interaction', 'Social Interaction'),
        ('content_contribution', 'Content Contribution'),
        ('milestone', 'Milestone'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='points')
    total_points = models.IntegerField(default=0)
    current_points = models.IntegerField(default=0, help_text='Points available for redemption')
    lifetime_points = models.IntegerField(default=0, help_text='Total points ever earned')
    
    class Meta:
        verbose_name = 'User Points'
        verbose_name_plural = 'User Points'
        indexes = [
            models.Index(fields=['total_points']),
            models.Index(fields=['-total_points']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.total_points} points"
    
    @staticmethod
    def award_points(user, amount, source, description=None):
        """Award points to a user"""
        points, created = UserPoints.objects.get_or_create(
            user=user,
            defaults={
                'total_points': amount,
                'current_points': amount,
                'lifetime_points': amount,
            }
        )
        
        if not created:
            points.total_points += amount
            points.current_points += amount
            points.lifetime_points += amount
            points.save()
        
        # Create point transaction record
        PointTransaction.objects.create(
            user=user,
            amount=amount,
            source=source,
            description=description or f"Points from {source}",
            balance_after=points.total_points,
        )
        
        return points


class PointTransaction(TimestampedModel):
    """Point transaction history"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='point_transactions')
    amount = models.IntegerField(help_text='Positive for earned, negative for spent')
    source = models.CharField(max_length=50, choices=UserPoints.POINT_SOURCES)
    description = models.TextField(blank=True, null=True)
    balance_after = models.IntegerField(help_text='Points balance after this transaction')
    related_object_type = models.CharField(max_length=50, blank=True, null=True)
    related_object_id = models.IntegerField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Point Transaction'
        verbose_name_plural = 'Point Transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['source']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.amount} points ({self.source})"


class Leaderboard(TimestampedModel):
    """Leaderboard entries"""
    
    LEADERBOARD_TYPES = [
        ('points', 'Points'),
        ('achievements', 'Achievements'),
        ('study_groups', 'Study Groups'),
        ('contributions', 'Contributions'),
        ('streak', 'Streak'),
        ('overall', 'Overall'),
    ]
    
    PERIOD_TYPES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('all_time', 'All Time'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='leaderboard_entries')
    leaderboard_type = models.CharField(max_length=20, choices=LEADERBOARD_TYPES)
    period = models.CharField(max_length=20, choices=PERIOD_TYPES)
    score = models.IntegerField(default=0)
    rank = models.IntegerField(blank=True, null=True)
    period_start = models.DateTimeField(blank=True, null=True)
    period_end = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Leaderboard Entry'
        verbose_name_plural = 'Leaderboard Entries'
        unique_together = [['user', 'leaderboard_type', 'period', 'period_start']]
        indexes = [
            models.Index(fields=['leaderboard_type', 'period', '-score']),
            models.Index(fields=['user', 'leaderboard_type', 'period']),
        ]
        ordering = ['-score']
    
    def __str__(self):
        return f"{self.user.username} - {self.get_leaderboard_type_display()} ({self.get_period_display()}) - Rank {self.rank}"


class Reward(TimestampedModel):
    """Rewards available for redemption"""
    
    REWARD_TYPES = [
        ('badge', 'Badge'),
        ('discount', 'Discount'),
        ('privilege', 'Privilege'),
        ('recognition', 'Recognition'),
        ('physical', 'Physical Item'),
    ]
    
    name = models.CharField(max_length=200)
    description = models.TextField()
    reward_type = models.CharField(max_length=20, choices=REWARD_TYPES)
    points_cost = models.IntegerField()
    icon = models.CharField(max_length=100, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    stock_quantity = models.IntegerField(blank=True, null=True, help_text='Null for unlimited')
    redemption_limit = models.IntegerField(
        blank=True,
        null=True,
        help_text='Max redemptions per user (null for unlimited)'
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text='Additional reward data (e.g., discount code, badge details)'
    )
    
    class Meta:
        verbose_name = 'Reward'
        verbose_name_plural = 'Rewards'
        ordering = ['points_cost']
        indexes = [
            models.Index(fields=['is_active', 'points_cost']),
            models.Index(fields=['reward_type']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.points_cost} points)"


class RewardRedemption(TimestampedModel):
    """User reward redemptions"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('fulfilled', 'Fulfilled'),
        ('cancelled', 'Cancelled'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reward_redemptions')
    reward = models.ForeignKey(Reward, on_delete=models.CASCADE, related_name='redemptions')
    points_spent = models.IntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    redeemed_at = models.DateTimeField(auto_now_add=True)
    fulfilled_at = models.DateTimeField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Reward Redemption'
        verbose_name_plural = 'Reward Redemptions'
        ordering = ['-redeemed_at']
        indexes = [
            models.Index(fields=['user', '-redeemed_at']),
            models.Index(fields=['status']),
            models.Index(fields=['reward', 'status']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.reward.name} ({self.status})"


class UserStreak(TimestampedModel):
    """User daily login streak"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='streak')
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_login_date = models.DateField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'User Streak'
        verbose_name_plural = 'User Streaks'
    
    def __str__(self):
        return f"{self.user.username} - {self.current_streak} day streak"
    
    def update_streak(self):
        """Update streak based on login"""
        today = timezone.now().date()
        
        if self.last_login_date is None:
            # First login
            self.current_streak = 1
            self.longest_streak = 1
            self.last_login_date = today
            self.save()
            return
        
        if self.last_login_date == today:
            # Already logged in today
            return
        
        days_diff = (today - self.last_login_date).days
        
        if days_diff == 1:
            # Consecutive day
            self.current_streak += 1
        elif days_diff > 1:
            # Streak broken
            self.current_streak = 1
        
        if self.current_streak > self.longest_streak:
            self.longest_streak = self.current_streak
        
        self.last_login_date = today
        self.save()
        
        # Award points for streaks
        if self.current_streak % 7 == 0:  # Weekly milestone
            UserPoints.award_points(
                self.user,
                50,
                'milestone',
                f"{self.current_streak}-day streak milestone"
            )

















