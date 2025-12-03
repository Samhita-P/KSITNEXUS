"""
URLs for reservations app
"""
from django.urls import path
from . import views

urlpatterns = [
    path('rooms/', views.ReadingRoomListView.as_view(), name='reading-room-list'),
    path('rooms/<int:room_id>/seats/', views.SeatListView.as_view(), name='seat-list'),
    path('rooms/<int:room_id>/availability/', views.SeatAvailabilityView.as_view(), name='seat-availability'),
    path('', views.ReservationListCreateView.as_view(), name='reservation-list'),
    path('<int:pk>/', views.ReservationDetailView.as_view(), name='reservation-detail'),
    path('<int:pk>/checkin/', views.CheckInView.as_view(), name='check-in'),
    path('<int:pk>/checkout/', views.CheckOutView.as_view(), name='check-out'),
    path('<int:pk>/cancel/', views.CancelReservationView.as_view(), name='cancel-reservation'),
    path('my/', views.MyReservationsView.as_view(), name='my-reservations'),
    path('user/', views.user_reservations, name='user-reservations'),
]
