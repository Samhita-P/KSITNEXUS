from django.urls import path
from . import views

urlpatterns = [
    # Emergency Mode
    path('emergency/alerts/', views.EmergencyAlertListView.as_view(), name='emergency-alert-list'),
    path('emergency/alerts/<int:pk>/', views.EmergencyAlertDetailView.as_view(), name='emergency-alert-detail'),
    path('emergency/alerts/active/', views.active_emergency_alerts, name='active-emergency-alerts'),
    path('emergency/alerts/<int:alert_id>/acknowledge/', views.acknowledge_emergency_alert, name='acknowledge-emergency-alert'),
    path('emergency/alerts/<int:alert_id>/resolve/', views.resolve_emergency_alert, name='resolve-emergency-alert'),
    path('emergency/contacts/', views.emergency_contacts, name='emergency-contacts'),
    path('emergency/personal-contacts/', views.UserPersonalEmergencyContactListView.as_view(), name='personal-emergency-contacts'),
    path('emergency/personal-contacts/<int:pk>/', views.UserPersonalEmergencyContactDetailView.as_view(), name='personal-emergency-contact-detail'),
    path('emergency/personal-contacts/<int:contact_id>/send-alert/', views.send_alert_to_contact, name='send-alert-to-contact'),
    
    # Counseling Services
    path('counseling/services/', views.CounselingServiceListView.as_view(), name='counseling-service-list'),
    path('counseling/services/<int:pk>/', views.CounselingServiceDetailView.as_view(), name='counseling-service-detail'),
    path('counseling/appointments/', views.CounselingAppointmentListView.as_view(), name='counseling-appointment-list'),
    path('counseling/appointments/<int:pk>/', views.CounselingAppointmentDetailView.as_view(), name='counseling-appointment-detail'),
    path('counseling/appointments/upcoming/', views.upcoming_appointments, name='upcoming-appointments'),
    path('counseling/check-ins/', views.submit_anonymous_check_in, name='submit-anonymous-check-in'),
    path('counseling/check-ins/list/', views.anonymous_check_ins, name='anonymous-check-ins'),
    path('counseling/check-ins/<int:check_in_id>/respond/', views.respond_to_check_in, name='respond-to-check-in'),
    
    # Safety Resources
    path('resources/', views.SafetyResourceListView.as_view(), name='safety-resource-list'),
    path('resources/<int:pk>/', views.SafetyResourceDetailView.as_view(), name='safety-resource-detail'),
]


