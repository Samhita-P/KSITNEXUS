"""
WebSocket and real-time features tests
"""

import json
import pytest
from django.test import TestCase
from django.contrib.auth import get_user_model
from channels.testing import WebsocketCommunicator
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .consumers import NotificationConsumer, StudyGroupConsumer, ChatConsumer, ReservationConsumer
from .models import Notification
from apps.study_groups.models import StudyGroup, GroupMessage
from apps.reservations.models import Reservation

User = get_user_model()


class NotificationConsumerTest(TestCase):
    """Test NotificationConsumer WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.notification = Notification.objects.create(
            user=self.user,
            title='Test Notification',
            message='This is a test notification',
            notification_type='info'
        )
    
    async def test_notification_consumer_connect(self):
        """Test notification consumer connection"""
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f'/ws/notifications/{self.user.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test receiving notification
        await communicator.send_json_to({
            'type': 'mark_read',
            'notification_id': str(self.notification.id)
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'notification')
        
        await communicator.disconnect()
    
    async def test_notification_consumer_disconnect(self):
        """Test notification consumer disconnection"""
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f'/ws/notifications/{self.user.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        await communicator.disconnect()
        # Should not raise any exceptions


class StudyGroupConsumerTest(TestCase):
    """Test StudyGroupConsumer WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test Description',
            max_members=10
        )
    
    async def test_study_group_consumer_connect(self):
        """Test study group consumer connection"""
        communicator = WebsocketCommunicator(
            StudyGroupConsumer.as_asgi(),
            f'/ws/study-groups/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test group update
        await communicator.send_json_to({
            'type': 'update_group',
            'data': {'name': 'Updated Group'}
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'group_update')
        
        await communicator.disconnect()
    
    async def test_join_group(self):
        """Test joining a study group"""
        communicator = WebsocketCommunicator(
            StudyGroupConsumer.as_asgi(),
            f'/ws/study-groups/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test join group
        await communicator.send_json_to({
            'type': 'join_group',
            'user_id': str(self.user.id)
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'join_result')
        self.assertTrue(response['success'])
        
        await communicator.disconnect()


class ChatConsumerTest(TestCase):
    """Test ChatConsumer WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test Description',
            max_members=10
        )
        self.study_group.members.add(self.user)
    
    async def test_chat_consumer_connect(self):
        """Test chat consumer connection"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f'/ws/chat/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test sending message
        await communicator.send_json_to({
            'type': 'chat_message',
            'user_id': str(self.user.id),
            'message': 'Hello, world!'
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'chat_message')
        self.assertIn('message', response)
        
        await communicator.disconnect()
    
    async def test_typing_indicator(self):
        """Test typing indicator"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f'/ws/chat/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test typing indicator
        await communicator.send_json_to({
            'type': 'typing',
            'user_id': str(self.user.id),
            'is_typing': True
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'typing')
        self.assertTrue(response['is_typing'])
        
        await communicator.disconnect()


class ReservationConsumerTest(TestCase):
    """Test ReservationConsumer WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.reservation = Reservation.objects.create(
            user=self.user,
            resource_type='library',
            start_time='2024-01-01T10:00:00Z',
            end_time='2024-01-01T12:00:00Z',
            status='confirmed'
        )
    
    async def test_reservation_consumer_connect(self):
        """Test reservation consumer connection"""
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            '/ws/reservations/library/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test receiving availability data
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'availability_data')
        self.assertIn('data', response)
        
        await communicator.disconnect()
    
    async def test_refresh_availability(self):
        """Test refreshing availability"""
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            '/ws/reservations/library/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Test refresh availability
        await communicator.send_json_to({
            'type': 'refresh_availability'
        })
        
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'availability_data')
        
        await communicator.disconnect()


class WebSocketIntegrationTest(TestCase):
    """Integration tests for WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test Description',
            max_members=10
        )
        self.study_group.members.add(self.user)
    
    async def test_notification_signal_integration(self):
        """Test notification signal integration with WebSocket"""
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f'/ws/notifications/{self.user.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Create a new notification (should trigger signal)
        notification = Notification.objects.create(
            user=self.user,
            title='Signal Test',
            message='This notification should be sent via WebSocket',
            notification_type='info'
        )
        
        # Should receive the notification via WebSocket
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'notification')
        self.assertEqual(response['notification']['title'], 'Signal Test')
        
        await communicator.disconnect()
    
    async def test_chat_message_signal_integration(self):
        """Test chat message signal integration with WebSocket"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f'/ws/chat/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Create a new chat message (should trigger signal)
        message = GroupMessage.objects.create(
            group=self.study_group,
            sender=self.user,
            content='Signal test message'
        )
        
        # Should receive the message via WebSocket
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'chat_message')
        self.assertEqual(response['message']['content'], 'Signal test message')
        
        await communicator.disconnect()
    
    async def test_reservation_signal_integration(self):
        """Test reservation signal integration with WebSocket"""
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            '/ws/reservations/library/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Create a new reservation (should trigger signal)
        reservation = Reservation.objects.create(
            user=self.user,
            resource_type='library',
            start_time='2024-01-01T14:00:00Z',
            end_time='2024-01-01T16:00:00Z',
            status='confirmed'
        )
        
        # Should receive availability update via WebSocket
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'availability_update')
        self.assertIn('data', response)
        
        await communicator.disconnect()


class WebSocketPerformanceTest(TestCase):
    """Performance tests for WebSocket functionality"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test Description',
            max_members=10
        )
        self.study_group.members.add(self.user)
    
    async def test_multiple_connections(self):
        """Test multiple WebSocket connections"""
        communicators = []
        
        try:
            # Create multiple connections
            for i in range(5):
                communicator = WebsocketCommunicator(
                    ChatConsumer.as_asgi(),
                    f'/ws/chat/{self.study_group.id}/'
                )
                connected, subprotocol = await communicator.connect()
                self.assertTrue(connected)
                communicators.append(communicator)
            
            # Send a message to all connections
            message = GroupMessage.objects.create(
                group=self.study_group,
                sender=self.user,
                content='Broadcast message'
            )
            
            # All connections should receive the message
            for communicator in communicators:
                response = await communicator.receive_json_from()
                self.assertEqual(response['type'], 'chat_message')
                self.assertEqual(response['message']['content'], 'Broadcast message')
        
        finally:
            # Clean up all connections
            for communicator in communicators:
                await communicator.disconnect()
    
    async def test_high_frequency_messages(self):
        """Test high frequency message handling"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f'/ws/chat/{self.study_group.id}/'
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        try:
            # Send multiple messages rapidly
            for i in range(10):
                await communicator.send_json_to({
                    'type': 'chat_message',
                    'user_id': str(self.user.id),
                    'message': f'Message {i}'
                })
                
                response = await communicator.receive_json_from()
                self.assertEqual(response['type'], 'chat_message')
                self.assertEqual(response['message']['content'], f'Message {i}')
        
        finally:
            await communicator.disconnect()
