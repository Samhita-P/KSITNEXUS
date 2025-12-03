"""
Notification digest service for generating and managing notification digests
"""
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from ..models import Notification, NotificationPreference
from ..models_digest import NotificationDigest, NotificationTier
from .summary_service import SummaryService

User = get_user_model()


class DigestService:
    """Service for generating notification digests"""
    
    @staticmethod
    def generate_daily_digest(user: User, date: Optional[datetime] = None) -> Optional[NotificationDigest]:
        """
        Generate daily digest for user
        
        Args:
            user: User instance
            date: Date for digest (defaults to today)
            
        Returns:
            NotificationDigest instance or None
        """
        if date is None:
            date = timezone.now().date()
        
        # Get user's digest preference
        pref = NotificationPreference.objects.filter(user=user).first()
        if not pref or pref.digest_frequency != 'daily':
            return None
        
        # Calculate period
        period_start = timezone.make_aware(datetime.combine(date, datetime.min.time()))
        period_end = period_start + timedelta(days=1) - timedelta(seconds=1)
        
        # Get notifications for this period
        notifications = Notification.objects.filter(
            user=user,
            created_at__gte=period_start,
            created_at__lte=period_end,
            is_read=False
        ).order_by('-priority', '-created_at')
        
        if not notifications.exists():
            return None
        
        # Create digest
        digest = NotificationDigest.objects.create(
            user=user,
            frequency='daily',
            period_start=period_start,
            period_end=period_end,
            title=f"Daily Digest - {date.strftime('%B %d, %Y')}",
            notification_count=notifications.count(),
            unread_count=notifications.count(),
        )
        
        # Add notifications to digest
        digest.notifications.set(notifications)
        
        # Generate summary using SummaryService
        summary_text = SummaryService.generate_digest_summary(list(notifications))
        digest.summary = summary_text
        digest.save()
        
        return digest
    
    @staticmethod
    def generate_weekly_digest(user: User, week_start: Optional[datetime] = None) -> Optional[NotificationDigest]:
        """
        Generate weekly digest for user
        
        Args:
            user: User instance
            week_start: Start of week (defaults to Monday of current week)
            
        Returns:
            NotificationDigest instance or None
        """
        # Get user's digest preference
        pref = NotificationPreference.objects.filter(user=user).first()
        if not pref or pref.digest_frequency != 'weekly':
            return None
        
        if week_start is None:
            today = timezone.now().date()
            # Get Monday of current week
            days_since_monday = today.weekday()
            monday = today - timedelta(days=days_since_monday)
            week_start = timezone.make_aware(datetime.combine(monday, datetime.min.time()))
        
        period_end = week_start + timedelta(days=7) - timedelta(seconds=1)
        
        # Get notifications for this period
        notifications = Notification.objects.filter(
            user=user,
            created_at__gte=week_start,
            created_at__lte=period_end,
            is_read=False
        ).order_by('-priority', '-created_at')
        
        if not notifications.exists():
            return None
        
        # Create digest
        digest = NotificationDigest.objects.create(
            user=user,
            frequency='weekly',
            period_start=week_start,
            period_end=period_end,
            title=f"Weekly Digest - {week_start.date()} to {period_end.date()}",
            notification_count=notifications.count(),
            unread_count=notifications.count(),
        )
        
        # Add notifications to digest
        digest.notifications.set(notifications)
        
        # Generate summary using SummaryService
        summary_text = SummaryService.generate_digest_summary(list(notifications))
        digest.summary = summary_text
        digest.save()
        
        return digest
    
    @staticmethod
    def get_user_digests(user: User, limit: int = 10) -> List[NotificationDigest]:
        """
        Get user's notification digests
        
        Args:
            user: User instance
            limit: Maximum number of digests to return
            
        Returns:
            List of NotificationDigest instances
        """
        return NotificationDigest.objects.filter(
            user=user
        ).order_by('-created_at')[:limit]
    
    @staticmethod
    def mark_digest_as_read(digest_id: int, user: User) -> bool:
        """
        Mark digest as read and mark all notifications in digest as read
        
        Args:
            digest_id: Digest ID
            user: User instance
            
        Returns:
            True if successful, False otherwise
        """
        try:
            digest = NotificationDigest.objects.get(id=digest_id, user=user)
            digest.mark_as_read()
            
            # Mark all notifications in digest as read
            for notification in digest.notifications.all():
                notification.mark_as_read()
            
            return True
        except NotificationDigest.DoesNotExist:
            return False


class TierService:
    """Service for managing notification tiers"""
    
    @staticmethod
    def get_user_tier(user: User, notification_type: str) -> str:
        """
        Get tier for notification type for user
        
        Args:
            user: User instance
            notification_type: Notification type
            
        Returns:
            Tier name (essential, important, optional)
        """
        tier = NotificationTier.objects.filter(
            user=user,
            notification_types__contains=[notification_type]
        ).first()
        
        if tier:
            return tier.tier
        
        # Default tier based on notification type
        default_tiers = {
            'complaint': 'essential',
            'notice': 'important',
            'study_group': 'important',
            'reservation': 'important',
            'feedback': 'optional',
            'announcement': 'important',
            'general': 'optional',
        }
        
        return default_tiers.get(notification_type, 'important')
    
    @staticmethod
    def set_tier(user: User, tier: str, notification_types: List[str]) -> NotificationTier:
        """
        Set tier for notification types
        
        Args:
            user: User instance
            tier: Tier name (essential, important, optional)
            notification_types: List of notification types
            
        Returns:
            NotificationTier instance
        """
        tier_obj, created = NotificationTier.objects.get_or_create(
            user=user,
            tier=tier,
            defaults={
                'notification_types': notification_types,
            }
        )
        
        if not created:
            # Update notification types
            existing_types = set(tier_obj.notification_types)
            existing_types.update(notification_types)
            tier_obj.notification_types = list(existing_types)
            tier_obj.save()
        
        return tier_obj
    
    @staticmethod
    def get_user_tiers(user: User) -> List[NotificationTier]:
        """
        Get all tiers for user
        
        Args:
            user: User instance
            
        Returns:
            List of NotificationTier instances
        """
        return NotificationTier.objects.filter(user=user).order_by('tier')
    
    @staticmethod
    def should_send_notification(user: User, notification) -> bool:
        """
        Check if notification should be sent based on tier settings
        
        Args:
            user: User instance
            notification: Notification instance or object with notification_type attribute
            
        Returns:
            True if notification should be sent, False otherwise
        """
        tier_name = TierService.get_user_tier(user, notification.notification_type)
        tier = NotificationTier.objects.filter(user=user, tier=tier_name).first()
        
        if not tier:
            # Default: send all notifications
            return True
        
        # Check tier settings
        pref = NotificationPreference.objects.filter(user=user).first()
        if not pref:
            return True
        
        # Essential tier: always send
        if tier_name == 'essential':
            return True
        
        # Important tier: send based on preferences
        if tier_name == 'important':
            return pref.in_app_enabled or pref.push_enabled
        
        # Optional tier: only send if enabled
        if tier_name == 'optional':
            return pref.in_app_enabled
        
        return True

