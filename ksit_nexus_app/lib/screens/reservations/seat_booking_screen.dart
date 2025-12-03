import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/reservation_model.dart';
import '../../services/api_service.dart';

class SeatBookingScreen extends ConsumerStatefulWidget {
  final ReadingRoom room;
  final DateTime startTime;
  final DateTime endTime;
  
  const SeatBookingScreen({
    super.key,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends ConsumerState<SeatBookingScreen> {
  List<Seat> _selectedSeats = [];
  int? _requestedSeatCount;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;
  Timer? _refreshTimer;
  bool _showSeatCountDialog = false;

  @override
  void initState() {
    super.initState();
    // Show seat count dialog on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSeatCountInputDialog();
    });
    // Set up periodic refresh for real-time updates
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    // Changed to 10 seconds to match seat_layout_widget
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Only invalidate if not already fetching to prevent flicker
        ref.invalidate(roomSeatsProvider(widget.room.id));
      }
    });
  }

  void _showSeatCountInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 500,
          desktop: 600,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: AlertDialog(
          title: Text(
            'How many seats do you want to reserve?',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 18),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                ),
                decoration: InputDecoration(
                  labelText: 'Number of seats',
                  hintText: 'Enter number (1-50)',
                  border: const OutlineInputBorder(),
                  contentPadding: Responsive.padding(context, mobile: 12, tablet: 16, desktop: 16),
                ),
                onChanged: (value) {
                  final count = int.tryParse(value);
                  if (count != null && count > 0 && count <= 50) {
                    setState(() {
                      _requestedSeatCount = count;
                    });
                  }
                },
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
              if (_requestedSeatCount != null)
                Text(
                  'You can select up to $_requestedSeatCount seat${_requestedSeatCount! > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.fontSize(context, 14),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/reservations');
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _requestedSeatCount != null && _requestedSeatCount! > 0
                  ? () {
                      Navigator.pop(context);
                      setState(() {
                        _showSeatCountDialog = false;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: Responsive.padding(context, mobile: 12, tablet: 16, desktop: 20),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Seats - ${widget.room.name}'),
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
              ref.invalidate(roomSeatsProvider(widget.room.id));
              ref.invalidate(userReservationsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 900,
          desktop: 1000,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: _requestedSeatCount == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Room Info Header
                    _buildRoomInfoHeader(),
                    
                    // Selection Status
                    _buildSelectionStatus(),
                    
                    // Seat Layout
                    _buildSeatLayout(),
                    
                    // Booking Form
                    if (_selectedSeats.isNotEmpty) _buildBookingForm(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRoomInfoHeader() {
    return Container(
      padding: Responsive.padding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.meeting_room,
                color: AppTheme.primaryColor,
                size: Responsive.value(context: context, mobile: 20, tablet: 24, desktop: 28),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
              Expanded(
                child: Text(
                  widget.room.name ?? 'Unnamed Room',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.spacing(context, mobile: 8, tablet: 10, desktop: 12),
                  vertical: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8),
                ),
                decoration: BoxDecoration(
                  color: _getRoomStatusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoomStatusText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Text(
            widget.room.location ?? 'Location not specified',
            style: TextStyle(
              color: AppTheme.grey600,
              fontSize: Responsive.fontSize(context, 14),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: Responsive.value(context: context, mobile: 16, tablet: 18, desktop: 20),
                color: AppTheme.grey600,
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
              Text(
                '${_formatDateTime(widget.startTime)} - ${_formatDateTime(widget.endTime)}',
                style: TextStyle(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Row(
            children: [
              Icon(
                Icons.event_seat,
                size: Responsive.value(context: context, mobile: 16, tablet: 18, desktop: 20),
                color: AppTheme.grey600,
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
              Text(
                'Available: ${widget.room.availableSeats}/${widget.room.totalSeats} seats',
                style: TextStyle(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionStatus() {
    final remaining = (_requestedSeatCount ?? 0) - _selectedSeats.length;
    return Container(
      padding: Responsive.padding(context),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected: ${_selectedSeats.length} / ${_requestedSeatCount ?? 0}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (remaining > 0)
                    Text(
                      'Select $remaining more seat${remaining > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: AppTheme.grey600,
                      ),
                    ),
                ],
              ),
          if (_selectedSeats.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSeats.clear();
                });
              },
              icon: Icon(
                Icons.clear,
                size: Responsive.value(context: context, mobile: 16, tablet: 18, desktop: 20),
              ),
              label: Text(
                'Clear',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.error,
                padding: Responsive.padding(context, mobile: 8, tablet: 12, desktop: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeatLayout() {
    return Consumer(
      builder: (context, ref, child) {
        final seatsAsync = ref.watch(roomSeatsProvider(widget.room.id));
        
        return seatsAsync.when(
          data: (seats) {
            if (seats.isEmpty) {
              return _buildEmptyState();
            }
            
            // Group seats by table
            final seatsByTable = <int, List<Seat>>{};
            for (final seat in seats) {
              final tableNum = seat.tableNumber ?? 0;
              if (!seatsByTable.containsKey(tableNum)) {
                seatsByTable[tableNum] = [];
              }
              seatsByTable[tableNum]!.add(seat);
            }
            
            // Determine room type based on name
            final roomName = (widget.room.name ?? '').toLowerCase();
            final isStudyRoom = roomName.contains('study') || roomName.contains('hall');
            final isLibrary = roomName.contains('library');
            
            return Padding(
              padding: Responsive.padding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legend
                  _buildLegend(),
                  SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  
                  // Seat Layout based on room type
                  if (isStudyRoom)
                    _buildStudyRoomLayout(seatsByTable)
                  else if (isLibrary)
                    _buildLibraryLayout(seatsByTable)
                  else
                    _buildGenericLayout(seatsByTable),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildStudyRoomLayout(Map<int, List<Seat>> seatsByTable) {
    // Study Room: 10 tables (4 seats) + 5 tables (2 seats)
    final tables4Seats = <int, List<Seat>>{};
    final tables2Seats = <int, List<Seat>>{};
    
    for (final entry in seatsByTable.entries) {
      if (entry.value.length == 4) {
        tables4Seats[entry.key] = entry.value;
      } else if (entry.value.length == 2) {
        tables2Seats[entry.key] = entry.value;
      }
    }
    
    return Column(
      children: [
        // 4-seat tables
        if (tables4Seats.isNotEmpty) ...[
          Text(
            '4-Seat Tables',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            runSpacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            children: tables4Seats.entries.map((entry) {
              return _buildTableWidget(entry.key, entry.value, 4);
            }).toList(),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32)),
        ],
        
        // 2-seat tables
        if (tables2Seats.isNotEmpty) ...[
          Text(
            '2-Seat Tables',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            runSpacing: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            children: tables2Seats.entries.map((entry) {
              return _buildTableWidget(entry.key, entry.value, 2);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLibraryLayout(Map<int, List<Seat>> seatsByTable) {
    // Library: 5 tables with 7 seats horizontally
    return Column(
      children: seatsByTable.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${entry.key}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w500,
                color: AppTheme.grey600,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            _buildTableWidget(entry.key, entry.value, 7),
          ],
        ),
      );
      }).toList(),
    );
  }

  Widget _buildGenericLayout(Map<int, List<Seat>> seatsByTable) {
    // Generic layout: show all tables
    return Column(
      children: seatsByTable.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${entry.key}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.w500,
                color: AppTheme.grey600,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            _buildTableWidget(entry.key, entry.value, entry.value.length),
          ],
        ),
      );
      }).toList(),
    );
  }

  Widget _buildTableWidget(int tableNumber, List<Seat> seats, int seatsPerTable) {
    // Sort seats by position for consistent display
    seats.sort((a, b) {
      if (a.rowNumber != null && b.rowNumber != null) {
        final rowCompare = a.rowNumber!.compareTo(b.rowNumber!);
        if (rowCompare != 0) return rowCompare;
      }
      if (a.columnNumber != null && b.columnNumber != null) {
        return a.columnNumber!.compareTo(b.columnNumber!);
      }
      return a.seatNumber.compareTo(b.seatNumber);
    });
    
    // Responsive sizes
    final tableSize = Responsive.value(
      context: context,
      mobile: 120.0,
      tablet: 140.0,
      desktop: 160.0,
    );
    final seatSize = Responsive.value(
      context: context,
      mobile: 45.0,
      tablet: 50.0,
      desktop: 55.0,
    );
    final smallTableWidth = Responsive.value(
      context: context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );
    final smallTableHeight = Responsive.value(
      context: context,
      mobile: 70.0,
      tablet: 80.0,
      desktop: 90.0,
    );
    final tableLabelSize = Responsive.value(
      context: context,
      mobile: 50.0,
      tablet: 60.0,
      desktop: 70.0,
    );
    final smallTableLabelSize = Responsive.value(
      context: context,
      mobile: 40.0,
      tablet: 50.0,
      desktop: 60.0,
    );
    
    if (seatsPerTable == 4) {
      // Square table: 4 seats around
      return Container(
        width: tableSize,
        height: tableSize,
        child: Stack(
          children: [
            // Table representation
            Center(
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
                    'T$tableNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Top seat
            if (seats.length > 0)
              Positioned(
                top: 0,
                left: (tableSize - seatSize) / 2,
                child: _buildSeatWidget(seats[0], seatSize),
              ),
            // Right seat
            if (seats.length > 1)
              Positioned(
                right: 0,
                top: (tableSize - seatSize) / 2,
                child: _buildSeatWidget(seats[1], seatSize),
              ),
            // Bottom seat
            if (seats.length > 2)
              Positioned(
                bottom: 0,
                left: (tableSize - seatSize) / 2,
                child: _buildSeatWidget(seats[2], seatSize),
              ),
            // Left seat
            if (seats.length > 3)
              Positioned(
                left: 0,
                top: (tableSize - seatSize) / 2,
                child: _buildSeatWidget(seats[3], seatSize),
              ),
          ],
        ),
      );
    } else if (seatsPerTable == 2) {
      // Small table: 2 seats facing each other
      return Container(
        width: smallTableWidth,
        height: smallTableHeight,
        child: Stack(
          children: [
            // Table
            Center(
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
                    'T$tableNumber',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Left seat
            if (seats.length > 0)
              Positioned(
                left: 0,
                top: (smallTableHeight - seatSize) / 2,
                child: _buildSeatWidget(seats[0], seatSize),
              ),
            // Right seat
            if (seats.length > 1)
              Positioned(
                right: 0,
                top: (smallTableHeight - seatSize) / 2,
                child: _buildSeatWidget(seats[1], seatSize),
              ),
          ],
        ),
      );
    } else {
      // Long table: seats in a row (for library)
      final tableHeight = Responsive.value(
        context: context,
        mobile: 35.0,
        tablet: 40.0,
        desktop: 45.0,
      );
      return Container(
        width: double.infinity,
        child: Column(
          children: [
            // Table representation
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
                  'Table $tableNumber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            // Seats in a row
            Wrap(
              spacing: Responsive.spacing(context, mobile: 6, tablet: 8, desktop: 10),
              runSpacing: Responsive.spacing(context, mobile: 6, tablet: 8, desktop: 10),
              children: seats.map((seat) => _buildSeatWidget(seat, seatSize)).toList(),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSeatWidget(Seat seat, [double? size]) {
    final seatSize = size ?? Responsive.value(
      context: context,
      mobile: 45.0,
      tablet: 50.0,
      desktop: 55.0,
    );
    final iconSize = Responsive.value(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );
    final fontSize = Responsive.fontSize(context, 9);
    final isSelected = _selectedSeats.any((s) => s.id == seat.id);
    final isAvailable = seat.status == 'free' || seat.isAvailableNow;
    final canSelect = isAvailable && 
                     (_selectedSeats.length < (_requestedSeatCount ?? 0));
    
    Color seatColor;
    Color textColor;
    String statusText = '';
    
    if (isSelected) {
      seatColor = AppTheme.primaryColor;
      textColor = Colors.white;
      statusText = 'Selected';
    } else if (!isAvailable) {
      seatColor = AppTheme.error;
      textColor = Colors.white;
      statusText = 'Reserved';
    } else if (!canSelect) {
      seatColor = AppTheme.grey300;
      textColor = AppTheme.grey600;
      statusText = 'Limit';
    } else {
      seatColor = AppTheme.success;
      textColor = Colors.white;
      statusText = 'Free';
    }
    
    return GestureDetector(
      onTap: canSelect && isAvailable
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedSeats.removeWhere((s) => s.id == seat.id);
                } else {
                  _selectedSeats.add(seat);
                }
              });
            }
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
          children: [
            Icon(
              Icons.event_seat,
              color: textColor,
              size: iconSize,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 2, tablet: 3, desktop: 4)),
            Text(
              seat.seatNumber.length > 6 
                  ? seat.seatNumber.substring(0, 6) 
                  : seat.seatNumber,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
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

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
      runSpacing: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
      children: [
        _buildLegendItem(AppTheme.success, 'Available'),
        _buildLegendItem(AppTheme.error, 'Reserved'),
        _buildLegendItem(AppTheme.primaryColor, 'Selected'),
        _buildLegendItem(AppTheme.grey300, 'Limit Reached'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final legendSize = Responsive.value(
      context: context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: legendSize,
          height: legendSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 12),
            color: AppTheme.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: Responsive.padding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Selected Seats Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          color: AppTheme.primaryColor,
                          size: Responsive.value(context: context, mobile: 20, tablet: 24, desktop: 28),
                        ),
                        SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
                        Text(
                          '${_selectedSeats.length} Seat${_selectedSeats.length > 1 ? 's' : ''} Selected',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    Wrap(
                      spacing: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8),
                      runSpacing: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8),
                      children: _selectedSeats.map((seat) {
                        return Chip(
                          label: Text(
                            seat.seatNumber,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 11),
                            ),
                          ),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Purpose Field
          TextFormField(
            controller: _purposeController,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
            ),
            decoration: InputDecoration(
              labelText: 'Purpose (Optional)',
              hintText: 'e.g., Study, Group work, Exam prep',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(
                Icons.description,
                size: Responsive.value(context: context, mobile: 20, tablet: 24, desktop: 28),
              ),
              contentPadding: Responsive.padding(context, mobile: 12, tablet: 16, desktop: 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Notes Field
          TextFormField(
            controller: _notesController,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 16),
            ),
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Any special requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(
                Icons.note,
                size: Responsive.value(context: context, mobile: 20, tablet: 24, desktop: 28),
              ),
              contentPadding: Responsive.padding(context, mobile: 12, tablet: 16, desktop: 20),
            ),
            maxLines: 2,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32)),
          
          // Book Button
          SizedBox(
            width: double.infinity,
            height: Responsive.value(context: context, mobile: 48, tablet: 50, desktop: 56),
            child: ElevatedButton(
              onPressed: _isBooking || _selectedSeats.isEmpty 
                  ? null 
                  : _bookSeats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Book ${_selectedSeats.length} Seat${_selectedSeats.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: Responsive.padding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_outlined,
              size: Responsive.value(context: context, mobile: 56, tablet: 64, desktop: 72),
              color: AppTheme.grey400,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              widget.room.totalSeats == 0 ? 'No Seats Configured' : 'No Seats Available',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: AppTheme.grey600,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              widget.room.totalSeats == 0 
                  ? 'This room has no seats configured'
                  : 'All seats are currently occupied or reserved',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: AppTheme.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: Responsive.padding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.value(context: context, mobile: 56, tablet: 64, desktop: 72),
              color: AppTheme.error,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              'Error Loading Seats',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.error,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              error,
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: Responsive.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
            ElevatedButton(
              onPressed: () => ref.refresh(roomSeatsProvider(widget.room.id)),
              style: ElevatedButton.styleFrom(
                padding: Responsive.padding(context, mobile: 12, tablet: 16, desktop: 20),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _bookSeats() async {
    if (_selectedSeats.isEmpty) return;
    
    setState(() {
      _isBooking = true;
    });
    
    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Create reservation request with multiple seats
      final request = ReservationCreateRequest(
        roomId: widget.room.id,
        seatIds: _selectedSeats.map((s) => s.id).toList(),
        startTime: widget.startTime,
        endTime: widget.endTime,
        purpose: _purposeController.text.isNotEmpty ? _purposeController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      await apiService.createReservation(request);
      
      // Refresh data
      ref.invalidate(userReservationsProvider);
      ref.invalidate(roomSeatsProvider(widget.room.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSeats.length} seat${_selectedSeats.length > 1 ? 's' : ''} booked successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book seats: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Color _getRoomStatusColor() {
    if (!widget.room.isActive) {
      return AppTheme.grey400;
    } else if (widget.room.hasAvailableSeats) {
      return AppTheme.success;
    } else if (widget.room.isFullyOccupied) {
      return AppTheme.warning;
    } else {
      return AppTheme.grey400;
    }
  }

  String _getRoomStatusText() {
    if (!widget.room.isActive) {
      return 'Closed';
    } else if (widget.room.hasAvailableSeats) {
      return 'Available';
    } else if (widget.room.isFullyOccupied) {
      return 'Full';
    } else {
      return 'No Seats';
    }
  }
}
