"""
Views for notifications app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from .models import Notification, NotificationPreference, NotificationTemplate, NotificationLog
from .serializers import (
    NotificationSerializer, NotificationPreferenceSerializer,
    NotificationTemplateSerializer, NotificationLogSerializer,
    NotificationCreateSerializer, MarkAsReadSerializer, NotificationStatsSerializer
)
from .services.quiet_hours_service import QuietHoursService
from datetime import time
from django.core.cache import cache

User = get_user_model()


class NotificationListView(generics.ListAPIView):
    """List notifications"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'message']
    ordering_fields = ['created_at', 'priority']
    ordering = ['-created_at']
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)
    
    def list(self, request, *args, **kwargs):
        # Cache the queryset results
        cache_key = f'notifications:list:{request.user.id}'
        
        # Try to get from cache
        cached_result = cache.get(cache_key)
        if cached_result is not None:
            # Return cached serializer data
            serializer = self.get_serializer(cached_result, many=True)
            return Response(serializer.data)
        
        # Get fresh data
        response = super().list(request, *args, **kwargs)
        
        # Cache the queryset
        if response.status_code == 200:
            queryset = self.get_queryset()
            cache.set(cache_key, list(queryset), 60)  # Cache for 1 minute
        
        return response


class NotificationDetailView(generics.RetrieveAPIView):
    """Notification detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class MarkAsReadView(generics.UpdateAPIView):
    """Mark notification as read"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MarkAsReadSerializer
    
    def get_object(self):
        notification_id = self.kwargs['pk']
        return get_object_or_404(
            Notification, 
            id=notification_id, 
            user=self.request.user
        )
    
    def update(self, request, *args, **kwargs):
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'message': 'Notification marked as read'})


class NotificationPreferenceView(generics.RetrieveUpdateAPIView):
    """Notification preferences view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationPreferenceSerializer
    
    def get_object(self):
        cache_key = f'notification_preferences:{self.request.user.id}'
        
        # Try to get from cache
        preference = cache.get(cache_key)
        if preference is None:
            preference, created = NotificationPreference.objects.get_or_create(
                user=self.request.user
            )
            cache.set(cache_key, preference, 300)  # Cache for 5 minutes
        
        return preference
    
    def update(self, request, *args, **kwargs):
        # Invalidate cache when updating preferences
        cache_key = f'notification_preferences:{request.user.id}'
        cache.delete(cache_key)
        return super().update(request, *args, **kwargs)


class UnreadCountView(generics.RetrieveAPIView):
    """Get unread notification count"""
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        cache_key = f'notification_count:{request.user.id}'
        
        # Try to get from cache
        count = cache.get(cache_key)
        if count is None:
            count = Notification.objects.filter(
                user=request.user, 
                is_read=False
            ).count()
            cache.set(cache_key, count, 30)  # Cache for 30 seconds
        
        return Response({'unread_count': count})


class MarkAllReadView(generics.UpdateAPIView):
    """Mark all notifications as read"""
    permission_classes = [permissions.IsAuthenticated]
    
    def update(self, request, *args, **kwargs):
        updated_count = Notification.objects.filter(
            user=request.user, 
            is_read=False
        ).update(is_read=True)
        
        return Response({
            'message': f'{updated_count} notifications marked as read'
        })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_notification(request):
    """Create a notification"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    serializer = NotificationCreateSerializer(data=request.data)
    if serializer.is_valid():
        notification = serializer.save()
        return Response({
            'message': 'Notification created successfully',
            'notification': NotificationSerializer(notification).data
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notification_stats(request):
    """Get notification statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_notifications': Notification.objects.count(),
        'unread_notifications': Notification.objects.filter(is_read=False).count(),
        'notifications_by_type': {},
        'notifications_by_priority': {},
        'recent_notifications': [],
    }
    
    # Type breakdown
    for notification_type, _ in Notification.NOTIFICATION_TYPES:
        stats['notifications_by_type'][notification_type] = Notification.objects.filter(
            notification_type=notification_type
        ).count()
    
    # Priority breakdown
    for priority, _ in Notification.PRIORITY_CHOICES:
        stats['notifications_by_priority'][priority] = Notification.objects.filter(
            priority=priority
        ).count()
    
    # Recent notifications
    recent = Notification.objects.select_related('user').order_by('-created_at')[:10]
    stats['recent_notifications'] = NotificationSerializer(recent, many=True).data
    
    return Response(stats)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def send_notification(request):
    """Send notification to users"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    user_ids = request.data.get('user_ids', [])
    notification_type = request.data.get('notification_type')
    title = request.data.get('title')
    message = request.data.get('message')
    priority = request.data.get('priority', 'medium')
    
    if not all([user_ids, notification_type, title, message]):
        return Response(
            {'error': 'user_ids, notification_type, title, and message are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Create notifications for each user
    notifications = []
    for user_id in user_ids:
        try:
            user = User.objects.get(id=user_id)
            notification = Notification.objects.create(
                user=user,
                notification_type=notification_type,
                priority=priority,
                title=title,
                message=message
            )
            notifications.append(notification)
        except User.DoesNotExist:
            continue
    
    return Response({
        'message': f'Notifications sent to {len(notifications)} users',
        'notifications': NotificationSerializer(notifications, many=True).data
    })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_quiet_hours_status(request):
    """Get quiet hours status for current user"""
    try:
        is_quiet_hours = QuietHoursService.is_quiet_hours(request.user)
        next_send_time = QuietHoursService.get_next_send_time(request.user)
        
        pref = NotificationPreference.objects.filter(user=request.user).first()
        quiet_hours_start = pref.quiet_hours_start.isoformat() if pref and pref.quiet_hours_start else None
        quiet_hours_end = pref.quiet_hours_end.isoformat() if pref and pref.quiet_hours_end else None
        
        return Response({
            'is_quiet_hours': is_quiet_hours,
            'quiet_hours_enabled': pref.quiet_hours_start is not None and pref.quiet_hours_end is not None if pref else False,
            'quiet_hours_start': quiet_hours_start,
            'quiet_hours_end': quiet_hours_end,
            'timezone': pref.timezone if pref else 'Asia/Kolkata',
            'next_send_time': next_send_time.isoformat() if next_send_time else None,
        })
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def set_quiet_hours(request):
    """Set quiet hours for current user"""
    try:
        start_hour = request.data.get('start_hour')
        start_minute = request.data.get('start_minute')
        end_hour = request.data.get('end_hour')
        end_minute = request.data.get('end_minute')
        timezone_str = request.data.get('timezone', 'Asia/Kolkata')
        
        if start_hour is None or start_minute is None or end_hour is None or end_minute is None:
            return Response({
                'error': 'start_hour, start_minute, end_hour, and end_minute are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        start_time = time(hour=start_hour, minute=start_minute)
        end_time = time(hour=end_hour, minute=end_minute)
        
        pref = QuietHoursService.set_quiet_hours(
            user=request.user,
            start_time=start_time,
            end_time=end_time,
            timezone_str=timezone_str
        )
        
        serializer = NotificationPreferenceSerializer(pref)
        return Response(serializer.data)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def disable_quiet_hours(request):
    """Disable quiet hours for current user"""
    try:
        QuietHoursService.disable_quiet_hours(request.user)
        return Response({
            'message': 'Quiet hours disabled successfully'
        })
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)