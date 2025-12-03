/// Notification tiers screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_widget.dart' as error_widget;
import '../../widgets/empty_state.dart';

final appLogger = Logger('NotificationTiersScreen');

class NotificationTiersScreen extends ConsumerStatefulWidget {
  const NotificationTiersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationTiersScreen> createState() => _NotificationTiersScreenState();
}

class _NotificationTiersScreenState extends ConsumerState<NotificationTiersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _tiers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tiers = await _apiService.getTiers();
      setState(() {
        _tiers = tiers;
      });
    } catch (e) {
      appLogger.error('Error loading tiers: $e');
      setState(() {
        _error = 'Failed to load tiers';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTier() async {
    // Show dialog to create tier
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateTierDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.createTier(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tier created successfully')),
          );
          await _loadTiers();
        }
      } catch (e) {
        appLogger.error('Error creating tier: $e');
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
  }

  Future<void> _updateTier(int id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateTier(id, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tier updated successfully')),
        );
        await _loadTiers();
      }
    } catch (e) {
      appLogger.error('Error updating tier: $e');
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

  Future<void> _deleteTier(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tier'),
        content: const Text('Are you sure you want to delete this tier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.deleteTier(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tier deleted successfully')),
          );
          await _loadTiers();
        }
      } catch (e) {
        appLogger.error('Error deleting tier: $e');
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
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'essential':
        return Colors.red;
      case 'important':
        return Colors.orange;
      case 'optional':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Tiers'),
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
              _loadTiers();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTier,
            tooltip: 'Create Tier',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _error != null
            ? error_widget.ErrorDisplayWidget(
                message: _error!,
                onRetry: _loadTiers,
              )
            : _tiers.isEmpty
                ? EmptyStateWidget(
                    message: 'No tiers configured',
                    icon: Icons.layers,
                    action: ElevatedButton.icon(
                      onPressed: _createTier,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Tier'),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tiers.length,
                    itemBuilder: (context, index) {
                      final tier = _tiers[index];
                      final tierName = tier['tier'] ?? 'important';
                      final tierDisplay = tier['tier_display'] ?? tierName;
                      final notificationTypes = tier['notification_types'] as List<dynamic>? ?? [];
                      final pushEnabled = tier['push_enabled'] ?? true;
                      final emailEnabled = tier['email_enabled'] ?? true;
                      final escalationEnabled = tier['escalation_enabled'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTierColor(tierName),
                            child: Text(
                              tierDisplay[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            tierDisplay,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${notificationTypes.length} notification type(s)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (notificationTypes.isNotEmpty)
                                Text(
                                  notificationTypes.join(', '),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Row(
                                children: [
                                  if (pushEnabled)
                                    Chip(
                                      label: const Text('Push'),
                                      labelStyle: const TextStyle(fontSize: 10),
                                    ),
                                  if (emailEnabled)
                                    Chip(
                                      label: const Text('Email'),
                                      labelStyle: const TextStyle(fontSize: 10),
                                    ),
                                  if (escalationEnabled)
                                    Chip(
                                      label: const Text('Escalate'),
                                      labelStyle: const TextStyle(fontSize: 10),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                // TODO: Implement edit tier
                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => _CreateTierDialog(),
                                );
                                if (result != null) {
                                  await _updateTier(tier['id'], result);
                                }
                              } else if (value == 'delete') {
                                await _deleteTier(tier['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _CreateTierDialog extends StatefulWidget {
  @override
  State<_CreateTierDialog> createState() => _CreateTierDialogState();
}

class _CreateTierDialogState extends State<_CreateTierDialog> {
  final _formKey = GlobalKey<FormState>();
  String _tier = 'important';
  List<String> _selectedTypes = [];
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _inAppEnabled = true;
  bool _escalationEnabled = false;

  final List<String> _notificationTypes = [
    'complaint',
    'study_group',
    'notice',
    'reservation',
    'feedback',
    'announcement',
    'general',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Notification Tier'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tier,
                decoration: const InputDecoration(labelText: 'Tier'),
                items: const [
                  DropdownMenuItem(value: 'essential', child: Text('Essential')),
                  DropdownMenuItem(value: 'important', child: Text('Important')),
                  DropdownMenuItem(value: 'optional', child: Text('Optional')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tier = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Notification Types:'),
              Wrap(
                spacing: 8,
                children: _notificationTypes.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Push Enabled'),
                value: _pushEnabled,
                onChanged: (value) => setState(() => _pushEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Email Enabled'),
                value: _emailEnabled,
                onChanged: (value) => setState(() => _emailEnabled = value),
              ),
              SwitchListTile(
                title: const Text('SMS Enabled'),
                value: _smsEnabled,
                onChanged: (value) => setState(() => _smsEnabled = value),
              ),
              SwitchListTile(
                title: const Text('In-App Enabled'),
                value: _inAppEnabled,
                onChanged: (value) => setState(() => _inAppEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Escalation Enabled'),
                value: _escalationEnabled,
                onChanged: (value) => setState(() => _escalationEnabled = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                {
                  'tier': _tier,
                  'notification_types': _selectedTypes,
                  'push_enabled': _pushEnabled,
                  'email_enabled': _emailEnabled,
                  'sms_enabled': _smsEnabled,
                  'in_app_enabled': _inAppEnabled,
                  'escalation_enabled': _escalationEnabled,
                },
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

