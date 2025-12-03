"""
Views for marketplace app
"""
from rest_framework import generics, status, permissions, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os
from .models import (
    MarketplaceItem, BookListing, RideListing, LostFoundItem,
    MarketplaceTransaction, MarketplaceFavorite
)
from .serializers import (
    MarketplaceItemSerializer, BookListingSerializer, RideListingSerializer,
    LostFoundItemSerializer, MarketplaceTransactionSerializer, MarketplaceFavoriteSerializer
)

User = get_user_model()


# Marketplace Items
class MarketplaceItemListView(generics.ListCreateAPIView):
    """List and create marketplace items"""
    serializer_class = MarketplaceItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = MarketplaceItem.objects.filter(is_active=True).select_related('posted_by')
            
            item_type = self.request.query_params.get('item_type')
            status_filter = self.request.query_params.get('status')
            search = self.request.query_params.get('search')
            
            if item_type:
                queryset = queryset.filter(item_type=item_type)
            if status_filter:
                queryset = queryset.filter(status=status_filter)
            if search:
                # Search in title and description
                queryset = queryset.filter(
                    Q(title__icontains=search) |
                    Q(description__icontains=search)
                )
                # For tags (JSONField), we need to handle it differently
                # Try to search in tags if it's a list
                try:
                    queryset = queryset.filter(tags__icontains=search)
                except Exception:
                    # If tags search fails, just use title/description search
                    pass
            
            return queryset.order_by('-created_at')
        except Exception as e:
            import traceback
            print(f"Error in MarketplaceItemListView.get_queryset: {e}")
            traceback.print_exc()
            return MarketplaceItem.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully"""
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in MarketplaceItemListView.list: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to load marketplace items: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def perform_create(self, serializer):
        serializer.save(posted_by=self.request.user)


class MarketplaceItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Marketplace item detail view"""
    queryset = MarketplaceItem.objects.all()
    serializer_class = MarketplaceItemSerializer
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


