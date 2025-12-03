"""
WebSocket consumers for real-time features
"""

import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Notification
from apps.study_groups.models import StudyGroup, GroupMessage
from apps.reservations.models import Reservation

User = get_user_model()


class NotificationConsumer(AsyncWebsocketConsumer):
    """Consumer for real-time notifications"""
    
    async def connect(self):
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.room_group_name = f'notifications_{self.user_id}'
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # Send any pending notifications
        await self.send_pending_notifications()
    
    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'mark_read':
            notification_id = data.get('notification_id')
            await self.mark_notification_read(notification_id)
        elif message_type == 'mark_all_read':
            await self.mark_all_notifications_read()
    
    async def send_notification(self, event):
        """Send notification to WebSocket"""
        notification = event['notification']
        
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'notification': notification
        }))
    
    async def send_pending_notifications(self):
        """Send any unread notifications on connect"""
        notifications = await self.get_unread_notifications()
        for notification in notifications:
            await self.send(text_data=json.dumps({
                'type': 'notification',
                'notification': notification
            }))
    
    @database_sync_to_async
    def get_unread_notifications(self):
        """Get unread notifications for user"""
        try:
            user = User.objects.get(id=self.user_id)
            notifications = Notification.objects.filter(
                user=user,
                is_read=False
            ).order_by('-created_at')[:10]
            
            return [
                {
                    'id': str(notification.id),
                    'title': notification.title,
                    'message': notification.message,
                    'type': notification.type,
                    'is_read': notification.is_read,
                    'created_at': notification.created_at.isoformat(),
                }
                for notification in notifications
            ]
        except User.DoesNotExist:
            return []
    
    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """Mark a specific notification as read"""
        try:
            notification = Notification.objects.get(
                id=notification_id,
                user_id=self.user_id
            )
            notification.is_read = True
            notification.save()
        except Notification.DoesNotExist:
            pass
    
    @database_sync_to_async
    def mark_all_notifications_read(self):
        """Mark all notifications as read for user"""
        Notification.objects.filter(
            user_id=self.user_id,
            is_read=False
        ).update(is_read=True)


