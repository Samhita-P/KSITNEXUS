"""
Quiet hours service for notification scheduling
"""
from datetime import time, datetime
from typing import Optional
from django.utils import timezone
import pytz
from ..models import NotificationPreference


class QuietHoursService:
    """Service for managing quiet hours"""
    
    @staticmethod
    def is_quiet_hours(user) -> bool:
        """
        Check if current time is within quiet hours for user
        
        Args:
            user: User instance
            
        Returns:
            True if current time is within quiet hours, False otherwise
        """
        try:
            pref = NotificationPreference.objects.filter(user=user).first()
            if not pref:
                return False
            
            # Check if quiet hours are enabled
            if not pref.quiet_hours_start or not pref.quiet_hours_end:
                return False
            
            # Get user's timezone
            if pref.timezone:
                try:
                    user_tz = pytz.timezone(pref.timezone)
                except pytz.UnknownTimeZoneError:
                    user_tz = timezone.get_current_timezone()
            else:
                user_tz = timezone.get_current_timezone()
            current_time = timezone.now().astimezone(user_tz).time()
            
            start_time = pref.quiet_hours_start
            end_time = pref.quiet_hours_end
            
            # Handle quiet hours that span midnight (e.g., 22:00 - 06:00)
            if start_time <= end_time:
                # Normal case: quiet hours within same day
                return start_time <= current_time <= end_time
            else:
                # Quiet hours span midnight
                return current_time >= start_time or current_time <= end_time
                
        except Exception as e:
            print(f"Error checking quiet hours: {e}")
            return False
    
    @staticmethod
    def should_send_notification(user, priority: str = 'medium') -> bool:
        """
        Check if notification should be sent based on quiet hours
        
        Args:
            user: User instance
            priority: Notification priority (low, medium, high, urgent)
            
        Returns:
            True if notification should be sent, False if in quiet hours
        """
        # Urgent notifications bypass quiet hours
        if priority == 'urgent':
            return True
        
        # High priority notifications bypass quiet hours
        if priority == 'high':
            return True
        
        # Check quiet hours for medium and low priority
        return not QuietHoursService.is_quiet_hours(user)
    
    @staticmethod
    def get_next_send_time(user) -> Optional[datetime]:
        """
        Get the next time when notifications can be sent (after quiet hours)
        
        Args:
            user: User instance
            
        Returns:
            Next datetime when notifications can be sent, None if quiet hours not enabled
        """
        try:
            pref = NotificationPreference.objects.filter(user=user).first()
            if not pref or not pref.quiet_hours_start or not pref.quiet_hours_end:
                return None
            
            # Get user's timezone
            if pref.timezone:
                try:
                    user_tz = pytz.timezone(pref.timezone)
                except pytz.UnknownTimeZoneError:
                    user_tz = timezone.get_current_timezone()
            else:
                user_tz = timezone.get_current_timezone()
            now = timezone.now().astimezone(user_tz)
            current_time = now.time()
            
            start_time = pref.quiet_hours_start
            end_time = pref.quiet_hours_end
            
            # If currently in quiet hours, return end time today
            if QuietHoursService.is_quiet_hours(user):
                # Calculate end time
                if start_time <= end_time:
                    # Same day
                    next_send = now.replace(
                        hour=end_time.hour,
                        minute=end_time.minute,
                        second=end_time.second,
                        microsecond=0
                    )
                else:
                    # Spans midnight - end is next day
                    if current_time >= start_time:
                        # After start, end is next day
                        next_send = (now + timezone.timedelta(days=1)).replace(
                            hour=end_time.hour,
                            minute=end_time.minute,
                            second=end_time.second,
                            microsecond=0
                        )
                    else:
                        # Before start, end is today
                        next_send = now.replace(
                            hour=end_time.hour,
                            minute=end_time.minute,
                            second=end_time.second,
                            microsecond=0
                        )
                
                return next_send.astimezone(timezone.utc)
            
            # Not in quiet hours
            return None
            
        except Exception as e:
            print(f"Error getting next send time: {e}")
            return None
    
    @staticmethod
    def set_quiet_hours(user, start_time: time, end_time: time, timezone_str: str = 'Asia/Kolkata'):
        """
        Set quiet hours for user
        
        Args:
            user: User instance
            start_time: Start time for quiet hours
            end_time: End time for quiet hours
            timezone_str: Timezone string
            
        Returns:
            NotificationPreference instance
        """
        pref, created = NotificationPreference.objects.get_or_create(
            user=user,
            defaults={
                'quiet_hours_start': start_time,
                'quiet_hours_end': end_time,
                'timezone': timezone_str,
            }
        )
        
        if not created:
            pref.quiet_hours_start = start_time
            pref.quiet_hours_end = end_time
            pref.timezone = timezone_str
            pref.save()
        
        return pref
    
    @staticmethod
    def disable_quiet_hours(user):
        """
        Disable quiet hours for user
        
        Args:
            user: User instance
        """
        pref = NotificationPreference.objects.filter(user=user).first()
        if pref:
            pref.quiet_hours_start = None
            pref.quiet_hours_end = None
            pref.save()

