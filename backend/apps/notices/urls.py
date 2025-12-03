"""
URLs for notices app
"""
from django.urls import path
from . import views

urlpatterns = [
    path('', views.NoticeListCreateView.as_view(), name='notice-list'),
    path('<int:pk>/', views.NoticeDetailView.as_view(), name='notice-detail'),
    path('<int:pk>/view/', views.NoticeViewView.as_view(), name='notice-view'),
    path('<int:pk>/publish/', views.publish_notice, name='publish-notice'),
    path('<int:pk>/pin/', views.pin_notice, name='pin-notice'),
    path('announcements/', views.AnnouncementListCreateView.as_view(), name='announcement-list'),
    path('announcements/<int:pk>/', views.AnnouncementDetailView.as_view(), name='announcement-detail'),
    path('my/', views.MyNoticesView.as_view(), name='my-notices'),
    path('drafts/', views.DraftNoticesView.as_view(), name='draft-notices'),
    path('save-draft/', views.save_draft, name='save-draft'),
    path('save-draft/<int:pk>/', views.save_draft, name='save-draft-update'),
    path('stats/', views.notice_stats, name='notice-stats'),
]
