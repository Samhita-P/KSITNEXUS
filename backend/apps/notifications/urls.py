"""
URLs for notifications app
"""
from django.urls import path
from . import views
from . import fcm_views
from . import views_digest
# from . import health_views  # Temporarily disabled due to missing psutil dependency

urlpatterns = [
    path('', views.NotificationListView.as_view(), name='notification-list'),
    path('<int:pk>/', views.NotificationDetailView.as_view(), name='notification-detail'),
    path('<int:pk>/read/', views.MarkAsReadView.as_view(), name='mark-as-read'),
    path('preferences/', views.NotificationPreferenceView.as_view(), name='notification-preferences'),
    path('unread-count/', views.UnreadCountView.as_view(), name='unread-count'),
    path('mark-all-read/', views.MarkAllReadView.as_view(), name='mark-all-read'),
    
    # FCM Token endpoints
    path('fcm-tokens/', fcm_views.FCMTokenListCreateView.as_view(), name='fcm-token-list'),
    path('fcm-tokens/<int:pk>/', fcm_views.FCMTokenDetailView.as_view(), name='fcm-token-detail'),
    path('fcm-tokens/register/', fcm_views.register_fcm_token, name='register-fcm-token'),
    path('fcm-tokens/<str:token>/unregister/', fcm_views.unregister_fcm_token, name='unregister-fcm-token'),
    
    # Push notification endpoints
    path('push-notifications/send/', fcm_views.send_push_notification, name='send-push-notification'),
    path('push-notifications/topic/', fcm_views.send_topic_notification, name='send-topic-notification'),
    path('push-notifications/history/', fcm_views.get_notification_history, name='notification-history'),
    
    # Topic subscription endpoints
    path('topics/subscribe/', fcm_views.subscribe_to_topic, name='subscribe-topic'),
    path('topics/unsubscribe/', fcm_views.unsubscribe_from_topic, name='unsubscribe-topic'),
    
    # Template endpoints
    path('templates/', fcm_views.NotificationTemplateListCreateView.as_view(), name='template-list'),
    path('templates/<int:pk>/', fcm_views.NotificationTemplateDetailView.as_view(), name='template-detail'),
    path('templates/send/', fcm_views.send_template_notification, name='send-template-notification'),
    
    # Quiet hours endpoints
    path('quiet-hours/status/', views.get_quiet_hours_status, name='quiet-hours-status'),
    path('quiet-hours/set/', views.set_quiet_hours, name='set-quiet-hours'),
    path('quiet-hours/disable/', views.disable_quiet_hours, name='disable-quiet-hours'),
    
    # Digest endpoints
    path('digests/', views_digest.NotificationDigestListView.as_view(), name='digest-list'),
    path('digests/<int:pk>/', views_digest.NotificationDigestDetailView.as_view(), name='digest-detail'),
    path('digests/<int:pk>/read/', views_digest.NotificationDigestMarkAsReadView.as_view(), name='digest-mark-read'),
    path('digests/generate-daily/', views_digest.generate_daily_digest, name='generate-daily-digest'),
    path('digests/generate-weekly/', views_digest.generate_weekly_digest, name='generate-weekly-digest'),
    
    # Tier endpoints
    path('tiers/', views_digest.NotificationTierListView.as_view(), name='tier-list'),
    path('tiers/<int:pk>/', views_digest.NotificationTierDetailView.as_view(), name='tier-detail'),
    
    # Summary endpoints
    path('summaries/<int:pk>/', views_digest.NotificationSummaryView.as_view(), name='summary-detail'),
    path('summaries/generate/', views_digest.generate_summary, name='generate-summary'),
    
    # Priority endpoints
    path('priority-rules/', views_digest.NotificationPriorityRuleListView.as_view(), name='priority-rule-list'),
    path('priority-rules/<int:pk>/', views_digest.NotificationPriorityRuleDetailView.as_view(), name='priority-rule-detail'),
    path('notifications/<int:pk>/priority/', views_digest.get_notification_priority, name='get-notification-priority'),
    path('notifications/filter-by-priority/', views_digest.filter_by_priority, name='filter-by-priority'),
    
    # Health check endpoints - temporarily disabled due to missing psutil dependency
    # path('health/', health_views.health_check, name='health-check'),
    # path('health/detailed/', health_views.detailed_health_check, name='detailed-health-check'),
    # path('metrics/', health_views.metrics, name='metrics'),
]
