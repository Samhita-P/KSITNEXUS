import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../models/reservation_model.dart';
import '../../providers/data_providers.dart';
import '../../services/api_service.dart';
import 'seat_layout_widget.dart';

class RoomSelectionScreen extends ConsumerStatefulWidget {
  final bool showTodayOnly;
  
  const RoomSelectionScreen({
    Key? key,
    this.showTodayOnly = false,
  }) : super(key: key);

  @override
  ConsumerState<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends ConsumerState<RoomSelectionScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  ReadingRoom? selectedRoom;
  List<Seat>? _selectedSeats;
  int? requestedSeatCount;
  String purpose = '';
  String notes = '';
  bool _showSeatCountDialog = false;
  Timer? _seatUpdateTimer; // For real-time polling
  int _refreshKey = 0; // For manual refresh

  // Getter to ensure selectedSeats is always a valid list
  List<Seat> get selectedSeats {
    try {
      if (_selectedSeats == null || _selectedSeats is! List<Seat>) {
        _selectedSeats = <Seat>[];
      }
      // Ensure it's a proper list, not undefined
      final seats = _selectedSeats!;
      if (seats is! List<Seat>) {
        _selectedSeats = <Seat>[];
        return <Seat>[];
      }
      return seats;
    } catch (e) {
      _selectedSeats = <Seat>[];
      return <Seat>[];
    }
  }
  
  set selectedSeats(List<Seat> value) {
    _selectedSeats = value;
  }

  @override
  void initState() {
    super.initState();
    // Ensure selectedSeats is always initialized
    _selectedSeats = <Seat>[];
    if (widget.showTodayOnly) {
      selectedDate = DateTime.now();
    }
  }
  
  @override
  void dispose() {
    _seatUpdateTimer?.cancel();
    super.dispose();
  }
  
  void _startSeatPolling() {
    // DISABLED: Polling is now handled by SeatLayoutWidget
    // This prevents duplicate polling timers
    // SeatLayoutWidget handles its own 10-second polling
    _seatUpdateTimer?.cancel();
  }
  
