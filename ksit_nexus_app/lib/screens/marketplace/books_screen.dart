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

final bookListingsProvider = FutureProvider<List<MarketplaceItem>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBookListings();
});

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
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
              ref.invalidate(bookListingsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          // Filter out items without book listings
          final validBooks = books.where((item) => item.bookListing != null).toList();
          
          if (validBooks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book,
              title: 'No Books',
              message: 'No books available in the marketplace.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookListingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: validBooks.length,
              itemBuilder: (context, index) {
                final item = validBooks[index];
                final book = item.bookListing;
                if (book == null) {
                  return const SizedBox.shrink(); // Skip items without book listing
                }
                return _buildBookCard(context, ref, item, book);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(bookListingsProvider);
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

  Widget _buildBookCard(BuildContext context, WidgetRef ref, MarketplaceItem item, BookListing book) {
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
                height: 120,
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
                          errorWidget: (context, url, error) => const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.book, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isNotEmpty ? item.title : 'Untitled Book',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author.isNotEmpty ? book.author : 'Unknown'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (book.courseCode != null && book.courseCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.courseCode!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConditionColor(book.condition).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.condition.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getConditionColor(book.condition),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${book.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (book.negotiable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Price negotiable',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'new':
        return AppTheme.success;
      case 'like_new':
        return AppTheme.primaryColor;
      case 'good':
        return AppTheme.accentBlue;
      case 'fair':
        return AppTheme.warning;
      case 'poor':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }
}


