"""
WebSocket URL routing for real-time notifications
"""

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/notifications/(?P<user_id>\w+)/$', consumers.NotificationConsumer.as_asgi()),
    re_path(r'ws/study-groups/(?P<group_id>\w+)/$', consumers.StudyGroupConsumer.as_asgi()),
    re_path(r'ws/chat/(?P<group_id>\w+)/$', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/reservations/(?P<resource_type>\w+)/$', consumers.ReservationConsumer.as_asgi()),
]
