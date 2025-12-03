"""
FCM API views for push notifications
"""

from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import asyncio
from .fcm_models import FCMToken, PushNotification, FCMNotificationTemplate
from .fcm_serializers import FCMTokenSerializer, PushNotificationSerializer, NotificationTemplateSerializer
from .fcm_service import FCMService


class FCMTokenListCreateView(generics.ListCreateAPIView):
    """List and create FCM tokens"""
    serializer_class = FCMTokenSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return FCMToken.objects.filter(user=self.request.user, is_active=True)
    
    def perform_create(self, serializer):
        # Deactivate old tokens for the same user and platform
        FCMToken.objects.filter(
            user=self.request.user,
            platform=serializer.validated_data['platform']
        ).update(is_active=False)
        
        serializer.save(user=self.request.user)


class FCMTokenDetailView(generics.RetrieveDestroyAPIView):
    """Retrieve and delete FCM token"""
    serializer_class = FCMTokenSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return FCMToken.objects.filter(user=self.request.user)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_fcm_token(request):
    """Register FCM token for push notifications"""
    try:
        token = request.data.get('token')
        platform = request.data.get('platform', 'flutter')
        
        if not token:
            return Response(
                {'error': 'Token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Deactivate old tokens for the same user and platform
        FCMToken.objects.filter(
            user=request.user,
            platform=platform
        ).update(is_active=False)
        
        # Create or update FCM token
        fcm_token, created = FCMToken.objects.get_or_create(
            token=token,
            defaults={
                'user': request.user,
                'platform': platform,
                'is_active': True,
                'last_used': timezone.now()
            }
        )
        
        if not created:
            fcm_token.is_active = True
            fcm_token.last_used = timezone.now()
            fcm_token.save()
        
        return Response({
            'message': 'FCM token registered successfully',
            'created': created
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def unregister_fcm_token(request, token):
    """Unregister FCM token"""
    try:
        fcm_token = get_object_or_404(
            FCMToken,
            token=token,
            user=request.user
        )
        fcm_token.is_active = False
        fcm_token.save()
        
        return Response({
            'message': 'FCM token unregistered successfully'
        })
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_push_notification(request):
    """Send push notification to users"""
    try:
        title = request.data.get('title')
        body = request.data.get('body')
        notification_type = request.data.get('notification_type', 'info')
        priority = request.data.get('priority', 'normal')
        target_user_ids = request.data.get('target_user_ids', [])
        target_topic = request.data.get('target_topic')
        data = request.data.get('data', {})
        
        if not title or not body:
            return Response(
                {'error': 'Title and body are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create push notification record
        push_notification = PushNotification.objects.create(
            title=title,
            body=body,
            notification_type=notification_type,
            priority=priority,
            target_topic=target_topic,
            data=data,
            status='pending'
        )
        
        # Add target users
        if target_user_ids:
            push_notification.target_users.set(target_user_ids)
        
        # Send notification using asyncio
        fcm_service = FCMService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            success = loop.run_until_complete(fcm_service.send_notification(push_notification))
        finally:
            loop.close()
        
        if success:
            push_notification.mark_as_sent()
            return Response({
                'message': 'Push notification sent successfully',
                'notification_id': push_notification.id
            })
        else:
            push_notification.mark_as_failed('Failed to send notification')
            return Response(
                {'error': 'Failed to send push notification'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_topic_notification(request):
    """Send push notification to topic subscribers"""
    try:
        topic = request.data.get('topic')
        title = request.data.get('title')
        body = request.data.get('body')
        data = request.data.get('data', {})
        
        if not topic or not title or not body:
            return Response(
                {'error': 'Topic, title, and body are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create push notification record
        push_notification = PushNotification.objects.create(
            title=title,
            body=body,
            target_topic=topic,
            data=data,
            status='pending'
        )
        
        # Send topic notification using asyncio
        fcm_service = FCMService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            success = loop.run_until_complete(fcm_service.send_topic_notification(topic, title, body, data))
        finally:
            loop.close()
        
        if success:
            push_notification.mark_as_sent()
            return Response({
                'message': 'Topic notification sent successfully',
                'notification_id': push_notification.id
            })
        else:
            push_notification.mark_as_failed('Failed to send topic notification')
            return Response(
                {'error': 'Failed to send topic notification'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notification_history(request):
    """Get push notification history for user"""
    try:
        notifications = PushNotification.objects.filter(
            target_users=request.user
        ).order_by('-created_at')[:50]
        
        serializer = PushNotificationSerializer(notifications, many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def subscribe_to_topic(request):
    """Subscribe user to notification topic"""
    try:
        topic = request.data.get('topic')
        
        if not topic:
            return Response(
                {'error': 'Topic is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get user's active FCM tokens
        fcm_tokens = FCMToken.objects.filter(
            user=request.user,
            is_active=True
        )
        
        if not fcm_tokens.exists():
            return Response(
                {'error': 'No active FCM tokens found'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Subscribe to topic using asyncio
        fcm_service = FCMService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            success = loop.run_until_complete(fcm_service.subscribe_to_topic(topic, fcm_tokens))
        finally:
            loop.close()
        
        if success:
            return Response({
                'message': f'Successfully subscribed to topic: {topic}'
            })
        else:
            return Response(
                {'error': 'Failed to subscribe to topic'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def unsubscribe_from_topic(request):
    """Unsubscribe user from notification topic"""
    try:
        topic = request.data.get('topic')
        
        if not topic:
            return Response(
                {'error': 'Topic is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get user's active FCM tokens
        fcm_tokens = FCMToken.objects.filter(
            user=request.user,
            is_active=True
        )
        
        if not fcm_tokens.exists():
            return Response(
                {'error': 'No active FCM tokens found'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Unsubscribe from topic using asyncio
        fcm_service = FCMService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            success = loop.run_until_complete(fcm_service.unsubscribe_from_topic(topic, fcm_tokens))
        finally:
            loop.close()
        
        if success:
            return Response({
                'message': f'Successfully unsubscribed from topic: {topic}'
            })
        else:
            return Response(
                {'error': 'Failed to unsubscribe from topic'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


class NotificationTemplateListCreateView(generics.ListCreateAPIView):
    """List and create notification templates"""
    queryset = FCMNotificationTemplate.objects.filter(is_active=True)
    serializer_class = NotificationTemplateSerializer
    permission_classes = [IsAuthenticated]


class NotificationTemplateDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete notification template"""
    queryset = FCMNotificationTemplate.objects.all()
    serializer_class = NotificationTemplateSerializer
    permission_classes = [IsAuthenticated]


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_template_notification(request):
    """Send notification using template"""
    try:
        template_id = request.data.get('template_id')
        context = request.data.get('context', {})
        target_user_ids = request.data.get('target_user_ids', [])
        target_topic = request.data.get('target_topic')
        
        if not template_id:
            return Response(
                {'error': 'Template ID is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        template = get_object_or_404(FCMNotificationTemplate, id=template_id)
        rendered = template.render(context)
        
        # Create push notification
        push_notification = PushNotification.objects.create(
            title=rendered['title'],
            body=rendered['body'],
            notification_type=rendered['notification_type'],
            priority=rendered['priority'],
            target_topic=target_topic,
            data=context,
            status='pending'
        )
        
        # Add target users
        if target_user_ids:
            push_notification.target_users.set(target_user_ids)
        
        # Send notification using asyncio
        fcm_service = FCMService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            success = loop.run_until_complete(fcm_service.send_notification(push_notification))
        finally:
            loop.close()
        
        if success:
            push_notification.mark_as_sent()
            return Response({
                'message': 'Template notification sent successfully',
                'notification_id': push_notification.id
            })
        else:
            push_notification.mark_as_failed('Failed to send template notification')
            return Response(
                {'error': 'Failed to send template notification'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
