import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/two_factor_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';

class DeviceSessionsScreen extends ConsumerStatefulWidget {
  const DeviceSessionsScreen({super.key});

  @override
  ConsumerState<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends ConsumerState<DeviceSessionsScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final sessions = await _twoFactorService.getActiveSessions();
      
      // If no sessions found, try to create one for current device
      if (sessions.isEmpty) {
        try {
          await _twoFactorService.createCurrentDeviceSession();
          // Reload sessions after creating one
          final updatedSessions = await _twoFactorService.getActiveSessions();
          setState(() {
            _sessions = updatedSessions;
            if (updatedSessions.isNotEmpty) {
              _currentSessionId = updatedSessions.first['id'].toString();
            }
          });
        } catch (createError) {
          print('Could not create device session: $createError');
          setState(() {
            _sessions = sessions;
          });
        }
      } else {
        setState(() {
          _sessions = sessions;
          // Assume the first session is the current one (you might want to track this differently)
          if (sessions.isNotEmpty) {
            _currentSessionId = sessions.first['id'].toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deactivateSession(int sessionId) async {
    setState(() => _isLoading = true);
    
    try {
      await _twoFactorService.deactivateSession(sessionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deactivated successfully')),
        );
        _loadSessions(); // Reload sessions
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deactivating session: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logoutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout All Devices'),
        content: const Text(
          'This will log you out from all devices except this one. '
          'You will need to log in again on other devices. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      final result = await _twoFactorService.logoutAllDevices(
        _currentSessionId != null ? int.tryParse(_currentSessionId!) : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Logged out from all devices')),
        );
        _loadSessions(); // Reload sessions
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out all devices: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    try {
      final DateTime dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(dt);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet_android;
      case 'desktop':
        return Icons.desktop_windows;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Sessions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_sessions.length > 1)
            TextButton(
              onPressed: _isLoading ? null : _logoutAllDevices,
              child: const Text(
                'Logout All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading && _sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              maxWidth: Responsive.value(
                context: context,
                mobile: double.infinity,
                tablet: double.infinity,
                desktop: 1200,
              ),
              padding: EdgeInsets.zero,
              centerContent: false,
              child: RefreshIndicator(
                onRefresh: _loadSessions,
                child: _sessions.isEmpty
                  ? const Center(
                      child: Text('No active sessions found'),
                    )
                  : ListView.builder(
                      padding: Responsive.padding(context),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isCurrentSession = session['id'].toString() == _currentSessionId;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrentSession 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey[300],
                              child: Icon(
                                _getDeviceIcon(session['device_type'] ?? 'unknown'),
                                color: isCurrentSession ? Colors.white : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              session['device_name'] ?? 'Unknown Device',
                              style: TextStyle(
                                fontWeight: isCurrentSession ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${session['device_type']?.toString().toUpperCase() ?? 'UNKNOWN'} • ${session['ip_address'] ?? 'Unknown IP'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last active: ${_formatDateTime(session['last_activity'])}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                if (isCurrentSession) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'CURRENT DEVICE',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isCurrentSession
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.red),
                                    onPressed: _isLoading
                                        ? null
                                        : () => _deactivateSession(session['id']),
                                    tooltip: 'Deactivate this session',
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            ),
    );
  }
}
