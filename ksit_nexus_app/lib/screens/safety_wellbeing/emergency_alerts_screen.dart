import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/safety_wellbeing_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';
import 'package:go_router/go_router.dart';

final emergencyAlertsProvider = FutureProvider.family<List<EmergencyAlert>, String?>((ref, status) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getEmergencyAlerts(status: status);
});

class EmergencyAlertsScreen extends ConsumerStatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  ConsumerState<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends ConsumerState<EmergencyAlertsScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(emergencyAlertsProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/safety');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(emergencyAlertsProvider(_selectedStatus));
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            tooltip: 'Manage Emergency Contacts',
            onPressed: () => _showManageContactsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.warning,
              title: 'No Emergency Alerts',
              message: 'No emergency alerts found.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(emergencyAlertsProvider(_selectedStatus));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(context, alert);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(emergencyAlertsProvider(_selectedStatus));
          },
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, EmergencyAlert alert) {
    Color severityColor;
    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: severityColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                Chip(
                  label: Text(alert.status.toUpperCase()),
                  backgroundColor: alert.status == 'active' ? Colors.red : Colors.grey,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.alertId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (alert.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    alert.location!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(alert.alertType.replaceAll('_', ' ').toUpperCase()),
                  backgroundColor: severityColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(alert.severity.toUpperCase()),
                  backgroundColor: severityColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (alert.status == 'active') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final apiService = ref.read(apiServiceProvider);
                  try {
                    await apiService.acknowledgeEmergencyAlert(
                      alertId: alert.id,
                      isSafe: true,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert acknowledged')),
                      );
                      ref.invalidate(emergencyAlertsProvider(_selectedStatus));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('I\'m Safe'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                Navigator.pop(context);
                setState(() {});
              },
            );
          },
        ),
      ),
    );
  }

  void _showManageContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ManageContactsDialog(),
    );
  }
}

class _ManageContactsDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManageContactsDialog> createState() => _ManageContactsDialogState();
}

class _ManageContactsDialogState extends ConsumerState<_ManageContactsDialog> {
  List<UserPersonalEmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final contacts = await apiService.getPersonalEmergencyContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContact(int contactId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deletePersonalEmergencyContact(contactId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
        _loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendAlertToContact(UserPersonalEmergencyContact contact) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Emergency Alert'),
        content: Text(
          'Send an emergency alert to ${contact.name}?\n\n'
          'They will be notified via phone and email (if available).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.sendAlertToContact(contact.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Alert sent successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending alert: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();
    String selectedType = 'family';
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Contact Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                    DropdownMenuItem(value: 'colleague', child: Text('Colleague')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (e.g., Mother, Father)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Primary Contact'),
                  subtitle: const Text('Notify this contact first'),
                  value: isPrimary,
                  onChanged: (value) {
                    setState(() {
                      isPrimary = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and phone number are required')),
                  );
                  return;
                }

                try {
                  final apiService = ref.read(apiServiceProvider);
                  await apiService.createPersonalEmergencyContact({
                    'name': nameController.text,
                    'contact_type': selectedType,
                    'phone_number': phoneController.text,
                    'email': emailController.text.isEmpty ? null : emailController.text,
                    'relationship': relationshipController.text.isEmpty ? null : relationshipController.text,
                    'is_primary': isPrimary,
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact added')),
                    );
                    _loadContacts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadContacts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _contacts.isEmpty
                          ? const Center(
                              child: Text('No emergency contacts. Add one to get started.'),
                            )
                          : ListView.builder(
                              itemCount: _contacts.length,
                              itemBuilder: (context, index) {
                                final contact = _contacts[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: contact.isPrimary
                                          ? Colors.red.shade100
                                          : Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        color: contact.isPrimary
                                            ? Colors.red.shade700
                                            : Colors.grey,
                                      ),
                                    ),
                                    title: Text(contact.name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(contact.phoneNumber),
                                        if (contact.email != null) Text(contact.email!),
                                        if (contact.relationship != null)
                                          Text('Relationship: ${contact.relationship}'),
                                        if (contact.isPrimary)
                                          Chip(
                                            label: const Text('Primary'),
                                            backgroundColor: Colors.red.shade100,
                                            labelStyle: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.warning, color: Colors.orange),
                                          tooltip: 'Send Emergency Alert',
                                          onPressed: () => _sendAlertToContact(contact),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete Contact',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Contact'),
                                                content: Text('Delete ${contact.name}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _deleteContact(contact.id);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () => _sendAlertToContact(contact),
                                  ),
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


