import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/faculty_admin_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final broadcastsProvider = FutureProvider.family<List<Broadcast>, String?>((ref, type) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBroadcasts(type: type);
});

class BroadcastStudioScreen extends ConsumerStatefulWidget {
  const BroadcastStudioScreen({super.key});

  @override
  ConsumerState<BroadcastStudioScreen> createState() => _BroadcastStudioScreenState();
}

class _BroadcastStudioScreenState extends ConsumerState<BroadcastStudioScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final broadcastsAsync = ref.watch(broadcastsProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Studio'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(broadcastsProvider(_selectedType));
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create broadcast screen
            },
          ),
        ],
      ),
      body: broadcastsAsync.when(
        data: (broadcasts) {
          if (broadcasts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.broadcast_on_personal,
              title: 'No Broadcasts',
              message: 'No broadcasts found.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(broadcastsProvider(_selectedType));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: broadcasts.length,
              itemBuilder: (context, index) {
                final broadcast = broadcasts[index];
                return _buildBroadcastCard(context, broadcast);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(broadcastsProvider(_selectedType));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create broadcast screen
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBroadcastCard(BuildContext context, Broadcast broadcast) {
    Color priorityColor;
    switch (broadcast.priority) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'urgent':
        priorityColor = Colors.orange;
        break;
      case 'important':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to broadcast detail screen
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      broadcast.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (broadcast.isPublished)
                    Chip(
                      label: const Text('PUBLISHED'),
                      backgroundColor: Colors.green.withOpacity(0.2),
                      labelStyle: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Chip(
                      label: const Text('DRAFT'),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(broadcast.broadcastType.toUpperCase()),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(broadcast.priority.toUpperCase()),
                    backgroundColor: priorityColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                broadcast.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${broadcast.viewsCount} views',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${broadcast.engagementCount} engagements',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (broadcast.createdByName != null)
                    Text(
                      'By ${broadcast.createdByName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Broadcasts'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                DropdownMenuItem(value: 'event', child: Text('Event')),
                DropdownMenuItem(value: 'alert', child: Text('Alert')),
                DropdownMenuItem(value: 'news', child: Text('News')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
                Navigator.pop(context);
                setState(() {});
              },
            );
          },
        ),
      ),
    );
  }
}

