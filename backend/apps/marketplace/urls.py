from django.urls import path
from . import views

urlpatterns = [
    # Marketplace Items
    path('items/', views.MarketplaceItemListView.as_view(), name='marketplace-item-list'),
    path('items/<int:pk>/', views.MarketplaceItemDetailView.as_view(), name='marketplace-item-detail'),
    path('items/<int:item_id>/favorite/', views.toggle_favorite, name='toggle-favorite'),
    path('my-listings/', views.my_listings, name='my-listings'),
    
    # Book Listings
    path('books/', views.BookListingListView.as_view(), name='book-listing-list'),
    path('books/<int:pk>/', views.BookListingDetailView.as_view(), name='book-listing-detail'),
    
    # Ride Listings
    path('rides/', views.RideListingListView.as_view(), name='ride-listing-list'),
    path('rides/<int:pk>/', views.RideListingDetailView.as_view(), name='ride-listing-detail'),
    
    # Lost & Found
    path('lost-found/', views.LostFoundItemListView.as_view(), name='lost-found-list'),
    path('lost-found/<int:pk>/', views.LostFoundItemDetailView.as_view(), name='lost-found-detail'),
    
    # Transactions
    path('transactions/', views.MarketplaceTransactionListView.as_view(), name='transaction-list'),
    path('transactions/<int:pk>/', views.MarketplaceTransactionDetailView.as_view(), name='transaction-detail'),
    
    # Favorites
    path('favorites/', views.MarketplaceFavoriteListView.as_view(), name='favorite-list'),
    
    # Image Upload
    path('upload-image/', views.upload_marketplace_image, name='upload-marketplace-image'),
]




