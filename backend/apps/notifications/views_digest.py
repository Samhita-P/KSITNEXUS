"""
Views for notification digests, tiers, summaries, and priorities
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.core.cache import cache
from .models_digest import NotificationDigest, NotificationTier, NotificationSummary, NotificationPriorityRule
from .serializers_digest import (
    NotificationDigestSerializer, NotificationTierSerializer,
    NotificationSummarySerializer, NotificationPriorityRuleSerializer,
    CreateNotificationTierSerializer, CreatePriorityRuleSerializer
)
from .services.digest_service import DigestService, TierService
from .services.summary_service import SummaryService
from .services.priority_service import PriorityService
from .models import Notification

User = get_user_model()


# Digest Views
class NotificationDigestListView(generics.ListAPIView):
    """List notification digests for current user"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationDigestSerializer
    
    def get_queryset(self):
        return NotificationDigest.objects.filter(user=self.request.user).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        # Cache the queryset results
        cache_key = f'notification_digests:list:{request.user.id}'
        
        # Try to get from cache
        cached_result = cache.get(cache_key)
        if cached_result is not None:
            serializer = self.get_serializer(cached_result, many=True)
            return Response(serializer.data)
        
        # Get fresh data
        response = super().list(request, *args, **kwargs)
        
        # Cache the queryset
        if response.status_code == 200:
            queryset = self.get_queryset()
            cache.set(cache_key, list(queryset), 300)  # Cache for 5 minutes
        
        return response


class NotificationDigestDetailView(generics.RetrieveAPIView):
    """Notification digest detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationDigestSerializer
    
    def get_queryset(self):
        return NotificationDigest.objects.filter(user=self.request.user)


class NotificationDigestMarkAsReadView(generics.UpdateAPIView):
    """Mark notification digest as read"""
    permission_classes = [permissions.IsAuthenticated]
    
    def update(self, request, *args, **kwargs):
        digest_id = self.kwargs['pk']
        success = DigestService.mark_digest_as_read(digest_id, request.user)
        
        if success:
            # Invalidate cache
            cache_key = f'notification_digests:list:{request.user.id}'
            cache.delete(cache_key)
            return Response({'message': 'Digest marked as read'})
        else:
            return Response(
                {'error': 'Digest not found'},
                status=status.HTTP_404_NOT_FOUND
            )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def generate_daily_digest(request):
    """Generate daily digest for current user"""
    try:
        digest = DigestService.generate_daily_digest(request.user)
        if digest:
            serializer = NotificationDigestSerializer(digest)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'message': 'No new notifications for digest'},
                status=status.HTTP_200_OK
            )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def generate_weekly_digest(request):
    """Generate weekly digest for current user"""
    try:
        digest = DigestService.generate_weekly_digest(request.user)
        if digest:
            serializer = NotificationDigestSerializer(digest)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'message': 'No new notifications for digest'},
                status=status.HTTP_200_OK
            )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Tier Views
class NotificationTierListView(generics.ListCreateAPIView):
    """List and create notification tiers for current user"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationTierSerializer
    
    def get_queryset(self):
        return NotificationTier.objects.filter(user=self.request.user).order_by('tier')
    
    def create(self, request, *args, **kwargs):
        serializer = CreateNotificationTierSerializer(data=request.data)
        if serializer.is_valid():
            tier = TierService.set_tier(
                user=request.user,
                tier=serializer.validated_data['tier'],
                notification_types=serializer.validated_data['notification_types']
            )
            
            # Update tier settings
            tier.push_enabled = serializer.validated_data.get('push_enabled', tier.push_enabled)
            tier.email_enabled = serializer.validated_data.get('email_enabled', tier.email_enabled)
            tier.sms_enabled = serializer.validated_data.get('sms_enabled', tier.sms_enabled)
            tier.in_app_enabled = serializer.validated_data.get('in_app_enabled', tier.in_app_enabled)
            tier.escalation_enabled = serializer.validated_data.get('escalation_enabled', tier.escalation_enabled)
            tier.escalation_delay_minutes = serializer.validated_data.get('escalation_delay_minutes', tier.escalation_delay_minutes)
            tier.escalate_to_tier = serializer.validated_data.get('escalate_to_tier', tier.escalate_to_tier)
            if 'notification_types' in serializer.validated_data:
                tier.notification_types = serializer.validated_data['notification_types']
            tier.save()
            
            response_serializer = NotificationTierSerializer(tier)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class NotificationTierDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Notification tier detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationTierSerializer
    
    def get_queryset(self):
        return NotificationTier.objects.filter(user=self.request.user)


