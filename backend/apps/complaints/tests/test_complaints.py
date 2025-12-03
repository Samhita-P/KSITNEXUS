"""
Test cases for complaints functionality
"""
import json
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch, MagicMock
from ..models import Complaint
from ..serializers import ComplaintSerializer

User = get_user_model()


class ComplaintTestCase(APITestCase):
    """Test cases for complaint endpoints"""
    
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
        self.admin = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass123',
            user_type='admin'
        )
        
        self.complaint_data = {
            'title': 'Test Complaint',
            'description': 'This is a test complaint',
            'category': 'academic',
            'priority': 'medium',
            'is_anonymous': False
        }
        
    def test_create_complaint_authenticated(self):
        """Test creating complaint when authenticated"""
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        
        response = self.client.post(url, self.complaint_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Complaint.objects.count(), 1)
        
        complaint = Complaint.objects.first()
        self.assertEqual(complaint.title, 'Test Complaint')
        self.assertEqual(complaint.user, self.user)
        
    def test_create_complaint_anonymous(self):
        """Test creating anonymous complaint"""
        url = reverse('complaint-list')
        anonymous_data = {
            **self.complaint_data,
            'is_anonymous': True,
            'contact_email': 'anonymous@example.com'
        }
        
        response = self.client.post(url, anonymous_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        complaint = Complaint.objects.first()
        self.assertTrue(complaint.is_anonymous)
        self.assertEqual(complaint.contact_email, 'anonymous@example.com')
        
    def test_create_complaint_with_file(self):
        """Test creating complaint with file attachment"""
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        
        with open('test_file.txt', 'w') as f:
            f.write('Test file content')
        
        with open('test_file.txt', 'rb') as f:
            data = {
                **self.complaint_data,
                'attachments': f
            }
            response = self.client.post(url, data, format='multipart')
            
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        complaint = Complaint.objects.first()
        self.assertTrue(complaint.attachments.exists())
        
    def test_list_complaints_student(self):
        """Test listing complaints for student"""
        # Create complaints
        Complaint.objects.create(
            user=self.user,
            title='My Complaint',
            description='Test description',
            category='academic',
            priority='high'
        )
        Complaint.objects.create(
            user=self.faculty,
            title='Other Complaint',
            description='Other description',
            category='administrative',
            priority='low'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  # Only own complaints
        
    def test_list_complaints_admin(self):
        """Test listing complaints for admin"""
        # Create complaints
        Complaint.objects.create(
            user=self.user,
            title='Student Complaint',
            description='Test description',
            category='academic',
            priority='high'
        )
        Complaint.objects.create(
            user=self.faculty,
            title='Faculty Complaint',
            description='Other description',
            category='administrative',
            priority='low'
        )
        
        self.client.force_authenticate(user=self.admin)
        url = reverse('complaint-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)  # All complaints for admin
        
    def test_update_complaint_status(self):
        """Test updating complaint status"""
        complaint = Complaint.objects.create(
            user=self.user,
            title='Test Complaint',
            description='Test description',
            category='academic',
            priority='high'
        )
        
        self.client.force_authenticate(user=self.admin)
        url = reverse('complaint-detail', kwargs={'pk': complaint.id})
        data = {'status': 'in_progress', 'admin_notes': 'Working on it'}
        
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        complaint.refresh_from_db()
        self.assertEqual(complaint.status, 'in_progress')
        self.assertEqual(complaint.admin_notes, 'Working on it')
        
    def test_complaint_filtering(self):
        """Test complaint filtering by category and status"""
        Complaint.objects.create(
            user=self.user,
            title='Academic Complaint',
            description='Test description',
            category='academic',
            priority='high',
            status='pending'
        )
        Complaint.objects.create(
            user=self.user,
            title='Administrative Complaint',
            description='Test description',
            category='administrative',
            priority='low',
            status='resolved'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        
        # Filter by category
        response = self.client.get(url, {'category': 'academic'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Filter by status
        response = self.client.get(url, {'status': 'resolved'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_complaint_search(self):
        """Test complaint search functionality"""
        Complaint.objects.create(
            user=self.user,
            title='Library Issue',
            description='Books are not available',
            category='academic',
            priority='medium'
        )
        Complaint.objects.create(
            user=self.user,
            title='Cafeteria Problem',
            description='Food quality is poor',
            category='administrative',
            priority='low'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        
        # Search by title
        response = self.client.get(url, {'search': 'Library'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
        # Search by description
        response = self.client.get(url, {'search': 'food'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        
    def test_complaint_priority_ordering(self):
        """Test complaint ordering by priority"""
        Complaint.objects.create(
            user=self.user,
            title='Low Priority',
            description='Test description',
            category='academic',
            priority='low'
        )
        Complaint.objects.create(
            user=self.user,
            title='High Priority',
            description='Test description',
            category='academic',
            priority='high'
        )
        Complaint.objects.create(
            user=self.user,
            title='Medium Priority',
            description='Test description',
            category='academic',
            priority='medium'
        )
        
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        response = self.client.get(url, {'ordering': '-priority'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        priorities = [item['priority'] for item in response.data]
        self.assertEqual(priorities, ['high', 'medium', 'low'])
        
    def test_complaint_serializer(self):
        """Test complaint serializer"""
        complaint = Complaint.objects.create(
            user=self.user,
            title='Test Complaint',
            description='Test description',
            category='academic',
            priority='high'
        )
        
        serializer = ComplaintSerializer(complaint)
        data = serializer.data
        
        self.assertEqual(data['title'], 'Test Complaint')
        self.assertEqual(data['category'], 'academic')
        self.assertEqual(data['priority'], 'high')
        self.assertIn('created_at', data)
        self.assertIn('updated_at', data)
        
    def test_complaint_validation(self):
        """Test complaint data validation"""
        self.client.force_authenticate(user=self.user)
        url = reverse('complaint-list')
        
        # Test missing required fields
        invalid_data = {
            'title': '',  # Empty title
            'description': 'Test description'
        }
        
        response = self.client.post(url, invalid_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Test invalid category
        invalid_data = {
            'title': 'Test Complaint',
            'description': 'Test description',
            'category': 'invalid_category'
        }
        
        response = self.client.post(url, invalid_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_complaint_permissions(self):
        """Test complaint permissions"""
        complaint = Complaint.objects.create(
            user=self.user,
            title='Test Complaint',
            description='Test description',
            category='academic',
            priority='high'
        )
        
        # Test that user can only access their own complaints
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='otherpass123'
        )
        
        self.client.force_authenticate(user=other_user)
        url = reverse('complaint-detail', kwargs={'pk': complaint.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        
    def test_complaint_statistics(self):
        """Test complaint statistics endpoint"""
        # Create complaints with different statuses
        Complaint.objects.create(
            user=self.user,
            title='Pending Complaint',
            description='Test description',
            category='academic',
            priority='high',
            status='pending'
        )
        Complaint.objects.create(
            user=self.user,
            title='Resolved Complaint',
            description='Test description',
            category='administrative',
            priority='medium',
            status='resolved'
        )
        
        self.client.force_authenticate(user=self.admin)
        url = reverse('complaint-statistics')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_complaints', response.data)
        self.assertIn('pending_complaints', response.data)
        self.assertIn('resolved_complaints', response.data)
        self.assertIn('complaints_by_category', response.data)
