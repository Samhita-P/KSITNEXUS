import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/marketplace_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final rideListingsProvider = FutureProvider<List<MarketplaceItem>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getRideListings();
});

class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(rideListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Sharing'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ridesAsync.when(
        data: (rides) {
          if (rides.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.directions_car,
              title: 'No Rides',
              message: 'No ride sharing listings available.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rideListingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final item = rides[index];
                final ride = item.rideListing!;
                return _buildRideCard(context, item, ride);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(rideListingsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, MarketplaceItem item, RideListing ride) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to ride detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car, color: AppTheme.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ride.departureLocation} → ${ride.destination}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.availableSeats > 0
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ride.availableSeats} seats',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ride.availableSeats > 0 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(ride.departureDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (ride.luggageSpace)
                    _buildFeatureChip('Luggage', Icons.luggage),
                  if (ride.smokingAllowed)
                    _buildFeatureChip('Smoking', Icons.smoking_rooms),
                  if (ride.petsAllowed)
                    _buildFeatureChip('Pets', Icons.pets),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${ride.pricePerSeat.toStringAsFixed(0)} per seat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Request ride
                    },
                    child: const Text('Request Ride'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 10),
        padding: EdgeInsets.zero,
      ),
    );
  }
}


