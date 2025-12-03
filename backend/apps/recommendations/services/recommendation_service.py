"""
Recommendation Service for content-based recommendations
"""
from typing import List, Dict, Optional, Tuple
from django.contrib.auth import get_user_model
from django.db.models import Q, Count, Avg, F, ExpressionWrapper, FloatField
from django.utils import timezone
from datetime import timedelta, datetime
from apps.recommendations.models import (
    Recommendation, UserPreference, ContentInteraction,
    UserSimilarity, ItemSimilarity
)
from apps.shared.utils.logging import get_logger
from apps.shared.utils.cache import cache_result, invalidate_cache

User = get_user_model()
logger = get_logger(__name__)


class RecommendationService:
    """Service for generating content-based recommendations"""
    
    # Default weights for recommendation factors
    DEFAULT_WEIGHTS = {
        'relevance': 0.4,      # User preferences match
        'popularity': 0.2,     # Overall popularity
        'recency': 0.2,       # How recent the content is
        'interaction': 0.2,   # User interaction patterns
    }
    
    @staticmethod
    def get_recommendations(
        user: User,
        content_type: str,
        limit: int = 10,
        recommendation_type: str = 'content_based',
        exclude_dismissed: bool = True,
        exclude_viewed: bool = False,
    ) -> List[Recommendation]:
        """
        Get recommendations for a user
        
        Args:
            user: User to get recommendations for
            content_type: Type of content ('notice', 'study_group', 'resource', etc.)
            limit: Maximum number of recommendations to return
            recommendation_type: Type of recommendation algorithm to use
            exclude_dismissed: Whether to exclude dismissed recommendations
            exclude_viewed: Whether to exclude viewed recommendations
        
        Returns:
            List of Recommendation objects
        """
        # Check cache first
        cache_key = f'recommendations:{user.id}:{content_type}:{recommendation_type}:{limit}'
        
        # Get existing recommendations
        queryset = Recommendation.objects.filter(
            user=user,
            content_type=content_type,
            recommendation_type=recommendation_type,
        )
        
        if exclude_dismissed:
            queryset = queryset.filter(is_dismissed=False)
        
        if exclude_viewed:
            queryset = queryset.filter(is_viewed=False)
        
        # Filter out expired recommendations
        queryset = queryset.filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())
        )
        
        existing_recommendations = list(queryset.order_by('-score', '-created_at')[:limit])
        
        # If we have enough recommendations, return them
        if len(existing_recommendations) >= limit:
            return existing_recommendations
        
        # Generate new recommendations based on type
        if recommendation_type == 'content_based':
            new_recommendations = RecommendationService._generate_content_based_recommendations(
                user, content_type, limit
            )
        elif recommendation_type == 'popular':
            new_recommendations = RecommendationService._generate_popular_recommendations(
                user, content_type, limit
            )
        elif recommendation_type == 'trending':
            new_recommendations = RecommendationService._generate_trending_recommendations(
                user, content_type, limit
            )
        else:
            # Default to content-based
            new_recommendations = RecommendationService._generate_content_based_recommendations(
                user, content_type, limit
            )
        
        # Combine and return
        all_recommendations = existing_recommendations + new_recommendations
        return all_recommendations[:limit]
    
    @staticmethod
    def _generate_content_based_recommendations(
        user: User,
        content_type: str,
        limit: int = 10,
    ) -> List[Recommendation]:
        """Generate content-based recommendations"""
        recommendations = []
        
        # Get user preferences
        try:
            user_preference = UserPreference.objects.get(
                user=user,
                content_type=content_type
            )
            preferences = user_preference.preferences
            interests = user_preference.interests
        except UserPreference.DoesNotExist:
            # Create default preferences
            preferences = {}
            interests = []
            user_preference = UserPreference.objects.create(
                user=user,
                content_type=content_type,
                preferences=preferences,
                interests=interests,
            )
        
        # Get user's interaction history
        user_interactions = ContentInteraction.objects.filter(
            user=user,
            content_type=content_type,
        ).order_by('-created_at')[:50]
        
        # Get interacted content IDs to exclude
        interacted_content_ids = set(
            user_interactions.values_list('content_id', flat=True)
        )
        
        # Get content items based on type
        content_items = RecommendationService._get_content_items(
            content_type, exclude_ids=list(interacted_content_ids), limit=limit * 2
        )
        
        # Score each item
        scored_items = []
        for item in content_items:
            score = RecommendationService._calculate_content_score(
                item, user_preference, user_interactions, content_type
            )
            
            if score > 0:
                scored_items.append((item['id'], score, item))
        
        # Sort by score and get top items
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        # Create recommendation objects
        for item_id, score, item_data in scored_items[:limit]:
            # Check if recommendation already exists
            recommendation, created = Recommendation.objects.get_or_create(
                user=user,
                content_type=content_type,
                content_id=item_id,
                recommendation_type='content_based',
                defaults={
                    'score': score,
                    'reason': RecommendationService._generate_recommendation_reason(
                        item_data, user_preference, score, content_type
                    ),
                }
            )
            
            if created or recommendation.score < score:
                # Update score if better
                recommendation.score = score
                recommendation.reason = RecommendationService._generate_recommendation_reason(
                    item_data, user_preference, score, content_type
                )
                recommendation.save()
            
            recommendations.append(recommendation)
        
        return recommendations
    
    @staticmethod
    def _generate_popular_recommendations(
        user: User,
        content_type: str,
        limit: int = 10,
    ) -> List[Recommendation]:
        """Generate popular item recommendations"""
        recommendations = []
        
        # Get user's interacted content IDs
        user_interactions = ContentInteraction.objects.filter(
            user=user,
            content_type=content_type,
        )
        interacted_content_ids = set(user_interactions.values_list('content_id', flat=True))
        
        # Get popular items (based on interaction count)
        popular_items = RecommendationService._get_popular_content(
            content_type, exclude_ids=list(interacted_content_ids), limit=limit * 2
        )
        
        # Create recommendations
        for item in popular_items[:limit]:
            recommendation, created = Recommendation.objects.get_or_create(
                user=user,
                content_type=content_type,
                content_id=item['id'],
                recommendation_type='popular',
                defaults={
                    'score': item.get('popularity_score', 0.5),
                    'reason': f"Popular {content_type} with {item.get('interaction_count', 0)} interactions",
                }
            )
            
            if created:
                recommendations.append(recommendation)
        
        return recommendations
    
    @staticmethod
    def _generate_trending_recommendations(
        user: User,
        content_type: str,
        limit: int = 10,
    ) -> List[Recommendation]:
        """Generate trending item recommendations"""
        recommendations = []
        
        # Get trending time window (last 7 days)
        time_window = timezone.now() - timedelta(days=7)
        
        # Get user's interacted content IDs
        user_interactions = ContentInteraction.objects.filter(
            user=user,
            content_type=content_type,
        )
        interacted_content_ids = set(user_interactions.values_list('content_id', flat=True))
        
        # Get trending items (based on recent interactions)
        trending_items = RecommendationService._get_trending_content(
            content_type, time_window, exclude_ids=list(interacted_content_ids), limit=limit * 2
        )
        
        # Create recommendations
        for item in trending_items[:limit]:
            recommendation, created = Recommendation.objects.get_or_create(
                user=user,
                content_type=content_type,
                content_id=item['id'],
                recommendation_type='trending',
                defaults={
                    'score': item.get('trending_score', 0.5),
                    'reason': f"Trending {content_type} with {item.get('recent_interactions', 0)} recent interactions",
                }
            )
            
            if created:
                recommendations.append(recommendation)
        
        return recommendations
    
    @staticmethod
    def _get_content_items(
        content_type: str,
        exclude_ids: Optional[List[int]] = None,
        limit: int = 20,
    ) -> List[Dict]:
        """Get content items based on type"""
        exclude_ids = exclude_ids or []
        
        if content_type == 'notice':
            from apps.notices.models import Notice
            items = Notice.objects.exclude(id__in=exclude_ids).order_by('-created_at')[:limit]
            return [
                {
                    'id': item.id,
                    'title': item.title,
                    'content': item.content,
                    'category': getattr(item, 'category', None),
                    'tags': getattr(item, 'tags', []),
                    'created_at': item.created_at,
                }
                for item in items
            ]
        elif content_type == 'study_group':
            from apps.study_groups.models import StudyGroup
            items = StudyGroup.objects.exclude(id__in=exclude_ids).filter(is_active=True).order_by('-created_at')[:limit]
            return [
                {
                    'id': item.id,
                    'title': item.name,
                    'content': item.description,
                    'category': getattr(item, 'subject', None),
                    'tags': getattr(item, 'tags', []),
                    'created_at': item.created_at,
                }
                for item in items
            ]
        else:
            # For other types, return empty list (can be extended)
            return []
    
    @staticmethod
    def _get_popular_content(
        content_type: str,
        exclude_ids: Optional[List[int]] = None,
        limit: int = 20,
    ) -> List[Dict]:
        """Get popular content based on interaction count"""
        exclude_ids = exclude_ids or []
        
        # Get interaction counts per content item
        interactions = ContentInteraction.objects.filter(
            content_type=content_type,
        ).exclude(content_id__in=exclude_ids).values('content_id').annotate(
            interaction_count=Count('id'),
            avg_rating=Avg('rating'),
        ).order_by('-interaction_count')[:limit]
        
        items = []
        for interaction in interactions:
            items.append({
                'id': interaction['content_id'],
                'interaction_count': interaction['interaction_count'],
                'popularity_score': min(interaction['interaction_count'] / 100.0, 1.0),
                'avg_rating': interaction['avg_rating'] or 0.0,
            })
        
        return items
    
    @staticmethod
    def _get_trending_content(
        content_type: str,
        time_window: datetime,
        exclude_ids: Optional[List[int]] = None,
        limit: int = 20,
    ) -> List[Dict]:
        """Get trending content based on recent interactions"""
        exclude_ids = exclude_ids or []
        
        # Get recent interaction counts per content item
        interactions = ContentInteraction.objects.filter(
            content_type=content_type,
            created_at__gte=time_window,
        ).exclude(content_id__in=exclude_ids).values('content_id').annotate(
            recent_interactions=Count('id'),
            avg_rating=Avg('rating'),
        ).order_by('-recent_interactions')[:limit]
        
        items = []
        for interaction in interactions:
            items.append({
                'id': interaction['content_id'],
                'recent_interactions': interaction['recent_interactions'],
                'trending_score': min(interaction['recent_interactions'] / 50.0, 1.0),
                'avg_rating': interaction['avg_rating'] or 0.0,
            })
        
        return items
    
    @staticmethod
    def _calculate_content_score(
        item: Dict,
        user_preference: UserPreference,
        user_interactions: List[ContentInteraction],
        content_type: str,
    ) -> float:
        """Calculate recommendation score for a content item"""
        score = 0.0
        weights = user_preference.weight_preferences or RecommendationService.DEFAULT_WEIGHTS.copy()
        
        # Relevance score (based on preferences and interests)
        relevance_score = RecommendationService._calculate_relevance_score(
            item, user_preference
        )
        score += relevance_score * weights.get('relevance', 0.4)
        
        # Popularity score
        popularity_score = RecommendationService._calculate_popularity_score(
            item['id'], content_type
        )
        score += popularity_score * weights.get('popularity', 0.2)
        
        # Recency score
        recency_score = RecommendationService._calculate_recency_score(
            item.get('created_at', timezone.now())
        )
        score += recency_score * weights.get('recency', 0.2)
        
        # Interaction pattern score
        interaction_score = RecommendationService._calculate_interaction_score(
            item['id'], content_type, user_interactions
        )
        score += interaction_score * weights.get('interaction', 0.2)
        
        return min(score, 1.0)  # Cap at 1.0
    
    @staticmethod
    def _calculate_relevance_score(item: Dict, user_preference: UserPreference) -> float:
        """Calculate relevance score based on user preferences"""
        score = 0.5  # Base score
        
        # Match interests
        item_tags = item.get('tags', [])
        user_interests = user_preference.interests or []
        
        if item_tags and user_interests:
            matching_tags = set(item_tags) & set(user_interests)
            if matching_tags:
                score += 0.3 * (len(matching_tags) / max(len(item_tags), len(user_interests)))
        
        # Match category
        item_category = item.get('category')
        preferences = user_preference.preferences or {}
        preferred_categories = preferences.get('categories', [])
        
        if item_category and preferred_categories:
            if item_category in preferred_categories:
                score += 0.2
        
        return min(score, 1.0)
    
    @staticmethod
    def _calculate_popularity_score(content_id: int, content_type: str) -> float:
        """Calculate popularity score based on interaction count"""
        interaction_count = ContentInteraction.objects.filter(
            content_type=content_type,
            content_id=content_id,
        ).count()
        
        # Normalize to 0-1 range (assuming max 100 interactions = 1.0)
        return min(interaction_count / 100.0, 1.0)
    
    @staticmethod
    def _calculate_recency_score(created_at: timezone.datetime) -> float:
        """Calculate recency score based on creation date"""
        if not created_at:
            return 0.5
        
        days_old = (timezone.now() - created_at).days
        
        # Newer items get higher scores
        # Items less than 7 days old = 1.0, older items decay
        if days_old < 7:
            return 1.0
        elif days_old < 30:
            return 0.7
        elif days_old < 90:
            return 0.4
        else:
            return 0.2
    
    @staticmethod
    def _calculate_interaction_score(
        content_id: int,
        content_type: str,
        user_interactions: List[ContentInteraction],
    ) -> float:
        """Calculate score based on similar items user has interacted with"""
        # For now, return a base score
        # Can be enhanced to look at similar items user has interacted with
        return 0.5
    
    @staticmethod
    def _generate_recommendation_reason(
        item: Dict,
        user_preference: UserPreference,
        score: float,
        content_type: str,
    ) -> str:
        """Generate a human-readable reason for the recommendation"""
        reasons = []
        
        # Check for matching interests
        item_tags = item.get('tags', [])
        user_interests = user_preference.interests or []
        matching_tags = set(item_tags) & set(user_interests)
        
        if matching_tags:
            reasons.append(f"Matches your interests: {', '.join(list(matching_tags)[:3])}")
        
        # Check for category match
        item_category = item.get('category')
        if item_category:
            reasons.append(f"Related to {item_category}")
        
        # Add popularity info
        popularity_score = RecommendationService._calculate_popularity_score(
            item['id'], content_type
        )
        if popularity_score > 0.7:
            reasons.append("Popular among users")
        
        # Default reason
        if not reasons:
            reasons.append(f"Recommended {content_type} for you")
        
        return ". ".join(reasons[:2])  # Limit to 2 reasons
    
    @staticmethod
    def track_interaction(
        user: User,
        content_type: str,
        content_id: int,
        interaction_type: str,
        rating: Optional[int] = None,
        duration: Optional[int] = None,
        metadata: Optional[Dict] = None,
    ) -> ContentInteraction:
        """Track user interaction with content"""
        interaction = ContentInteraction.objects.create(
            user=user,
            content_type=content_type,
            content_id=content_id,
            interaction_type=interaction_type,
            rating=rating,
            duration=duration,
            metadata=metadata or {},
        )
        
        # Update recommendation status if applicable
        Recommendation.objects.filter(
            user=user,
            content_type=content_type,
            content_id=content_id,
        ).update(
            is_viewed=True if interaction_type == 'view' else F('is_viewed'),
            is_interacted=True,
        )
        
        # Invalidate recommendation cache
        invalidate_cache(f'recommendations:{user.id}:{content_type}:*')
        
        return interaction
    
    @staticmethod
    def dismiss_recommendation(
        user: User,
        content_type: str,
        content_id: int,
        recommendation_type: Optional[str] = None,
    ) -> Recommendation:
        """Dismiss a recommendation"""
        queryset = Recommendation.objects.filter(
            user=user,
            content_type=content_type,
            content_id=content_id,
        )
        
        if recommendation_type:
            queryset = queryset.filter(recommendation_type=recommendation_type)
        
        recommendation = queryset.first()
        
        if recommendation:
            recommendation.is_dismissed = True
            recommendation.save()
            
            # Invalidate recommendation cache
            invalidate_cache(f'recommendations:{user.id}:{content_type}:*')
        
        return recommendation
    
    @staticmethod
    def submit_feedback(
        user: User,
        content_type: str,
        content_id: int,
        feedback_type: str,
        feedback_data: Dict,
        recommendation_type: Optional[str] = None,
    ) -> Recommendation:
        """Submit feedback on a recommendation"""
        queryset = Recommendation.objects.filter(
            user=user,
            content_type=content_type,
            content_id=content_id,
        )
        
        if recommendation_type:
            queryset = queryset.filter(recommendation_type=recommendation_type)
        
        recommendation = queryset.first()
        
        if recommendation:
            feedback = recommendation.feedback or {}
            feedback[feedback_type] = feedback_data
            recommendation.feedback = feedback
            recommendation.save()
        
        return recommendation

