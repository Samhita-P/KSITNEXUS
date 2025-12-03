import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../providers/data_providers.dart';
import '../../models/notification_model.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Notification channels
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _inAppEnabled = true;

  // Notification categories
  bool _complaintUpdates = true;
  bool _studyGroupMessages = true;
  bool _newNotices = true;
  bool _reservationReminders = true;
  bool _feedbackRequests = true;
  bool _generalAnnouncements = true;

  // Timing preferences
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;
  String _timezone = 'Asia/Kolkata';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
              _loadPreferences();
            },
            tooltip: 'Refresh',
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              maxWidth: Responsive.value(
                context: context,
                mobile: double.infinity,
                tablet: 700,
                desktop: 800,
              ),
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                padding: Responsive.padding(context),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Channels
                  _buildSectionHeader(
                    'Notification Channels',
                    'Choose how you want to receive notifications',
                    Icons.notifications,
                  ),
                  const SizedBox(height: 16),
                  _buildChannelCard(),
                  const SizedBox(height: 24),

                  // Notification Categories
                  _buildSectionHeader(
                    'Notification Categories',
                    'Select which types of notifications you want to receive',
                    Icons.category,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(),
                  const SizedBox(height: 24),

                  // Timing Preferences
                  _buildSectionHeader(
                    'Timing Preferences',
                    'Set quiet hours and timezone for notifications',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 16),
                  _buildTimingCard(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildSectionHeader(
                    'Quick Actions',
                    'Manage your notification settings',
                    Icons.settings,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              ),
            ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _pushEnabled,
              onChanged: (value) => setState(() => _pushEnabled = value),
              icon: Icons.phone_android,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailEnabled,
              onChanged: (value) => setState(() => _emailEnabled = value),
              icon: Icons.email,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'SMS Notifications',
              subtitle: 'Receive notifications via SMS',
              value: _smsEnabled,
              onChanged: (value) => setState(() => _smsEnabled = value),
              icon: Icons.sms,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'In-App Notifications',
              subtitle: 'Show notifications within the app',
              value: _inAppEnabled,
              onChanged: (value) => setState(() => _inAppEnabled = value),
              icon: Icons.notifications_active,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Complaint Updates',
              subtitle: 'Updates about your submitted complaints',
              value: _complaintUpdates,
              onChanged: (value) => setState(() => _complaintUpdates = value),
              icon: Icons.report,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Study Group Messages',
              subtitle: 'Messages and updates from your study groups',
              value: _studyGroupMessages,
              onChanged: (value) => setState(() => _studyGroupMessages = value),
              icon: Icons.group,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'New Notices',
              subtitle: 'New notices and announcements',
              value: _newNotices,
              onChanged: (value) => setState(() => _newNotices = value),
              icon: Icons.campaign,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Reservation Reminders',
              subtitle: 'Reminders about your seat reservations',
              value: _reservationReminders,
              onChanged: (value) => setState(() => _reservationReminders = value),
              icon: Icons.bookmark,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Feedback Requests',
              subtitle: 'Requests for faculty feedback',
              value: _feedbackRequests,
              onChanged: (value) => setState(() => _feedbackRequests = value),
              icon: Icons.star,
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'General Announcements',
              subtitle: 'General system announcements and updates',
              value: _generalAnnouncements,
              onChanged: (value) => setState(() => _generalAnnouncements = value),
              icon: Icons.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timezone
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Timezone'),
              subtitle: Text(_timezone),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectTimezone,
            ),
            const Divider(),
            
            // Quiet Hours
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('Quiet Hours'),
              subtitle: Text(_getQuietHoursText()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _setQuietHours,
            ),
            const Divider(),
            
            // Clear Quiet Hours
            if (_quietHoursStart != null || _quietHoursEnd != null)
              ListTile(
                leading: const Icon(Icons.clear, color: AppTheme.error),
                title: const Text('Clear Quiet Hours'),
                subtitle: const Text('Disable quiet hours'),
                onTap: _clearQuietHours,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Mark All as Read'),
              subtitle: const Text('Mark all notifications as read'),
              onTap: _markAllAsRead,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear All Notifications'),
              subtitle: const Text('Delete all notifications'),
              onTap: _clearAllNotifications,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset to Default'),
              subtitle: const Text('Reset all preferences to default'),
              onTap: _resetToDefault,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getQuietHoursText() {
    if (_quietHoursStart == null || _quietHoursEnd == null) {
      return 'Not set';
    }
    return '${_formatTime(_quietHoursStart!)} - ${_formatTime(_quietHoursEnd!)}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load preferences from API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Set default values for now
      setState(() {
        _pushEnabled = true;
        _emailEnabled = true;
        _smsEnabled = false;
        _inAppEnabled = true;
        _complaintUpdates = true;
        _studyGroupMessages = true;
        _newNotices = true;
        _reservationReminders = true;
        _feedbackRequests = true;
        _generalAnnouncements = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preferences: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Save preferences to API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectTimezone() async {
    // TODO: Implement timezone selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timezone selection coming soon')),
    );
  }

  Future<void> _setQuietHours() async {
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: _quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
    );

    if (start != null) {
      final TimeOfDay? end = await showTimePicker(
        context: context,
        initialTime: _quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0),
      );

      if (end != null) {
        setState(() {
          _quietHoursStart = start;
          _quietHoursEnd = end;
        });
      }
    }
  }

  void _clearQuietHours() {
    setState(() {
      _quietHoursStart = null;
      _quietHoursEnd = null;
    });
  }

  void _markAllAsRead() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text('Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear all notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text('Are you sure you want to reset all preferences to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pushEnabled = true;
                _emailEnabled = true;
                _smsEnabled = false;
                _inAppEnabled = true;
                _complaintUpdates = true;
                _studyGroupMessages = true;
                _newNotices = true;
                _reservationReminders = true;
                _feedbackRequests = true;
                _generalAnnouncements = true;
                _quietHoursStart = null;
                _quietHoursEnd = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences reset to default')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
