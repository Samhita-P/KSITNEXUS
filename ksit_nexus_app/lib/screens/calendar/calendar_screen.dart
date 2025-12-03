import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/calendar_service.dart';
import '../../services/api_service.dart';
import '../../models/calendar_event_model.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';
import 'google_calendar_settings_screen.dart';

enum CalendarView { month, week, day, list }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with WidgetsBindingObserver {
  CalendarView _currentView = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _selectedFilter = 'all';
  String? _selectedEventType;
  bool _showCancelled = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh events when app comes back to foreground
      ref.read(calendarEventsProvider.notifier).refreshEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
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
              ref.read(calendarEventsProvider.notifier).refreshEvents();
            },
            tooltip: 'Refresh',
          ),
          // View switcher
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Change view',
            onSelected: (view) {
              setState(() {
                _currentView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week),
                    SizedBox(width: 8),
                    Text('Week'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Day'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.list,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('List'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter events',
          ),
          IconButton(
            onPressed: _exportICal,
            icon: const Icon(Icons.download),
            tooltip: 'Export iCal',
          ),
          IconButton(
            onPressed: () => context.push('/calendar/google-settings'),
            icon: const Icon(Icons.sync),
            tooltip: 'Google Calendar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Calendar view
          Expanded(
            child: _buildCalendarView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEvent,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarView() {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return eventsAsync.when(
      data: (events) {
        // Debug: Print all events
        print('📅 Total events loaded: ${events.length}');
        for (final event in events) {
          print('  Event: ${event.title} - Date: ${event.startTime} (UTC: ${event.startTime.toUtc()})');
        }
        final filteredEvents = _filterEvents(events);
        print('📅 Filtered events: ${filteredEvents.length}');
        final eventsByDate = _groupEventsByDate(filteredEvents);
        // Debug: Print grouped events
        print('📅 Events grouped by date:');
        eventsByDate.forEach((date, eventList) {
          print('  ${date.toString().substring(0, 10)}: ${eventList.length} events');
        });

        switch (_currentView) {
          case CalendarView.month:
            return _buildMonthView(eventsByDate);
          case CalendarView.week:
            return _buildWeekView(eventsByDate);
          case CalendarView.day:
            return _buildDayView(eventsByDate);
          case CalendarView.list:
            return _buildListView(filteredEvents);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorDisplayWidget(
        message: error.toString(),
        onRetry: () {
          ref.read(calendarEventsProvider.notifier).loadEvents();
        },
      ),
    );
  }

  Widget _buildMonthView(Map<DateTime, List<CalendarEvent>> eventsByDate) {
    return TableCalendar<CalendarEvent>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        // Normalize day - TableCalendar passes UTC dates representing the calendar date
        // Extract date components directly (day is already the correct calendar date in UTC)
        final normalizedDay = DateTime.utc(day.year, day.month, day.day);
        final events = eventsByDate[normalizedDay] ?? [];
        if (events.isNotEmpty) {
          print('📅 eventLoader: Found ${events.length} event(s) for ${normalizedDay.toString().substring(0, 10)}');
          for (final event in events) {
            print('   - ${event.title}');
          }
        }
        return events;
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: Colors.grey[600]),
        selectedDecoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.accentBlue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: AppTheme.error,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 6,
        // Make days with events more visible
        defaultTextStyle: const TextStyle(),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: const Icon(Icons.chevron_left),
        rightChevronIcon: const Icon(Icons.chevron_right),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        // Show events for selected day
        _showDayEvents(selectedDay, eventsByDate);
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, events) {
          // Make days with events more visible - add border or bold text
          // Normalize date - TableCalendar passes UTC dates representing the calendar date
          // Extract date components directly
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          final dayEvents = eventsByDate[normalizedDate] ?? [];
          final hasEvents = dayEvents.isNotEmpty;
          final isSelected = isSameDay(_selectedDay, date);
          final isToday = isSameDay(DateTime.now(), date);
          
          // Build decoration based on state
          BoxDecoration? decoration;
          Color? textColor;
          
          if (isSelected) {
            decoration = BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            );
            textColor = Colors.white;
          } else if (isToday) {
            decoration = BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.3),
              shape: BoxShape.circle,
            );
            textColor = AppTheme.primaryColor;
          } else if (hasEvents) {
            // Highlight dates with events with a circular border
            decoration = BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2.5,
              ),
              color: AppTheme.primaryColor.withOpacity(0.1),
            );
            textColor = AppTheme.primaryColor;
          }
          
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: decoration,
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
                  fontSize: hasEvents ? 16 : 14,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
          );
        },
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: events.take(3).map((event) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: _parseColor(event.color),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekView(Map<DateTime, List<CalendarEvent>> eventsByDate) {
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Column(
      children: [
        // Week navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                  });
                },
              ),
              Text(
                '${DateFormat('MMM d', 'en_US').format(weekDays.first)} - ${DateFormat('MMM d, yyyy', 'en_US').format(weekDays.last)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),
        // Week grid
        Expanded(
          child: Row(
            children: weekDays.map((day) {
              // Normalize day to UTC midnight for consistent comparison
              // Convert to local time first to match how events are grouped
              final localDay = day.toLocal();
              final normalizedDay = DateTime.utc(localDay.year, localDay.month, localDay.day);
              final dayEvents = eventsByDate[normalizedDay] ?? [];
              final isSelected = isSameDay(_selectedDay, day);
              final isToday = isSameDay(DateTime.now(), day);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isToday ? AppTheme.accentBlue.withOpacity(0.1) : null,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE', 'en_US').format(day),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primaryColor : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(4),
                            itemCount: dayEvents.length > 3 ? 3 : dayEvents.length,
                            itemBuilder: (context, index) {
                              final event = dayEvents[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _parseColor(event.color).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _parseColor(event.color),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  event.title,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        if (dayEvents.length > 3)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              '+${dayEvents.length - 3} more',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(Map<DateTime, List<CalendarEvent>> eventsByDate) {
    // Normalize selected day to UTC midnight for consistent comparison
    // Convert to local time first to match how events are grouped
    final localDay = _selectedDay.toLocal();
    final normalizedDay = DateTime.utc(localDay.year, localDay.month, localDay.day);
    final dayEvents = eventsByDate[normalizedDay] ?? [];

    return Column(
      children: [
        // Day navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.subtract(const Duration(days: 1));
                    _focusedDay = _selectedDay;
                  });
                },
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy', 'en_US').format(_selectedDay),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(days: 1));
                    _focusedDay = _selectedDay;
                  });
                },
              ),
            ],
          ),
        ),
        // Day events
        Expanded(
          child: dayEvents.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.event_busy,
                  title: 'No Events',
                  message: 'No events scheduled for this day.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(dayEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListView(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_today,
        title: 'No Events',
        message: 'You don\'t have any events yet. Create one to get started!',
        action: ElevatedButton(
          onPressed: _createEvent,
          child: const Text('Create Event'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(calendarEventsProvider.notifier).refreshEvents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
      ),
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByDate(List<CalendarEvent> events) {
    final Map<DateTime, List<CalendarEvent>> grouped = {};
    print('📅 Grouping ${events.length} events by date...');
    for (final event in events) {
      // Group events by their calendar date (local date)
      // Convert event time to local first to get the correct calendar date
      // Then normalize to UTC midnight for consistent comparison with TableCalendar dates
      final localTime = event.startTime.toLocal();
      final date = DateTime.utc(localTime.year, localTime.month, localTime.day);
      print('  📅 Event "${event.title}"');
      print('     Original: ${event.startTime} (isUtc: ${event.startTime.isUtc})');
      print('     Local time: ${localTime}');
      print('     Normalized date key: ${date.toString().substring(0, 10)}');
      grouped.putIfAbsent(date, () => []).add(event);
    }
    print('📅 Grouped into ${grouped.length} dates');
    for (final entry in grouped.entries) {
      print('   ${entry.key.toString().substring(0, 10)}: ${entry.value.length} event(s)');
    }
    return grouped;
  }

  List<CalendarEvent> _filterEvents(List<CalendarEvent> events) {
    return events.where((event) {
      // Filter by cancelled status
      if (!_showCancelled && event.isCancelled) {
        return false;
      }

      // Filter by event type
      if (_selectedEventType != null && event.eventType != _selectedEventType) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            (event.description == null || !event.description!.toLowerCase().contains(query)) &&
            (event.location == null || !event.location!.toLowerCase().contains(query))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (event.id != null) {
            context.push('/calendar/events/${event.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(event.color),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.eventTypeDisplay ?? event.eventType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cancelled',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(event.startTime, event.allDay),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (event.endTime != null) ...[
                    const Text(' - '),
                    Text(
                      _formatDateTime(event.endTime!, event.allDay),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  String _formatDateTime(DateTime dateTime, bool allDay) {
    if (allDay) {
      return DateFormat('yyyy-MM-dd', 'en_US').format(dateTime);
    }
    return DateFormat('yyyy-MM-dd HH:mm', 'en_US').format(dateTime);
  }

  void _createEvent() {
    // Pass the selected date to the create event screen
    context.push(
      '/calendar/events/create',
      extra: {'selectedDate': _selectedDay},
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...CalendarEvent.eventTypes.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedEventType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Cancelled Events'),
              value: _showCancelled,
              onChanged: (value) {
                setState(() {
                  _showCancelled = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedEventType = null;
                _showCancelled = false;
                _searchQuery = '';
              });
              Navigator.of(context).pop();
              ref.read(calendarEventsProvider.notifier).loadEvents();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(calendarEventsProvider.notifier).loadEvents();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportICal() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final icalContent = await apiService.exportICal();
      // TODO: Implement file download
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('iCal file exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting iCal: $e')),
        );
      }
    }
  }

  void _showDayEvents(DateTime day, Map<DateTime, List<CalendarEvent>> eventsByDate) {
    // Normalize day - TableCalendar passes UTC dates representing the calendar date
    // Extract date components directly (day is already the correct calendar date in UTC)
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final dayEvents = eventsByDate[normalizedDay] ?? [];
    
    print('📅 Showing day events for:');
    print('   Original day: $day (isUtc: ${day.isUtc})');
    print('   Normalized day: $normalizedDay');
    print('   Events found: ${dayEvents.length}');
    print('   Available dates in eventsByDate:');
    for (final key in eventsByDate.keys) {
      print('     - ${key.toString().substring(0, 10)}: ${eventsByDate[key]!.length} event(s)');
      for (final event in eventsByDate[key]!) {
        print('       * ${event.title} - ${event.startTime} (local: ${event.startTime.toLocal()})');
      }
    }
    
    if (dayEvents.isEmpty) {
      // Show message that there are no events
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No events on ${DateFormat('MMMM d, yyyy').format(day)}'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Show bottom sheet with events for the day
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(day),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Events list
            Expanded(
              child: dayEvents.length == 1
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildEventCard(dayEvents.first),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEventCard(dayEvents[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
