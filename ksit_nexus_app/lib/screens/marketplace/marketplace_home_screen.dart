import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/marketplace_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import '../../config/api_config.dart';
import 'books_screen.dart';
import 'lost_found_screen.dart';
import 'my_listings_screen.dart';
import 'favorites_screen.dart';
import 'create_item_dialog.dart';
import 'marketplace_item_detail_screen.dart';

final marketplaceItemsProvider = FutureProvider.family<List<MarketplaceItem>, String>((ref, itemType) async {
  final apiService = ref.read(apiServiceProvider);
  // When itemType is 'all', pass null to get all items
  final String? filterType = itemType == 'all' ? null : itemType;
  return await apiService.getMarketplaceItems(itemType: filterType);
});

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Marketplace'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(marketplaceItemsProvider('all'));
              ref.invalidate(marketplaceItemsProvider('book'));
              ref.invalidate(marketplaceItemsProvider('lost_found'));
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.push('/marketplace/my-listings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search marketplace...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Category tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('all', 'All', Icons.apps),
                _buildCategoryChip('book', 'Books', Icons.book),
                _buildCategoryChip('lost_found', 'Lost & Found', Icons.search),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateItemDialog(),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedCategory == 'book') {
      return const BooksScreen();
    } else if (_selectedCategory == 'lost_found') {
      return const LostFoundScreen();
    }

    // All items view - pass null to get all item types
    final itemsAsync = ref.watch(marketplaceItemsProvider('all'));

    return itemsAsync.when(
      data: (items) {
        final filtered = _searchQuery.isEmpty
            ? items
            : items.where((item) {
                return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    item.description.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.store,
            title: 'No Items',
            message: 'No marketplace items found.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(marketplaceItemsProvider('all'));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildItemCard(context, filtered[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorDisplayWidget(
        message: error.toString(),
        onRetry: () {
          ref.invalidate(marketplaceItemsProvider('all'));
        },
      ),
    );
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

  Widget _buildItemCard(BuildContext context, MarketplaceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MarketplaceItemDetailScreen(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
                child: item.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _getFullImageUrl(item.images.first),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        _getItemIcon(item.itemType),
                        size: 64,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(
                      _getItemIcon(item.itemType),
                      size: 64,
                      color: Colors.grey[600],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getItemTypeColor(item.itemType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.itemType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getItemTypeColor(item.itemType),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          item.isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: item.isFavorited ? AppTheme.error : Colors.grey,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(apiServiceProvider).toggleFavorite(item.id!);
                            ref.invalidate(marketplaceItemsProvider('all'));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        item.postedByName ?? 'User',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (item.bookListing != null)
                        Text(
                          '₹${item.bookListing!.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType) {
      case 'book':
        return Icons.book;
      case 'lost_found':
        return Icons.search;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType) {
      case 'book':
        return AppTheme.primaryColor;
      case 'lost_found':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }
}


