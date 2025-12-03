"""
Test script for Phase 3: Smart Notifications System
"""
import os
import django

# Setup Django - change to backend directory
import sys
from pathlib import Path

# Get the backend directory
backend_dir = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(backend_dir))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.notifications.models import Notification, NotificationPreference
from apps.notifications.models_digest import (
    NotificationDigest, NotificationTier, NotificationSummary, NotificationPriorityRule
)
from apps.notifications.services.digest_service import DigestService, TierService
from apps.notifications.services.summary_service import SummaryService
from apps.notifications.services.priority_service import PriorityService
from apps.notifications.notification_service import NotificationService
from django.utils import timezone
from datetime import datetime, timedelta

User = get_user_model()


def test_digest_service():
    """Test digest service"""
    print("Testing DigestService...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase3',
        defaults={'email': 'test@example.com'}
    )
    
    # Set digest frequency
    pref, _ = NotificationPreference.objects.get_or_create(
        user=user,
        defaults={'digest_frequency': 'daily'}
    )
    pref.digest_frequency = 'daily'
    pref.save()
    
    # Create some test notifications
    for i in range(5):
        Notification.objects.create(
            user=user,
            notification_type='notice',
            title=f'Test Notification {i+1}',
            message=f'This is test notification {i+1}',
            priority='medium',
            is_read=False
        )
    
    # Generate daily digest
    digest = DigestService.generate_daily_digest(user)
    if digest:
        print(f"✓ Daily digest created: {digest.title}")
        print(f"  - Notifications: {digest.notification_count}")
        print(f"  - Summary: {digest.summary[:100]}...")
    else:
        print("✗ Failed to create daily digest")
    
    # Generate weekly digest
    pref.digest_frequency = 'weekly'
    pref.save()
    weekly_digest = DigestService.generate_weekly_digest(user)
    if weekly_digest:
        print(f"✓ Weekly digest created: {weekly_digest.title}")
    else:
        print("✗ Failed to create weekly digest")
    
    print()


def test_tier_service():
    """Test tier service"""
    print("Testing TierService...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase3',
        defaults={'email': 'test@example.com'}
    )
    
    # Create a tier
    tier = TierService.set_tier(
        user=user,
        tier='essential',
        notification_types=['complaint', 'notice']
    )
    print(f"✓ Tier created: {tier.tier} for {tier.notification_types}")
    
    # Get user tier
    tier_name = TierService.get_user_tier(user, 'complaint')
    print(f"✓ User tier for 'complaint': {tier_name}")
    
    # Get all tiers
    tiers = TierService.get_user_tiers(user)
    print(f"✓ User has {len(tiers)} tier(s)")
    
    print()


def test_summary_service():
    """Test summary service"""
    print("Testing SummaryService...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase3',
        defaults={'email': 'test@example.com'}
    )
    
    # Create a test notification
    notification = Notification.objects.create(
        user=user,
        notification_type='notice',
        title='Test Notification for Summary',
        message='This is a test notification that will be summarized. It contains important information about the system.',
        priority='high',
        is_read=False
    )
    
    # Generate summary
    summary = SummaryService.generate_summary(notification, 'short')
    if summary:
        print(f"✓ Summary generated: {summary.summary_text[:100]}...")
        print(f"  - Type: {summary.summary_type}")
        print(f"  - Word count: {summary.word_count}")
        print(f"  - Key points: {summary.key_points}")
    else:
        print("✗ Failed to generate summary")
    
    # Generate digest summary
    notifications = Notification.objects.filter(user=user)[:5]
    digest_summary = SummaryService.generate_digest_summary(list(notifications))
    print(f"✓ Digest summary generated: {digest_summary[:100]}...")
    
    print()


def test_priority_service():
    """Test priority service"""
    print("Testing PriorityService...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase3',
        defaults={'email': 'test@example.com'}
    )
    
    # Create a priority rule
    rule = PriorityService.create_priority_rule(
        user=user,
        notification_type='complaint',
        keyword='urgent',
        priority='urgent',
        is_active=True
    )
    print(f"✓ Priority rule created: {rule}")
    
    # Calculate priority
    priority = PriorityService.calculate_priority(
        notification_type='complaint',
        title='Urgent complaint needs attention',
        message='This is an urgent complaint that needs immediate attention.',
        user=user,
        default_priority='medium'
    )
    print(f"✓ Calculated priority: {priority}")
    
    # Get user priority rules
    rules = PriorityService.get_user_priority_rules(user)
    print(f"✓ User has {len(rules)} priority rule(s)")
    
    print()


def test_notification_service_integration():
    """Test notification service integration"""
    print("Testing NotificationService Integration...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase3',
        defaults={'email': 'test@example.com'}
    )
    
    # Create a notification (this should use priority and tier services)
    notification = NotificationService.create_notification(
        user=user,
        notification_type='complaint',
        title='Test Complaint',
        message='This is a test complaint notification.',
        priority='medium',
        data={'action': 'review', 'status': 'pending'}
    )
    
    if notification:
        print(f"✓ Notification created: {notification.title}")
        print(f"  - Priority: {notification.priority}")
        print(f"  - Type: {notification.notification_type}")
        
        # Check if summary was generated
        try:
            summary = notification.summary
            print(f"  - Summary: {summary.summary_text[:50]}...")
        except:
            print("  - No summary generated yet")
    else:
        print("✗ Failed to create notification")
    
    print()


def cleanup_test_data():
    """Cleanup test data"""
    print("Cleaning up test data...")
    
    user = User.objects.filter(username='test_user_phase3').first()
    if user:
        Notification.objects.filter(user=user).delete()
        NotificationDigest.objects.filter(user=user).delete()
        NotificationTier.objects.filter(user=user).delete()
        NotificationPriorityRule.objects.filter(user=user).delete()
        NotificationSummary.objects.filter(notification__user=user).delete()
        print("✓ Test data cleaned up")
    else:
        print("✗ No test user found")
    
    print()


if __name__ == '__main__':
    print("=" * 60)
    print("Phase 3: Smart Notifications System - Test Suite")
    print("=" * 60)
    print()
    
    try:
        test_digest_service()
        test_tier_service()
        test_summary_service()
        test_priority_service()
        test_notification_service_integration()
        
        print("=" * 60)
        print("All tests completed!")
        print("=" * 60)
        
        # Ask if user wants to cleanup
        response = input("\nCleanup test data? (y/n): ")
        if response.lower() == 'y':
            cleanup_test_data()
    except Exception as e:
        print(f"✗ Error during testing: {e}")
        import traceback
        traceback.print_exc()

