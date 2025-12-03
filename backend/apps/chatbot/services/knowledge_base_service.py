"""
Knowledge Base Service for dynamic learning and question clustering
"""
from typing import List, Dict, Optional
from django.db.models import Q, Count, Avg
from django.utils import timezone
from apps.chatbot.models import ChatbotQuestion, ChatbotCategory, ChatbotMessage, ChatbotFeedback
from apps.shared.utils.logging import get_logger

logger = get_logger(__name__)


class KnowledgeBaseService:
    """Service for knowledge base management and dynamic learning"""
    
    @staticmethod
    def learn_from_interaction(
        question: ChatbotQuestion,
        user_message: str,
        bot_response: str,
        confidence_score: float,
        feedback: Optional[Dict] = None,
    ):
        """Learn from user interaction"""
        # Update question usage
        question.increment_usage()
        
        # Learn from feedback
        if feedback:
            rating = feedback.get('rating')
            comment = feedback.get('comment')
            
            # If low rating, flag for review
            if rating and rating < 3:
                # Could add a flag for review
                logger.warning(f"Low rating for question {question.id}: {rating}")
        
        # Extract new keywords from user message if confidence is low
        if confidence_score < 0.5:
            # Could suggest adding keywords from user message
            logger.info(f"Low confidence for question {question.id}, suggesting keyword review")
    
    @staticmethod
    def cluster_similar_questions(threshold: float = 0.7) -> List[List[int]]:
        """Cluster similar questions (simplified implementation)"""
        questions = ChatbotQuestion.objects.filter(is_active=True)
        clusters = []
        processed = set()
        
        for question in questions:
            if question.id in processed:
                continue
            
            cluster = [question.id]
            processed.add(question.id)
            
            # Find similar questions
            for other_question in questions:
                if other_question.id in processed:
                    continue
                
                similarity = KnowledgeBaseService._calculate_similarity(
                    question.question,
                    other_question.question,
                )
                
                if similarity >= threshold:
                    cluster.append(other_question.id)
                    processed.add(other_question.id)
            
            if len(cluster) > 1:
                clusters.append(cluster)
        
        return clusters
    
    @staticmethod
    def _calculate_similarity(text1: str, text2: str) -> float:
        """Calculate similarity between two texts (simple word overlap)"""
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        
        if not union:
            return 0.0
        
        return len(intersection) / len(union)
    
    @staticmethod
    def get_answer_quality_metrics(question: ChatbotQuestion) -> Dict:
        """Get answer quality metrics for a question"""
        # Get feedback for this question
        feedbacks = ChatbotFeedback.objects.filter(
            message__related_question=question,
        )
        
        total_feedback = feedbacks.count()
        average_rating = feedbacks.aggregate(Avg('rating'))['rating__avg'] or 0.0
        
        # Get usage statistics
        usage_count = question.usage_count
        
        # Calculate quality score
        quality_score = 0.0
        if total_feedback > 0:
            quality_score = (average_rating / 5.0) * 0.7 + (min(usage_count / 100, 1.0)) * 0.3
        else:
            quality_score = min(usage_count / 100, 1.0) * 0.5
        
        return {
            'question_id': question.id,
            'total_feedback': total_feedback,
            'average_rating': average_rating,
            'usage_count': usage_count,
            'quality_score': quality_score,
        }
    
    @staticmethod
    def suggest_improvements(question: ChatbotQuestion) -> List[str]:
        """Suggest improvements for a question"""
        suggestions = []
        
        # Check if question has keywords
        if not question.keywords or len(question.keywords) == 0:
            suggestions.append("Add keywords to improve matching accuracy")
        
        # Check answer length
        if len(question.answer) < 50:
            suggestions.append("Answer is too short, consider adding more details")
        elif len(question.answer) > 1000:
            suggestions.append("Answer is very long, consider breaking it into smaller parts")
        
        # Check feedback
        feedbacks = ChatbotFeedback.objects.filter(
            message__related_question=question,
        )
        if feedbacks.count() > 0:
            average_rating = feedbacks.aggregate(Avg('rating'))['rating__avg'] or 0.0
            if average_rating < 3.0:
                suggestions.append("Low average rating, consider improving the answer")
        
        # Check usage
        if question.usage_count == 0:
            suggestions.append("Question has not been used, consider reviewing relevance")
        
        return suggestions
    
    @staticmethod
    def expand_knowledge_base(
        user_message: str,
        bot_response: str,
        category: Optional[ChatbotCategory] = None,
    ) -> Optional[ChatbotQuestion]:
        """Expand knowledge base with new question (requires manual review)"""
        # This would typically require admin approval
        # For now, just log the suggestion
        logger.info(f"Suggested new question: {user_message}")
        
        # Could create a pending question that requires approval
        # For now, return None
        return None
    
    @staticmethod
    def get_unanswered_questions(limit: int = 10) -> List[Dict]:
        """Get questions that couldn't be answered"""
        # Get messages with low confidence scores
        unanswered_messages = ChatbotMessage.objects.filter(
            message_type='user',
            session__messages__message_type='bot',
            session__messages__confidence_score__lt=0.3,
        ).distinct()[:limit]
        
        unanswered_questions = []
        for message in unanswered_messages:
            unanswered_questions.append({
                'message': message.content,
                'session_id': message.session.session_id,
                'created_at': message.created_at.isoformat(),
            })
        
        return unanswered_questions
    
    @staticmethod
    def update_question_keywords(question: ChatbotQuestion, new_keywords: List[str]):
        """Update question keywords"""
        existing_keywords = question.keywords or []
        
        # Merge new keywords with existing
        all_keywords = list(set(existing_keywords + new_keywords))
        question.keywords = all_keywords
        question.save(update_fields=['keywords'])
    
    @staticmethod
    def get_popular_topics(limit: int = 10) -> List[Dict]:
        """Get popular topics based on question usage"""
        popular_questions = ChatbotQuestion.objects.filter(
            is_active=True,
        ).annotate(
            message_count=Count('messages'),
        ).order_by('-message_count', '-usage_count')[:limit]
        
        topics = []
        for question in popular_questions:
            topics.append({
                'question': question.question,
                'category': question.category.name,
                'usage_count': question.usage_count,
                'message_count': question.message_count,
            })
        
        return topics

