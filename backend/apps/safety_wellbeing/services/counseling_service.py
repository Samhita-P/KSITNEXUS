"""
Counseling Service
"""
from typing import Optional
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from datetime import timedelta
from apps.safety_wellbeing.models import (
    CounselingService as CounselingServiceModel, CounselingAppointment, AnonymousCheckIn
)
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class CounselingService:
    """Service for counseling management"""
    
    @staticmethod
    def create_appointment(
        service: CounselingServiceModel,
        scheduled_at: timezone.datetime,
        reason: str,
        user: Optional[User] = None,
        is_anonymous: bool = False,
        contact_email: Optional[str] = None,
        contact_phone: Optional[str] = None,
        preferred_name: Optional[str] = None,
        urgency: str = 'medium',
        duration_minutes: int = 60,
        notes: Optional[str] = None,
    ) -> CounselingAppointment:
        """Create a counseling appointment"""
        if not is_anonymous and not user:
            raise ValueError("User is required for non-anonymous appointments")
        
        if is_anonymous and not (contact_email or contact_phone):
            raise ValueError("Contact email or phone is required for anonymous appointments")
        
        appointment = CounselingAppointment.objects.create(
            service=service,
            user=user,
            is_anonymous=is_anonymous,
            scheduled_at=scheduled_at,
            duration_minutes=duration_minutes,
            reason=reason,
            urgency=urgency,
            contact_email=contact_email,
            contact_phone=contact_phone,
            preferred_name=preferred_name,
            notes=notes,
        )
        
        # TODO: Send confirmation email/SMS
        # TODO: Send calendar invite
        
        return appointment
    
    @staticmethod
    def cancel_appointment(
        appointment: CounselingAppointment,
        cancellation_reason: Optional[str] = None,
    ) -> CounselingAppointment:
        """Cancel a counseling appointment"""
        appointment.status = 'cancelled'
        if cancellation_reason:
            appointment.notes = f"{appointment.notes or ''}\nCancelled: {cancellation_reason}"
        appointment.save()
        
        # TODO: Send cancellation notification
        
        return appointment
    
    @staticmethod
    def complete_appointment(
        appointment: CounselingAppointment,
        counselor_notes: Optional[str] = None,
        follow_up_required: bool = False,
        follow_up_date: Optional[timezone.datetime] = None,
    ) -> CounselingAppointment:
        """Mark appointment as completed"""
        appointment.status = 'completed'
        appointment.completed_at = timezone.now()
        if counselor_notes:
            appointment.counselor_notes = counselor_notes
        appointment.follow_up_required = follow_up_required
        if follow_up_date:
            appointment.follow_up_date = follow_up_date
        appointment.save()
        
        return appointment
    
    @staticmethod
    def submit_anonymous_check_in(
        check_in_type: str,
        mood_level: int,
        message: Optional[str] = None,
        contact_email: Optional[str] = None,
        contact_phone: Optional[str] = None,
        allow_follow_up: bool = False,
    ) -> AnonymousCheckIn:
        """Submit an anonymous check-in"""
        try:
            check_in = AnonymousCheckIn.objects.create(
                check_in_type=check_in_type,
                mood_level=mood_level,
                message=message,
                contact_email=contact_email,
                contact_phone=contact_phone,
                allow_follow_up=allow_follow_up,
            )
            
            # TODO: Alert counselors if mood level is low or crisis type
            # TODO: Send automated response if configured
            
            return check_in
        except Exception as e:
            print(f"Warning: Could not create anonymous check-in: {e}")
            raise
    
    @staticmethod
    def respond_to_check_in(
        check_in: AnonymousCheckIn,
        responded_by: User,
        response_notes: str,
    ) -> AnonymousCheckIn:
        """Respond to an anonymous check-in"""
        check_in.responded_by = responded_by
        check_in.response_notes = response_notes
        check_in.response_sent_at = timezone.now()
        check_in.save()
        
        # TODO: Send response email/SMS if contact info provided
        
        return check_in
    
    @staticmethod
    def get_upcoming_appointments(user: Optional[User] = None, service: Optional[CounselingServiceModel] = None):
        """Get upcoming appointments"""
        try:
            queryset = CounselingAppointment.objects.filter(
                status__in=['scheduled', 'confirmed'],
                scheduled_at__gte=timezone.now()
            )
            
            if user:
                queryset = queryset.filter(user=user)
            if service:
                queryset = queryset.filter(service=service)
            
            return queryset.order_by('scheduled_at')
        except Exception as e:
            print(f"Warning: Could not fetch upcoming appointments: {e}")
            return CounselingAppointment.objects.none()
    
    @staticmethod
    def get_available_time_slots(service: CounselingServiceModel, date: timezone.datetime.date):
        """Get available time slots for a service on a given date"""
        # This is a simplified implementation
        # In production, you'd check service hours, existing appointments, etc.
        start_time = timezone.datetime.combine(date, timezone.datetime.min.time().replace(hour=9))
        end_time = timezone.datetime.combine(date, timezone.datetime.min.time().replace(hour=17))
        
        # Get existing appointments for the day
        existing_appointments = CounselingAppointment.objects.filter(
            service=service,
            scheduled_at__date=date,
            status__in=['scheduled', 'confirmed', 'in_progress']
        )
        
        # Generate 1-hour slots
        slots = []
        current = start_time
        while current < end_time:
            # Check if slot is available
            slot_end = current + timedelta(hours=1)
            conflicting = existing_appointments.filter(
                scheduled_at__lt=slot_end,
                scheduled_at__gte=current
            ).exists()
            
            if not conflicting:
                slots.append(current)
            
            current += timedelta(hours=1)
        
        return slots

