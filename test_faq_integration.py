#!/usr/bin/env python3
"""
Test script to verify FAQ integration in the chatbot
"""
import requests
import json

# Backend URL
BASE_URL = "http://127.0.0.1:8000/api/chatbot"

def test_chatbot_endpoints():
    """Test all chatbot endpoints"""
    print("Testing Chatbot FAQ Integration...")
    print("=" * 50)
    
    # Test 1: Get categories
    print("\n1. Testing categories endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/categories/")
        if response.status_code == 200:
            categories = response.json()
            print(f"✅ Categories loaded: {len(categories)} categories found")
            for cat in categories[:3]:  # Show first 3
                print(f"   - {cat['name']}: {cat['description']}")
        else:
            print(f"❌ Categories failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Categories error: {e}")
    
    # Test 2: Get questions
    print("\n2. Testing questions endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/questions/")
        if response.status_code == 200:
            questions = response.json()
            print(f"✅ Questions loaded: {len(questions)} questions found")
            for q in questions[:3]:  # Show first 3
                print(f"   - {q['question'][:50]}...")
        else:
            print(f"❌ Questions failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Questions error: {e}")
    
    # Test 3: Test question suggestions
    print("\n3. Testing question suggestions...")
    try:
        response = requests.get(f"{BASE_URL}/suggestions/?query=library")
        if response.status_code == 200:
            suggestions = response.json()
            print(f"✅ Suggestions loaded: {len(suggestions)} suggestions found")
            for s in suggestions[:3]:  # Show first 3
                print(f"   - {s['question'][:50]}...")
        else:
            print(f"❌ Suggestions failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Suggestions error: {e}")
    
    # Test 4: Test chat endpoint with FAQ question
    print("\n4. Testing chat endpoint with FAQ question...")
    try:
        chat_data = {
            "message": "How do I book a seat in the library?",
            "session_id": "test-session-123"
        }
        response = requests.post(f"{BASE_URL}/chat/", json=chat_data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Chat response received")
            print(f"   Response: {result['response'][:100]}...")
            print(f"   Confidence: {result['confidence']}")
            print(f"   Category: {result['category']}")
            print(f"   Related questions: {len(result.get('related_questions', []))}")
        else:
            print(f"❌ Chat failed: {response.status_code}")
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"❌ Chat error: {e}")
    
    # Test 5: Test search FAQ
    print("\n5. Testing FAQ search...")
    try:
        response = requests.get(f"{BASE_URL}/search/?query=reservation")
        if response.status_code == 200:
            results = response.json()
            print(f"✅ Search results: {len(results)} results found")
            for r in results[:3]:  # Show first 3
                print(f"   - {r['question'][:50]}...")
        else:
            print(f"❌ Search failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Search error: {e}")
    
    # Test 6: Test popular questions
    print("\n6. Testing popular questions...")
    try:
        response = requests.get(f"{BASE_URL}/popular/")
        if response.status_code == 200:
            popular = response.json()
            print(f"✅ Popular questions: {len(popular)} questions found")
            for p in popular[:3]:  # Show first 3
                print(f"   - {p['question'][:50]}... (used {p['usage_count']} times)")
        else:
            print(f"❌ Popular questions failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Popular questions error: {e}")
    
    print("\n" + "=" * 50)
    print("FAQ Integration Test Complete!")

if __name__ == "__main__":
    test_chatbot_endpoints()
