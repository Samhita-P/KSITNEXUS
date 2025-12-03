"""
Test cases for notifications functionality
"""
import json
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch, MagicMock
from ..models import Notification, NotificationPreference
from ..serializers import NotificationSerializer

User = get_user_model()


class NotificationTestCase(APITestCase):
    """Test cases for notification endpoints"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            user_type='student'
        )
        self.faculty = User.objects.create_user(
            username='faculty',
            email='faculty@example.com',
            password='facultypass123',
            user_type='faculty'
        )
        self.client.force_authenticate(user=self.user)
        
    def test_create_notification(self):
        """Test creating a notification"""
        url = reverse('notification-list')
        data = {
            'title': 'Test Notification',
            'message': 'This is a test notification',
            'category': 'system',
            'priority': 'medium',
            'recipients': [self.user.id]
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Notification.objects.count(), 1)
        
        notification = Notification.objects.first()
        self.assertEqual(notification.title, 'Test Notification')
        self.assertEqual(notification.message, 'This is a test notification')
        
    def test_get_user_notifications(self):
        """Test getting user notifications"""
        # Create notifications
        Notification.objects.create(
            title='Notification 1',
            message='Message 1',
            category='system',
            priority='high',
            user=self.user
        )
        Notification.objects.create(
            title='Notification 2',
            message='Message 2',
            category='academic',
            priority='medium',
            user=self.user
        )
        Notification.objects.create(
            title='Notification 3',
            message='Message 3',
            category='system',
            priority='low',
            user=self.faculty
        )
        
        url = reverse('notification-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)  # Only user's notifications
        
    def test_mark_notification_as_read(self):
        """Test marking notification as read"""
        notification = Notification.objects.create(
            title='Test Notification',
            message='Test message',
            category='system',
            priority='medium',
            user=self.user,
            is_read=False
        )
        
        url = reverse('notification-mark-read', kwargs={'pk': notification.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        notification.refresh_from_db()
        self.assertTrue(notification.is_read)
        
    def test_mark_all_notifications_as_read(self):
        """Test marking all notifications as read"""
        # Create unread notifications
        Notification.objects.create(
            title='Notification 1',
            message='Message 1',
            category='system',
            priority='high',
            user=self.user,
            is_read=False
        )
        Notification.objects.create(
            title='Notification 2',
            message='Message 2',
            category='academic',
            priority='medium',
            user=self.user,
            is_read=False
        )
        
        url = reverse('notification-mark-all-read')
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify all notifications are marked as read
        unread_count = Notification.objects.filter(user=self.user, is_read=False).count()
        self.assertEqual(unread_count, 0)
        
    def test_notification_filtering(self):
        """Test filtering notifications by category and status"""
        # Create notifications with different categories
        Notification.objects.create(
            title='System Notification',
            message='System message',
            category='system',
            priority='high',
            user=self.user,
            is_read=False
        )
        Notification.objects.create(
            title='Academic Notification',
            message='Academic message',
            category='academic',
            priority='medium',
            user=self.user,
            is_read=True
        )
        
        url = reverse('notification-list')
        
        # Filter by category
        response = self.client.get(url, {'category': 'system'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Filter by read status
        response = self.client.get(url, {'is_read': 'false'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_notification_search(self):
        """Test searching notifications"""
        Notification.objects.create(
            title='Library Update',
            message='Library will be closed tomorrow',
            category='system',
            priority='medium',
            user=self.user
        )
        Notification.objects.create(
            title='Exam Schedule',
            message='Final exams start next week',
            category='academic',
            priority='high',
            user=self.user
        )
        
        url = reverse('notification-list')
        
        # Search by title
        response = self.client.get(url, {'search': 'Library'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Search by message
        response = self.client.get(url, {'search': 'exams'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_notification_preferences(self):
        """Test notification preferences"""
        url = reverse('notification-preferences')
        
        # Get current preferences
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Update preferences
        data = {
            'email_notifications': True,
            'push_notifications': False,
            'categories': {
                'system': True,
                'academic': True,
                'social': False
            }
        }
        
        response = self.client.put(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify preferences were updated
        preferences = NotificationPreference.objects.get(user=self.user)
        self.assertTrue(preferences.email_notifications)
        self.assertFalse(preferences.push_notifications)
        
    def test_notification_statistics(self):
        """Test notification statistics"""
        # Create notifications with different statuses
        Notification.objects.create(
            title='Notification 1',
            message='Message 1',
            category='system',
            priority='high',
            user=self.user,
            is_read=True
        )
        Notification.objects.create(
            title='Notification 2',
            message='Message 2',
            category='academic',
            priority='medium',
            user=self.user,
            is_read=False
        )
        Notification.objects.create(
            title='Notification 3',
            message='Message 3',
            category='system',
            priority='low',
            user=self.user,
            is_read=False
        )
        
        url = reverse('notification-statistics')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_notifications', response.data)
        self.assertIn('unread_notifications', response.data)
        self.assertIn('notifications_by_category', response.data)
        self.assertEqual(response.data['total_notifications'], 3)
        self.assertEqual(response.data['unread_notifications'], 2)
        
    def test_bulk_notification_operations(self):
        """Test bulk notification operations"""
        # Create multiple notifications
        notifications = []
        for i in range(5):
            notification = Notification.objects.create(
                title=f'Notification {i+1}',
                message=f'Message {i+1}',
                category='system',
                priority='medium',
                user=self.user,
                is_read=False
            )
            notifications.append(notification)
        
        # Mark multiple notifications as read
        notification_ids = [n.id for n in notifications[:3]]
        url = reverse('notification-bulk-mark-read')
        data = {'notification_ids': notification_ids}
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify notifications were marked as read
        read_count = Notification.objects.filter(
            id__in=notification_ids,
            is_read=True
        ).count()
        self.assertEqual(read_count, 3)
        
    def test_notification_serializer(self):
        """Test notification serializer"""
        notification = Notification.objects.create(
            title='Test Notification',
            message='Test message',
            category='system',
            priority='high',
            user=self.user
        )
        
        serializer = NotificationSerializer(notification)
        data = serializer.data
        
        self.assertEqual(data['title'], 'Test Notification')
        self.assertEqual(data['message'], 'Test message')
        self.assertEqual(data['category'], 'system')
        self.assertEqual(data['priority'], 'high')
        self.assertIn('created_at', data)
        self.assertIn('is_read', data)
        
    def test_notification_permissions(self):
        """Test notification permissions"""
        # Create notification for another user
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='otherpass123'
        )
        
        notification = Notification.objects.create(
            title='Other User Notification',
            message='This is for another user',
            category='system',
            priority='medium',
            user=other_user
        )
        
        # Try to access other user's notification
        url = reverse('notification-detail', kwargs={'pk': notification.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        
    def test_notification_creation_with_attachments(self):
        """Test creating notification with attachments"""
        url = reverse('notification-list')
        
        with open('test_attachment.txt', 'w') as f:
            f.write('Test attachment content')
        
        with open('test_attachment.txt', 'rb') as f:
            data = {
                'title': 'Notification with Attachment',
                'message': 'This notification has an attachment',
                'category': 'system',
                'priority': 'medium',
                'recipients': [self.user.id],
                'attachments': f
            }
            response = self.client.post(url, data, format='multipart')
            
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        notification = Notification.objects.first()
        self.assertTrue(notification.attachments.exists())
        
    def test_notification_priority_ordering(self):
        """Test notification ordering by priority"""
        # Create notifications with different priorities
        Notification.objects.create(
            title='Low Priority',
            message='Low priority message',
            category='system',
            priority='low',
            user=self.user
        )
        Notification.objects.create(
            title='High Priority',
            message='High priority message',
            category='system',
            priority='high',
            user=self.user
        )
        Notification.objects.create(
            title='Medium Priority',
            message='Medium priority message',
            category='system',
            priority='medium',
            user=self.user
        )
        
        url = reverse('notification-list')
        response = self.client.get(url, {'ordering': '-priority'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        priorities = [item['priority'] for item in response.data]
        self.assertEqual(priorities, ['high', 'medium', 'low'])
        
    def test_notification_cleanup(self):
        """Test notification cleanup for old notifications"""
        from datetime import datetime, timedelta
        from django.utils import timezone
        
        # Create old notification
        old_date = timezone.now() - timedelta(days=30)
        Notification.objects.create(
            title='Old Notification',
            message='This is an old notification',
            category='system',
            priority='low',
            user=self.user,
            created_at=old_date
        )
        
        # Create recent notification
        Notification.objects.create(
            title='Recent Notification',
            message='This is a recent notification',
            category='system',
            priority='high',
            user=self.user
        )
        
        url = reverse('notification-cleanup')
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify old notification was cleaned up
        self.assertEqual(Notification.objects.count(), 1)
        self.assertEqual(Notification.objects.first().title, 'Recent Notification')
