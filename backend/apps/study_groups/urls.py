"""
URLs for study_groups app
"""
from django.urls import path
from . import views
from . import download_view

urlpatterns = [
    path('', views.StudyGroupListCreateView.as_view(), name='study-group-list'),
    path('<int:pk>/', views.StudyGroupDetailView.as_view(), name='study-group-detail'),
    path('<int:pk>/join/', views.join_group, name='join-group'),
    path('<int:pk>/leave/', views.leave_group, name='leave-group'),
    path('<int:pk>/join-requests/', views.GroupJoinRequestListView.as_view(), name='group-join-requests'),
    path('<int:pk>/join-requests/<int:request_id>/', views.GroupJoinRequestUpdateView.as_view(), name='update-join-request'),
    path('<int:pk>/messages/', views.GroupMessageListCreateView.as_view(), name='group-messages'),
    path('<int:pk>/resources/', views.ResourceListCreateView.as_view(), name='group-resources'),
    path('<int:group_id>/resources/<int:resource_id>/download/', download_view.download_resource, name='download-resource'),
    path('<int:pk>/events/', views.EventListCreateView.as_view(), name='group-events'),
    path('my/', views.MyStudyGroupsView.as_view(), name='my-study-groups'),
    # Moderation endpoints
    path('<int:group_id>/report/', views.report_study_group, name='report-study-group'),
    path('<int:group_id>/close/', views.close_study_group, name='close-study-group'),
    path('<int:group_id>/mute/', views.mute_study_group, name='mute-study-group'),
    # Faculty-specific endpoints
    path('faculty/', views.faculty_study_groups, name='faculty-study-groups'),
    path('<int:group_id>/approve/', views.approve_study_group, name='approve-study-group'),
    path('<int:group_id>/reject/', views.reject_study_group, name='reject-study-group'),
    path('<int:group_id>/reopen/', views.reopen_study_group, name='reopen-study-group'),
]