  void _stopSeatPolling() {
    _seatUpdateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showTodayOnly ? 'Today\'s Availability' : 'Book a Seat'),
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
              setState(() {
                // Force refresh by updating key
                _refreshKey = DateTime.now().millisecondsSinceEpoch;
              });
              ref.invalidate(readingRoomsProvider);
              if (selectedRoom != null) {
                ref.invalidate(roomSeatsProvider(selectedRoom!.id));
              }
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
          tablet: 800,
          desktop: 900,
        ),
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildTimeSelector(),
            const SizedBox(height: 20),
            _buildRoomSelector(),
            // Show seat count prompt FIRST if room/date/time selected but count not entered
            if (selectedRoom != null && 
                selectedDate != null && 
                selectedStartTime != null && 
                selectedEndTime != null && 
                requestedSeatCount == null) ...[
              const SizedBox(height: 20),
              _buildSeatCountPrompt(),
            ],
            // Show seat layout ONLY after seat count is entered
            if (selectedRoom != null && 
                requestedSeatCount != null && 
                requestedSeatCount! > 0) ...[
              const SizedBox(height: 20),
              _buildSelectionStatus(),
              const SizedBox(height: 20),
              _buildSeatSelector(),
            ],
            const SizedBox(height: 20),
            _buildPurposeField(),
            const SizedBox(height: 20),
            _buildNotesField(),
            const SizedBox(height: 30),
            _buildBookButton(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    selectedRoom = null;
                    selectedSeats = <Seat>[];
                    requestedSeatCount = null;
                    _showSeatCountDialog = false;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.grey300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? (selectedDate != null ? DateFormat('EEEE, MMMM d, y').format(selectedDate!) : 'Select a date')
                          : 'Select a date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    'Start Time',
                    selectedStartTime,
                    (time) {
                      setState(() {
                        selectedStartTime = time;
                        selectedSeats = <Seat>[];
                        requestedSeatCount = null;
                        _showSeatCountDialog = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    'End Time',
                    selectedEndTime,
                    (time) {
                      setState(() {
                        selectedEndTime = time;
                        selectedSeats = <Seat>[];
                        requestedSeatCount = null;
                        _showSeatCountDialog = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, Function(TimeOfDay?) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (selectedTime != null) {
          onChanged(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  (time != null && time is TimeOfDay && time.hour != null) 
                      ? time.format(context) 
                      : 'Select time',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Room',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final roomsAsync = ref.watch(readingRoomsProvider);
                
                return roomsAsync.when(
                  data: (rooms) {
                    // Filter to show only Main Library and Study Hall
                    final filteredRooms = rooms.where((room) {
                      final roomName = (room.name ?? '').toLowerCase();
                      return roomName.contains('main library') || 
                             roomName.contains('study hall');
                    }).toList();
                    
                    if (filteredRooms.isEmpty) {
                      return const Text('No rooms available');
                    }
                    
                    return Column(
                      children: filteredRooms.map((room) {
                        return RadioListTile<ReadingRoom>(
                          title: Text(room.name ?? 'Unknown Room'),
                          subtitle: Text('${room.location ?? 'Unknown Location'} • ${room.capacity ?? 0} seats'),
                          value: room,
                          groupValue: selectedRoom,
                          onChanged: (room) {
                            setState(() {
                              selectedRoom = room;
                              selectedSeats = <Seat>[];
                              requestedSeatCount = null;
                              _showSeatCountDialog = false;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                );
              },
            ),
          ],
          ),
      ),
    );
  }

  Widget _buildSeatCountPrompt() {
    return Card(
      child: Padding(
        padding: Responsive.padding(context),
        child: Column(
          children: [
            Icon(
              Icons.event_seat,
              size: Responsive.value(context: context, mobile: 48, tablet: 56, desktop: 64),
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              'How many seats do you want to reserve?',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32)),
            SizedBox(
              width: double.infinity,
              height: Responsive.value(context: context, mobile: 48, tablet: 50, desktop: 56),
              child: ElevatedButton(
                onPressed: () => _showSeatCountInputDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Enter Number of Seats',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeatCountInputDialog() {
    int? tempCount;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                autofocus: true,
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
                    setDialogState(() {
                      tempCount = count;
                    });
                  } else {
                    setDialogState(() {
                      tempCount = null;
                    });
                  }
                },
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
              if (tempCount != null)
                Text(
                  'You can select up to $tempCount seat${tempCount! > 1 ? 's' : ''}',
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
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: tempCount != null && tempCount! > 0
                  ? () {
                      setState(() {
                        requestedSeatCount = tempCount;
                        _showSeatCountDialog = true;
                        selectedSeats = <Seat>[];
                      });
                      Navigator.pop(context);
                      // Start polling for real-time updates
                      _startSeatPolling();
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

  Widget _buildSelectionStatus() {
    // Ensure selectedSeats is always a valid list - defensive check
    List<Seat> seatsList;
    try {
      if (selectedSeats != null && selectedSeats is List) {
        seatsList = List<Seat>.from(selectedSeats as List);
      } else {
        seatsList = <Seat>[];
      }
    } catch (e) {
      seatsList = <Seat>[];
    }
    final remaining = (requestedSeatCount ?? 0) - seatsList.length;
    return Container(
      padding: Responsive.padding(context),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected: ${seatsList.length.toString()} / ${(requestedSeatCount ?? 0).toString()}',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (remaining > 0)
                Text(
                  'Select ${remaining.toString()} more seat${remaining > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12),
                    color: AppTheme.grey600,
                  ),
                ),
            ],
          ),
          if (seatsList.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedSeats = <Seat>[];
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

  Widget _buildSeatSelector() {
    // Wrap entire method in try-catch to handle JS undefined errors
    try {
      if (selectedRoom == null || selectedDate == null || selectedStartTime == null || selectedEndTime == null || requestedSeatCount == null) {
        return const SizedBox.shrink();
      }

      // Extract hour values safely to avoid JS undefined errors
      // These must be declared outside the children list
      int startHour = 0;
      int endHour = 0;
      int roomId = 0;
      int dateMs = 0;
      
      try {
        if (selectedStartTime != null && selectedStartTime is TimeOfDay) {
          final hour = selectedStartTime!.hour;
          startHour = (hour != null && hour is int) ? hour : 0;
        }
      } catch (e) {
        startHour = 0;
      }
      
      try {
        if (selectedEndTime != null && selectedEndTime is TimeOfDay) {
          final hour = selectedEndTime!.hour;
          endHour = (hour != null && hour is int) ? hour : 0;
        }
      } catch (e) {
        endHour = 0;
      }
      
      try {
        if (selectedRoom != null) {
          final id = selectedRoom!.id;
          roomId = (id != null && id is int) ? id : 0;
        }
      } catch (e) {
        roomId = 0;
      }
      
      try {
        if (selectedDate != null) {
          dateMs = selectedDate!.millisecondsSinceEpoch;
        }
      } catch (e) {
        dateMs = 0;
      }
      
      // Build key string safely - explicitly convert all to strings
      final refreshKeyValue = (_refreshKey != null && _refreshKey is int) ? _refreshKey! : 0;
      // Use StringBuffer to avoid any toString() issues in string interpolation
      final keyString = StringBuffer()
        ..write('seats_')
        ..write(roomId.toString())
        ..write('_')
        ..write(dateMs.toString())
        ..write('_')
        ..write(startHour.toString())
        ..write('_')
        ..write(endHour.toString())
        ..write('_')
        ..write(refreshKeyValue.toString())
        ..toString();

    return Card(
      child: Padding(
        padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Select Seat',
              style: TextStyle(
                fontSize: (context != null) ? Responsive.fontSize(context, 18) : 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
            // Legend
            _buildSeatLegend(),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
            // Use a key to force rebuild on refresh - include refresh key for manual refresh
            SeatLayoutWidget(
              key: ValueKey(keyString),
              room: selectedRoom!,
              selectedDate: selectedDate!,
              selectedStartTime: selectedStartTime!,
              selectedEndTime: selectedEndTime!,
              selectedSeats: (selectedSeats != null && selectedSeats is List<Seat>) ? selectedSeats : <Seat>[],
              requestedSeatCount: (requestedSeatCount != null && requestedSeatCount is int) ? requestedSeatCount! : 0,
              onSeatTap: (seat) {
                setState(() {
                  final seatsList = (selectedSeats != null && selectedSeats is List) 
                      ? List<Seat>.from(selectedSeats) 
                      : <Seat>[];
                  final currentSeats = List<Seat>.from(seatsList);
                  final isSelected = currentSeats.any((s) => s.id == seat.id);
                  if (isSelected) {
                    currentSeats.removeWhere((s) => s.id == seat.id);
                  } else {
                    if (currentSeats.length < (requestedSeatCount ?? 0)) {
                      currentSeats.add(seat);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You can only select ${(requestedSeatCount ?? 0).toString()} seat${(requestedSeatCount ?? 0) > 1 ? 's' : ''}',
                          ),
                          backgroundColor: AppTheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                  selectedSeats = currentSeats;
                });
              },
            ),
          ],
        ),
      ),
    );
    } catch (e) {
      // If any error occurs, return empty widget to prevent crash
      print('Error building seat selector: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildSeatLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
      runSpacing: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16),
      children: [
        _buildLegendItem(AppTheme.success, 'Available'),
        _buildLegendItem(AppTheme.error, 'Reserved'),
        _buildLegendItem(AppTheme.primaryColor, 'Selected'),
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

  Widget _buildStudyRoomLayoutForSelection(Map<int, List<Seat>> seatsByTable) {
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
              return _buildTableWidgetForSelection(entry.key, entry.value, 4);
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
              return _buildTableWidgetForSelection(entry.key, entry.value, 2);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLibraryLayoutForSelection(Map<int, List<Seat>> seatsByTable) {
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
              _buildTableWidgetForSelection(entry.key, entry.value, 7),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenericLayoutForSelection(Map<int, List<Seat>> seatsByTable) {
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
              _buildTableWidgetForSelection(entry.key, entry.value, entry.value.length),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableWidgetForSelection(int tableNumber, List<Seat> seats, int seatsPerTable) {
    // Sort seats by position
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
                child: _buildSeatWidgetForSelection(seats[0], seatSize),
              ),
            // Right seat
            if (seats.length > 1)
              Positioned(
                right: 0,
                top: (tableSize - seatSize) / 2,
                child: _buildSeatWidgetForSelection(seats[1], seatSize),
              ),
            // Bottom seat
            if (seats.length > 2)
              Positioned(
                bottom: 0,
                left: (tableSize - seatSize) / 2,
                child: _buildSeatWidgetForSelection(seats[2], seatSize),
              ),
            // Left seat
            if (seats.length > 3)
              Positioned(
                left: 0,
                top: (tableSize - seatSize) / 2,
                child: _buildSeatWidgetForSelection(seats[3], seatSize),
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
                child: _buildSeatWidgetForSelection(seats[0], seatSize),
              ),
            // Right seat
            if (seats.length > 1)
              Positioned(
                right: 0,
                top: (smallTableHeight - seatSize) / 2,
                child: _buildSeatWidgetForSelection(seats[1], seatSize),
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
              children: seats.map((seat) => _buildSeatWidgetForSelection(seat, seatSize)).toList(),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSeatWidgetForSelection(Seat seat, double seatSize) {
    // Ensure selectedSeats is always a valid list - defensive check
    List<Seat> seatsList;
    try {
      if (selectedSeats != null && selectedSeats is List) {
        seatsList = List<Seat>.from(selectedSeats as List);
      } else {
        seatsList = <Seat>[];
      }
    } catch (e) {
      seatsList = <Seat>[];
    }
    final isSelected = seatsList.any((s) => s.id == seat.id);
    final isAvailable = seat.status == 'free' || seat.isAvailableNow;
    final canSelect = isAvailable && (seatsList.length < (requestedSeatCount ?? 0));
    
    Color seatColor;
    Color textColor;
    
    if (isSelected) {
      seatColor = AppTheme.primaryColor; // Blue for selected
      textColor = Colors.white;
    } else if (!isAvailable) {
      seatColor = AppTheme.error; // Red for reserved
      textColor = Colors.white;
    } else if (!canSelect) {
      seatColor = AppTheme.grey300; // Grey when limit reached
      textColor = AppTheme.grey600;
    } else {
      seatColor = AppTheme.success; // Green for available
      textColor = Colors.white;
    }
    
    final iconSize = Responsive.value(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );
    final fontSize = Responsive.fontSize(context, 9);
    
    return GestureDetector(
      onTap: canSelect && isAvailable
          ? () {
              setState(() {
                final currentSeats = List<Seat>.from(selectedSeats ?? <Seat>[]);
                if (isSelected) {
                  currentSeats.removeWhere((s) => s.id == seat.id);
                } else {
                  currentSeats.add(seat);
                }
                selectedSeats = currentSeats;
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

  Widget _buildPurposeField() {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Purpose (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g., Study session, Group work, Exam preparation',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  purpose = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  notes = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    // Ensure selectedSeats is always a valid list - defensive check
    List<Seat> seatsList;
    try {
      if (selectedSeats != null && selectedSeats is List) {
        seatsList = List<Seat>.from(selectedSeats as List);
      } else {
        seatsList = <Seat>[];
      }
    } catch (e) {
      seatsList = <Seat>[];
    }
    
    final canBook = selectedDate != null &&
        selectedStartTime != null &&
        selectedEndTime != null &&
        selectedRoom != null &&
        requestedSeatCount != null &&
        requestedSeatCount! > 0 &&
        seatsList.length > 0 &&
        seatsList.length == requestedSeatCount!;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canBook ? _bookSeat : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Book Seat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<List<Seat>> _getAvailableSeats() async {
    if (selectedRoom == null || selectedDate == null || selectedStartTime == null || selectedEndTime == null) {
      return [];
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedStartTime!.hour,
        selectedStartTime!.minute,
      );
      final endDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedEndTime!.hour,
        selectedEndTime!.minute,
      );

      // Get all seats for the room first (to show table layout)
      final allSeats = await apiService.getRoomSeats(selectedRoom!.id);
      
      // Get available seats for the time period
      final availableSeats = await apiService.getAvailableSeats(
        selectedRoom!.id,
        startDateTime,
        endDateTime,
      );
      
      // Create a set of available seat IDs for quick lookup
      final availableSeatIds = availableSeats.map((s) => s.id).toSet();
      
      // Mark seats as available or reserved
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

  Future<void> _bookSeat() async {
    // Ensure selectedSeats is always a valid list - defensive check
    List<Seat> seatsList;
    try {
      if (selectedSeats != null && selectedSeats is List) {
        seatsList = List<Seat>.from(selectedSeats as List);
      } else {
        seatsList = <Seat>[];
      }
    } catch (e) {
      seatsList = <Seat>[];
    }
    
    if (selectedDate == null ||
        selectedStartTime == null ||
        selectedEndTime == null ||
        selectedRoom == null ||
        seatsList.isEmpty ||
        seatsList.length == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            seatsList.isEmpty 
                ? 'Please select ${requestedSeatCount ?? 0} seat${(requestedSeatCount ?? 0) > 1 ? 's' : ''}'
                : 'Please select all required fields',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (seatsList.length != (requestedSeatCount ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly ${requestedSeatCount ?? 0} seat${(requestedSeatCount ?? 0) > 1 ? 's' : ''}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedStartTime!.hour,
        selectedStartTime!.minute,
      );
      final endDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedEndTime!.hour,
        selectedEndTime!.minute,
      );

      print('Creating reservation with:');
      print('  Room ID: ${selectedRoom!.id}');
      print('  Seat IDs: ${seatsList.map((s) => s.id).toList()}');
      print('  Start Time: $startDateTime');
      print('  End Time: $endDateTime');

      final request = ReservationCreateRequest(
        roomId: selectedRoom!.id,
        seatIds: seatsList.map((s) => s.id).toList(),
        startTime: startDateTime,
        endTime: endDateTime,
        purpose: purpose.isNotEmpty ? purpose : null,
        notes: notes.isNotEmpty ? notes : null,
      );

      print('Request data: ${request.toJson()}');

      final apiService = ref.read(apiServiceProvider);
      final reservation = await apiService.createReservation(request);
      
      print('Reservation created successfully: ${reservation.id}');

      // Refresh the reservations list and rooms
      ref.refresh(userReservationsProvider);
      ref.refresh(readingRoomsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${seatsList.length} seat${seatsList.length > 1 ? 's' : ''} booked successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error booking seats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking seats: $e'),
            backgroundColor: AppTheme.error,
      ),
    );
  }
    }
  }
}