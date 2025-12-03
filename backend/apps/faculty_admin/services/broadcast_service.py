"""
Broadcast Service
"""
from typing import List, Optional
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from apps.faculty_admin.models import Broadcast, BroadcastEngagement
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class BroadcastService:
    """Service for broadcast management"""
    
    @staticmethod
    def get_target_users(broadcast: Broadcast) -> List[User]:
        """Get list of target users for a broadcast"""
        if broadcast.target_audience == 'all':
            return list(User.objects.filter(is_active=True))
        elif broadcast.target_audience == 'students':
            return list(User.objects.filter(user_type='student', is_active=True))
        elif broadcast.target_audience == 'faculty':
            return list(User.objects.filter(user_type='faculty', is_active=True))
        elif broadcast.target_audience == 'staff':
            return list(User.objects.filter(user_type='staff', is_active=True))
        elif broadcast.target_audience == 'specific':
            return list(broadcast.target_users.all())
        return []
    
    @staticmethod
    def publish_broadcast(broadcast: Broadcast):
        """Publish a broadcast"""
        broadcast.is_published = True
        broadcast.published_at = timezone.now()
        broadcast.save()
        
        # Create engagement records for target users
        target_users = BroadcastService.get_target_users(broadcast)
        for user in target_users:
            BroadcastEngagement.objects.get_or_create(
                broadcast=broadcast,
                user=user
            )
    
    @staticmethod
    def track_view(broadcast: Broadcast, user: User):
        """Track broadcast view"""
        engagement, created = BroadcastEngagement.objects.get_or_create(
            broadcast=broadcast,
            user=user
        )
        
        if not engagement.viewed_at:
            engagement.viewed_at = timezone.now()
            engagement.save()
            broadcast.views_count += 1
            broadcast.save(update_fields=['views_count'])

















