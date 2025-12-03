"""
Views for safety_wellbeing app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils import timezone
from .models import (
    EmergencyAlert, EmergencyAcknowledgment, EmergencyContact,
    UserPersonalEmergencyContact,
    CounselingService, CounselingAppointment, AnonymousCheckIn, SafetyResource
)
from .serializers import (
    EmergencyAlertSerializer, EmergencyAcknowledgmentSerializer, EmergencyContactSerializer,
    UserPersonalEmergencyContactSerializer, UserPersonalEmergencyContactCreateSerializer,
    CounselingServiceSerializer, CounselingAppointmentSerializer, AnonymousCheckInSerializer,
    SafetyResourceSerializer
)
from .services.emergency_service import EmergencyService
from .services.counseling_service import CounselingService as CounselingServiceHelper

User = get_user_model()


# Emergency Mode
class EmergencyAlertListView(generics.ListCreateAPIView):
    """List and create emergency alerts"""
    serializer_class = EmergencyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            status_filter = self.request.query_params.get('status')
            queryset = EmergencyAlert.objects.all().select_related('created_by', 'responded_by')
            
            if status_filter:
                queryset = queryset.filter(status=status_filter)
            else:
                # Default to active alerts for non-admin users
                if self.request.user.user_type not in ['admin', 'faculty']:
                    queryset = queryset.filter(status='active')
            
            return queryset.order_by('-created_at')
        except Exception as e:
            import traceback
            print(f"Error in EmergencyAlertListView.get_queryset: {e}")
            traceback.print_exc()
            return EmergencyAlert.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in EmergencyAlertListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def perform_create(self, serializer):
        try:
            alert = serializer.save(created_by=self.request.user)
            # Handle personal emergency contacts notification
            contact_ids = self.request.data.get('notify_contact_ids', [])
            if contact_ids:
                contacts = UserPersonalEmergencyContact.objects.filter(
                    id__in=contact_ids,
                    user=self.request.user
                )
                alert.notify_contacts.set(contacts)
                # Send notifications to selected contacts
                EmergencyService.notify_personal_contacts(alert, list(contacts))
        except Exception as e:
            import traceback
            print(f"Error in EmergencyAlertListView.perform_create: {e}")
            traceback.print_exc()
            raise


class EmergencyAlertDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Emergency alert detail view"""
    serializer_class = EmergencyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return EmergencyAlert.objects.all()
        except Exception as e:
            print(f"Error in EmergencyAlertDetailView.get_queryset: {e}")
            return EmergencyAlert.objects.none()
    
    def retrieve(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            instance.views_count += 1
            instance.save(update_fields=['views_count'])
            serializer = self.get_serializer(instance)
            return Response(serializer.data)
        except Exception as e:
            import traceback
            print(f"Error in EmergencyAlertDetailView.retrieve: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to retrieve emergency alert: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def acknowledge_emergency_alert(request, alert_id):
    """Acknowledge an emergency alert"""
    try:
        alert = EmergencyAlert.objects.get(id=alert_id)
        is_safe = request.data.get('is_safe', True)
        notes = request.data.get('notes')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        acknowledgment = EmergencyService.acknowledge_alert(
            alert=alert,
            user=request.user,
            is_safe=is_safe,
            notes=notes,
            latitude=float(latitude) if latitude else None,
            longitude=float(longitude) if longitude else None,
        )
        
        serializer = EmergencyAcknowledgmentSerializer(acknowledgment)
        return Response(serializer.data)
    except EmergencyAlert.DoesNotExist:
        return Response(
            {'error': 'Emergency alert not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def resolve_emergency_alert(request, alert_id):
    """Resolve an emergency alert"""
    try:
        alert = EmergencyAlert.objects.get(id=alert_id)
        if request.user.user_type not in ['admin', 'faculty', 'staff']:
            return Response(
                {'error': 'Permission denied'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        response_notes = request.data.get('response_notes', '')
        EmergencyService.resolve_alert(
            alert=alert,
            responded_by=request.user,
            response_notes=response_notes,
        )
        
        serializer = EmergencyAlertSerializer(alert)
        return Response(serializer.data)
    except EmergencyAlert.DoesNotExist:
        return Response(
            {'error': 'Emergency alert not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def active_emergency_alerts(request):
    """Get all active emergency alerts"""
    try:
        alerts = EmergencyService.get_active_alerts()
        serializer = EmergencyAlertSerializer(alerts, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error getting active emergency alerts: {e}")
        traceback.print_exc()
        # Return empty list if table doesn't exist or other error
        return Response([], status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def emergency_contacts(request):
    """Get emergency contacts"""
    try:
        contacts = EmergencyService.get_emergency_contacts()
        serializer = EmergencyContactSerializer(contacts, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error getting emergency contacts: {e}")
        traceback.print_exc()
        # Return empty list if table doesn't exist or other error
        return Response([], status=status.HTTP_200_OK)


# User Personal Emergency Contacts
class UserPersonalEmergencyContactListView(generics.ListCreateAPIView):
    """List and create user's personal emergency contacts"""
    serializer_class = UserPersonalEmergencyContactSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return UserPersonalEmergencyContact.objects.filter(user=self.request.user)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactListView.get_queryset: {e}")
            traceback.print_exc()
            return UserPersonalEmergencyContact.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return UserPersonalEmergencyContactCreateSerializer
        return UserPersonalEmergencyContactSerializer
    
    def create(self, request, *args, **kwargs):
        """Override create to handle errors gracefully"""
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            from django.db import OperationalError, IntegrityError
            from rest_framework.exceptions import ValidationError
            import traceback
            import sys
            
            print(f"\n{'!'*80}")
            print(f"ERROR in UserPersonalEmergencyContactListView.create")
            print(f"Error: {e}")
            print(f"Error type: {type(e)}")
            print(f"Request data: {request.data}")
            print(f"User: {request.user.username if request.user else 'Anonymous'}")
            print(f"Traceback:")
            traceback.print_exc()
            print(f"{'!'*80}\n")
            sys.stdout.flush()
            
            # Handle database table doesn't exist
            if isinstance(e, OperationalError):
                error_msg = "Database table does not exist. Please run migrations: python manage.py makemigrations safety_wellbeing && python manage.py migrate"
                print(f"\n{error_msg}\n")
                sys.stdout.flush()
                return Response(
                    {'error': error_msg}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
            # Handle duplicate phone number (unique_together constraint)
            if isinstance(e, IntegrityError):
                error_msg = "A contact with this phone number already exists for your account."
                print(f"\n{error_msg}\n")
                sys.stdout.flush()
                return Response(
                    {'error': error_msg}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Handle validation errors from serializer
            if isinstance(e, ValidationError):
                error_msg = str(e.detail) if hasattr(e, 'detail') else str(e)
                print(f"\nValidation Error: {error_msg}\n")
                sys.stdout.flush()
                return Response(
                    {'error': error_msg}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if it's a DRF validation error
            if hasattr(e, 'detail'):
                error_msg = str(e.detail)
                print(f"\nDRF Error: {error_msg}\n")
                sys.stdout.flush()
                return Response(
                    {'error': error_msg}, 
                    status=getattr(e, 'status_code', status.HTTP_400_BAD_REQUEST)
                )
            
            # Generic error
            error_msg = f'Failed to create contact: {str(e)}'
            print(f"\nGeneric Error: {error_msg}\n")
            sys.stdout.flush()
            return Response(
                {'error': error_msg}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        try:
            serializer.save(user=self.request.user)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactListView.perform_create: {e}")
            traceback.print_exc()
            raise


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def send_alert_to_contact(request, contact_id):
    """Send an emergency alert to a specific personal contact"""
    try:
        contact = UserPersonalEmergencyContact.objects.filter(
            id=contact_id,
            user=request.user
        ).first()
        
        if not contact:
            return Response(
                {'error': 'Contact not found or you do not have permission to access it'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get optional message from request
        message = request.data.get('message', None)
        
        # Send alert
        result = EmergencyService.send_alert_to_contact(
            user=request.user,
            contact=contact,
            message=message
        )
        
        if result.get('success'):
            return Response(result, status=status.HTTP_200_OK)
        else:
            return Response(
                {'error': result.get('error', 'Failed to send alert')},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    except Exception as e:
        import traceback
        print(f"Error in send_alert_to_contact view: {e}")
        traceback.print_exc()
        return Response(
            {'error': f'Failed to send alert: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


class UserPersonalEmergencyContactDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Detail view for user's personal emergency contact"""
    serializer_class = UserPersonalEmergencyContactSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return UserPersonalEmergencyContact.objects.filter(user=self.request.user)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactDetailView.get_queryset: {e}")
            traceback.print_exc()
            return UserPersonalEmergencyContact.objects.none()
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to handle errors gracefully"""
        try:
            return super().retrieve(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactDetailView.retrieve: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to retrieve contact: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def update(self, request, *args, **kwargs):
        """Override update to handle errors gracefully"""
        try:
            return super().update(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactDetailView.update: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to update contact: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def destroy(self, request, *args, **kwargs):
        """Override destroy to handle errors gracefully"""
        try:
            return super().destroy(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in UserPersonalEmergencyContactDetailView.destroy: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to delete contact: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# Counseling Services
class CounselingServiceListView(generics.ListAPIView):
    """List counseling services"""
    serializer_class = CounselingServiceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = CounselingService.objects.filter(is_active=True)
            service_type = self.request.query_params.get('service_type')
            if service_type:
                queryset = queryset.filter(service_type=service_type)
            return queryset
        except Exception as e:
            import traceback
            print(f"Error in CounselingServiceListView.get_queryset: {e}")
            traceback.print_exc()
            return CounselingService.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in CounselingServiceListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class CounselingServiceDetailView(generics.RetrieveAPIView):
    """Counseling service detail view"""
    serializer_class = CounselingServiceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return CounselingService.objects.all()
        except Exception as e:
            print(f"Error in CounselingServiceDetailView.get_queryset: {e}")
            return CounselingService.objects.none()


class CounselingAppointmentListView(generics.ListCreateAPIView):
    """List and create counseling appointments"""
    serializer_class = CounselingAppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            user = self.request.user
            queryset = CounselingAppointment.objects.all().select_related('service', 'user')
            
            if user.user_type == 'student':
                queryset = queryset.filter(user=user)
            elif user.user_type in ['faculty', 'admin']:
                # Faculty/admin can see all appointments
                service_id = self.request.query_params.get('service_id')
                if service_id:
                    queryset = queryset.filter(service_id=service_id)
            else:
                queryset = queryset.none()
            
            status_filter = self.request.query_params.get('status')
            if status_filter:
                queryset = queryset.filter(status=status_filter)
            
            return queryset.order_by('-scheduled_at')
        except Exception as e:
            import traceback
            print(f"Error in CounselingAppointmentListView.get_queryset: {e}")
            traceback.print_exc()
            return CounselingAppointment.objects.none()
    
    def perform_create(self, serializer):
        try:
            service_id = serializer.validated_data['service'].id
            service = CounselingService.objects.get(id=service_id)
            
            appointment = CounselingServiceHelper.create_appointment(
                service=service,
                scheduled_at=serializer.validated_data['scheduled_at'],
                reason=serializer.validated_data['reason'],
                user=self.request.user if not serializer.validated_data.get('is_anonymous') else None,
                is_anonymous=serializer.validated_data.get('is_anonymous', False),
                contact_email=serializer.validated_data.get('contact_email'),
                contact_phone=serializer.validated_data.get('contact_phone'),
                preferred_name=serializer.validated_data.get('preferred_name'),
                urgency=serializer.validated_data.get('urgency', 'medium'),
                duration_minutes=serializer.validated_data.get('duration_minutes', 60),
                notes=serializer.validated_data.get('notes'),
            )
            
            serializer.instance = appointment
        except Exception as e:
            import traceback
            print(f"Error in CounselingAppointmentListView.perform_create: {e}")
            traceback.print_exc()
            raise


class CounselingAppointmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Counseling appointment detail view"""
    serializer_class = CounselingAppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return CounselingAppointment.objects.all()
        except Exception as e:
            print(f"Error in CounselingAppointmentDetailView.get_queryset: {e}")
            return CounselingAppointment.objects.none()
    
    def perform_update(self, serializer):
        appointment = self.get_object()
        
        # Only allow status updates for faculty/admin
        if self.request.user.user_type in ['faculty', 'admin']:
            if 'status' in serializer.validated_data:
                new_status = serializer.validated_data['status']
                if new_status == 'completed':
                    CounselingServiceHelper.complete_appointment(
                        appointment=appointment,
                        counselor_notes=serializer.validated_data.get('counselor_notes'),
                        follow_up_required=serializer.validated_data.get('follow_up_required', False),
                        follow_up_date=serializer.validated_data.get('follow_up_date'),
                    )
                elif new_status == 'cancelled':
                    CounselingServiceHelper.cancel_appointment(
                        appointment=appointment,
                        cancellation_reason=serializer.validated_data.get('notes'),
                    )
                else:
                    serializer.save()
            else:
                serializer.save()
        else:
            # Students can only update their own appointments
            if appointment.user == self.request.user:
                serializer.save()
            else:
                return Response(
                    {'error': 'Permission denied'},
                    status=status.HTTP_403_FORBIDDEN
                )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])  # Allow anonymous
def submit_anonymous_check_in(request):
    """Submit an anonymous check-in"""
    try:
        check_in = CounselingServiceHelper.submit_anonymous_check_in(
            check_in_type=request.data.get('check_in_type'),
            mood_level=request.data.get('mood_level', 3),
            message=request.data.get('message'),
            contact_email=request.data.get('contact_email'),
            contact_phone=request.data.get('contact_phone'),
            allow_follow_up=request.data.get('allow_follow_up', False),
        )
        
        serializer = AnonymousCheckInSerializer(check_in)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    except Exception as e:
        import traceback
        print(f"Error in submit_anonymous_check_in: {e}")
        traceback.print_exc()
        return Response(
            {'error': f'Failed to submit check-in: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def anonymous_check_ins(request):
    """Get anonymous check-ins (for counselors/admins)"""
    if request.user.user_type not in ['faculty', 'admin', 'staff']:
        return Response(
            {'error': 'Permission denied'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        queryset = AnonymousCheckIn.objects.all().order_by('-created_at')
        
        check_in_type = request.query_params.get('check_in_type')
        if check_in_type:
            queryset = queryset.filter(check_in_type=check_in_type)
        
        responded = request.query_params.get('responded')
        if responded == 'true':
            queryset = queryset.exclude(responded_by__isnull=True)
        elif responded == 'false':
            queryset = queryset.filter(responded_by__isnull=True)
        
        serializer = AnonymousCheckInSerializer(queryset, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in anonymous_check_ins: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def respond_to_check_in(request, check_in_id):
    """Respond to an anonymous check-in"""
    if request.user.user_type not in ['faculty', 'admin', 'staff']:
        return Response(
            {'error': 'Permission denied'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        check_in = AnonymousCheckIn.objects.get(id=check_in_id)
        response_notes = request.data.get('response_notes', '')
        
        CounselingServiceHelper.respond_to_check_in(
            check_in=check_in,
            responded_by=request.user,
            response_notes=response_notes,
        )
        
        serializer = AnonymousCheckInSerializer(check_in)
        return Response(serializer.data)
    except AnonymousCheckIn.DoesNotExist:
        return Response(
            {'error': 'Check-in not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def upcoming_appointments(request):
    """Get upcoming appointments"""
    try:
        user = request.user if request.user.user_type == 'student' else None
        service_id = request.query_params.get('service_id')
        service = None
        if service_id:
            try:
                service = CounselingService.objects.get(id=service_id)
            except CounselingService.DoesNotExist:
                pass
        
        appointments = CounselingServiceHelper.get_upcoming_appointments(user=user, service=service)
        serializer = CounselingAppointmentSerializer(appointments, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in upcoming_appointments: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


# Safety Resources
class SafetyResourceListView(generics.ListAPIView):
    """List safety resources"""
    serializer_class = SafetyResourceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = SafetyResource.objects.filter(is_active=True)
            resource_type = self.request.query_params.get('resource_type')
            if resource_type:
                queryset = queryset.filter(resource_type=resource_type)
            return queryset.order_by('-is_featured', 'title')
        except Exception as e:
            import traceback
            print(f"Error in SafetyResourceListView.get_queryset: {e}")
            traceback.print_exc()
            return SafetyResource.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in SafetyResourceListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class SafetyResourceDetailView(generics.RetrieveAPIView):
    """Safety resource detail view"""
    serializer_class = SafetyResourceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return SafetyResource.objects.all()
        except Exception as e:
            print(f"Error in SafetyResourceDetailView.get_queryset: {e}")
            return SafetyResource.objects.none()
    
    def retrieve(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            instance.views_count += 1
            instance.save(update_fields=['views_count'])
            serializer = self.get_serializer(instance)
            return Response(serializer.data)
        except Exception as e:
            import traceback
            print(f"Error in SafetyResourceDetailView.retrieve: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to retrieve safety resource: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