class StudyGroupConsumer(AsyncWebsocketConsumer):
    """Consumer for study group updates"""
    
    async def connect(self):
        self.group_id = self.scope['url_route']['kwargs']['group_id']
        self.room_group_name = f'study_group_{self.group_id}'
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'join_group':
            await self.handle_join_group(data)
        elif message_type == 'leave_group':
            await self.handle_leave_group(data)
        elif message_type == 'update_group':
            await self.handle_update_group(data)
    
    async def group_update(self, event):
        """Send group update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'group_update',
            'data': event['data']
        }))
    
    async def handle_join_group(self, data):
        """Handle user joining group"""
        user_id = data.get('user_id')
        success = await self.add_user_to_group(user_id)
        
        await self.send(text_data=json.dumps({
            'type': 'join_result',
            'success': success,
            'message': 'Joined group successfully' if success else 'Failed to join group'
        }))
    
    async def handle_leave_group(self, data):
        """Handle user leaving group"""
        user_id = data.get('user_id')
        success = await self.remove_user_from_group(user_id)
        
        await self.send(text_data=json.dumps({
            'type': 'leave_result',
            'success': success,
            'message': 'Left group successfully' if success else 'Failed to leave group'
        }))
    
    async def handle_update_group(self, data):
        """Handle group updates"""
        group_data = await self.get_group_data()
        
        # Send update to all group members
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'group_update',
                'data': group_data
            }
        )
    
    @database_sync_to_async
    def add_user_to_group(self, user_id):
        """Add user to study group"""
        try:
            user = User.objects.get(id=user_id)
            group = StudyGroup.objects.get(id=self.group_id)
            
            if group.members.filter(id=user_id).exists():
                return False  # Already a member
            
            group.members.add(user)
            return True
        except (User.DoesNotExist, StudyGroup.DoesNotExist):
            return False
    
    @database_sync_to_async
    def remove_user_from_group(self, user_id):
        """Remove user from study group"""
        try:
            user = User.objects.get(id=user_id)
            group = StudyGroup.objects.get(id=self.group_id)
            
            if not group.members.filter(id=user_id).exists():
                return False  # Not a member
            
            group.members.remove(user)
            return True
        except (User.DoesNotExist, StudyGroup.DoesNotExist):
            return False
    
    @database_sync_to_async
    def get_group_data(self):
        """Get current group data"""
        try:
            group = StudyGroup.objects.get(id=self.group_id)
            return {
                'id': str(group.id),
                'name': group.name,
                'description': group.description,
                'member_count': group.members.count(),
                'max_members': group.max_members,
                'is_active': group.is_active,
            }
        except StudyGroup.DoesNotExist:
            return None


class ChatConsumer(AsyncWebsocketConsumer):
    """Consumer for study group chat"""
    
    async def connect(self):
        self.group_id = self.scope['url_route']['kwargs']['group_id']
        self.room_group_name = f'chat_{self.group_id}'
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'chat_message':
            await self.handle_chat_message(data)
        elif message_type == 'typing':
            await self.handle_typing(data)
    
    async def chat_message(self, event):
        """Send chat message to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message']
        }))
    
    async def user_typing(self, event):
        """Send typing indicator to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'typing',
            'user': event['user'],
            'is_typing': event['is_typing']
        }))
    
    async def handle_chat_message(self, data):
        """Handle incoming chat message"""
        user_id = data.get('user_id')
        message_text = data.get('message')
        
        if user_id and message_text:
            message_data = await self.save_chat_message(user_id, message_text)
            
            # Send message to all group members
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': message_data
                }
            )
    
    async def handle_typing(self, data):
        """Handle typing indicator"""
        user_id = data.get('user_id')
        is_typing = data.get('is_typing', False)
        
        if user_id:
            user_data = await self.get_user_data(user_id)
            
            # Send typing indicator to all group members except sender
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_typing',
                    'user': user_data,
                    'is_typing': is_typing
                }
            )
    
    @database_sync_to_async
    def save_chat_message(self, user_id, message_text):
        """Save chat message to database"""
        try:
            user = User.objects.get(id=user_id)
            group = StudyGroup.objects.get(id=self.group_id)
            
            message = GroupMessage.objects.create(
                group=group,
                sender=user,
                content=message_text
            )
            
            return {
                'id': str(message.id),
                'content': message.content,
                'sender': {
                    'id': str(user.id),
                    'name': user.get_full_name() or user.username,
                    'profile_picture': user.profile_picture.url if user.profile_picture else None,
                },
                'created_at': message.created_at.isoformat(),
            }
        except (User.DoesNotExist, StudyGroup.DoesNotExist):
            return None
    
    @database_sync_to_async
    def get_user_data(self, user_id):
        """Get user data for typing indicator"""
        try:
            user = User.objects.get(id=user_id)
            return {
                'id': str(user.id),
                'name': user.get_full_name() or user.username,
                'profile_picture': user.profile_picture.url if user.profile_picture else None,
            }
        except User.DoesNotExist:
            return None


class ReservationConsumer(AsyncWebsocketConsumer):
    """Consumer for live seat availability updates"""
    
    async def connect(self):
        self.resource_type = self.scope['url_route']['kwargs']['resource_type']
        self.room_group_name = f'reservations_{self.resource_type}'
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # Send current availability
        await self.send_current_availability()
    
    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'refresh_availability':
            await self.send_current_availability()
    
    async def availability_update(self, event):
        """Send availability update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'availability_update',
            'data': event['data']
        }))
    
    async def send_current_availability(self):
        """Send current availability status"""
        availability_data = await self.get_current_availability()
        
        await self.send(text_data=json.dumps({
            'type': 'availability_data',
            'data': availability_data
        }))
    
    @database_sync_to_async
    def get_current_availability(self):
        """Get current availability for resource type"""
        try:
            # Get all reservations for this resource type
            reservations = Reservation.objects.filter(
                resource_type=self.resource_type,
                status__in=['confirmed', 'pending']
            ).select_related('user')
            
            # Calculate availability
            total_slots = 50  # Default total slots, can be made configurable
            occupied_slots = reservations.count()
            available_slots = total_slots - occupied_slots
            
            # Get recent reservations (last 10)
            recent_reservations = reservations.order_by('-created_at')[:10]
            
            return {
                'resource_type': self.resource_type,
                'total_slots': total_slots,
                'occupied_slots': occupied_slots,
                'available_slots': available_slots,
                'availability_percentage': (available_slots / total_slots) * 100,
                'recent_reservations': [
                    {
                        'id': str(reservation.id),
                        'user': {
                            'id': str(reservation.user.id),
                            'name': reservation.user.get_full_name() or reservation.user.username,
                        },
                        'start_time': reservation.start_time.isoformat(),
                        'end_time': reservation.end_time.isoformat(),
                        'status': reservation.status,
                        'created_at': reservation.created_at.isoformat(),
                    }
                    for reservation in recent_reservations
                ],
                'last_updated': timezone.now().isoformat(),
            }
        except Exception as e:
            return {
                'resource_type': self.resource_type,
                'error': str(e),
                'total_slots': 0,
                'occupied_slots': 0,
                'available_slots': 0,
                'availability_percentage': 0,
                'recent_reservations': [],
            }
