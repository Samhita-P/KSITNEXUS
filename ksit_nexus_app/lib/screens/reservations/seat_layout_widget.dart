import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../models/reservation_model.dart';
import '../../providers/data_providers.dart';
import '../../services/api_service.dart';

class SeatLayoutWidget extends ConsumerStatefulWidget {
  final ReadingRoom room;
  final DateTime selectedDate;
  final TimeOfDay selectedStartTime;
  final TimeOfDay selectedEndTime;
  final List<Seat> selectedSeats;
  final int requestedSeatCount;
  final Function(Seat) onSeatTap;
  final VoidCallback? onManualRefresh; // Callback for manual refresh

  const SeatLayoutWidget({
    super.key,
    required this.room,
    required this.selectedDate,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.selectedSeats,
    required this.requestedSeatCount,
    required this.onSeatTap,
    this.onManualRefresh,
  });

  @override
  ConsumerState<SeatLayoutWidget> createState() => _SeatLayoutWidgetState();
}

class _SeatLayoutWidgetState extends ConsumerState<SeatLayoutWidget> {
  Timer? _pollTimer;
  bool _isFetching = false;
  List<Seat>? _cachedSeats;
  DateTime? _lastFetchTime;
  DateTime? _lastRefreshRequest;
  static const Duration _pollInterval = Duration(seconds: 10); // 10-second polling
  static const Duration _quickPollThreshold = Duration(milliseconds: 500); // Don't show spinner if fetch < 500ms

  @override
  void initState() {
    super.initState();
    // Initial load - fetch seats immediately
    _refreshSeats(silent: false);
    // Start polling for real-time updates every 10 seconds
    _startPolling();
  }
  
