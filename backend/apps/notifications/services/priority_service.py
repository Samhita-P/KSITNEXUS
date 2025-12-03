"""
Priority service for enhanced notification priority handling
"""
from django.contrib.auth import get_user_model
from django.db.models import Q
from typing import Optional, List, Dict, Any
from ..models import Notification
from ..models_digest import NotificationPriorityRule

User = get_user_model()


class PriorityService:
    """Service for managing notification priorities"""
    
    @staticmethod
    def calculate_priority(
        notification_type: str,
        title: str = '',
        message: str = '',
        data: Optional[Dict[str, Any]] = None,
        user: Optional[User] = None,
        default_priority: str = 'medium'
    ) -> str:
        """
        Calculate priority for notification based on rules
        
        Args:
            notification_type: Notification type
            title: Notification title
            message: Notification message
            data: Notification data
            user: User instance (optional)
            default_priority: Default priority if no rules match
            
        Returns:
            Priority level (low, medium, high, urgent)
        """
        # Create a temporary notification-like object for rule matching
        class TempNotification:
            def __init__(self, notification_type, title, message, data):
                self.notification_type = notification_type
                self.title = title
                self.message = message
                self.data = data or {}
        
        temp_notification = TempNotification(notification_type, title, message, data)
        
        # Check user-specific rules first
        if user:
            rule = PriorityService._find_matching_rule(temp_notification, user)
            if rule:
                return rule.priority
        
        # Check global rules
        rule = PriorityService._find_global_rule(temp_notification)
        if rule:
            return rule.priority
        
        # Default priority based on notification type
        default_priorities = {
            'complaint': 'high',
            'notice': 'medium',
            'study_group': 'medium',
            'reservation': 'medium',
            'feedback': 'low',
            'announcement': 'high',
            'general': 'low',
        }
        
        return default_priorities.get(notification_type, default_priority)
    
    @staticmethod
    def _find_matching_rule(notification, user: User) -> Optional[NotificationPriorityRule]:
        """
        Find matching priority rule for notification and user
        
        Args:
            notification: Notification-like object with notification_type, title, message, data
            user: User instance
            
        Returns:
            NotificationPriorityRule instance or None
        """
        # Check user-specific rules
        rules = NotificationPriorityRule.objects.filter(
            user=user,
            is_active=True
        ).order_by('-created_at')
        
        for rule in rules:
            if PriorityService._rule_matches(rule, notification):
                return rule
        
        return None
    
    @staticmethod
    def _find_global_rule(notification) -> Optional[NotificationPriorityRule]:
        """
        Find matching global priority rule for notification
        
        Args:
            notification: Notification-like object with notification_type, title, message, data
            
        Returns:
            NotificationPriorityRule instance or None
        """
        # Check global rules
        rules = NotificationPriorityRule.objects.filter(
            is_global=True,
            is_active=True
        ).order_by('-created_at')
        
        for rule in rules:
            if PriorityService._rule_matches(rule, notification):
                return rule
        
        return None
    
    @staticmethod
    def _rule_matches(rule: NotificationPriorityRule, notification) -> bool:
        """
        Check if rule matches notification
        
        Args:
            rule: NotificationPriorityRule instance
            notification: Notification instance
            
        Returns:
            True if rule matches, False otherwise
        """
        # Check notification type
        if rule.notification_type and rule.notification_type != notification.notification_type:
            return False
        
        # Check keyword
        if rule.keyword:
            keyword_lower = rule.keyword.lower()
            title_lower = notification.title.lower()
            message_lower = notification.message.lower()
            if keyword_lower not in title_lower and keyword_lower not in message_lower:
                return False
        
        # Check sender (for user-to-user notifications)
        if rule.sender:
            # This would need to be implemented based on your notification structure
            # For now, skip sender check
            pass
        
        return True
    
    @staticmethod
    def create_priority_rule(
        user: Optional[User],
        notification_type: Optional[str],
        priority: str,
        keyword: Optional[str] = None,
        sender: Optional[str] = None,
        is_global: bool = False,
        is_active: bool = True
    ) -> NotificationPriorityRule:
        """
        Create priority rule
        
        Args:
            user: User instance (None for global rules)
            notification_type: Notification type (None for all types)
            priority: Priority level
            keyword: Keyword to match (optional)
            sender: Sender to match (optional)
            is_global: Whether rule is global
            is_active: Whether rule is active
            
        Returns:
            NotificationPriorityRule instance
        """
        rule = NotificationPriorityRule.objects.create(
            user=user,
            notification_type=notification_type,
            priority=priority,
            keyword=keyword,
            sender=sender,
            is_global=is_global,
            is_active=is_active
        )
        
        return rule
    
    @staticmethod
    def get_user_priority_rules(user: User) -> List[NotificationPriorityRule]:
        """
        Get priority rules for user
        
        Args:
            user: User instance
            
        Returns:
            List of NotificationPriorityRule instances
        """
        return NotificationPriorityRule.objects.filter(
            user=user,
            is_active=True
        ).order_by('-created_at')
    
    @staticmethod
    def get_global_priority_rules() -> List[NotificationPriorityRule]:
        """
        Get global priority rules
        
        Returns:
            List of NotificationPriorityRule instances
        """
        return NotificationPriorityRule.objects.filter(
            is_global=True,
            is_active=True
        ).order_by('-created_at')
    
    @staticmethod
    def should_escalate(notification: Notification, user: Optional[User] = None) -> bool:
        """
        Check if notification should be escalated
        
        Args:
            notification: Notification instance
            user: User instance (optional)
            
        Returns:
            True if notification should be escalated, False otherwise
        """
        # Check if notification is unread and old enough
        if notification.is_read:
            return False
        
        # Check escalation rules
        rules = NotificationPriorityRule.objects.filter(
            notification_type=notification.notification_type,
            auto_escalate=True,
            is_active=True
        )
        
        # Filter by user if provided
        if user:
            rules = rules.filter(
                Q(user=user) | Q(is_global=True)
            )
        else:
            rules = rules.filter(is_global=True)
        
        for rule in rules:
            if PriorityService._rule_matches(rule, notification):
                # Check if escalation delay has passed
                from django.utils import timezone as django_timezone
                from datetime import timedelta
                
                escalation_time = notification.created_at + timedelta(minutes=rule.escalation_minutes)
                if django_timezone.now() >= escalation_time:
                    return True
        
        return False
    
    @staticmethod
    def escalate_notification(notification: Notification) -> Notification:
        """
        Escalate notification priority
        
        Args:
            notification: Notification instance
            
        Returns:
            Updated Notification instance
        """
        # Escalate priority
        priority_map = {
            'low': 'medium',
            'medium': 'high',
            'high': 'urgent',
            'urgent': 'urgent',  # Already at maximum
        }
        
        new_priority = priority_map.get(notification.priority, 'high')
        notification.priority = new_priority
        notification.save()
        
        return notification

