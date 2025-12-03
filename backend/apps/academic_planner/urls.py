from django.urls import path
from . import views

urlpatterns = [
    # Courses
    path('courses/', views.CourseListView.as_view(), name='course-list'),
    path('courses/<int:pk>/', views.CourseDetailView.as_view(), name='course-detail'),
    
    # Course Enrollments
    path('enrollments/', views.CourseEnrollmentListView.as_view(), name='enrollment-list'),
    path('enrollments/<int:pk>/', views.CourseEnrollmentDetailView.as_view(), name='enrollment-detail'),
    
    # Assignments
    path('assignments/', views.AssignmentListView.as_view(), name='assignment-list'),
    path('assignments/<int:pk>/', views.AssignmentDetailView.as_view(), name='assignment-detail'),
    path('assignments/<int:assignment_id>/submit/', views.submit_assignment, name='submit-assignment'),
    
    # Grades
    path('grades/', views.GradeListView.as_view(), name='grade-list'),
    path('grades/<int:pk>/', views.GradeDetailView.as_view(), name='grade-detail'),
    
    # Academic Reminders
    path('reminders/', views.AcademicReminderListView.as_view(), name='reminder-list'),
    path('reminders/<int:pk>/', views.AcademicReminderDetailView.as_view(), name='reminder-detail'),
    
    # Dashboard and Statistics
    path('dashboard/', views.academic_dashboard, name='academic-dashboard'),
    path('deadlines/', views.upcoming_deadlines, name='upcoming-deadlines'),
    path('gpa/', views.calculate_gpa, name='calculate-gpa'),
    path('courses/<int:course_id>/calculate-grade/', views.calculate_course_grade, name='calculate-course-grade'),
]

















