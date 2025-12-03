"""
URL patterns for recommendations app
"""
from django.urls import path
from . import views

urlpatterns = [
    # Recommendation endpoints
    path('', views.RecommendationListView.as_view(), name='recommendations-list'),
    path('create/', views.RecommendationCreateView.as_view(), name='recommendations-create'),
    path('<int:recommendation_id>/dismiss/', views.dismiss_recommendation, name='recommendations-dismiss'),
    path('feedback/', views.submit_recommendation_feedback, name='recommendations-feedback'),
    path('refresh/', views.refresh_recommendations, name='recommendations-refresh'),
    
    # Content-specific recommendation endpoints
    path('notices/', views.get_notice_recommendations, name='recommendations-notices'),
    path('study-groups/', views.get_study_group_recommendations, name='recommendations-study-groups'),
    path('resources/', views.get_resource_recommendations, name='recommendations-resources'),
    
    # Popular and trending endpoints
    path('popular/', views.get_popular_items, name='recommendations-popular'),
    path('trending/', views.get_trending_items, name='recommendations-trending'),
    
    # User preference endpoints
    path('preferences/', views.UserPreferenceView.as_view(), name='recommendations-preferences'),
    
    # Content interaction endpoints
    path('interactions/', views.ContentInteractionListView.as_view(), name='recommendations-interactions'),
]

