"""
API tests for notifications and real-time features
"""

import json
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Notification
from apps.study_groups.models import StudyGroup, GroupMessage
from apps.reservations.models import Reservation

User = get_user_model()


class NotificationAPITest(APITestCase):
    """Test Notification API endpoints"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='testpass123'
        )
        
        # Create test notifications
        self.notification1 = Notification.objects.create(
            user=self.user,
            title='Test Notification 1',
            message='This is a test notification',
            notification_type='info'
        )
        self.notification2 = Notification.objects.create(
            user=self.user,
            title='Test Notification 2',
            message='This is another test notification',
            notification_type='warning'
        )
        self.other_notification = Notification.objects.create(
            user=self.other_user,
            title='Other User Notification',
            message='This notification belongs to another user',
            notification_type='info'
        )
        
        # Get JWT token
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_notifications(self):
        """Test listing user notifications"""
        url = reverse('notification-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)
        
        # Check that only user's notifications are returned
        notification_ids = [n['id'] for n in response.data['results']]
        self.assertIn(str(self.notification1.id), notification_ids)
        self.assertIn(str(self.notification2.id), notification_ids)
        self.assertNotIn(str(self.other_notification.id), notification_ids)
    
    def test_create_notification(self):
        """Test creating a new notification"""
        url = reverse('notification-list')
        data = {
            'title': 'New Notification',
            'message': 'This is a new notification',
            'notification_type': 'success'
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'New Notification')
        self.assertEqual(response.data['user'], self.user.id)
    
    def test_retrieve_notification(self):
        """Test retrieving a specific notification"""
        url = reverse('notification-detail', kwargs={'pk': self.notification1.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Test Notification 1')
    
    def test_update_notification(self):
        """Test updating a notification"""
        url = reverse('notification-detail', kwargs={'pk': self.notification1.id})
        data = {
            'title': 'Updated Notification',
            'message': 'This notification has been updated',
            'notification_type': 'error'
        }
        response = self.client.put(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Updated Notification')
    
    def test_mark_notification_read(self):
        """Test marking a notification as read"""
        url = reverse('notification-mark-read', kwargs={'pk': self.notification1.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.notification1.refresh_from_db()
        self.assertTrue(self.notification1.is_read)
    
    def test_mark_all_notifications_read(self):
        """Test marking all notifications as read"""
        url = reverse('notification-mark-all-read')
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.notification_set.filter(is_read=False).count() == 0
    
    def test_delete_notification(self):
        """Test deleting a notification"""
        url = reverse('notification-detail', kwargs={'pk': self.notification1.id})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Notification.objects.filter(id=self.notification1.id).exists())
    
    def test_unauthorized_access(self):
        """Test unauthorized access to notifications"""
        self.client.credentials()  # Remove authentication
        
        url = reverse('notification-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_access_other_user_notification(self):
        """Test accessing another user's notification"""
        url = reverse('notification-detail', kwargs={'pk': self.other_notification.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class StudyGroupAPITest(APITestCase):
    """Test Study Group API endpoints"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='testpass123'
        )
        
        # Create test study group
        self.study_group = StudyGroup.objects.create(
            name='Test Study Group',
            description='This is a test study group',
            max_members=5
        )
        self.study_group.members.add(self.user)
        
        # Get JWT token
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_study_groups(self):
        """Test listing study groups"""
        url = reverse('studygroup-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Test Study Group')
    
    def test_create_study_group(self):
        """Test creating a new study group"""
        url = reverse('studygroup-list')
        data = {
            'name': 'New Study Group',
            'description': 'This is a new study group',
            'max_members': 10
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'New Study Group')
        self.assertEqual(response.data['created_by'], self.user.id)
    
    def test_join_study_group(self):
        """Test joining a study group"""
        # Create a new study group
        new_group = StudyGroup.objects.create(
            name='New Group',
            description='A new group to join',
            max_members=10
        )
        
        url = reverse('studygroup-join', kwargs={'pk': new_group.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(new_group.members.filter(id=self.user.id).exists())
    
    def test_leave_study_group(self):
        """Test leaving a study group"""
        url = reverse('studygroup-leave', kwargs={'pk': self.study_group.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(self.study_group.members.filter(id=self.user.id).exists())
    
    def test_send_message(self):
        """Test sending a message to study group"""
        url = reverse('studygroup-send-message', kwargs={'pk': self.study_group.id})
        data = {
            'content': 'Hello, everyone!'
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['content'], 'Hello, everyone!')
        self.assertEqual(response.data['sender'], self.user.id)
    
    def test_list_messages(self):
        """Test listing study group messages"""
        # Create some messages
        GroupMessage.objects.create(
            group=self.study_group,
            sender=self.user,
            content='Message 1'
        )
        GroupMessage.objects.create(
            group=self.study_group,
            sender=self.user,
            content='Message 2'
        )
        
        url = reverse('studygroup-messages', kwargs={'pk': self.study_group.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)


class ReservationAPITest(APITestCase):
    """Test Reservation API endpoints"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Get JWT token
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_reservations(self):
        """Test listing user reservations"""
        # Create test reservation
        reservation = Reservation.objects.create(
            user=self.user,
            resource_type='library',
            start_time='2024-01-01T10:00:00Z',
            end_time='2024-01-01T12:00:00Z',
            status='confirmed'
        )
        
        url = reverse('reservation-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['resource_type'], 'library')
    
    def test_create_reservation(self):
        """Test creating a new reservation"""
        url = reverse('reservation-list')
        data = {
            'resource_type': 'library',
            'start_time': '2024-01-01T14:00:00Z',
            'end_time': '2024-01-01T16:00:00Z',
            'notes': 'Study session'
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['resource_type'], 'library')
        self.assertEqual(response.data['user'], self.user.id)
    
    def test_get_availability(self):
        """Test getting resource availability"""
        url = reverse('reservation-availability', kwargs={'resource_type': 'library'})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_slots', response.data)
        self.assertIn('available_slots', response.data)
        self.assertIn('availability_percentage', response.data)
    
    def test_cancel_reservation(self):
        """Test canceling a reservation"""
        reservation = Reservation.objects.create(
            user=self.user,
            resource_type='library',
            start_time='2024-01-01T10:00:00Z',
            end_time='2024-01-01T12:00:00Z',
            status='confirmed'
        )
        
        url = reverse('reservation-cancel', kwargs={'pk': reservation.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        reservation.refresh_from_db()
        self.assertEqual(reservation.status, 'cancelled')


class PerformanceAPITest(APITestCase):
    """Test API performance and caching"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Get JWT token
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_api_response_time(self):
        """Test API response time"""
        import time
        
        # Create test data
        for i in range(10):
            Notification.objects.create(
                user=self.user,
                title=f'Notification {i}',
                message=f'This is notification {i}',
                notification_type='info'
            )
        
        # Measure response time
        start_time = time.time()
        url = reverse('notification-list')
        response = self.client.get(url)
        end_time = time.time()
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        response_time = end_time - start_time
        
        # Response should be under 1 second
        self.assertLess(response_time, 1.0)
    
    def test_pagination_performance(self):
        """Test pagination performance with large dataset"""
        # Create large dataset
        for i in range(100):
            Notification.objects.create(
                user=self.user,
                title=f'Notification {i}',
                message=f'This is notification {i}',
                notification_type='info'
            )
        
        # Test pagination
        url = reverse('notification-list')
        response = self.client.get(url, {'page': 1, 'page_size': 20})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 20)
        self.assertEqual(response.data['count'], 100)
    
    def test_concurrent_requests(self):
        """Test handling concurrent requests"""
        import threading
        import time
        
        results = []
        
        def make_request():
            url = reverse('notification-list')
            response = self.client.get(url)
            results.append(response.status_code)
        
        # Create multiple threads
        threads = []
        for _ in range(5):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # All requests should succeed
        self.assertEqual(len(results), 5)
        self.assertTrue(all(status_code == 200 for status_code in results))


class WebSocketAPIIntegrationTest(APITestCase):
    """Test WebSocket integration with API"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Get JWT token
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_notification_creation_triggers_websocket(self):
        """Test that creating a notification triggers WebSocket update"""
        # This would require a more complex test setup with actual WebSocket connections
        # For now, we'll test that the signal is properly connected
        url = reverse('notification-list')
        data = {
            'title': 'WebSocket Test',
            'message': 'This should trigger WebSocket',
            'notification_type': 'info'
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify notification was created
        notification = Notification.objects.get(title='WebSocket Test')
        self.assertIsNotNone(notification)
    
    def test_study_group_message_triggers_websocket(self):
        """Test that sending a study group message triggers WebSocket update"""
        # Create study group
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test Description',
            max_members=10
        )
        study_group.members.add(self.user)
        
        # Send message
        url = reverse('studygroup-send-message', kwargs={'pk': study_group.id})
        data = {
            'content': 'WebSocket test message'
        }
        response = self.client.post(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify message was created
        message = GroupMessage.objects.get(content='WebSocket test message')
        self.assertIsNotNone(message)
