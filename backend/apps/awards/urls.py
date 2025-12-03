from django.urls import path
from . import views

urlpatterns = [
    # Awards
    path('categories/', views.AwardCategoryListView.as_view(), name='award-category-list'),
    path('awards/', views.AwardListView.as_view(), name='award-list'),
    path('awards/<int:pk>/', views.AwardDetailView.as_view(), name='award-detail'),
    path('user-awards/', views.UserAwardListView.as_view(), name='user-award-list'),
    path('user-awards/<int:pk>/', views.UserAwardDetailView.as_view(), name='user-award-detail'),
    path('users/<int:user_id>/awards-summary/', views.user_awards_summary, name='user-awards-summary'),
    
    # Recognition Posts
    path('recognition-posts/', views.RecognitionPostListView.as_view(), name='recognition-post-list'),
    path('recognition-posts/<int:pk>/', views.RecognitionPostDetailView.as_view(), name='recognition-post-detail'),
    path('recognition-posts/<int:post_id>/like/', views.toggle_recognition_like, name='toggle-recognition-like'),
    
    # Award Nominations
    path('nominations/', views.AwardNominationListView.as_view(), name='award-nomination-list'),
    path('nominations/<int:pk>/', views.AwardNominationDetailView.as_view(), name='award-nomination-detail'),
    
    # Award Ceremonies
    path('ceremonies/', views.AwardCeremonyListView.as_view(), name='award-ceremony-list'),
    path('ceremonies/<int:pk>/', views.AwardCeremonyDetailView.as_view(), name='award-ceremony-detail'),
]

















