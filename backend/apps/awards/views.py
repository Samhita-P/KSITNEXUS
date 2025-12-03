"""
Views for awards app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from .models import (
    AwardCategory, Award, UserAward, RecognitionPost,
    RecognitionLike, AwardNomination, AwardCeremony
)
from .serializers import (
    AwardCategorySerializer, AwardSerializer, UserAwardSerializer,
    RecognitionPostSerializer, AwardNominationSerializer, AwardCeremonySerializer
)

User = get_user_model()


# Awards
class AwardCategoryListView(generics.ListAPIView):
    """List award categories"""
    queryset = AwardCategory.objects.filter(is_active=True)
    serializer_class = AwardCategorySerializer
    permission_classes = [permissions.IsAuthenticated]


class AwardListView(generics.ListAPIView):
    """List awards"""
    serializer_class = AwardSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = Award.objects.filter(is_active=True).select_related('category')
        
        award_type = self.request.query_params.get('award_type')
        category_id = self.request.query_params.get('category_id')
        is_featured = self.request.query_params.get('is_featured')
        
        if award_type:
            queryset = queryset.filter(award_type=award_type)
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        if is_featured == 'true':
            queryset = queryset.filter(is_featured=True)
        
        return queryset


class AwardDetailView(generics.RetrieveAPIView):
    """Award detail view"""
    queryset = Award.objects.all()
    serializer_class = AwardSerializer
    permission_classes = [permissions.IsAuthenticated]


class UserAwardListView(generics.ListCreateAPIView):
    """List and create user awards"""
    serializer_class = UserAwardSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = UserAward.objects.all().select_related('award', 'user', 'awarded_by')
        
        if user.user_type == 'student':
            # Students see their own awards
            queryset = queryset.filter(user=user)
        else:
            # Faculty/admin can see all or filter by user
            user_id = self.request.query_params.get('user_id')
            if user_id:
                queryset = queryset.filter(user_id=user_id)
        
        award_id = self.request.query_params.get('award_id')
        if award_id:
            queryset = queryset.filter(award_id=award_id)
        
        return queryset.order_by('-awarded_at')
    
    def perform_create(self, serializer):
        if self.request.user.user_type not in ['faculty', 'admin']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only faculty and admin can create awards')
        serializer.save(awarded_by=self.request.user)


class UserAwardDetailView(generics.RetrieveUpdateDestroyAPIView):
    """User award detail view"""
    queryset = UserAward.objects.all()
    serializer_class = UserAwardSerializer
    permission_classes = [permissions.IsAuthenticated]


# Recognition Posts
class RecognitionPostListView(generics.ListCreateAPIView):
    """List and create recognition posts"""
    serializer_class = RecognitionPostSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = RecognitionPost.objects.filter(is_published=True).prefetch_related(
            'recognized_users', 'likes'
        )
        
        post_type = self.request.query_params.get('post_type')
        if post_type:
            queryset = queryset.filter(post_type=post_type)
        
        return queryset.order_by('-published_at', '-created_at')
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def perform_create(self, serializer):
        if self.request.user.user_type not in ['faculty', 'admin']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only faculty and admin can create recognition posts')
        post = serializer.save(created_by=self.request.user)
        if post.is_published:
            post.published_at = timezone.now()
            post.save(update_fields=['published_at'])


class RecognitionPostDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Recognition post detail view"""
    queryset = RecognitionPost.objects.all()
    serializer_class = RecognitionPostSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


