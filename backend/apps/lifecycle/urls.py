from django.urls import path
from . import views

urlpatterns = [
    # Onboarding
    path('onboarding/steps/', views.OnboardingStepListView.as_view(), name='onboarding-steps'),
    path('onboarding/progress/', views.UserOnboardingProgressView.as_view(), name='onboarding-progress'),
    path('onboarding/complete-step/', views.complete_onboarding_step, name='complete-onboarding-step'),
    
    # Alumni
    path('alumni/profiles/', views.AlumniProfileListView.as_view(), name='alumni-profile-list'),
    path('alumni/profiles/<int:pk>/', views.AlumniProfileDetailView.as_view(), name='alumni-profile-detail'),
    path('alumni/mentorship/requests/', views.MentorshipRequestListView.as_view(), name='mentorship-request-list'),
    path('alumni/mentorship/requests/<int:request_id>/respond/', views.respond_to_mentorship_request, name='respond-mentorship-request'),
    path('alumni/events/', views.AlumniEventListView.as_view(), name='alumni-event-list'),
    
    # Placement
    path('placement/opportunities/', views.PlacementOpportunityListView.as_view(), name='placement-opportunity-list'),
    path('placement/opportunities/<int:pk>/', views.PlacementOpportunityDetailView.as_view(), name='placement-opportunity-detail'),
    path('placement/applications/', views.PlacementApplicationListView.as_view(), name='placement-application-list'),
    path('placement/applications/<int:pk>/', views.PlacementApplicationDetailView.as_view(), name='placement-application-detail'),
    path('placement/statistics/', views.placement_statistics, name='placement-statistics'),
]

















