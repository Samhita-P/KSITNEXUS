import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class SelectiveSyncScreen extends ConsumerStatefulWidget {
  const SelectiveSyncScreen({super.key});

  @override
  ConsumerState<SelectiveSyncScreen> createState() => _SelectiveSyncScreenState();
}

class _SelectiveSyncScreenState extends ConsumerState<SelectiveSyncScreen> {
  static const String _syncSettingsKey = 'selective_sync_settings';
  
  final Map<String, bool> _syncSettings = {
    'notifications': true,
    'complaints': true,
    'reservations': true,
    'study_groups': true,
    'notices': true,
    'feedback': true,
    'chat_messages': true,
    'user_profile': true,
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_syncSettingsKey);
      
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(
          jsonDecode(settingsJson),
        );
        
        setState(() {
          _syncSettings.updateAll((key, value) => settings[key] ?? value);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sync settings: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSyncSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _syncSettingsKey,
        jsonEncode(_syncSettings),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sync settings: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSyncSetting(String key) {
    setState(() {
      _syncSettings[key] = !_syncSettings[key]!;
    });
    _saveSyncSettings();
  }

  void _toggleAllSettings(bool enabled) {
    setState(() {
      _syncSettings.updateAll((key, value) => enabled);
    });
    _saveSyncSettings();
  }

  String _getModuleDisplayName(String key) {
    switch (key) {
      case 'notifications':
        return 'Notifications';
      case 'complaints':
        return 'Complaints';
      case 'reservations':
        return 'Reservations';
      case 'study_groups':
        return 'Study Groups';
      case 'notices':
        return 'Notices';
      case 'feedback':
        return 'Feedback';
      case 'chat_messages':
        return 'Chat Messages';
      case 'user_profile':
        return 'User Profile';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getModuleDescription(String key) {
    switch (key) {
      case 'notifications':
        return 'Sync notifications and alerts';
      case 'complaints':
        return 'Sync complaint submissions and updates';
      case 'reservations':
        return 'Sync seat and room reservations';
      case 'study_groups':
        return 'Sync study group data and memberships';
      case 'notices':
        return 'Sync notice board updates';
      case 'feedback':
        return 'Sync faculty feedback submissions';
      case 'chat_messages':
        return 'Sync study group chat messages';
      case 'user_profile':
        return 'Sync your profile information';
      default:
        return 'Sync this module\'s data';
    }
  }

  IconData _getModuleIcon(String key) {
    switch (key) {
      case 'notifications':
        return Icons.notifications;
      case 'complaints':
        return Icons.report_problem;
      case 'reservations':
        return Icons.event_seat;
      case 'study_groups':
        return Icons.group;
      case 'notices':
        return Icons.notifications_active;
      case 'feedback':
        return Icons.star;
      case 'chat_messages':
        return Icons.chat;
      case 'user_profile':
        return Icons.person;
      default:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selective Sync'),
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
          TextButton(
            onPressed: _isLoading ? null : () => _toggleAllSettings(true),
            child: const Text(
              'Enable All',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _toggleAllSettings(false),
            child: const Text(
              'Disable All',
              style: TextStyle(color: Colors.white),
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
                tablet: 800,
                desktop: 900,
              ),
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                padding: Responsive.padding(context),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sync,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Selective Sync Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose which modules to keep synchronized when offline. '
                            'Disabled modules will not sync data and may not be available offline.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sync Settings
                  Card(
                    child: Column(
                      children: _syncSettings.entries.map((entry) {
                        final key = entry.key;
                        final isEnabled = entry.value;
                        
                        return ListTile(
                          leading: Icon(
                            _getModuleIcon(key),
                            color: isEnabled ? AppTheme.primaryColor : Colors.grey,
                          ),
                          title: Text(
                            _getModuleDisplayName(key),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isEnabled ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            _getModuleDescription(key),
                            style: TextStyle(
                              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: _isLoading ? null : (_) => _toggleSyncSetting(key),
                            activeColor: AppTheme.primaryColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sync Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sync Statistics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Enabled',
                                  _syncSettings.values.where((v) => v).length.toString(),
                                  Colors.green,
                                  Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Disabled',
                                  _syncSettings.values.where((v) => !v).length.toString(),
                                  Colors.red,
                                  Icons.cancel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sync Tips
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sync Tips',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Enable essential modules like Notifications and User Profile for best experience\n'
                            '• Disable modules you rarely use to save storage and bandwidth\n'
                            '• Chat Messages can be disabled if you don\'t need offline chat history\n'
                            '• Changes take effect on next sync cycle\n'
                            '• You can always change these settings later',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
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

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
