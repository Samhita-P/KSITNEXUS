import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/timezone_utils.dart';
import '../../providers/data_providers.dart';
import '../../models/reservation_model.dart';
import 'room_selection_screen.dart';
import 'seat_booking_screen.dart';
import 'reservation_history_screen.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
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
              ref.refresh(userReservationsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Book Seat', icon: Icon(Icons.add)),
            Tab(text: 'My Bookings', icon: Icon(Icons.bookmark)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingTab(),
          _buildMyBookingsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: 900,
        desktop: 1000,
      ),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a room and book your seat instantly',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24)),
          
          // Room Selection Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToRoomSelection(),
              icon: const Icon(Icons.meeting_room_outlined),
              label: const Text(
                'Select Room & Book Seat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24)),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.schedule,
                  title: 'Today\'s Availability',
                  subtitle: 'View available seats',
                  onTap: () => _navigateToRoomSelection(showTodayOnly: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.calendar_today,
                  title: 'Book for Later',
                  subtitle: 'Schedule in advance',
                  onTap: () => _navigateToRoomSelection(),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: Consumer(
        builder: (context, ref, child) {
          final reservationsAsync = ref.watch(userReservationsProvider);
          
          return reservationsAsync.when(
          data: (reservations) {
            // Filter to show only active/upcoming bookings (not completed or cancelled)
            final currentBookings = reservations
                .where((r) => r.status != 'completed' && r.status != 'cancelled')
                .toList();
            
            if (currentBookings.isEmpty) {
              return _buildEmptyState(
                icon: Icons.bookmark_border,
                title: 'No Current Bookings',
                subtitle: 'Your active and upcoming reservations will appear here',
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(userReservationsProvider);
              },
              child: ListView.builder(
                padding: Responsive.padding(context),
                itemCount: currentBookings.length,
                itemBuilder: (context, index) {
                  final reservation = currentBookings[index];
                  return _buildReservationCard(reservation, showActions: true);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, {bool showActions = true}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status ?? 'unknown'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (reservation.status ?? 'unknown').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(reservation.startTime),
                  style: TextStyle(
                    color: AppTheme.grey600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${reservation.seat?.room?.name ?? 'Room'} - Seat ${reservation.seat?.seatNumber ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reservation.seat?.room?.location ?? 'Location not available',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}',
                  style: TextStyle(color: AppTheme.grey600),
                ),
                const Spacer(),
                if (showActions) ...[
                  if (reservation.status == 'confirmed' && reservation.isUpcoming)
                    TextButton(
                      onPressed: () => _cancelReservation(reservation),
                      child: const Text('Cancel'),
                    ),
                  if (reservation.status == 'active')
                    TextButton(
                      onPressed: () => _checkOut(reservation),
                      child: const Text('Check Out'),
                    ),
                  if (reservation.status == 'confirmed' && _canCheckIn(reservation))
                    TextButton(
                      onPressed: () => _checkIn(reservation),
                      child: const Text('Check In'),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(
      builder: (context, ref, child) {
        final reservationsAsync = ref.watch(userReservationsProvider);
        
        return reservationsAsync.when(
          data: (reservations) {
            // Show all completed and cancelled bookings
            final historyReservations = reservations
                .where((r) => r.status == 'completed' || r.status == 'cancelled')
                .toList()
                ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Sort by date (newest first)
                
            if (historyReservations.isEmpty) {
              return _buildEmptyState(
                icon: Icons.history,
                title: 'No History',
                subtitle: 'Your completed and cancelled reservations will appear here',
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(userReservationsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: historyReservations.length,
                itemBuilder: (context, index) {
                  final reservation = historyReservations[index];
                  return _buildReservationCard(reservation, showActions: false);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading Reservations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(userReservationsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.success;
      case 'active':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.grey600;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  String _formatDate(DateTime date) {
    return TimezoneUtils.formatDateIST(date);
  }

  String _formatTime(DateTime time) {
    return TimezoneUtils.formatTimeIST(time);
  }

  void _navigateToRoomSelection({bool showTodayOnly = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomSelectionScreen(showTodayOnly: showTodayOnly),
      ),
    );
  }

  void _cancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.cancelReservation(reservation.id);
                ref.refresh(userReservationsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reservation cancelled successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling reservation: $e')),
                  );
                }
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _checkOut(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Out'),
        content: const Text('Are you ready to check out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.checkOutReservation(reservation.id);
                ref.refresh(userReservationsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checked out successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error checking out: $e')),
                  );
                }
              }
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  void _checkIn(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check In'),
        content: const Text('Are you ready to check in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.checkInReservation(reservation.id);
                ref.refresh(userReservationsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checked in successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error checking in: $e')),
                  );
                }
              }
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  bool _canCheckIn(Reservation reservation) {
    final now = DateTime.now();
    final checkInTime = reservation.startTime.subtract(const Duration(minutes: 15));
    return now.isAfter(checkInTime) && now.isBefore(reservation.endTime);
  }
}