import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/timezone_utils.dart';
import '../../providers/data_providers.dart';
import '../../models/reservation_model.dart';

class ReservationHistoryScreen extends ConsumerStatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  ConsumerState<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends ConsumerState<ReservationHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Reservation History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reservations');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(userReservationsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsList('all'),
          _buildReservationsList('upcoming'),
          _buildReservationsList('active'),
          _buildReservationsList('completed'),
        ],
      ),
    );
  }

  Widget _buildReservationsList(String filter) {
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
              final filteredReservations = _filterReservations(reservations, filter);
              
              if (filteredReservations.isEmpty) {
                return _buildEmptyState(filter);
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(userReservationsProvider);
                },
                child: ListView.builder(
                  padding: Responsive.padding(context),
                itemCount: filteredReservations.length,
                itemBuilder: (context, index) {
                  final reservation = filteredReservations[index];
                  return _buildReservationCard(reservation);
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

  List<Reservation> _filterReservations(List<Reservation> reservations, String filter) {
    switch (filter) {
      case 'upcoming':
        return reservations.where((r) => r.status == 'confirmed' && r.isUpcoming).toList();
      case 'active':
        return reservations.where((r) => r.status == 'active').toList();
      case 'completed':
        return reservations.where((r) => r.status == 'completed' || r.status == 'cancelled').toList();
      default:
        return reservations;
    }
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
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
            
            // Room and seat info
            Row(
              children: [
                Icon(Icons.meeting_room, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reservation.seat?.room?.name ?? 'Unknown Room'} - Seat ${reservation.seat?.seatNumber ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reservation.seat?.room?.location ?? 'Unknown Location',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            // Time info
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}',
                  style: TextStyle(color: AppTheme.grey600),
                ),
                const Spacer(),
                Text(
                  '${reservation.durationHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    color: AppTheme.grey600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Purpose and notes
            if (reservation.purpose?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description, size: 16, color: AppTheme.grey600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.purpose!,
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (reservation.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: AppTheme.grey600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reservation.notes!,
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Check-in/out info
            if (reservation.checkedInAt != null || reservation.checkedOutAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (reservation.checkedInAt != null)
                      Row(
                        children: [
                          Icon(Icons.login, size: 16, color: AppTheme.success),
                          const SizedBox(width: 4),
                          Text(
                            'Checked in: ${_formatDateTime(reservation.checkedInAt!)}',
                            style: TextStyle(
                              color: AppTheme.grey700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    if (reservation.checkedOutAt != null) ...[
                      if (reservation.checkedInAt != null) const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.logout, size: 16, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            'Checked out: ${_formatDateTime(reservation.checkedOutAt!)}',
                            style: TextStyle(
                              color: AppTheme.grey700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Action buttons
            if (reservation.status == 'confirmed' && reservation.isUpcoming) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelReservation(reservation),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _checkIn(reservation),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (reservation.status == 'active') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _checkOut(reservation),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;
    
    switch (filter) {
      case 'upcoming':
        title = 'No Upcoming Reservations';
        subtitle = 'Your confirmed future bookings will appear here';
        icon = Icons.schedule;
        break;
      case 'active':
        title = 'No Active Reservations';
        subtitle = 'Your current bookings will appear here';
        icon = Icons.event_seat;
        break;
      case 'completed':
        title = 'No Completed Reservations';
        subtitle = 'Your past bookings will appear here';
        icon = Icons.history;
        break;
      default:
        title = 'No Reservations';
        subtitle = 'Your booking history will appear here';
        icon = Icons.bookmark_border;
    }
    
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

  String _formatDateTime(DateTime dateTime) {
    return TimezoneUtils.formatDateTimeIST(dateTime);
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel reservation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reservation cancelled')),
              );
            },
            child: const Text('Yes'),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement check in
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checked in successfully')),
              );
            },
            child: const Text('Check In'),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement check out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checked out successfully')),
              );
            },
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }
}
