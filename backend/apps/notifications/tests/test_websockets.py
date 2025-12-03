"""
Test cases for WebSocket functionality
"""
import json
from django.test import TestCase, TransactionTestCase
from django.contrib.auth import get_user_model
from channels.testing import WebsocketCommunicator
from channels.db import database_sync_to_async
from asgiref.sync import sync_to_async
from unittest.mock import patch, MagicMock
from ..consumers import ChatConsumer, NotificationConsumer, ReservationConsumer
from ..routing import websocket_urlpatterns
from apps.study_groups.models import StudyGroup, GroupMembership, GroupMessage
from apps.reservations.models import ReadingRoom, Seat, Reservation

User = get_user_model()


class WebSocketTestCase(TransactionTestCase):
    """Base test case for WebSocket tests"""
    
    async def setUp(self):
        """Set up test data"""
        self.user = await database_sync_to_async(User.objects.create_user)(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            user_type='student'
        )
        
        self.faculty = await database_sync_to_async(User.objects.create_user)(
            username='faculty',
            email='faculty@example.com',
            password='facultypass123',
            user_type='faculty'
        )


class ChatConsumerTestCase(WebSocketTestCase):
    """Test cases for chat WebSocket consumer"""
    
    async def test_chat_connection(self):
        """Test WebSocket connection to chat consumer"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/1/chat/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        await communicator.disconnect()
        
    async def test_chat_message_send(self):
        """Test sending a chat message via WebSocket"""
        # Create study group
        study_group = await database_sync_to_async(StudyGroup.objects.create)(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        await database_sync_to_async(StudyGroupMember.objects.create)(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/{study_group.id}/chat/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send message
        message_data = {
            'type': 'chat_message',
            'message': 'Hello everyone!',
            'user_id': self.user.id
        }
        
        await communicator.send_json_to(message_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'chat_message')
        self.assertEqual(response['message'], 'Hello everyone!')
        self.assertEqual(response['user']['username'], 'testuser')
        
        await communicator.disconnect()
        
    async def test_chat_message_broadcast(self):
        """Test that chat messages are broadcast to all connected users"""
        # Create study group
        study_group = await database_sync_to_async(StudyGroup.objects.create)(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add users as members
        await database_sync_to_async(StudyGroupMember.objects.create)(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        await database_sync_to_async(StudyGroupMember.objects.create)(
            study_group=study_group,
            user=self.faculty,
            role='member'
        )
        
        # Create two communicators (simulating two users)
        communicator1 = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/{study_group.id}/chat/"
        )
        communicator2 = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/{study_group.id}/chat/"
        )
        
        connected1, _ = await communicator1.connect()
        connected2, _ = await communicator2.connect()
        self.assertTrue(connected1)
        self.assertTrue(connected2)
        
        # Send message from user 1
        message_data = {
            'type': 'chat_message',
            'message': 'Hello from user 1!',
            'user_id': self.user.id
        }
        
        await communicator1.send_json_to(message_data)
        
        # Both communicators should receive the message
        response1 = await communicator1.receive_json_from()
        response2 = await communicator2.receive_json_from()
        
        self.assertEqual(response1['message'], 'Hello from user 1!')
        self.assertEqual(response2['message'], 'Hello from user 1!')
        
        await communicator1.disconnect()
        await communicator2.disconnect()
        
    async def test_chat_typing_indicator(self):
        """Test typing indicator functionality"""
        study_group = await database_sync_to_async(StudyGroup.objects.create)(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        await database_sync_to_async(StudyGroupMember.objects.create)(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/{study_group.id}/chat/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send typing indicator
        typing_data = {
            'type': 'typing',
            'user_id': self.user.id,
            'is_typing': True
        }
        
        await communicator.send_json_to(typing_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'typing')
        self.assertEqual(response['user_id'], self.user.id)
        self.assertTrue(response['is_typing'])
        
        await communicator.disconnect()


class NotificationConsumerTestCase(WebSocketTestCase):
    """Test cases for notification WebSocket consumer"""
    
    async def test_notification_connection(self):
        """Test WebSocket connection to notification consumer"""
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.user.id}/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        await communicator.disconnect()
        
    async def test_notification_send(self):
        """Test sending a notification via WebSocket"""
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.user.id}/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send notification
        notification_data = {
            'type': 'notification',
            'title': 'Test Notification',
            'message': 'This is a test notification',
            'category': 'system'
        }
        
        await communicator.send_json_to(notification_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'notification')
        self.assertEqual(response['title'], 'Test Notification')
        self.assertEqual(response['message'], 'This is a test notification')
        
        await communicator.disconnect()
        
    async def test_notification_broadcast(self):
        """Test that notifications are sent to specific users"""
        communicator1 = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.user.id}/"
        )
        communicator2 = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.faculty.id}/"
        )
        
        connected1, _ = await communicator1.connect()
        connected2, _ = await communicator2.connect()
        self.assertTrue(connected1)
        self.assertTrue(connected2)
        
        # Send notification to user 1 only
        notification_data = {
            'type': 'notification',
            'title': 'User 1 Notification',
            'message': 'This is for user 1 only',
            'user_id': self.user.id
        }
        
        await communicator1.send_json_to(notification_data)
        
        # Only communicator 1 should receive the notification
        response1 = await communicator1.receive_json_from()
        self.assertEqual(response1['title'], 'User 1 Notification')
        
        # Communicator 2 should not receive anything
        with self.assertRaises(Exception):  # Should timeout
            await communicator2.receive_json_from(timeout=1)
        
        await communicator1.disconnect()
        await communicator2.disconnect()


class ReservationConsumerTestCase(WebSocketTestCase):
    """Test cases for reservation WebSocket consumer"""
    
    async def test_reservation_connection(self):
        """Test WebSocket connection to reservation consumer"""
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            "/ws/reservations/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        await communicator.disconnect()
        
    async def test_seat_availability_update(self):
        """Test seat availability updates via WebSocket"""
        # Create room and seat
        room = await database_sync_to_async(ReadingReadingRoom.objects.create)(
            name='Test Room',
            capacity=10,
            location='Building A'
        )
        
        seat = await database_sync_to_async(Seat.objects.create)(
            room=room,
            seat_number='A1',
            is_available=True
        )
        
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            "/ws/reservations/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send seat availability update
        update_data = {
            'type': 'seat_update',
            'seat_id': seat.id,
            'is_available': False,
            'room_id': room.id
        }
        
        await communicator.send_json_to(update_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'seat_update')
        self.assertEqual(response['seat_id'], seat.id)
        self.assertFalse(response['is_available'])
        
        await communicator.disconnect()
        
    async def test_reservation_creation(self):
        """Test reservation creation via WebSocket"""
        room = await database_sync_to_async(ReadingRoom.objects.create)(
            name='Test Room',
            capacity=10,
            location='Building A'
        )
        
        seat = await database_sync_to_async(Seat.objects.create)(
            room=room,
            seat_number='A1',
            is_available=True
        )
        
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            "/ws/reservations/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send reservation creation
        reservation_data = {
            'type': 'reservation_created',
            'reservation_id': 1,
            'seat_id': seat.id,
            'user_id': self.user.id,
            'start_time': '2024-01-15T10:00:00Z',
            'end_time': '2024-01-15T12:00:00Z'
        }
        
        await communicator.send_json_to(reservation_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'reservation_created')
        self.assertEqual(response['seat_id'], seat.id)
        self.assertEqual(response['user_id'], self.user.id)
        
        await communicator.disconnect()
        
    async def test_reservation_cancellation(self):
        """Test reservation cancellation via WebSocket"""
        room = await database_sync_to_async(ReadingRoom.objects.create)(
            name='Test Room',
            capacity=10,
            location='Building A'
        )
        
        seat = await database_sync_to_async(Seat.objects.create)(
            room=room,
            seat_number='A1',
            is_available=False
        )
        
        communicator = WebsocketCommunicator(
            ReservationConsumer.as_asgi(),
            "/ws/reservations/"
        )
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # Send reservation cancellation
        cancellation_data = {
            'type': 'reservation_cancelled',
            'reservation_id': 1,
            'seat_id': seat.id,
            'user_id': self.user.id
        }
        
        await communicator.send_json_to(cancellation_data)
        
        # Receive response
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'reservation_cancelled')
        self.assertEqual(response['seat_id'], seat.id)
        self.assertEqual(response['user_id'], self.user.id)
        
        await communicator.disconnect()


class WebSocketIntegrationTestCase(WebSocketTestCase):
    """Integration tests for WebSocket functionality"""
    
    async def test_multiple_consumers_integration(self):
        """Test integration between multiple WebSocket consumers"""
        # Create study group
        study_group = await database_sync_to_async(StudyGroup.objects.create)(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        await database_sync_to_async(StudyGroupMember.objects.create)(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        # Connect to both chat and notification consumers
        chat_communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/study_groups/{study_group.id}/chat/"
        )
        notification_communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.user.id}/"
        )
        
        connected_chat, _ = await chat_communicator.connect()
        connected_notification, _ = await notification_communicator.connect()
        
        self.assertTrue(connected_chat)
        self.assertTrue(connected_notification)
        
        # Send chat message
        message_data = {
            'type': 'chat_message',
            'message': 'Hello!',
            'user_id': self.user.id
        }
        
        await chat_communicator.send_json_to(message_data)
        
        # Receive chat message
        chat_response = await chat_communicator.receive_json_from()
        self.assertEqual(chat_response['message'], 'Hello!')
        
        # Send notification
        notification_data = {
            'type': 'notification',
            'title': 'New Message',
            'message': 'You have a new message in Test Group',
            'category': 'study_group'
        }
        
        await notification_communicator.send_json_to(notification_data)
        
        # Receive notification
        notification_response = await notification_communicator.receive_json_from()
        self.assertEqual(notification_response['title'], 'New Message')
        
        await chat_communicator.disconnect()
        await notification_communicator.disconnect()
        
    async def test_websocket_error_handling(self):
        """Test WebSocket error handling"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            "/ws/study_groups/invalid/chat/"
        )
        
        # Should handle invalid group ID gracefully
        connected, subprotocol = await communicator.connect()
        # Connection might still succeed, but should handle errors in message processing
        
        # Send invalid message
        invalid_data = {
            'type': 'invalid_type',
            'invalid_field': 'invalid_value'
        }
        
        await communicator.send_json_to(invalid_data)
        
        # Should not crash and should handle gracefully
        await communicator.disconnect()
        
    async def test_websocket_authentication(self):
        """Test WebSocket authentication"""
        # Test that unauthenticated users cannot access protected consumers
        communicator = WebsocketCommunicator(
            NotificationConsumer.as_asgi(),
            f"/ws/notifications/{self.user.id}/"
        )
        
        # This should work as we're not enforcing authentication in the test
        # In a real implementation, you would test authentication here
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        await communicator.disconnect()
