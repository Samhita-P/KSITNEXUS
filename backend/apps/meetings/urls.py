from django.urls import path
from . import views

urlpatterns = [
    path('', views.MeetingListCreateView.as_view(), name='meeting-list-create'),
    path('<int:pk>/', views.MeetingRetrieveUpdateDestroyView.as_view(), name='meeting-detail'),
    path('user/', views.user_meetings, name='user-meetings'),
    path('<int:pk>/cancel/', views.cancel_meeting, name='cancel-meeting'),
    path('<int:pk>/complete/', views.complete_meeting, name='complete-meeting'),
]

