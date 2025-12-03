"""
URLs for faculty endpoints
"""
from django.urls import path
from . import views

urlpatterns = [
    path('', views.FacultyListView.as_view(), name='faculty-list'),
]

