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

final lostFoundItemsProvider = FutureProvider<List<MarketplaceItem>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getLostFoundItems();
});

class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(lostFoundItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
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
              ref.invalidate(lostFoundItemsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search,
              title: 'No Items',
              message: 'No lost & found items posted yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lostFoundItemsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final lostFound = item.lostFoundItem!;
                return _buildLostFoundCard(context, item, lostFound);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(lostFoundItemsProvider);
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

  Widget _buildLostFoundCard(BuildContext context, MarketplaceItem item, LostFoundItem lostFound) {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _getFullImageUrl(item.images.first),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            _getCategoryIcon(lostFound.category),
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(lostFound.category),
                        size: 40,
                        color: Colors.grey[600],
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lostFound.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item.status == 'found')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FOUND',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lostFound.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Brand: ${lostFound.brand}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    if (lostFound.foundLocation != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            lostFound.foundLocation!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    if (lostFound.rewardOffered != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reward: ₹${lostFound.rewardOffered!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'accessories':
        return Icons.watch;
      case 'documents':
        return Icons.description;
      case 'keys':
        return Icons.vpn_key;
      default:
        return Icons.search;
    }
  }
}