# Book Listings
class BookListingListView(generics.ListCreateAPIView):
    """List and create book listings"""
    serializer_class = BookListingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = BookListing.objects.filter(marketplace_item__is_active=True)
            queryset = queryset.select_related('marketplace_item', 'marketplace_item__posted_by')
            
            course_code = self.request.query_params.get('course_code')
            isbn = self.request.query_params.get('isbn')
            
            if course_code:
                queryset = queryset.filter(course_code=course_code)
            if isbn:
                queryset = queryset.filter(isbn=isbn)
            
            return queryset.order_by('-created_at')
        except Exception as e:
            import traceback
            print(f"Error in BookListingListView.get_queryset: {e}")
            traceback.print_exc()
            return BookListing.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to return MarketplaceItem objects instead of BookListing"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            
            page = self.paginate_queryset(queryset)
            if page is not None:
                # Get marketplace items from book listings
                marketplace_items = [book.marketplace_item for book in page]
                serializer = MarketplaceItemSerializer(marketplace_items, many=True, context={'request': request})
                return self.get_paginated_response(serializer.data)
            
            # Non-paginated response
            marketplace_items = [book.marketplace_item for book in queryset]
            serializer = MarketplaceItemSerializer(marketplace_items, many=True, context={'request': request})
            return Response(serializer.data)
        except Exception as e:
            import traceback
            print(f"Error in BookListingListView.list: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to load book listings: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        """Create marketplace item first, then book listing"""
        # Get marketplace_item data from request
        marketplace_item_data = self.request.data.get('marketplace_item', {})
        
        # Get user's email and phone from profile
        user = self.request.user
        
        # Email is required - use from user profile
        if not user.email:
            raise serializers.ValidationError({
                'contact_email': 'Email is required. Please update your profile.'
            })
        contact_email = user.email
        
        # Phone is required - get from user profile
        contact_phone = getattr(user, 'phone_number', None)
        if not contact_phone:
            raise serializers.ValidationError({
                'contact_phone': 'Phone number is required. Please update your profile.'
            })
        
        # Create marketplace item
        marketplace_item_data.update({
            'item_type': 'book',
            'posted_by': user.id,
            'contact_email': contact_email,
            'contact_phone': contact_phone,
        })
        
        marketplace_serializer = MarketplaceItemSerializer(data=marketplace_item_data, context={'request': self.request})
        marketplace_serializer.is_valid(raise_exception=True)
        marketplace_item = marketplace_serializer.save(posted_by=user)
        
        # Create book listing linked to marketplace item
        book_listing = serializer.save(marketplace_item=marketplace_item)
        
        # Refresh marketplace item to include book listing in response
        marketplace_item.refresh_from_db()
    
    def create(self, request, *args, **kwargs):
        """Override create to return MarketplaceItem instead of BookListing"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Get the marketplace item that was created
        book_listing = serializer.instance
        marketplace_item = book_listing.marketplace_item
        
        # Return the marketplace item instead of book listing
        marketplace_serializer = MarketplaceItemSerializer(marketplace_item, context={'request': request})
        headers = self.get_success_headers(marketplace_serializer.data)
        return Response(marketplace_serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class BookListingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Book listing detail view"""
    queryset = BookListing.objects.all()
    serializer_class = BookListingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        """Return MarketplaceItem instead of BookListing"""
        instance = self.get_object()
        marketplace_item = instance.marketplace_item
        serializer = MarketplaceItemSerializer(marketplace_item, context={'request': request})
        return Response(serializer.data)


# Ride Listings
class RideListingListView(generics.ListCreateAPIView):
    """List and create ride listings"""
    serializer_class = RideListingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = RideListing.objects.filter(
                marketplace_item__is_active=True,
                departure_date__gte=timezone.now()
            )
            queryset = queryset.select_related('marketplace_item', 'marketplace_item__posted_by')
            
            departure_location = self.request.query_params.get('departure_location')
            destination = self.request.query_params.get('destination')
            
            if departure_location:
                queryset = queryset.filter(departure_location__icontains=departure_location)
            if destination:
                queryset = queryset.filter(destination__icontains=destination)
            
            return queryset.order_by('departure_date')
        except Exception as e:
            import traceback
            print(f"Error in RideListingListView.get_queryset: {e}")
            traceback.print_exc()
            return RideListing.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully"""
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            import traceback
            print(f"Error in RideListingListView.list: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to load ride listings: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class RideListingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Ride listing detail view"""
    queryset = RideListing.objects.all()
    serializer_class = RideListingSerializer
    permission_classes = [permissions.IsAuthenticated]


# Lost & Found
class LostFoundItemListView(generics.ListCreateAPIView):
    """List and create lost & found items"""
    serializer_class = LostFoundItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = LostFoundItem.objects.filter(
                marketplace_item__is_active=True,
                marketplace_item__status__in=['available', 'found']
            )
            queryset = queryset.select_related('marketplace_item', 'marketplace_item__posted_by')
            
            category = self.request.query_params.get('category')
            found_location = self.request.query_params.get('found_location')
            
            if category:
                queryset = queryset.filter(category=category)
            if found_location:
                queryset = queryset.filter(found_location__icontains=found_location)
            
            return queryset.order_by('-created_at')
        except Exception as e:
            import traceback
            print(f"Error in LostFoundItemListView.get_queryset: {e}")
            traceback.print_exc()
            return LostFoundItem.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to return MarketplaceItem objects instead of LostFoundItem"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            
            page = self.paginate_queryset(queryset)
            if page is not None:
                # Get marketplace items from lost found items
                marketplace_items = [item.marketplace_item for item in page]
                serializer = MarketplaceItemSerializer(marketplace_items, many=True, context={'request': request})
                return self.get_paginated_response(serializer.data)
            
            # Non-paginated response
            marketplace_items = [item.marketplace_item for item in queryset]
            serializer = MarketplaceItemSerializer(marketplace_items, many=True, context={'request': request})
            return Response(serializer.data)
        except Exception as e:
            import traceback
            print(f"Error in LostFoundItemListView.list: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Failed to load lost & found items: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        """Create marketplace item first, then lost found item"""
        # Get marketplace_item data from request
        marketplace_item_data = self.request.data.get('marketplace_item', {})
        
        # Get user's email and phone from profile
        user = self.request.user
        
        # Email is required - use from user profile
        if not user.email:
            raise serializers.ValidationError({
                'contact_email': 'Email is required. Please update your profile.'
            })
        contact_email = user.email
        
        # Phone is required - get from user profile
        contact_phone = getattr(user, 'phone_number', None)
        if not contact_phone:
            raise serializers.ValidationError({
                'contact_phone': 'Phone number is required. Please update your profile.'
            })
        
        # Create marketplace item
        marketplace_item_data.update({
            'item_type': 'lost_found',
            'posted_by': user.id,
            'contact_email': contact_email,
            'contact_phone': contact_phone,
        })
        
        marketplace_serializer = MarketplaceItemSerializer(data=marketplace_item_data, context={'request': self.request})
        marketplace_serializer.is_valid(raise_exception=True)
        marketplace_item = marketplace_serializer.save(posted_by=user)
        
        # Create lost found item linked to marketplace item
        lost_found_item = serializer.save(marketplace_item=marketplace_item)
        
        # Refresh marketplace item to include lost found item in response
        marketplace_item.refresh_from_db()
    
    def create(self, request, *args, **kwargs):
        """Override create to return MarketplaceItem instead of LostFoundItem"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Get the marketplace item that was created
        lost_found_item = serializer.instance
        marketplace_item = lost_found_item.marketplace_item
        
        # Return the marketplace item instead of lost found item
        marketplace_serializer = MarketplaceItemSerializer(marketplace_item, context={'request': request})
        headers = self.get_success_headers(marketplace_serializer.data)
        return Response(marketplace_serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class LostFoundItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Lost & found item detail view"""
    queryset = LostFoundItem.objects.all()
    serializer_class = LostFoundItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        """Return MarketplaceItem instead of LostFoundItem"""
        instance = self.get_object()
        marketplace_item = instance.marketplace_item
        serializer = MarketplaceItemSerializer(marketplace_item, context={'request': request})
        return Response(serializer.data)


# Transactions
class MarketplaceTransactionListView(generics.ListCreateAPIView):
    """List and create marketplace transactions"""
    serializer_class = MarketplaceTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = MarketplaceTransaction.objects.filter(
            Q(buyer=user) | Q(seller=user)
        ).select_related('marketplace_item', 'buyer', 'seller')
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        marketplace_item = serializer.validated_data['marketplace_item']
        serializer.save(
            buyer=self.request.user,
            seller=marketplace_item.posted_by
        )


class MarketplaceTransactionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Marketplace transaction detail view"""
    queryset = MarketplaceTransaction.objects.all()
    serializer_class = MarketplaceTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]


# Favorites
class MarketplaceFavoriteListView(generics.ListCreateAPIView):
    """List and create marketplace favorites"""
    serializer_class = MarketplaceFavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return MarketplaceFavorite.objects.filter(
            user=self.request.user
        ).select_related('marketplace_item', 'marketplace_item__posted_by').order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


@api_view(['POST', 'DELETE'])
@permission_classes([permissions.IsAuthenticated])
def toggle_favorite(request, item_id):
    """Toggle favorite status for a marketplace item"""
    try:
        item = MarketplaceItem.objects.get(id=item_id)
        favorite, created = MarketplaceFavorite.objects.get_or_create(
            user=request.user,
            marketplace_item=item
        )
        
        if not created:
            favorite.delete()
            return Response({'is_favorited': False})
        
        return Response({'is_favorited': True})
    except MarketplaceItem.DoesNotExist:
        return Response(
            {'error': 'Item not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_listings(request):
    """Get user's marketplace listings"""
    items = MarketplaceItem.objects.filter(
        posted_by=request.user
    ).select_related('posted_by').order_by('-created_at')
    
    serializer = MarketplaceItemSerializer(items, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def upload_marketplace_image(request):
    """Upload an image for marketplace items"""
    try:
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({
                'error': 'No image provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image file
        if not image_file.content_type.startswith('image/'):
            return Response({
                'error': 'File must be an image'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate unique filename
        file_extension = os.path.splitext(image_file.name)[1]
        filename = f'marketplace/{request.user.id}/{timezone.now().strftime("%Y%m%d_%H%M%S")}{file_extension}'
        
        # Save file
        saved_path = default_storage.save(filename, ContentFile(image_file.read()))
        
        # Get URL
        if hasattr(default_storage, 'url'):
            image_url = default_storage.url(saved_path)
        else:
            # For local storage, construct URL
            image_url = f'/media/{saved_path}'
        
        return Response({
            'image_url': image_url,
            'message': 'Image uploaded successfully'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        import traceback
        print(f"Error uploading marketplace image: {e}")
        traceback.print_exc()
        return Response({
            'error': f'Failed to upload image: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)




