"""
Serializers for marketplace app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    MarketplaceItem, BookListing, RideListing, LostFoundItem,
    MarketplaceTransaction, MarketplaceFavorite
)

User = get_user_model()


class MarketplaceItemSerializer(serializers.ModelSerializer):
    """Serializer for MarketplaceItem"""
    posted_by_name = serializers.SerializerMethodField()
    book_listing = serializers.SerializerMethodField()
    ride_listing = serializers.SerializerMethodField()
    lost_found_item = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    
    class Meta:
        model = MarketplaceItem
        fields = [
            'id', 'item_type', 'title', 'description', 'status',
            'posted_by', 'posted_by_name', 'location', 'pickup_location',
            'dropoff_location', 'contact_phone', 'contact_email',
            'images', 'tags', 'is_active', 'views_count',
            'book_listing', 'ride_listing', 'lost_found_item',
            'is_favorited', 'created_at', 'updated_at',
        ]
        read_only_fields = ['posted_by', 'views_count', 'created_at', 'updated_at']
    
    def get_posted_by_name(self, obj):
        return f"{obj.posted_by.first_name} {obj.posted_by.last_name}".strip() or obj.posted_by.username
    
    def get_book_listing(self, obj):
        try:
            if hasattr(obj, 'book_listing'):
                return BookListingSerializer(obj.book_listing).data
        except Exception as e:
            print(f"Error serializing book_listing: {e}")
        return None
    
    def get_ride_listing(self, obj):
        try:
            if hasattr(obj, 'ride_listing'):
                return RideListingSerializer(obj.ride_listing).data
        except Exception as e:
            print(f"Error serializing ride_listing: {e}")
        return None
    
    def get_lost_found_item(self, obj):
        try:
            if hasattr(obj, 'lost_found_item'):
                return LostFoundItemSerializer(obj.lost_found_item).data
        except Exception as e:
            print(f"Error serializing lost_found_item: {e}")
        return None
    
    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.favorites.filter(user=request.user).exists()
        return False


class BookListingSerializer(serializers.ModelSerializer):
    """Serializer for BookListing"""
    # Don't include full marketplace_item to avoid circular reference
    # The marketplace_item will be serialized separately in MarketplaceItemSerializer
    
    class Meta:
        model = BookListing
        fields = [
            'id', 'isbn', 'author', 'publisher',
            'edition', 'condition', 'year', 'price', 'negotiable',
            'course_code', 'semester', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class RideListingSerializer(serializers.ModelSerializer):
    """Serializer for RideListing"""
    # Don't include full marketplace_item to avoid circular reference
    available_seats_display = serializers.SerializerMethodField()
    
    class Meta:
        model = RideListing
        fields = [
            'id', 'ride_type', 'departure_date',
            'return_date', 'departure_location', 'destination',
            'available_seats', 'total_seats', 'available_seats_display',
            'price_per_seat', 'vehicle_type', 'vehicle_number',
            'luggage_space', 'smoking_allowed', 'pets_allowed',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_available_seats_display(self, obj):
        return f"{obj.available_seats}/{obj.total_seats}"


class LostFoundItemSerializer(serializers.ModelSerializer):
    """Serializer for LostFoundItem"""
    # Don't include full marketplace_item to avoid circular reference
    
    class Meta:
        model = LostFoundItem
        fields = [
            'id', 'category', 'brand', 'color',
            'size', 'found_location', 'found_date', 'reward_offered',
            'verification_required', 'verification_details',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class MarketplaceTransactionSerializer(serializers.ModelSerializer):
    """Serializer for MarketplaceTransaction"""
    # Use a simplified marketplace item to avoid circular reference
    marketplace_item_id = serializers.IntegerField(source='marketplace_item.id', read_only=True)
    marketplace_item_title = serializers.CharField(source='marketplace_item.title', read_only=True)
    buyer_name = serializers.SerializerMethodField()
    seller_name = serializers.SerializerMethodField()
    
    class Meta:
        model = MarketplaceTransaction
        fields = [
            'id', 'marketplace_item_id', 'marketplace_item_title', 'buyer', 'buyer_name', 'seller', 'seller_name',
            'transaction_type', 'status', 'message', 'seats_requested',
            'agreed_price', 'meeting_location', 'meeting_date',
            'completed_at', 'rating', 'review', 'created_at', 'updated_at',
        ]
        read_only_fields = ['buyer', 'seller', 'completed_at', 'created_at', 'updated_at']
    
    def get_buyer_name(self, obj):
        return f"{obj.buyer.first_name} {obj.buyer.last_name}".strip() or obj.buyer.username
    
    def get_seller_name(self, obj):
        if obj.seller:
            return f"{obj.seller.first_name} {obj.seller.last_name}".strip() or obj.seller.username
        return None


class MarketplaceFavoriteSerializer(serializers.ModelSerializer):
    """Serializer for MarketplaceFavorite"""
    # Use full serializer here as it's a separate endpoint and won't cause circular reference
    marketplace_item = MarketplaceItemSerializer(read_only=True)
    
    class Meta:
        model = MarketplaceFavorite
        fields = [
            'id', 'user', 'marketplace_item', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']