# Summary Views
class NotificationSummaryView(generics.RetrieveAPIView):
    """Get notification summary"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSummarySerializer
    
    def get_object(self):
        notification_id = self.kwargs['pk']
        notification = Notification.objects.get(id=notification_id, user=self.request.user)
        
        # Get or generate summary
        summary = SummaryService.get_summary(notification)
        if not summary:
            summary = SummaryService.generate_summary(notification, 'short')
        
        return summary


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def generate_summary(request):
    """Generate summary for notification"""
    try:
        notification_id = request.data.get('notification_id')
        summary_type = request.data.get('summary_type', 'short')
        
        if not notification_id:
            return Response(
                {'error': 'notification_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        notification = Notification.objects.get(id=notification_id, user=request.user)
        summary = SummaryService.generate_summary(notification, summary_type)
        
        if summary:
            serializer = NotificationSummarySerializer(summary)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'error': 'Failed to generate summary'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    except Notification.DoesNotExist:
        return Response(
            {'error': 'Notification not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Priority Views
class NotificationPriorityRuleListView(generics.ListCreateAPIView):
    """List and create priority rules"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationPriorityRuleSerializer
    
    def get_queryset(self):
        # Get user-specific and global rules
        user_rules = NotificationPriorityRule.objects.filter(
            user=self.request.user,
            is_active=True
        )
        global_rules = NotificationPriorityRule.objects.filter(
            is_global=True,
            is_active=True
        )
        return (user_rules | global_rules).distinct().order_by('-is_global', '-created_at')
    
    def create(self, request, *args, **kwargs):
        serializer = CreatePriorityRuleSerializer(data=request.data)
        if serializer.is_valid():
            rule = PriorityService.create_priority_rule(
                user=request.user if not serializer.validated_data.get('is_global') else None,
                notification_type=serializer.validated_data.get('notification_type'),
                priority=serializer.validated_data['priority'],
                keyword=serializer.validated_data.get('keyword'),
                sender=serializer.validated_data.get('sender'),
                is_global=serializer.validated_data.get('is_global', False),
                is_active=True
            )
            
            # Update escalation settings
            rule.auto_escalate = serializer.validated_data.get('auto_escalate', False)
            rule.escalation_minutes = serializer.validated_data.get('escalation_minutes', 30)
            rule.save()
            
            response_serializer = NotificationPriorityRuleSerializer(rule)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class NotificationPriorityRuleDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Priority rule detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationPriorityRuleSerializer
    
    def get_queryset(self):
        # Users can only edit their own rules (not global rules)
        return NotificationPriorityRule.objects.filter(
            user=self.request.user,
            is_global=False
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_notification_priority(request, pk):
    """Get calculated priority for notification"""
    try:
        notification = Notification.objects.get(id=pk, user=request.user)
        priority = PriorityService.calculate_priority(
            notification_type=notification.notification_type,
            title=notification.title,
            message=notification.message,
            data=notification.data,
            user=request.user,
            default_priority=notification.priority
        )
        
        return Response({
            'notification_id': notification.id,
            'current_priority': notification.priority,
            'calculated_priority': priority,
        })
    except Notification.DoesNotExist:
        return Response(
            {'error': 'Notification not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def filter_by_priority(request):
    """Filter notifications by priority"""
    try:
        priority = request.query_params.get('priority')
        if not priority:
            return Response(
                {'error': 'priority is required as query parameter'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get all notifications for the user
        all_notifications = Notification.objects.filter(user=request.user).order_by('-created_at')
        
        # Filter based on calculated priority
        filtered_notifications = []
        for notification in all_notifications:
            calculated_priority = PriorityService.calculate_priority(
                notification_type=notification.notification_type,
                title=notification.title,
                message=notification.message,
                data=notification.data,
                user=request.user,
                default_priority=notification.priority
            )
            if calculated_priority == priority:
                filtered_notifications.append(notification)
        
        from .serializers import NotificationSerializer
        serializer = NotificationSerializer(filtered_notifications, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

