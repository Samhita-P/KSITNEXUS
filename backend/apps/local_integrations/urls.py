from django.urls import path
from . import views

urlpatterns = [
    # Hostel
    path('hostels/', views.HostelListView.as_view(), name='hostel-list'),
    path('hostels/<int:pk>/', views.HostelDetailView.as_view(), name='hostel-detail'),
    path('hostels/rooms/', views.HostelRoomListView.as_view(), name='hostel-room-list'),
    path('hostels/bookings/', views.HostelBookingListView.as_view(), name='hostel-booking-list'),
    path('hostels/bookings/<int:pk>/', views.HostelBookingDetailView.as_view(), name='hostel-booking-detail'),
    
    # Cafeteria
    path('cafeterias/', views.CafeteriaListView.as_view(), name='cafeteria-list'),
    path('cafeterias/<int:pk>/', views.CafeteriaDetailView.as_view(), name='cafeteria-detail'),
    path('cafeterias/menu/', views.CafeteriaMenuListView.as_view(), name='cafeteria-menu-list'),
    path('cafeterias/bookings/', views.CafeteriaBookingListView.as_view(), name='cafeteria-booking-list'),
    path('cafeterias/orders/', views.CafeteriaOrderListView.as_view(), name='cafeteria-order-list'),
    path('cafeterias/orders/<int:pk>/', views.CafeteriaOrderDetailView.as_view(), name='cafeteria-order-detail'),
    
    # Transport
    path('transport/routes/', views.TransportRouteListView.as_view(), name='transport-route-list'),
    path('transport/routes/<int:pk>/', views.TransportRouteDetailView.as_view(), name='transport-route-detail'),
    path('transport/schedules/', views.TransportScheduleListView.as_view(), name='transport-schedule-list'),
    path('transport/live-info/', views.transport_live_info, name='transport-live-info'),
    path('transport/vehicles/', views.transport_vehicles, name='transport-vehicles'),
]

















