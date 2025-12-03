from django.contrib import admin
from .models import (
    MarketplaceItem, BookListing, RideListing, LostFoundItem,
    MarketplaceTransaction, MarketplaceFavorite
)


@admin.register(MarketplaceItem)
class MarketplaceItemAdmin(admin.ModelAdmin):
    list_display = ['title', 'item_type', 'status', 'posted_by', 'is_active', 'views_count', 'created_at']
    list_filter = ['item_type', 'status', 'is_active', 'created_at']
    search_fields = ['title', 'description', 'posted_by__username']
    ordering = ['-created_at']


@admin.register(BookListing)
class BookListingAdmin(admin.ModelAdmin):
    list_display = ['marketplace_item', 'author', 'price', 'condition', 'course_code']
    list_filter = ['condition', 'course_code', 'negotiable']
    search_fields = ['marketplace_item__title', 'author', 'isbn', 'course_code']
    ordering = ['-created_at']


@admin.register(RideListing)
class RideListingAdmin(admin.ModelAdmin):
    list_display = ['marketplace_item', 'departure_location', 'destination', 'departure_date', 'available_seats']
    list_filter = ['ride_type', 'departure_date']
    search_fields = ['departure_location', 'destination', 'marketplace_item__title']
    ordering = ['departure_date']


@admin.register(LostFoundItem)
class LostFoundItemAdmin(admin.ModelAdmin):
    list_display = ['marketplace_item', 'category', 'found_location', 'found_date', 'reward_offered']
    list_filter = ['category', 'found_date']
    search_fields = ['marketplace_item__title', 'found_location', 'brand']
    ordering = ['-created_at']


@admin.register(MarketplaceTransaction)
class MarketplaceTransactionAdmin(admin.ModelAdmin):
    list_display = ['marketplace_item', 'buyer', 'seller', 'transaction_type', 'status', 'created_at']
    list_filter = ['transaction_type', 'status', 'created_at']
    search_fields = ['marketplace_item__title', 'buyer__username', 'seller__username']
    ordering = ['-created_at']
    readonly_fields = ['completed_at']


@admin.register(MarketplaceFavorite)
class MarketplaceFavoriteAdmin(admin.ModelAdmin):
    list_display = ['user', 'marketplace_item', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'marketplace_item__title']
    ordering = ['-created_at']

















