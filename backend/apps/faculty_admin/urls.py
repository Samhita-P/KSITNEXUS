from django.urls import path
from . import views

urlpatterns = [
    # Case Management
    path('cases/', views.CaseListView.as_view(), name='case-list'),
    path('cases/<int:pk>/', views.CaseDetailView.as_view(), name='case-detail'),
    path('cases/<int:case_id>/updates/', views.CaseUpdateListView.as_view(), name='case-updates'),
    path('cases/analytics/', views.case_analytics, name='case-analytics'),
    path('cases/at-risk/', views.cases_at_risk, name='cases-at-risk'),
    
    # Broadcast Studio
    path('broadcasts/', views.BroadcastListView.as_view(), name='broadcast-list'),
    path('broadcasts/<int:pk>/', views.BroadcastDetailView.as_view(), name='broadcast-detail'),
    path('broadcasts/<int:broadcast_id>/publish/', views.publish_broadcast, name='publish-broadcast'),
    
    # Predictive Operations
    path('predictive/metrics/', views.predictive_metrics, name='predictive-metrics'),
    path('alerts/', views.operational_alerts, name='operational-alerts'),
    path('alerts/<int:alert_id>/acknowledge/', views.acknowledge_alert, name='acknowledge-alert'),
    path('alerts/generate/', views.generate_alerts, name='generate-alerts'),
]






