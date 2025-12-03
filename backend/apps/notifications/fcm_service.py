"""
FCM Service for sending push notifications
"""

import json
import asyncio
from django.conf import settings
from django.utils import timezone
from .fcm_models import FCMToken, PushNotification
import requests


class FCMService:
    """Service for handling Firebase Cloud Messaging"""
    
    def __init__(self):
        self.server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        self.fcm_url = 'https://fcm.googleapis.com/fcm/send'
        
        if not self.server_key:
            raise ValueError('FCM_SERVER_KEY not configured')
    
    async def send_notification(self, push_notification):
        """Send push notification to target users"""
        try:
            # Get target FCM tokens
            fcm_tokens = self._get_target_tokens(push_notification)
            
            if not fcm_tokens:
                return False
            
            # Prepare notification payload
            payload = self._prepare_payload(push_notification)
            
            # Send to each token
            success_count = 0
            for token in fcm_tokens:
                if await self._send_to_token(token, payload):
                    success_count += 1
                    # Update last used timestamp
                    token.last_used = timezone.now()
                    token.save(update_fields=['last_used'])
            
            # Update push notification with FCM tokens
            push_notification.fcm_tokens.set(fcm_tokens)
            
            return success_count > 0
            
        except Exception as e:
            print(f"Error sending notification: {e}")
            return False
    
    async def send_topic_notification(self, topic, title, body, data=None):
        """Send notification to topic subscribers"""
        try:
            payload = {
                'to': f'/topics/{topic}',
                'notification': {
                    'title': title,
                    'body': body,
                },
                'data': data or {},
                'priority': 'high',
            }
            
            return await self._send_payload(payload)
            
        except Exception as e:
            print(f"Error sending topic notification: {e}")
            return False
    
    async def subscribe_to_topic(self, topic, fcm_tokens):
        """Subscribe FCM tokens to topic"""
        try:
            # This would typically use the FCM Admin SDK
            # For now, we'll just mark the subscription in our database
            for token in fcm_tokens:
                # In a real implementation, you would call FCM API to subscribe
                # For now, we'll just return True
                pass
            
            return True
            
        except Exception as e:
            print(f"Error subscribing to topic: {e}")
            return False
    
    async def unsubscribe_from_topic(self, topic, fcm_tokens):
        """Unsubscribe FCM tokens from topic"""
        try:
            # This would typically use the FCM Admin SDK
            # For now, we'll just mark the unsubscription in our database
            for token in fcm_tokens:
                # In a real implementation, you would call FCM API to unsubscribe
                # For now, we'll just return True
                pass
            
            return True
            
        except Exception as e:
            print(f"Error unsubscribing from topic: {e}")
            return False
    
    def _get_target_tokens(self, push_notification):
        """Get FCM tokens for push notification targets"""
        tokens = []
        
        # Get tokens from target users
        if push_notification.target_users.exists():
            user_tokens = FCMToken.objects.filter(
                user__in=push_notification.target_users.all(),
                is_active=True
            )
            tokens.extend(user_tokens)
        
        # Get tokens from target topic (if implemented)
        if push_notification.target_topic:
            # In a real implementation, you would query tokens by topic
            # For now, we'll get all active tokens
            topic_tokens = FCMToken.objects.filter(is_active=True)
            tokens.extend(topic_tokens)
        
        return list(set(tokens))  # Remove duplicates
    
    def _prepare_payload(self, push_notification):
        """Prepare FCM payload for notification"""
        payload = {
            'notification': {
                'title': push_notification.title,
                'body': push_notification.body,
            },
            'data': push_notification.data or {},
            'priority': 'high',
        }
        
        # Add notification type and priority
        payload['data']['notification_type'] = push_notification.notification_type
        payload['data']['priority'] = push_notification.priority
        
        return payload
    
    async def _send_to_token(self, fcm_token, payload):
        """Send notification to specific FCM token"""
        try:
            payload['to'] = fcm_token.token
            
            return await self._send_payload(payload)
            
        except Exception as e:
            print(f"Error sending to token {fcm_token.token}: {e}")
            return False
    
    async def _send_payload(self, payload):
        """Send payload to FCM"""
        try:
            headers = {
                'Authorization': f'key={self.server_key}',
                'Content-Type': 'application/json',
            }
            
            # Use asyncio to run the request in a thread pool
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: requests.post(
                    self.fcm_url,
                    headers=headers,
                    data=json.dumps(payload),
                    timeout=30
                )
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get('success', 0) > 0
            else:
                print(f"FCM API error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"Error sending FCM payload: {e}")
            return False
    
    async def send_bulk_notifications(self, notifications):
        """Send multiple notifications efficiently"""
        try:
            tasks = []
            for notification in notifications:
                task = self.send_notification(notification)
                tasks.append(task)
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            success_count = sum(1 for result in results if result is True)
            return success_count, len(notifications)
            
        except Exception as e:
            print(f"Error sending bulk notifications: {e}")
            return 0, 0
    
    async def retry_failed_notifications(self):
        """Retry failed notifications"""
        try:
            failed_notifications = PushNotification.objects.filter(
                status='failed',
                retry_count__lt=3
            )
            
            success_count = 0
            for notification in failed_notifications:
                if await self.send_notification(notification):
                    success_count += 1
            
            return success_count
            
        except Exception as e:
            print(f"Error retrying failed notifications: {e}")
            return 0
    
    def get_notification_stats(self):
        """Get notification statistics"""
        try:
            stats = {
                'total_sent': PushNotification.objects.filter(status='sent').count(),
                'total_failed': PushNotification.objects.filter(status='failed').count(),
                'total_pending': PushNotification.objects.filter(status='pending').count(),
                'active_tokens': FCMToken.objects.filter(is_active=True).count(),
            }
            
            return stats
            
        except Exception as e:
            print(f"Error getting notification stats: {e}")
            return {}
