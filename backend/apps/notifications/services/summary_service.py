"""
AI-powered summary service for notifications
"""
from typing import List, Optional
from ..models import Notification
from ..models_digest import NotificationSummary


class SummaryService:
    """Service for generating AI-powered summaries"""
    
    @staticmethod
    def generate_summary(notification: Notification, summary_type: str = 'short') -> Optional[NotificationSummary]:
        """
        Generate AI summary for notification
        
        Args:
            notification: Notification instance
            summary_type: Summary type (short, medium, long)
            
        Returns:
            NotificationSummary instance or None
        """
        try:
            # For now, use a simple extraction-based summary
            # In production, this would use an AI service (OpenAI, GPT, etc.)
            summary_text = SummaryService._extract_summary(notification, summary_type)
            
            # Calculate word count
            word_count = len(summary_text.split())
            
            # Extract key points
            key_points = SummaryService._extract_key_points(notification)
            
            # Create or update summary
            summary, created = NotificationSummary.objects.get_or_create(
                notification=notification,
                defaults={
                    'summary_text': summary_text,
                    'summary_type': summary_type,
                    'model_used': 'extraction_based',
                    'confidence_score': 0.8,  # Basic confidence score
                    'word_count': word_count,
                    'key_points': key_points,
                }
            )
            
            if not created:
                # Update existing summary
                summary.summary_text = summary_text
                summary.summary_type = summary_type
                summary.word_count = word_count
                summary.key_points = key_points
                summary.save()
            
            return summary
            
        except Exception as e:
            print(f"Error generating summary: {e}")
            return None
    
    @staticmethod
    def _extract_summary(notification: Notification, summary_type: str = 'short') -> str:
        """
        Extract summary from notification
        
        Args:
            notification: Notification instance
            summary_type: Summary type (short, medium, long)
            
        Returns:
            Summary text
        """
        # Short summary: first sentence or first 100 characters
        if summary_type == 'short':
            message = notification.message
            # Try to get first sentence
            sentences = message.split('.')
            if sentences and len(sentences[0]) > 0:
                return sentences[0].strip() + '.'
            # Fallback to first 100 characters
            return message[:100] + '...' if len(message) > 100 else message
        
        # Medium summary: first paragraph or first 200 characters
        elif summary_type == 'medium':
            message = notification.message
            # Try to get first paragraph
            paragraphs = message.split('\n\n')
            if paragraphs and len(paragraphs[0]) > 0:
                return paragraphs[0].strip()
            # Fallback to first 200 characters
            return message[:200] + '...' if len(message) > 200 else message
        
        # Long summary: full message with key points
        else:
            message = notification.message
            key_points = SummaryService._extract_key_points(notification)
            
            if key_points:
                points_text = '\n'.join([f"• {point}" for point in key_points[:3]])
                return f"{message}\n\nKey Points:\n{points_text}"
            
            return message
    
    @staticmethod
    def _extract_key_points(notification: Notification) -> List[str]:
        """
        Extract key points from notification
        
        Args:
            notification: Notification instance
            
        Returns:
            List of key points
        """
        key_points = []
        
        # Extract from title
        if notification.title:
            # Remove common words and extract important terms
            title_words = notification.title.split()
            if len(title_words) > 3:
                key_points.append(' '.join(title_words[:5]))
        
        # Extract from message (first sentence)
        message = notification.message
        if message:
            sentences = message.split('.')
            if sentences and len(sentences[0]) > 20:
                key_points.append(sentences[0].strip())
        
        # Extract from data field
        if notification.data:
            # Look for important fields
            important_fields = ['action', 'status', 'deadline', 'location']
            for field in important_fields:
                if field in notification.data:
                    value = notification.data[field]
                    key_points.append(f"{field.title()}: {value}")
        
        return key_points[:5]  # Limit to 5 key points
    
    @staticmethod
    def generate_batch_summaries(notifications: List[Notification], summary_type: str = 'short') -> List[NotificationSummary]:
        """
        Generate summaries for multiple notifications
        
        Args:
            notifications: List of Notification instances
            summary_type: Summary type (short, medium, long)
            
        Returns:
            List of NotificationSummary instances
        """
        summaries = []
        for notification in notifications:
            summary = SummaryService.generate_summary(notification, summary_type)
            if summary:
                summaries.append(summary)
        return summaries
    
    @staticmethod
    def get_summary(notification: Notification) -> Optional[NotificationSummary]:
        """
        Get summary for notification
        
        Args:
            notification: Notification instance
            
        Returns:
            NotificationSummary instance or None
        """
        try:
            return NotificationSummary.objects.get(notification=notification)
        except NotificationSummary.DoesNotExist:
            return None
    
    @staticmethod
    def generate_digest_summary(notifications: List[Notification]) -> str:
        """
        Generate summary for a digest of notifications
        
        Args:
            notifications: List of Notification instances
            
        Returns:
            Summary text
        """
        if not notifications:
            return "No new notifications."
        
        # Group by type
        by_type = {}
        for notification in notifications:
            notification_type = notification.get_notification_type_display()
            if notification_type not in by_type:
                by_type[notification_type] = []
            by_type[notification_type].append(notification)
        
        # Generate summary
        summary_parts = []
        summary_parts.append(f"Summary of {len(notifications)} notification(s):\n\n")
        
        for notification_type, notifs in by_type.items():
            count = len(notifs)
            summary_parts.append(f"• {notification_type}: {count} notification(s)")
            
            # Add priority breakdown
            urgent = [n for n in notifs if n.priority == 'urgent']
            high = [n for n in notifs if n.priority == 'high']
            medium = [n for n in notifs if n.priority == 'medium']
            
            if urgent:
                summary_parts.append(f"  - {len(urgent)} urgent")
            if high:
                summary_parts.append(f"  - {len(high)} high priority")
            if medium:
                summary_parts.append(f"  - {len(medium)} medium priority")
            
            # Add top 3 titles
            top_notifications = notifs[:3]
            for notif in top_notifications:
                summary_parts.append(f"    • {notif.title}")
        
        return "\n".join(summary_parts)