@api_view(['POST', 'DELETE'])
@permission_classes([permissions.IsAuthenticated])
def toggle_recognition_like(request, post_id):
    """Like or unlike a recognition post"""
    try:
        post = RecognitionPost.objects.get(id=post_id)
    except RecognitionPost.DoesNotExist:
        return Response(
            {'error': 'Post not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    if request.method == 'POST':
        like, created = RecognitionLike.objects.get_or_create(
            post=post,
            user=request.user
        )
        if created:
            post.likes_count += 1
            post.save(update_fields=['likes_count'])
            return Response({'liked': True})
        return Response({'liked': True, 'message': 'Already liked'})
    else:  # DELETE
        deleted = RecognitionLike.objects.filter(
            post=post,
            user=request.user
        ).delete()[0]
        if deleted:
            post.likes_count = max(0, post.likes_count - 1)
            post.save(update_fields=['likes_count'])
            return Response({'liked': False})
        return Response({'liked': False, 'message': 'Not liked'})


# Award Nominations
class AwardNominationListView(generics.ListCreateAPIView):
    """List and create award nominations"""
    serializer_class = AwardNominationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = AwardNomination.objects.all().select_related(
            'award', 'nominee', 'nominated_by', 'reviewed_by'
        )
        
        if user.user_type == 'student':
            # Students see nominations they sent or received
            queryset = queryset.filter(
                Q(nominated_by=user) | Q(nominee=user)
            )
        else:
            # Faculty/admin can see all
            status_filter = self.request.query_params.get('status')
            if status_filter:
                queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(nominated_by=self.request.user)


class AwardNominationDetailView(generics.RetrieveUpdateAPIView):
    """Award nomination detail view"""
    queryset = AwardNomination.objects.all()
    serializer_class = AwardNominationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_update(self, serializer):
        nomination = self.get_object()
        
        # Only allow status updates for faculty/admin
        if self.request.user.user_type in ['faculty', 'admin']:
            if 'status' in serializer.validated_data:
                new_status = serializer.validated_data['status']
                if new_status in ['approved', 'rejected']:
                    nomination.reviewed_by = self.request.user
                    nomination.reviewed_at = timezone.now()
                    nomination.review_notes = serializer.validated_data.get('review_notes', '')
                    nomination.save()
                    
                    # If approved, create UserAward
                    if new_status == 'approved':
                        UserAward.objects.create(
                            award=nomination.award,
                            user=nomination.nominee,
                            awarded_by=self.request.user,
                            reason=nomination.nomination_reason,
                        )
                serializer.save()
        else:
            # Students can only update their own nominations if pending
            if nomination.nominated_by == self.request.user and nomination.status == 'pending':
                serializer.save()
            else:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied('Permission denied')


# Award Ceremonies
class AwardCeremonyListView(generics.ListCreateAPIView):
    """List and create award ceremonies"""
    serializer_class = AwardCeremonySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = AwardCeremony.objects.filter(is_published=True).prefetch_related('awards')
        return queryset.order_by('-event_date')
    
    def perform_create(self, serializer):
        if self.request.user.user_type not in ['faculty', 'admin']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only faculty and admin can create award ceremonies')
        ceremony = serializer.save(created_by=self.request.user)
        if ceremony.is_published:
            ceremony.published_at = timezone.now()
            ceremony.save(update_fields=['published_at'])


class AwardCeremonyDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Award ceremony detail view"""
    queryset = AwardCeremony.objects.all()
    serializer_class = AwardCeremonySerializer
    permission_classes = [permissions.IsAuthenticated]


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_awards_summary(request, user_id):
    """Get awards summary for a user"""
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    awards = UserAward.objects.filter(user=user, is_public=True).select_related('award')
    
    summary = {
        'total_awards': awards.count(),
        'by_type': {},
        'featured_awards': [],
        'recent_awards': [],
    }
    
    for award in awards:
        award_type = award.award.award_type
        summary['by_type'][award_type] = summary['by_type'].get(award_type, 0) + 1
        
        if award.is_featured:
            summary['featured_awards'].append({
                'id': award.id,
                'award_name': award.award.name,
                'awarded_at': award.awarded_at.isoformat(),
            })
    
    summary['recent_awards'] = [
        {
            'id': award.id,
            'award_name': award.award.name,
            'awarded_at': award.awarded_at.isoformat(),
        }
        for award in awards.order_by('-awarded_at')[:5]
    ]
    
    return Response(summary)

