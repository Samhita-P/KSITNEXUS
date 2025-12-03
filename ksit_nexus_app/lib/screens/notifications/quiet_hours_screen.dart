/// Quiet hours settings screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/quiet_hours_service.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_widget.dart' as error_widget;

final appLogger = Logger('QuietHoursScreen');

class QuietHoursScreen extends ConsumerStatefulWidget {
  const QuietHoursScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends ConsumerState<QuietHoursScreen> {
  final ApiService _apiService = ApiService();
  final QuietHoursService _quietHoursService = QuietHoursService();
  
  bool _isLoading = false;
  bool _isEnabled = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuietHours();
  }

  Future<void> _loadQuietHours() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _quietHoursService.init();
      final status = await _apiService.getQuietHoursStatus();
      
      setState(() {
        _isEnabled = status['quiet_hours_enabled'] ?? false;
        if (status['quiet_hours_start'] != null) {
          final start = _parseTime(status['quiet_hours_start']);
          _startTime = start;
        }
        if (status['quiet_hours_end'] != null) {
          final end = _parseTime(status['quiet_hours_end']);
          _endTime = end;
        }
      });
    } catch (e) {
      appLogger.error('Error loading quiet hours: $e');
      setState(() {
        _error = 'Failed to load quiet hours settings';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      // Parse ISO time string (HH:MM:SS or HH:MM)
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      appLogger.error('Error parsing time: $e');
    }
    return null;
  }

  Future<void> _selectStartTime() async {
    final initialTime = _startTime ?? const TimeOfDay(hour: 22, minute: 0);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        _startTime = selectedTime;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final initialTime = _endTime ?? const TimeOfDay(hour: 6, minute: 0);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        _endTime = selectedTime;
      });
    }
  }

  Future<void> _saveQuietHours() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.setQuietHours(
        startHour: _startTime!.hour,
        startMinute: _startTime!.minute,
        endHour: _endTime!.hour,
        endMinute: _endTime!.minute,
      );

      await _quietHoursService.setQuietHours(
        startHour: _startTime!.hour,
        startMinute: _startTime!.minute,
        endHour: _endTime!.hour,
        endMinute: _endTime!.minute,
      );

      await _quietHoursService.enable();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiet hours saved successfully')),
        );
        setState(() {
          _isEnabled = true;
        });
      }
    } catch (e) {
      appLogger.error('Error saving quiet hours: $e');
      setState(() {
        _error = 'Failed to save quiet hours settings';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disableQuietHours() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.disableQuietHours();
      await _quietHoursService.disable();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiet hours disabled successfully')),
        );
        setState(() {
          _isEnabled = false;
        });
      }
    } catch (e) {
      appLogger.error('Error disabling quiet hours: $e');
      setState(() {
        _error = 'Failed to disable quiet hours';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiet Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/notifications');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadQuietHours();
            },
            tooltip: 'Refresh',
          ),
          if (_isEnabled)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _disableQuietHours,
              tooltip: 'Disable quiet hours',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? error_widget.ErrorDisplayWidget(
                message: _error!,
                onRetry: _loadQuietHours,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiet Hours',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set times when you don\'t want to receive notifications. Urgent and high priority notifications will still be delivered.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Enable Quiet Hours'),
                              value: _isEnabled,
                              onChanged: (value) {
                                if (value) {
                                  if (_startTime == null || _endTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please set start and end times first'),
                                      ),
                                    );
                                    return;
                                  }
                                  _saveQuietHours();
                                } else {
                                  _disableQuietHours();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Schedule',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('Start Time'),
                              subtitle: Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : 'Not set',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap: _selectStartTime,
                            ),
                            ListTile(
                              title: const Text('End Time'),
                              subtitle: Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : 'Not set',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap: _selectEndTime,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _saveQuietHours,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Quiet Hours'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Quiet hours apply to medium and low priority notifications only\n'
                              '• Urgent and high priority notifications will always be delivered\n'
                              '• Notifications received during quiet hours will be delivered after quiet hours end',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

