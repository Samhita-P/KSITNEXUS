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
import 'marketplace_item_detail_screen.dart';

final favoritesProvider = FutureProvider<List<MarketplaceItem>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getFavorites();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
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
              ref.invalidate(favoritesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'No Favorites',
              message: 'You haven\'t favorited any items yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoritesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildItemCard(context, ref, items[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(favoritesProvider);
          },
        ),
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

  Widget _buildItemCard(BuildContext context, WidgetRef ref, MarketplaceItem item) {
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
                        icon: const Icon(Icons.favorite, color: AppTheme.error),
                        onPressed: () async {
                          try {
                            await ref.read(apiServiceProvider).toggleFavorite(item.id!);
                            ref.invalidate(favoritesProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Removed from favorites')),
                              );
                            }
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

