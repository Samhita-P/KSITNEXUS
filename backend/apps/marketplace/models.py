"""
Community Marketplace models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class MarketplaceItem(TimestampedModel):
    """Base model for marketplace items"""
    
    ITEM_TYPES = [
        ('book', 'Book'),
        ('ride', 'Ride'),
        ('lost_found', 'Lost & Found'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('reserved', 'Reserved'),
        ('sold', 'Sold'),
        ('completed', 'Completed'),
        ('found', 'Found'),
        ('returned', 'Returned'),
        ('closed', 'Closed'),
    ]
    
    # Basic information
    item_type = models.CharField(max_length=20, choices=ITEM_TYPES)
    title = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    
    # User information
    posted_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='marketplace_items'
    )
    
    # Location
    location = models.CharField(max_length=200, blank=True, null=True)
    pickup_location = models.CharField(max_length=200, blank=True, null=True)
    dropoff_location = models.CharField(max_length=200, blank=True, null=True)
    
    # Contact
    contact_phone = models.CharField(max_length=15, blank=True, null=True)
    contact_email = models.EmailField(blank=True, null=True)
    
    # Images
    images = models.JSONField(
        default=list,
        blank=True,
        help_text='List of image URLs'
    )
    
    # Metadata
    tags = models.JSONField(
        default=list,
        blank=True,
        help_text='List of tags for search'
    )
    is_active = models.BooleanField(default=True)
    views_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Marketplace Item'
        verbose_name_plural = 'Marketplace Items'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['item_type', 'status', 'is_active']),
            models.Index(fields=['posted_by', 'status']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_item_type_display()} - {self.title}"


class BookListing(TimestampedModel):
    """Book listing model"""
    
    CONDITION_CHOICES = [
        ('new', 'New'),
        ('like_new', 'Like New'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('poor', 'Poor'),
    ]
    
    # Link to marketplace item
    marketplace_item = models.OneToOneField(
        MarketplaceItem,
        on_delete=models.CASCADE,
        related_name='book_listing'
    )
    
    # Book details
    isbn = models.CharField(max_length=20, blank=True, null=True)
    author = models.CharField(max_length=200)
    publisher = models.CharField(max_length=200, blank=True, null=True)
    edition = models.CharField(max_length=50, blank=True, null=True)
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES, default='good')
    year = models.IntegerField(blank=True, null=True)
    
    # Pricing
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    negotiable = models.BooleanField(default=True)
    
    # Academic info
    course_code = models.CharField(max_length=20, blank=True, null=True)
    semester = models.IntegerField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Book Listing'
        verbose_name_plural = 'Book Listings'
        indexes = [
            models.Index(fields=['isbn']),
            models.Index(fields=['course_code']),
            models.Index(fields=['price']),
        ]
    
    def __str__(self):
        return f"{self.marketplace_item.title} - {self.author}"


class RideListing(TimestampedModel):
    """Ride sharing listing model"""
    
    RIDE_TYPES = [
        ('one_way', 'One Way'),
        ('round_trip', 'Round Trip'),
        ('regular', 'Regular Commute'),
    ]
    
    # Link to marketplace item
    marketplace_item = models.OneToOneField(
        MarketplaceItem,
        on_delete=models.CASCADE,
        related_name='ride_listing'
    )
    
    # Ride details
    ride_type = models.CharField(max_length=20, choices=RIDE_TYPES, default='one_way')
    departure_date = models.DateTimeField()
    return_date = models.DateTimeField(blank=True, null=True)
    departure_location = models.CharField(max_length=200)
    destination = models.CharField(max_length=200)
    
    # Capacity
    available_seats = models.IntegerField(validators=[MinValueValidator(1)], default=1)
    total_seats = models.IntegerField(validators=[MinValueValidator(1)], default=4)
    
    # Pricing
    price_per_seat = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    
    # Vehicle info
    vehicle_type = models.CharField(max_length=50, blank=True, null=True)
    vehicle_number = models.CharField(max_length=20, blank=True, null=True)
    
    # Additional info
    luggage_space = models.BooleanField(default=False)
    smoking_allowed = models.BooleanField(default=False)
    pets_allowed = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Ride Listing'
        verbose_name_plural = 'Ride Listings'
        indexes = [
            models.Index(fields=['departure_date', 'departure_location']),
            models.Index(fields=['destination']),
        ]
    
    def __str__(self):
        return f"{self.departure_location} to {self.destination}"


class LostFoundItem(TimestampedModel):
    """Lost & Found item model"""
    
    ITEM_CATEGORIES = [
        ('electronics', 'Electronics'),
        ('clothing', 'Clothing'),
        ('books', 'Books'),
        ('accessories', 'Accessories'),
        ('documents', 'Documents'),
        ('keys', 'Keys'),
        ('other', 'Other'),
    ]
    
    # Link to marketplace item
    marketplace_item = models.OneToOneField(
        MarketplaceItem,
        on_delete=models.CASCADE,
        related_name='lost_found_item'
    )
    
    # Item details
    category = models.CharField(max_length=20, choices=ITEM_CATEGORIES, default='other')
    brand = models.CharField(max_length=100, blank=True, null=True)
    color = models.CharField(max_length=50, blank=True, null=True)
    size = models.CharField(max_length=50, blank=True, null=True)
    
    # Location details
    found_location = models.CharField(max_length=200, blank=True, null=True)
    found_date = models.DateField(blank=True, null=True)
    
    # Reward
    reward_offered = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0)]
    )
    
    # Verification
    verification_required = models.BooleanField(default=False)
    verification_details = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Lost & Found Item'
        verbose_name_plural = 'Lost & Found Items'
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['found_location']),
        ]
    
    def __str__(self):
        return f"{self.marketplace_item.title} - {self.get_category_display()}"


class MarketplaceTransaction(TimestampedModel):
    """Transaction/interaction model for marketplace items"""
    
    TRANSACTION_TYPES = [
        ('inquiry', 'Inquiry'),
        ('reservation', 'Reservation'),
        ('purchase', 'Purchase'),
        ('claim', 'Claim'),
        ('message', 'Message'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Relationships
    marketplace_item = models.ForeignKey(
        MarketplaceItem,
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    buyer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='marketplace_transactions'
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='marketplace_sales',
        null=True,
        blank=True
    )
    
    # Transaction details
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    message = models.TextField(blank=True, null=True)
    
    # For rides
    seats_requested = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    
    # For purchases
    agreed_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0)]
    )
    
    # Meeting details
    meeting_location = models.CharField(max_length=200, blank=True, null=True)
    meeting_date = models.DateTimeField(blank=True, null=True)
    
    # Completion
    completed_at = models.DateTimeField(blank=True, null=True)
    rating = models.IntegerField(
        blank=True,
        null=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    review = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Marketplace Transaction'
        verbose_name_plural = 'Marketplace Transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['marketplace_item', 'status']),
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['seller', 'status']),
        ]
    
    def __str__(self):
        return f"{self.get_transaction_type_display()} - {self.marketplace_item.title}"


class MarketplaceFavorite(TimestampedModel):
    """User favorites for marketplace items"""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='marketplace_favorites'
    )
    marketplace_item = models.ForeignKey(
        MarketplaceItem,
        on_delete=models.CASCADE,
        related_name='favorites'
    )
    
    class Meta:
        verbose_name = 'Marketplace Favorite'
        verbose_name_plural = 'Marketplace Favorites'
        unique_together = [['user', 'marketplace_item']]
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.marketplace_item.title}"