  @override
  void didUpdateWidget(SeatLayoutWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If key changed (manual refresh), force refresh and show spinner
    if (widget.key != oldWidget.key) {
      // Clear cache to force spinner on manual refresh
      setState(() {
        _cachedSeats = null;
      });
      _refreshSeats(force: true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (timer) {
      if (mounted && !_isFetching) {
        _refreshSeats(silent: true);
      }
    });
  }

  Future<void> _refreshSeats({bool silent = false, bool force = false}) async {
    // Guard: prevent duplicate fetches
    if (_isFetching) {
      return;
    }

    // Debounce: if refresh requested within last 500ms, skip (unless forced)
    final now = DateTime.now();
    if (!force && _lastRefreshRequest != null) {
      final timeSinceLastRequest = now.difference(_lastRefreshRequest!);
      if (timeSinceLastRequest < const Duration(milliseconds: 500)) {
        return; // Debounce
      }
    }
    _lastRefreshRequest = now;

    _isFetching = true;
    
    try {
      // Fetch new data in background - don't invalidate provider to avoid FutureBuilder rebuild
      final newSeats = await _getAllSeats();
      
      if (mounted) {
        // Update cached seats silently - UI will rebuild automatically
        setState(() {
          _cachedSeats = newSeats;
          _lastFetchTime = now;
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
      print('Error refreshing seats: $e');
    }
  }

  Future<List<Seat>> _getAllSeats() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedStartTime.hour,
        widget.selectedStartTime.minute,
      );
      
      // Calculate end time - if end time is before start time, assume next day
      DateTime endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedEndTime.hour,
        widget.selectedEndTime.minute,
      );
      
      // If end time is before or equal to start time, add one day
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      // Get all seats for the room
      final allSeats = await apiService.getRoomSeats(widget.room.id);
      
      // Get available seats for the time period
      final availableSeats = await apiService.getAvailableSeats(
        widget.room.id,
        startDateTime,
        endDateTime,
      );
      
      // Create a set of available seat IDs
      final availableSeatIds = availableSeats.map((s) => s.id).toSet();
      
      // Mark all seats with their status
      final seatsWithStatus = allSeats.map((seat) {
        final isAvailable = availableSeatIds.contains(seat.id);
        return Seat(
          id: seat.id,
          seatNumber: seat.seatNumber,
          seatType: seat.seatType,
          isActive: seat.isActive,
          hasPowerOutlet: seat.hasPowerOutlet,
          hasLight: seat.hasLight,
          room: seat.room,
          createdAt: seat.createdAt,
          updatedAt: seat.updatedAt,
          currentReservation: seat.currentReservation,
          rowNumber: seat.rowNumber,
          columnNumber: seat.columnNumber,
          tableNumber: seat.tableNumber,
          isAvailableNow: isAvailable,
          status: isAvailable ? 'free' : 'occupied',
        );
      }).toList();
      
      return seatsWithStatus;
    } catch (e) {
      print('Error fetching seats: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show cached data if available - polling timer handles background refresh
    if (_cachedSeats != null) {
      // Show cached data immediately - no flicker
      return _buildSeatLayout(_cachedSeats!);
    }
    
    // Only show spinner on initial load (no cached data)
    return FutureBuilder<List<Seat>>(
      future: _getAllSeats().then((seats) {
        if (mounted) {
          setState(() {
            _cachedSeats = seats;
            _lastFetchTime = DateTime.now();
            _isFetching = false;
          });
        }
        return seats;
      }),
      builder: (context, snapshot) {
        // Show spinner only on initial load
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Padding(
            padding: Responsive.padding(context),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: Responsive.value(context: context, mobile: 48, tablet: 56, desktop: 64),
                  color: AppTheme.error,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
                Text(
                  'Error loading seats',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
                Text(
                  snapshot.error != null ? snapshot.error.toString() : 'Unknown error',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    color: AppTheme.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cachedSeats = null; // Force retry
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final seats = snapshot.data ?? _cachedSeats ?? [];
        return _buildSeatLayout(seats);
      },
    );
  }

  Widget _buildSeatLayout(List<Seat> seats) {
    if (seats.isEmpty) {
      return Padding(
        padding: Responsive.padding(context),
        child: Column(
          children: [
            Icon(
              Icons.event_seat_outlined,
              size: Responsive.value(context: context, mobile: 48, tablet: 56, desktop: 64),
              color: AppTheme.grey400,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
            Text(
              'No seats configured for this room',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                color: AppTheme.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              'Please contact administrator to configure seats',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: AppTheme.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Determine room type FIRST - safely handle room name
    final roomName = (widget.room.name != null && widget.room.name is String) 
        ? widget.room.name!.toLowerCase() 
        : '';
    final isStudyRoom = roomName.contains('study') || roomName.contains('hall');
    final isLibrary = roomName.contains('library');
    
    // Group seats by table - FORCE table-based layout
    final seatsByTable = <int, List<Seat>>{};
    
    // Helper function to extract numeric value from seat number (e.g., "A1" -> 1, "A10" -> 10)
    int extractSeatNumber(String seatNumber) {
      // Remove all non-digit characters and parse as int
      final digits = seatNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return 0;
      return int.tryParse(digits) ?? 0;
    }
    
    // Natural sort function for seat numbers (handles "A1", "A2", "A10" correctly)
    int naturalSeatSort(Seat a, Seat b) {
      final numA = extractSeatNumber(a.seatNumber);
      final numB = extractSeatNumber(b.seatNumber);
      if (numA != numB) {
        return numA.compareTo(numB);
      }
      // If numbers are equal, fall back to string comparison
      return a.seatNumber.compareTo(b.seatNumber);
    }
    
    if (isStudyRoom) {
      // Study Room: ALWAYS create 15 tables (10 with 4 seats, 5 with 2 seats)
      // Sort all seats by seat number for consistent assignment (natural sort)
      final sortedSeats = List<Seat>.from(seats)..sort(naturalSeatSort);
      
      // Debug: Print seat count and first few seat numbers
      print('Study Room: Total seats received: ${sortedSeats.length}');
      if (sortedSeats.isNotEmpty) {
        print('First 10 seats: ${sortedSeats.take(10).map((s) => s.seatNumber).join(", ")}');
        if (sortedSeats.length < 50) {
          print('WARNING: Expected 50 seats for Study Room, but only received ${sortedSeats.length} seats!');
          print('Please ensure the database has 50 seats (A1-A50) for the Study Room.');
        }
      } else {
        print('WARNING: No seats received from API!');
      }
      
      int seatIndex = 0;
      
      // First 10 tables with 4 seats each (40 seats) - Tables 1-10
      // ALWAYS create all 10 tables, even if there aren't enough seats
      for (int tableNum = 1; tableNum <= 10; tableNum++) {
        seatsByTable[tableNum] = [];
        for (int s = 0; s < 4 && seatIndex < sortedSeats.length; s++) {
          seatsByTable[tableNum]!.add(sortedSeats[seatIndex]);
          seatIndex++;
        }
        // Debug: Print table assignment (including empty tables)
        print('Table $tableNum: ${seatsByTable[tableNum]!.isEmpty ? "EMPTY" : seatsByTable[tableNum]!.map((s) => s.seatNumber).join(", ")} (${seatsByTable[tableNum]!.length} seats)');
      }
      
      // Next 5 tables with 2 seats each (10 seats) - Tables 11-15
      // ALWAYS create all 5 tables, even if there aren't enough seats
      for (int tableNum = 11; tableNum <= 15; tableNum++) {
        seatsByTable[tableNum] = [];
        for (int s = 0; s < 2 && seatIndex < sortedSeats.length; s++) {
          seatsByTable[tableNum]!.add(sortedSeats[seatIndex]);
          seatIndex++;
        }
        // Debug: Print table assignment
        if (seatsByTable[tableNum]!.isNotEmpty) {
          print('Table $tableNum: ${seatsByTable[tableNum]!.map((s) => s.seatNumber).join(", ")}');
        }
      }
      
      // If there are more seats than expected (50), continue assigning to tables
      // This handles edge cases where there might be more seats
      if (seatIndex < sortedSeats.length) {
        int tableNum = 16;
        while (seatIndex < sortedSeats.length) {
          if (!seatsByTable.containsKey(tableNum)) {
            seatsByTable[tableNum] = [];
          }
          seatsByTable[tableNum]!.add(sortedSeats[seatIndex]);
          seatIndex++;
          if (seatsByTable[tableNum]!.length >= 4) {
            tableNum++;
          }
        }
      }
    } else if (isLibrary) {
      // Library: 5 tables with 7 seats each (35 seats)
      final sortedSeats = List<Seat>.from(seats)..sort(naturalSeatSort);
      
      int seatIndex = 0;
      for (int tableNum = 1; tableNum <= 5 && seatIndex < sortedSeats.length; tableNum++) {
        seatsByTable[tableNum] = [];
        for (int s = 0; s < 7 && seatIndex < sortedSeats.length; s++) {
          seatsByTable[tableNum]!.add(sortedSeats[seatIndex]);
          seatIndex++;
        }
      }
      
      // Handle extra seats if any
      if (seatIndex < sortedSeats.length) {
        int tableNum = 6;
        while (seatIndex < sortedSeats.length) {
          if (!seatsByTable.containsKey(tableNum)) {
            seatsByTable[tableNum] = [];
          }
          seatsByTable[tableNum]!.add(sortedSeats[seatIndex]);
          seatIndex++;
          if (seatsByTable[tableNum]!.length >= 7) {
            tableNum++;
          }
        }
      }
    } else {
      // Generic: group seats by existing table_number if available, otherwise create tables of 4
      bool hasTableNumbers = false;
      
      // First pass: group by existing table_number
      for (final seat in seats) {
        final tableNum = seat.tableNumber;
        if (tableNum != null && tableNum > 0) {
          hasTableNumbers = true;
          if (!seatsByTable.containsKey(tableNum)) {
            seatsByTable[tableNum] = [];
          }
          seatsByTable[tableNum]!.add(seat);
        }
      }
      
      // If no table numbers, assign default table numbers
      if (!hasTableNumbers) {
        final unassignedSeats = seats.where((s) => s.tableNumber == null || s.tableNumber == 0).toList();
        int tableNum = 1;
        int seatIndex = 0;
        while (seatIndex < unassignedSeats.length) {
          seatsByTable[tableNum] = [];
          for (int s = 0; s < 4 && seatIndex < unassignedSeats.length; s++) {
            seatsByTable[tableNum]!.add(unassignedSeats[seatIndex]);
            seatIndex++;
          }
          tableNum++;
        }
      }
    }
    
    // Sort seats within each table by seat number (natural sort)
    for (final tableSeats in seatsByTable.values) {
      tableSeats.sort(naturalSeatSort);
    }
    
    // Build layout
    Widget layout;
    if (isStudyRoom) {
      layout = _buildStudyRoomLayout(seatsByTable);
    } else if (isLibrary) {
      layout = _buildLibraryLayout(seatsByTable);
    } else {
      layout = _buildGenericLayout(seatsByTable);
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: Responsive.padding(context),
        child: layout,
      ),
    );
  }

  Widget _buildStudyRoomLayout(Map<int, List<Seat>> seatsByTable) {
    // Study Room: Tables 1-10 are 4-seat tables, Tables 11-15 are 2-seat tables
    // Always render all 15 tables, even if some have fewer seats
    
    // Get tables 1-10 (4-seat tables)
    final tables4Seats = <int, List<Seat>>{};
    for (int tableNum = 1; tableNum <= 10; tableNum++) {
      if (seatsByTable.containsKey(tableNum)) {
        tables4Seats[tableNum] = seatsByTable[tableNum]!;
      } else {
        // Create empty table if missing
        tables4Seats[tableNum] = [];
      }
    }
    
    // Get tables 11-15 (2-seat tables)
    final tables2Seats = <int, List<Seat>>{};
    for (int tableNum = 11; tableNum <= 15; tableNum++) {
      if (seatsByTable.containsKey(tableNum)) {
        tables2Seats[tableNum] = seatsByTable[tableNum]!;
      } else {
        // Create empty table if missing
        tables2Seats[tableNum] = [];
      }
    }
    
    // Sort by table number to ensure correct order
    final sorted4SeatTables = tables4Seats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sorted2SeatTables = tables2Seats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show 4-seat tables section (Tables 1-10)
          Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
            ),
            child: Text(
              '4-Seat Tables (T1-T10)',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            runSpacing: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24),
            alignment: WrapAlignment.start,
            children: sorted4SeatTables.map((entry) {
              return _buildTableWidget(entry.key, entry.value, 4);
            }).toList(),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32)),
          // Always show 2-seat tables section (Tables 11-15)
          Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
            ),
            child: Text(
              '2-Seat Tables (T11-T15)',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            runSpacing: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24),
            alignment: WrapAlignment.start,
            children: sorted2SeatTables.map((entry) {
              return _buildTableWidget(entry.key, entry.value, 2);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryLayout(Map<int, List<Seat>> seatsByTable) {
    // Sort tables by table number
    final sortedTables = seatsByTable.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedTables.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  child: Text(
                    'Table ${(entry.key ?? 0).toString()}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grey600,
                    ),
                  ),
                ),
                _buildTableWidget(entry.key ?? 0, entry.value, 7),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenericLayout(Map<int, List<Seat>> seatsByTable) {
    // Sort tables by table number
    final sortedTables = seatsByTable.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedTables.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
                  ),
                  child: Text(
                    'Table ${(entry.key ?? 0).toString()}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grey600,
                    ),
                  ),
                ),
                _buildTableWidget(entry.key ?? 0, entry.value, entry.value.length),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableWidget(int tableNumber, List<Seat> seats, int seatsPerTable) {
    // Ensure minimum touch target of 44px on mobile
    final seatSize = Responsive.value(
      context: context,
      mobile: 44.0, // Minimum touch target
      tablet: 50.0,
      desktop: 55.0,
    );
    // Calculate table size to accommodate seats + label + padding
    // For 4-seat: 2 rows of seats (seatSize * 2) + table label + padding * 2
    final padding = Responsive.value(
      context: context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final tableLabelSize = Responsive.value(
      context: context,
      mobile: 50.0,
      tablet: 60.0,
      desktop: 70.0,
    );
    
    // Calculate minimum height needed for 4-seat table
    // Content height: 2 rows of seats + table label + spacing between rows
    final contentHeight4Seat = (seatSize * 2) + tableLabelSize + 8; // 8px spacing between elements
    // Total height: content + padding on top and bottom
    final minHeight4Seat = contentHeight4Seat + (padding * 2);
    final tableSize = Responsive.value(
      context: context,
      mobile: minHeight4Seat > 180 ? minHeight4Seat : 180.0, // Ensure minimum 180px
      tablet: minHeight4Seat > 200 ? minHeight4Seat : 200.0,
      desktop: minHeight4Seat > 220 ? minHeight4Seat : 220.0,
    );
    
    final smallTableWidth = Responsive.value(
      context: context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );
    // Calculate minimum height needed for 2-seat table
    final smallTableLabelSize = Responsive.value(
      context: context,
      mobile: 40.0,
      tablet: 50.0,
      desktop: 60.0,
    );
    // Content height: 1 row of seats + table label + spacing
    final contentHeight2Seat = seatSize + (smallTableLabelSize * 0.6) + 8; // 8px spacing
    // Total height: content + padding on top and bottom
    final minHeight2Seat = contentHeight2Seat + (padding * 2);
    final smallTableHeight = Responsive.value(
      context: context,
      mobile: minHeight2Seat > 100 ? minHeight2Seat : 100.0, // Ensure minimum 100px
      tablet: minHeight2Seat > 110 ? minHeight2Seat : 110.0,
      desktop: minHeight2Seat > 120 ? minHeight2Seat : 120.0,
    );
    if (seatsPerTable == 4) {
      // 4-seat table: 2x2 grid with equal spacing - ALWAYS render 4 positions
      
      // Ensure we have exactly 4 seats (pad with null if needed)
      final paddedSeats = List<Seat?>.from(seats);
      while (paddedSeats.length < 4) {
        paddedSeats.add(null);
      }
      
      return Container(
        width: tableSize,
        height: tableSize,
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: 2 seats - ALWAYS render both positions
            SizedBox(
              height: seatSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  paddedSeats[0] != null 
                      ? _buildSeatWidget(paddedSeats[0]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                  paddedSeats[1] != null 
                      ? _buildSeatWidget(paddedSeats[1]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                ],
              ),
            ),
            // Center: Table label
            SizedBox(
              height: tableLabelSize,
              child: Center(
                child: Container(
                  width: tableLabelSize,
                  height: tableLabelSize,
                  decoration: BoxDecoration(
                    color: Colors.brown[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.brown[600]!,
                      width: Responsive.value(context: context, mobile: 1.5, tablet: 2, desktop: 2.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'T${(tableNumber ?? 0).toString()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom row: 2 seats - ALWAYS render both positions
            SizedBox(
              height: seatSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  paddedSeats[2] != null 
                      ? _buildSeatWidget(paddedSeats[2]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                  paddedSeats[3] != null 
                      ? _buildSeatWidget(paddedSeats[3]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                ],
              ),
            ),
          ],
        ),
      );
    } else if (seatsPerTable == 2) {
      // 2-seat table: 2 seats side-by-side with equal spacing - ALWAYS render 2 positions
      
      // Ensure we have exactly 2 seats (pad with null if needed)
      final paddedSeats = List<Seat?>.from(seats);
      while (paddedSeats.length < 2) {
        paddedSeats.add(null);
      }
      
      return Container(
        width: smallTableWidth,
        height: smallTableHeight,
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Table label
            SizedBox(
              height: smallTableLabelSize * 0.6,
              child: Center(
                child: Container(
                  width: smallTableLabelSize * 0.7,
                  height: smallTableLabelSize * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.brown[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.brown[600]!,
                      width: Responsive.value(context: context, mobile: 1.5, tablet: 2, desktop: 2.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'T${(tableNumber ?? 0).toString()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Seats row: 2 seats with equal spacing - ALWAYS render both positions
            SizedBox(
              height: seatSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  paddedSeats[0] != null 
                      ? _buildSeatWidget(paddedSeats[0]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                  paddedSeats[1] != null 
                      ? _buildSeatWidget(paddedSeats[1]!, seatSize)
                      : _buildPlaceholderSeat(seatSize), // Visible placeholder
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Library 7-seat table or other sizes: horizontal row with equal spacing
      final tableHeight = Responsive.value(
        context: context,
        mobile: 35.0,
        tablet: 40.0,
        desktop: 45.0,
      );
      final horizontalPadding = Responsive.value(
        context: context,
        mobile: 8.0,
        tablet: 10.0,
        desktop: 12.0,
      );
      
      // For narrow screens with many seats, use Wrap with equal spacing
      final screenWidth = MediaQuery.of(context).size.width;
      final minWidthNeeded = (seatSize * seats.length) + (horizontalPadding * 2);
      final useWrap = screenWidth < minWidthNeeded && seats.length > 5;
      
      return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table bar
            Container(
              width: double.infinity,
              height: tableHeight,
              decoration: BoxDecoration(
                color: Colors.brown[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.brown[600]!,
                  width: Responsive.value(context: context, mobile: 1.5, tablet: 2, desktop: 2.5),
                ),
              ),
              child: Center(
                child: Text(
                  'Table ${(tableNumber ?? 0).toString()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            // Seats: evenly distributed with equal spacing
            if (useWrap)
              // Wrap layout for narrow screens
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Wrap(
                  spacing: Responsive.spacing(context, mobile: 6, tablet: 8, desktop: 10),
                  runSpacing: Responsive.spacing(context, mobile: 6, tablet: 8, desktop: 10),
                  alignment: WrapAlignment.spaceBetween,
                  children: seats.map((seat) => _buildSeatWidget(seat, seatSize)).toList(),
                ),
              )
            else
              // Row layout with equal spacing for wider screens
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: seats.map((seat) => _buildSeatWidget(seat, seatSize)).toList(),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholderSeat(double seatSize) {
    // Visible placeholder for empty seat positions - shows that seat is not available
    return Container(
      width: seatSize,
      height: seatSize,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[400]!,
          width: Responsive.value(context: context, mobile: 0.8, tablet: 1, desktop: 1.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.block,
          color: Colors.grey[400],
          size: Responsive.value(context: context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
        ),
      ),
    );
  }

  Widget _buildSeatWidget(Seat seat, double seatSize) {
    final seatsList = widget.selectedSeats;
    final isSelected = seatsList.any((s) => s.id == seat.id);
    final isAvailable = seat.status == 'free' || seat.isAvailableNow;
    final canSelect = isAvailable && (seatsList.length < widget.requestedSeatCount);
    
    Color seatColor;
    Color textColor;
    
    if (isSelected) {
      seatColor = AppTheme.primaryColor; // Blue
      textColor = Colors.white;
    } else if (!isAvailable) {
      seatColor = AppTheme.error; // Red
      textColor = Colors.white;
    } else if (!canSelect) {
      seatColor = AppTheme.grey300; // Grey
      textColor = AppTheme.grey600;
    } else {
      seatColor = AppTheme.success; // Green
      textColor = Colors.white;
    }
    
    final iconSize = Responsive.value(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );
    // Make font size larger and more visible
    final fontSize = Responsive.fontSize(context, 11); // Increased for better visibility
    
    return GestureDetector(
      onTap: canSelect && isAvailable
          ? () => widget.onSeatTap(seat)
          : null,
      child: Container(
        width: seatSize,
        height: seatSize,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(
                  color: AppTheme.primaryColor,
                  width: Responsive.value(context: context, mobile: 2.5, tablet: 3, desktop: 3.5),
                )
              : Border.all(
                  color: Colors.grey[300]!,
                  width: Responsive.value(context: context, mobile: 0.8, tablet: 1, desktop: 1.2),
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: Responsive.value(context: context, mobile: 6, tablet: 8, desktop: 10),
                    spreadRadius: Responsive.value(context: context, mobile: 1.5, tablet: 2, desktop: 2.5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smaller icon to make room for seat number
            Icon(
              Icons.event_seat,
              color: textColor,
              size: iconSize * 0.8, // Slightly smaller icon
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 1, tablet: 2, desktop: 3)),
            // Seat number - ALWAYS visible and prominent
            Text(
              seat.seatNumber.length > 10 
                  ? seat.seatNumber.substring(0, 10) 
                  : seat.seatNumber,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: textColor == Colors.white 
                    ? [
                        Shadow(
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 1.5,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ]
                    : [
                        Shadow(
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 1.0,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

