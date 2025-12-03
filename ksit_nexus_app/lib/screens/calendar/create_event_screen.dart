import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/data_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final CalendarEvent? event;
  final DateTime? selectedDate;

  const CreateEventScreen({
    super.key,
    this.event,
    this.selectedDate,
  });

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _meetingLinkController;
  
  String _eventType = 'event';
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  bool _allDay = false;
  String _color = '#3b82f6';
  bool _isRecurring = false;
  String _recurrencePattern = 'none';
  List<int> _attendeeIds = [];
  List<String> _externalAttendees = [];
  bool _hasReminder = false;
  int _reminderMinutes = 15;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _meetingLinkController = TextEditingController(text: widget.event?.meetingLink ?? '');
    
    // Use selected date if provided, otherwise use event's start time or now
    if (widget.selectedDate != null) {
      _startTime = DateTime(
        widget.selectedDate!.year,
        widget.selectedDate!.month,
        widget.selectedDate!.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
    } else if (widget.event != null) {
      _startTime = widget.event!.startTime;
    }
    
    if (widget.event != null) {
      _eventType = widget.event!.eventType;
      _endTime = widget.event!.endTime;
      _allDay = widget.event!.allDay;
      _color = widget.event!.color;
      _isRecurring = widget.event!.isRecurring;
      _recurrencePattern = widget.event!.recurrencePattern;
      _attendeeIds = widget.event!.attendeeIds ?? [];
      _externalAttendees = widget.event!.externalAttendees ?? [];
      _hasReminder = widget.event!.hasReminder ?? false;
      if (widget.event!.reminders != null && widget.event!.reminders!.isNotEmpty) {
        _reminderMinutes = widget.event!.reminders!.first.minutesBefore;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/calendar');
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: CalendarEvent.eventTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _eventType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Day'),
              trailing: Switch(
                value: _allDay,
                onChanged: (value) {
                  setState(() {
                    _allDay = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_formatDateTime(_startTime)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  if (!_allDay) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  } else {
                    // For all-day events, set to UTC midnight of the selected date
                    setState(() {
                      _startTime = DateTime.utc(date.year, date.month, date.day);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('End Time (Optional)'),
              subtitle: Text(_endTime != null ? _formatDateTime(_endTime!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endTime ?? _startTime,
                  firstDate: _startTime,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  if (!_allDay) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime != null
                          ? TimeOfDay.fromDateTime(_endTime!)
                          : TimeOfDay.fromDateTime(_startTime),
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  } else {
                    // For all-day events, set to UTC midnight of the selected date
                    setState(() {
                      _endTime = DateTime.utc(date.year, date.month, date.day);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reminder'),
              subtitle: _hasReminder
                  ? Text('${_reminderMinutes} minutes before event')
                  : const Text('No reminder'),
              trailing: Switch(
                value: _hasReminder,
                onChanged: (value) {
                  setState(() {
                    _hasReminder = value;
                  });
                },
              ),
            ),
            if (_hasReminder) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  value: _reminderMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Time',
                    border: OutlineInputBorder(),
                  ),
                  items: [0, 5, 15, 30, 60, 120, 1440]
                      .map((minutes) {
                    String label;
                    if (minutes == 0) {
                      label = 'At event time';
                    } else if (minutes < 60) {
                      label = '$minutes minutes before';
                    } else if (minutes == 60) {
                      label = '1 hour before';
                    } else if (minutes == 120) {
                      label = '2 hours before';
                    } else {
                      label = '1 day before';
                    }
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _reminderMinutes = value;
                      });
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meetingLinkController,
              decoration: const InputDecoration(
                labelText: 'Meeting Link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.event == null ? 'Create Event' : 'Update Event'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    if (_allDay) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.user;
      if (currentUser == null || currentUser.id == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to create events')),
          );
        }
        return;
      }

      // Ensure all required String fields have non-null values
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a title')),
          );
        }
        return;
      }
      
      // Ensure all required fields have valid values
      final eventType = _eventType.isNotEmpty ? _eventType : 'event';
      final recurrencePattern = _recurrencePattern.isNotEmpty ? _recurrencePattern : 'none';
      final color = _color.isNotEmpty ? _color : '#3b82f6';
      final timezone = 'UTC';
      // All events are private to the user only
      const privacy = 'private';
      
      // Create reminders data if enabled (will be sent to backend)
      List<EventReminder>? reminders;
      if (_hasReminder) {
        reminders = [
          EventReminder(
            event: widget.event?.id ?? 0, // Will be set by backend after creation
            user: currentUser.id!,
            reminderType: 'notification',
            minutesBefore: _reminderMinutes,
          ),
        ];
      }

      CalendarEvent event;
      try {
        event = CalendarEvent(
          id: widget.event?.id,
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          eventType: eventType,
          startTime: _startTime,
          endTime: _endTime,
          allDay: _allDay,
          timezone: timezone,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          meetingLink: _meetingLinkController.text.trim().isEmpty
              ? null
              : _meetingLinkController.text.trim(),
          isRecurring: _isRecurring,
          recurrencePattern: recurrencePattern,
          color: color,
          privacy: privacy,
          createdBy: currentUser.id!,
          attendeeIds: _attendeeIds.isEmpty ? null : _attendeeIds,
          externalAttendees: _externalAttendees.isEmpty ? null : _externalAttendees,
          reminders: reminders,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating event object: $e')),
          );
        }
        print('Error creating CalendarEvent object: $e');
        print('Title: $title');
        print('EventType: $eventType');
        print('Timezone: $timezone');
        print('RecurrencePattern: $recurrencePattern');
        print('Color: $color');
        print('Privacy: $privacy');
        return;
      }

      try {
        CalendarEvent savedEvent;
        if (widget.event == null) {
          savedEvent = await ref.read(calendarEventsProvider.notifier).createEvent(event);
        } else {
          savedEvent = await ref.read(calendarEventsProvider.notifier).updateEvent(widget.event!.id!, event);
        }

        // Schedule notification if reminder is enabled
        if (_hasReminder && savedEvent.id != null) {
          try {
            await NotificationService.scheduleEventReminder(
              savedEvent,
              minutesBefore: _reminderMinutes,
            );
            print('📅 Reminder scheduled for event ${savedEvent.id}');
          } catch (e) {
            print('📅 Error scheduling reminder: $e');
            // Don't fail the event creation if reminder scheduling fails
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving event: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
        }
        print('Error saving event: $e');
        rethrow;
      }

      if (context.mounted) {
        // Force refresh the calendar before popping
        try {
          await ref.read(calendarEventsProvider.notifier).refreshEvents();
          print('📅 Calendar refreshed after event creation');
        } catch (e) {
          print('📅 Error refreshing calendar: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null
                ? 'Event created successfully'
                : 'Event updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a bit to ensure state updates, then pop
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (context.mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

