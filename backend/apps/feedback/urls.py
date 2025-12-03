"""
URLs for feedback app
"""
from django.urls import path
from . import views

urlpatterns = [
    path('', views.FeedbackListCreateView.as_view(), name='feedback-list'),
    path('<int:pk>/', views.FeedbackDetailView.as_view(), name='feedback-detail'),
    path('faculty/<int:faculty_id>/', views.FacultyFeedbackView.as_view(), name='faculty-feedback'),
    path('summary/', views.FeedbackSummaryView.as_view(), name='feedback-summary'),
    path('my/', views.MyFeedbackView.as_view(), name='my-feedback'),
    path('faculty-list/', views.faculty_list_for_feedback, name='faculty-list'),
    path('stats/', views.feedback_stats, name='feedback-stats'),
    path('submit/', views.submit_feedback, name='submit-feedback'),
]
