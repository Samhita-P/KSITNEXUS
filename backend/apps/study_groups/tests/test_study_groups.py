"""
Test cases for study groups functionality
"""
import json
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch, MagicMock
from ..models import StudyGroup, GroupMembership, GroupMessage, UpcomingEvent, Resource
from ..serializers import StudyGroupSerializer, GroupMessageSerializer

User = get_user_model()


class StudyGroupTestCase(APITestCase):
    """Test cases for study group endpoints"""
    
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
        
        self.study_group_data = {
            'name': 'Test Study Group',
            'description': 'This is a test study group',
            'subject': 'Computer Science',
            'is_private': False,
            'max_members': 10
        }
        
    def test_create_study_group(self):
        """Test creating a study group"""
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-list')
        
        response = self.client.post(url, self.study_group_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(StudyGroup.objects.count(), 1)
        
        study_group = StudyGroup.objects.first()
        self.assertEqual(study_group.name, 'Test Study Group')
        self.assertEqual(study_group.created_by, self.user)
        
        # Verify creator is automatically added as member
        self.assertTrue(GroupMembership.objects.filter(
            study_group=study_group,
            user=self.user,
            role='admin'
        ).exists())
        
    def test_join_study_group(self):
        """Test joining a study group"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='otherpass123'
        )
        
        self.client.force_authenticate(user=other_user)
        url = reverse('studygroup-join', kwargs={'pk': study_group.id})
        
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify user is added as member
        self.assertTrue(GroupMembership.objects.filter(
            study_group=study_group,
            user=other_user
        ).exists())
        
    def test_leave_study_group(self):
        """Test leaving a study group"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-leave', kwargs={'pk': study_group.id})
        
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify user is removed from group
        self.assertFalse(GroupMembership.objects.filter(
            study_group=study_group,
            user=self.user
        ).exists())
        
    def test_send_chat_message(self):
        """Test sending a chat message"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-messages', kwargs={'pk': study_group.id})
        data = {'content': 'Hello everyone!'}
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify message was created
        self.assertEqual(GroupMessage.objects.count(), 1)
        message = GroupMessage.objects.first()
        self.assertEqual(message.content, 'Hello everyone!')
        self.assertEqual(message.user, self.user)
        self.assertEqual(message.study_group, study_group)
        
    def test_get_chat_messages(self):
        """Test getting chat messages"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        # Create some messages
        GroupMessage.objects.create(
            study_group=study_group,
            user=self.user,
            content='Message 1'
        )
        GroupMessage.objects.create(
            study_group=study_group,
            user=self.user,
            content='Message 2'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-messages', kwargs={'pk': study_group.id})
        
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        
    def test_create_study_group_event(self):
        """Test creating a study group event"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='admin'
        )
        
        event_data = {
            'title': 'Study Session',
            'description': 'Group study session',
            'start_time': '2024-01-15T10:00:00Z',
            'end_time': '2024-01-15T12:00:00Z',
            'location': 'Library Room 101'
        }
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-events', kwargs={'pk': study_group.id})
        
        response = self.client.post(url, event_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify event was created
        self.assertEqual(UpcomingEvent.objects.count(), 1)
        event = UpcomingEvent.objects.first()
        self.assertEqual(event.title, 'Study Session')
        self.assertEqual(event.study_group, study_group)
        
    def test_upload_resource(self):
        """Test uploading a study group resource"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add user as member
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='member'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-resources', kwargs={'pk': study_group.id})
        
        with open('test_resource.txt', 'w') as f:
            f.write('Test resource content')
        
        with open('test_resource.txt', 'rb') as f:
            data = {
                'title': 'Test Resource',
                'description': 'A test resource file',
                'file': f
            }
            response = self.client.post(url, data, format='multipart')
            
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify resource was created
        self.assertEqual(Resource.objects.count(), 1)
        resource = Resource.objects.first()
        self.assertEqual(resource.title, 'Test Resource')
        self.assertEqual(resource.study_group, study_group)
        
    def test_study_group_search(self):
        """Test searching study groups"""
        StudyGroup.objects.create(
            name='Python Study Group',
            description='Learn Python programming',
            subject='Computer Science',
            created_by=self.user
        )
        StudyGroup.objects.create(
            name='Math Study Group',
            description='Advanced mathematics',
            subject='Mathematics',
            created_by=self.user
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-list')
        
        # Search by name
        response = self.client.get(url, {'search': 'Python'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Search by subject
        response = self.client.get(url, {'subject': 'Mathematics'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_study_group_filtering(self):
        """Test filtering study groups"""
        StudyGroup.objects.create(
            name='Public Group',
            description='Public study group',
            subject='Computer Science',
            is_private=False,
            created_by=self.user
        )
        StudyGroup.objects.create(
            name='Private Group',
            description='Private study group',
            subject='Computer Science',
            is_private=True,
            created_by=self.user
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-list')
        
        # Filter by privacy
        response = self.client.get(url, {'is_private': 'false'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_study_group_permissions(self):
        """Test study group permissions"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='otherpass123'
        )
        
        # Test that non-members cannot access private group data
        self.client.force_authenticate(user=other_user)
        url = reverse('studygroup-detail', kwargs={'pk': study_group.id})
        response = self.client.get(url)
        
        # Should be able to see public groups
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
    def test_study_group_serializer(self):
        """Test study group serializer"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        serializer = StudyGroupSerializer(study_group)
        data = serializer.data
        
        self.assertEqual(data['name'], 'Test Group')
        self.assertEqual(data['subject'], 'Computer Science')
        self.assertIn('created_at', data)
        self.assertIn('member_count', data)
        
    def test_study_group_message_serializer(self):
        """Test study group message serializer"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        message = GroupMessage.objects.create(
            study_group=study_group,
            user=self.user,
            content='Test message'
        )
        
        serializer = GroupMessageSerializer(message)
        data = serializer.data
        
        self.assertEqual(data['content'], 'Test message')
        self.assertEqual(data['user']['username'], 'testuser')
        self.assertIn('created_at', data)
        
    def test_study_group_statistics(self):
        """Test study group statistics"""
        study_group = StudyGroup.objects.create(
            name='Test Group',
            description='Test description',
            subject='Computer Science',
            created_by=self.user
        )
        
        # Add members
        GroupMembership.objects.create(
            study_group=study_group,
            user=self.user,
            role='admin'
        )
        
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='otherpass123'
        )
        GroupMembership.objects.create(
            study_group=study_group,
            user=other_user,
            role='member'
        )
        
        # Add messages
        GroupMessage.objects.create(
            study_group=study_group,
            user=self.user,
            content='Message 1'
        )
        GroupMessage.objects.create(
            study_group=study_group,
            user=other_user,
            content='Message 2'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('studygroup-statistics', kwargs={'pk': study_group.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('member_count', response.data)
        self.assertIn('message_count', response.data)
        self.assertIn('event_count', response.data)
        self.assertIn('resource_count', response.data)
