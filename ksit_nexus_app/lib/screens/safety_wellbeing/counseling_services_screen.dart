import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/safety_wellbeing_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final counselingServicesProvider = FutureProvider<List<CounselingService>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCounselingServices();
});

class CounselingServicesScreen extends ConsumerWidget {
  const CounselingServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(counselingServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counseling Services'),
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
              ref.invalidate(counselingServicesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.psychology,
              title: 'No Counseling Services',
              message: 'No counseling services available.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(counselingServicesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceCard(context, ref, service);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(counselingServicesProvider);
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, WidgetRef ref, CounselingService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(service.serviceType.replaceAll('_', ' ').toUpperCase()),
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  labelStyle: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (service.counselorName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    service.counselorName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (service.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    service.location!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to book appointment screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}


