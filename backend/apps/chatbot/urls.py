"""
URLs for chatbot app
"""
from django.urls import path
from . import views
from . import views_nlp

urlpatterns = [
    # Basic chatbot endpoints
    path('', views.ChatbotView.as_view(), name='chatbot'),
    path('chat/', views.chat_endpoint, name='chatbot-chat'),
    path('session/', views.ChatbotSessionView.as_view(), name='chatbot-session'),
    path('session/<str:session_id>/messages/', views.ChatbotMessageView.as_view(), name='chatbot-messages'),
    path('categories/', views.CategoryListView.as_view(), name='chatbot-categories'),
    path('questions/', views.QuestionListView.as_view(), name='chatbot-questions'),
    path('feedback/', views.ChatbotFeedbackView.as_view(), name='chatbot-feedback'),
    path('analytics/', views.ChatbotAnalyticsView.as_view(), name='chatbot-analytics'),
    path('suggestions/', views.question_suggestions, name='question-suggestions'),
    path('search/', views.search_faq, name='search-faq'),
    path('popular/', views.popular_questions, name='popular-questions'),
    
    # NLP endpoints
    path('context/<str:session_id>/', views_nlp.get_conversation_context, name='chatbot-context'),
    path('context/<str:session_id>/clear/', views_nlp.clear_conversation_context, name='chatbot-context-clear'),
    
    # Personalization endpoints
    path('profile/', views_nlp.get_user_profile, name='chatbot-profile'),
    path('profile/update/', views_nlp.update_user_profile, name='chatbot-profile-update'),
    path('recommendations/', views_nlp.get_personalized_recommendations, name='chatbot-recommendations'),
    path('history/', views_nlp.get_user_interaction_history, name='chatbot-history'),
    path('statistics/', views_nlp.get_user_statistics, name='chatbot-statistics'),
    
    # Action execution endpoints
    path('actions/', views_nlp.get_available_actions, name='chatbot-actions'),
    path('actions/<int:action_id>/execute/', views_nlp.execute_action, name='chatbot-action-execute'),
    
    # Knowledge base endpoints
    path('questions/<int:question_id>/quality/', views_nlp.get_answer_quality_metrics, name='chatbot-quality'),
    path('questions/<int:question_id>/suggestions/', views_nlp.get_suggested_improvements, name='chatbot-suggestions'),
    path('questions/cluster/', views_nlp.cluster_questions, name='chatbot-cluster'),
    path('questions/unanswered/', views_nlp.get_unanswered_questions, name='chatbot-unanswered'),
    path('topics/popular/', views_nlp.get_popular_topics, name='chatbot-popular-topics'),
]
