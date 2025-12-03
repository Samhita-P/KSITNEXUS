#!/usr/bin/env python3
import os
import sys
import django

# Add the backend directory to the Python path
sys.path.append('.')

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.chatbot.models import ChatbotCategory, ChatbotQuestion

def test_chatbot_data():
    print("=== Chatbot Data Test ===")
    print(f"Total Categories: {ChatbotCategory.objects.count()}")
    print(f"Total Questions: {ChatbotQuestion.objects.count()}")
    
    print("\n=== Categories ===")
    for category in ChatbotCategory.objects.all().order_by('order'):
        print(f"- {category.name}: {category.questions.count()} questions")
    
    print("\n=== Sample Questions ===")
    for question in ChatbotQuestion.objects.all()[:10]:
        print(f"- {question.question}")
        print(f"  Answer: {question.answer[:100]}...")
        print(f"  Category: {question.category.name}")
        print()

if __name__ == "__main__":
    test_chatbot_data()

