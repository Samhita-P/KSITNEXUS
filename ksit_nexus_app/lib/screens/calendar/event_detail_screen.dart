import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/calendar_service.dart';
import '../../models/calendar_event_model.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(calendarEventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
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
              ref.invalidate(calendarEventDetailProvider(eventId));
              ref.read(calendarEventsProvider.notifier).refreshEvents();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              eventAsync.whenData((event) {
                if (event.id != null) {
                  context.push('/calendar/events/${event.id}/edit', extra: event);
                }
              });
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit event',
          ),
          IconButton(
            onPressed: () {
              _showDeleteDialog(context, ref);
            },
            icon: const Icon(Icons.delete),
            tooltip: 'Delete event',
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) => _buildEventDetails(context, ref, event),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading event: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(calendarEventDetailProvider(eventId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, WidgetRef ref, CalendarEvent event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _parseColor(event.color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.eventTypeDisplay ?? event.eventType,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            context,
            Icons.access_time,
            'Start Time',
            _formatDateTime(event.startTime, event.allDay),
          ),
          if (event.endTime != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.access_time,
              'End Time',
              _formatDateTime(event.endTime!, event.allDay),
            ),
          ],
          if (event.location != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.location_on,
              'Location',
              event.location!,
            ),
          ],
          if (event.meetingLink != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.link,
              'Meeting Link',
              event.meetingLink!,
              onTap: () {
                // TODO: Open meeting link
              },
            ),
          ],
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.description,
              'Description',
              event.description!,
            ),
          ],
          if (event.attendeesDetails != null && event.attendeesDetails!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.people,
              'Attendees',
              '${event.attendeesDetails!.length} attendee(s)',
            ),
          ],
          if (event.isRecurring) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.repeat,
              'Recurrence',
              event.recurrencePattern,
            ),
          ],
          const SizedBox(height: 24),
          if (!event.isCancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _cancelEvent(context, ref, event);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel Event'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(calendarEventsProvider.notifier).deleteEvent(eventId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _cancelEvent(BuildContext context, WidgetRef ref, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text('Are you sure you want to cancel this event?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(calendarEventsProvider.notifier).cancelEvent(event.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event cancelled successfully')),
                  );
                  ref.invalidate(calendarEventDetailProvider(eventId));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling event: $e')),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

