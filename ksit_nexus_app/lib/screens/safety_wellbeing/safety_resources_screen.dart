import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/safety_wellbeing_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final safetyResourcesProvider = FutureProvider<List<SafetyResource>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getSafetyResources();
});

class SafetyResourcesScreen extends ConsumerWidget {
  const SafetyResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(safetyResourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Resources'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/safety');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(safetyResourcesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.library_books,
              title: 'No Resources',
              message: 'No safety resources available.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(safetyResourcesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return _buildResourceCard(context, resource);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(safetyResourcesProvider);
          },
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, SafetyResource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: resource.isFeatured ? Colors.orange : Colors.blue,
          child: Icon(
            _getResourceIcon(resource.resourceType),
            color: Colors.white,
          ),
        ),
        title: Text(
          resource.title,
          style: TextStyle(
            fontWeight: resource.isFeatured ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(resource.description),
        trailing: resource.isFeatured
            ? Chip(
                label: const Text('FEATURED'),
                backgroundColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 10,
                ),
              )
            : null,
        onTap: () {
          _showResourceDialog(context, resource);
        },
      ),
    );
  }

  IconData _getResourceIcon(String resourceType) {
    switch (resourceType) {
      case 'guide':
        return Icons.book;
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'contact':
        return Icons.contact_phone;
      case 'tool':
        return Icons.build;
      default:
        return Icons.info;
    }
  }

  void _showResourceDialog(BuildContext context, SafetyResource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: resource.isFeatured ? Colors.orange : Colors.blue,
              child: Icon(
                _getResourceIcon(resource.resourceType),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (resource.isFeatured)
                    Chip(
                      label: const Text('FEATURED', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(color: Colors.orange.shade800),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.description,
                style: const TextStyle(fontSize: 14),
              ),
              if (resource.content != null && resource.content!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resource.content!,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (resource.url != null && resource.url!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(resource.url!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open link')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


