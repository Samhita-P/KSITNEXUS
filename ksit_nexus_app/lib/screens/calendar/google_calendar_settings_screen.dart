import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/calendar_service.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../providers/data_providers.dart';

class GoogleCalendarSettingsScreen extends ConsumerStatefulWidget {
  const GoogleCalendarSettingsScreen({super.key});

  @override
  ConsumerState<GoogleCalendarSettingsScreen> createState() => _GoogleCalendarSettingsScreenState();
}

class _GoogleCalendarSettingsScreenState extends ConsumerState<GoogleCalendarSettingsScreen> {
  bool _isConnecting = false;
  String? _authorizationUrl;
  String? _state;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    await ref.read(googleCalendarSyncProvider.notifier).loadSyncStatus();
  }

  Future<void> _connectGoogleCalendar() async {
    try {
      setState(() {
        _isConnecting = true;
      });

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getGoogleCalendarAuthorizationUrl();
      
      setState(() {
        _authorizationUrl = response['authorization_url'] as String?;
        _state = response['state'] as String?;
      });

      if (_authorizationUrl != null) {
        // Launch browser for OAuth
        final uri = Uri.parse(_authorizationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show dialog to enter authorization code
          if (mounted) {
            _showAuthorizationCodeDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch browser')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _showAuthorizationCodeDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Authorization Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'After authorizing, you will receive an authorization code. Please enter it below:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'Enter the code from Google',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                await _handleAuthorizationCode(code);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuthorizationCode(String code) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      final syncNotifier = ref.read(googleCalendarSyncProvider.notifier);
      await syncNotifier.connect(code, state: _state);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Calendar connected successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Calendar?'),
        content: const Text('Are you sure you want to disconnect your Google Calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(googleCalendarSyncProvider.notifier).disconnect();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Calendar disconnected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error disconnecting: $e')),
          );
        }
      }
    }
  }

  Future<void> _syncGoogleCalendar({String syncDirection = 'bidirectional'}) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      final syncNotifier = ref.read(googleCalendarSyncProvider.notifier);
      final events = await syncNotifier.sync(syncDirection: syncDirection);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced ${events.length} events')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(googleCalendarSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Settings'),
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
              ref.invalidate(googleCalendarSyncProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : syncStatusAsync.when(
              data: (syncStatus) {
                final isConnected = syncStatus?.isConnected ?? false;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isConnected ? Icons.check_circle : Icons.cancel,
                                    color: isConnected ? AppTheme.success : AppTheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isConnected ? 'Connected' : 'Not Connected',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (syncStatus != null && isConnected) ...[
                                const SizedBox(height: 16),
                                _buildInfoRow('Last Sync', syncStatus.lastSyncAt != null
                                    ? _formatDateTime(syncStatus.lastSyncAt!)
                                    : 'Never'),
                                _buildInfoRow('Sync Direction', syncStatus.syncDirection ?? 'Bidirectional'),
                                _buildInfoRow('Sync Enabled', syncStatus.syncEnabled ? 'Yes' : 'No'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isConnected)
                        ElevatedButton.icon(
                          onPressed: _connectGoogleCalendar,
                          icon: const Icon(Icons.link),
                          label: const Text('Connect Google Calendar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: () => _syncGoogleCalendar(syncDirection: 'bidirectional'),
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Now (Bidirectional)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _syncGoogleCalendar(syncDirection: 'from_google'),
                          icon: const Icon(Icons.download),
                          label: const Text('Import from Google Calendar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _syncGoogleCalendar(syncDirection: 'to_google'),
                          icon: const Icon(Icons.upload),
                          label: const Text('Export to Google Calendar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _disconnectGoogleCalendar,
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSyncStatus,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}


