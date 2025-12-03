import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/marketplace_models.dart';
import '../../providers/data_providers.dart';
import '../../config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'favorites_screen.dart';

class MarketplaceItemDetailScreen extends ConsumerStatefulWidget {
  final MarketplaceItem item;

  const MarketplaceItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<MarketplaceItemDetailScreen> createState() => _MarketplaceItemDetailScreenState();
}

class _MarketplaceItemDetailScreenState extends ConsumerState<MarketplaceItemDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorited;
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    // If already a full URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Otherwise, prepend base URL
    return '${ApiConfig.mediaBaseUrl}$imageUrl';
  }

  Future<void> _toggleFavorite() async {
    if (widget.item.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.toggleFavorite(widget.item.id!);
      
      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        // Invalidate favorites provider to refresh
        ref.invalidate(favoritesProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _contactViaWhatsApp() async {
    final phoneNumber = widget.item.contactPhone;
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Remove any non-numeric characters except +
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Create WhatsApp URL
    final whatsappUrl = 'https://wa.me/$cleanPhone';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    // Debug: Print item type to ensure correct screen
    print('📦 Detail Screen - Item Type: ${item.itemType}');
    print('📦 Detail Screen - Has LostFoundItem: ${item.lostFoundItem != null}');
    if (item.lostFoundItem != null) {
      print('📦 LostFoundItem - Category: ${item.lostFoundItem!.category}');
      print('📦 LostFoundItem - Brand: ${item.lostFoundItem!.brand}');
      print('📦 LostFoundItem - Found Date: ${item.lostFoundItem!.foundDate}');
      print('📦 LostFoundItem - Reward: ${item.lostFoundItem!.rewardOffered}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/marketplace');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh item details and favorites
              ref.invalidate(favoritesProvider);
              setState(() {
                // Trigger rebuild to refresh item data
              });
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            if (item.images.isNotEmpty) ...[
              SizedBox(
                height: 300,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: item.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _getFullImageUrl(item.images[index]);
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (item.images.length > 1) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${item.images.length} photos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ] else ...[
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Posted by
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Posted by ${item.postedByName ?? "Unknown"}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Item-specific details
                  if (item.bookListing != null) _buildBookDetails(item.bookListing!),
                  if (item.lostFoundItem != null) _buildLostFoundDetails(item.lostFoundItem!),
                  
                  // Contact Information
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (item.contactEmail != null && item.contactEmail!.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.contactEmail!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (item.contactPhone != null && item.contactPhone!.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.contactPhone!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _toggleFavorite,
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : AppTheme.primaryColor,
                          ),
                          label: Text(_isFavorite ? 'Favorited' : 'Favorite'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _contactViaWhatsApp,
                          icon: const Icon(Icons.chat),
                          label: const Text('Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookDetails(BookListing book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Author', book.author),
        if (book.isbn != null && book.isbn!.isNotEmpty) _buildDetailRow('ISBN', book.isbn!),
        if (book.publisher != null && book.publisher!.isNotEmpty) _buildDetailRow('Publisher', book.publisher!),
        if (book.edition != null && book.edition!.isNotEmpty) _buildDetailRow('Edition', book.edition!),
        if (book.year != null) _buildDetailRow('Year', book.year.toString()),
        _buildDetailRow('Condition', book.condition.replaceAll('_', ' ').toUpperCase()),
        if (book.courseCode != null && book.courseCode!.isNotEmpty) _buildDetailRow('Course Code', book.courseCode!),
        if (book.semester != null) _buildDetailRow('Semester', book.semester.toString()),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Price: ',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              '₹${book.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            if (book.negotiable) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Negotiable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLostFoundDetails(LostFoundItem lostFound) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Always show category
        _buildDetailRow('Category', _getCategoryLabel(lostFound.category)),
        
        // Only show fields that were actually filled by the user
        if (lostFound.brand != null && lostFound.brand!.trim().isNotEmpty) 
          _buildDetailRow('Brand', lostFound.brand!.trim()),
        
        if (lostFound.color != null && lostFound.color!.trim().isNotEmpty) 
          _buildDetailRow('Color', lostFound.color!.trim()),
        
        if (lostFound.size != null && lostFound.size!.trim().isNotEmpty) 
          _buildDetailRow('Size', lostFound.size!.trim()),
        
        if (lostFound.foundLocation != null && lostFound.foundLocation!.trim().isNotEmpty) 
          _buildDetailRow('Found Location', lostFound.foundLocation!.trim()),
        
        if (lostFound.foundDate != null) 
          _buildDetailRow('Date Found', _formatDate(lostFound.foundDate!)),
        
        // Show reward only if it was provided and greater than 0
        if (lostFound.rewardOffered != null && lostFound.rewardOffered! > 0) ...[
          const SizedBox(height: 12),
          _buildDetailRow('Reward Offered', '₹${lostFound.rewardOffered!.toStringAsFixed(0)}'),
        ],
        
        // Only show verification section if verification is required AND there are details
        if (lostFound.verificationRequired) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Verification Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
                if (lostFound.verificationDetails != null && 
                    lostFound.verificationDetails!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lostFound.verificationDetails!.trim(),
                    style: TextStyle(fontSize: 14, color: Colors.orange[900]),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'electronics':
        return 'Electronics';
      case 'clothing':
        return 'Clothing';
      case 'books':
        return 'Books';
      case 'accessories':
        return 'Accessories';
      case 'documents':
        return 'Documents';
      case 'keys':
        return 'Keys';
      case 'other':
        return 'Other';
      default:
        return category.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    // Format date as "Nov 14, 2025" for example
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.success;
      case 'reserved':
        return AppTheme.warning;
      case 'sold':
      case 'found':
        return AppTheme.primaryColor;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

