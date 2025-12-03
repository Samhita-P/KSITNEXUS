"""
URL configuration for ksit_nexus project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView
from .health_views import health
# from apps.notifications.health_views import health_check, detailed_health_check, metrics

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/complaints/', include('apps.complaints.urls')),
    path('api/feedback/', include('apps.feedback.urls')),
    path('api/feedbacks/', include('apps.feedback.urls')),  # Alias for Flutter compatibility
    path('api/faculties/', include('apps.feedback.faculty_urls')),  # Faculty list endpoint
    path('api/study-groups/', include('apps.study_groups.urls')),
    path('api/notices/', include('apps.notices.urls')),
    path('api/meetings/', include('apps.meetings.urls')),
    path('api/reservations/', include('apps.reservations.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/chatbot/', include('apps.chatbot.urls')),
    path('api/calendars/', include('apps.calendars.urls')),
    path('api/recommendations/', include('apps.recommendations.urls')),
    path('api/gamification/', include('apps.gamification.urls')),
    path('api/academic/', include('apps.academic_planner.urls')),
    path('api/marketplace/', include('apps.marketplace.urls')),
    path('api/faculty-admin/', include('apps.faculty_admin.urls')),
    path('api/safety/', include('apps.safety_wellbeing.urls')),
    path('api/lifecycle/', include('apps.lifecycle.urls')),
    path('api/local/', include('apps.local_integrations.urls')),
    path('api/awards/', include('apps.awards.urls')),
    
    # API Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    
    # Health check endpoints
    path('health/', health, name='health'),
    # path('health/detailed/', detailed_health_check, name='detailed-health'),
    # path('metrics/', metrics, name='metrics'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)