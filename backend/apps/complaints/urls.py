"""
URLs for complaints app
"""
from django.urls import path
from . import views

urlpatterns = [
    path('', views.ComplaintListCreateView.as_view(), name='complaint-list'),
    path('<int:pk>/', views.ComplaintDetailView.as_view(), name='complaint-detail'),
    path('<int:pk>/update/', views.ComplaintUpdateView.as_view(), name='complaint-update'),
    path('<int:pk>/attachments/', views.ComplaintAttachmentView.as_view(), name='complaint-attachments'),
    path('my/', views.MyComplaintsView.as_view(), name='my-complaints'),
    path('admin/', views.AdminComplaintsView.as_view(), name='admin-complaints'),
    path('faculty/dashboard/', views.FacultyComplaintsDashboardView.as_view(), name='faculty-complaints-dashboard'),
    path('<int:pk>/respond/', views.respond_to_complaint, name='respond-to-complaint'),
    path('<int:pk>/mark-resolved/', views.mark_complaint_resolved, name='mark-complaint-resolved'),
    path('faculty/stats/', views.faculty_complaint_stats, name='faculty-complaint-stats'),
    path('<int:pk>/assign/', views.assign_complaint, name='assign-complaint'),
    path('stats/', views.complaint_stats, name='complaint-stats'),
]
