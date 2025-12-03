from django.urls import path
from . import views

urlpatterns = [
    # Calendar events
    path('events/', views.CalendarEventListCreateView.as_view(), name='calendar-event-list-create'),
    path('events/<int:pk>/', views.CalendarEventRetrieveUpdateDestroyView.as_view(), name='calendar-event-detail'),
    path('events/upcoming/', views.upcoming_events, name='calendar-event-upcoming'),
    path('events/date-range/', views.events_by_date_range, name='calendar-event-date-range'),
    path('events/type/<str:event_type>/', views.events_by_type, name='calendar-event-type'),
    path('events/<int:pk>/cancel/', views.cancel_event, name='calendar-event-cancel'),
    
    # Event reminders
    path('events/<int:pk>/reminders/', views.add_reminder, name='calendar-event-add-reminder'),
    path('events/<int:pk>/reminders/remove/', views.remove_reminder, name='calendar-event-remove-reminder'),
    
    # iCal export/import
    path('ical/export/', views.export_ical, name='calendar-ical-export'),
    path('ical/import/', views.import_ical, name='calendar-ical-import'),
    path('ical/feed/<int:user_id>/', views.ical_feed, name='calendar-ical-feed'),
    
    # Google Calendar integration
    path('google/authorize/', views.google_calendar_authorize, name='google-calendar-authorize'),
    path('google/callback/', views.google_calendar_callback, name='google-calendar-callback'),
    path('google/disconnect/', views.google_calendar_disconnect, name='google-calendar-disconnect'),
    path('google/sync-status/', views.google_calendar_sync_status, name='google-calendar-sync-status'),
    path('google/sync/', views.google_calendar_sync, name='google-calendar-sync'),
]

