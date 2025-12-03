import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/marketplace_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final myListingsProvider = FutureProvider<List<MarketplaceItem>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getMyListings();
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
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
              ref.invalidate(myListingsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.list,
              title: 'No Listings',
              message: 'You haven\'t posted any items yet.',
              action: ElevatedButton(
                onPressed: () {
                  // Show create dialog
                },
                child: const Text('Create Listing'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myListingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                return _buildListingCard(context, listings[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(myListingsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show create dialog
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, MarketplaceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getItemTypeColor(item.itemType).withOpacity(0.2),
          child: Icon(
            _getItemIcon(item.itemType),
            color: _getItemTypeColor(item.itemType),
          ),
        ),
        title: Text(item.title),
        subtitle: Text(
          '${item.itemType.replaceAll('_', ' ').toUpperCase()} • ${item.status.replaceAll('_', ' ').toUpperCase()}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          // Navigate to item detail
        },
      ),
    );
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType) {
      case 'book':
        return Icons.book;
      case 'ride':
        return Icons.directions_car;
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
      case 'ride':
        return AppTheme.accentBlue;
      case 'lost_found':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }
}

