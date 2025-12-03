import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/safety_wellbeing_models.dart';
import '../../widgets/error_widget.dart';
import '../../providers/data_providers.dart';
import 'emergency_alerts_screen.dart';
import 'counseling_services_screen.dart';
import 'anonymous_check_in_screen.dart';
import 'safety_resources_screen.dart';

final activeAlertsProvider = FutureProvider<List<EmergencyAlert>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getActiveEmergencyAlerts();
});

final personalEmergencyContactsProvider = FutureProvider<List<UserPersonalEmergencyContact>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getPersonalEmergencyContacts();
});

class SafetyWellbeingHomeScreen extends ConsumerWidget {
  const SafetyWellbeingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlertsAsync = ref.watch(activeAlertsProvider);
    final contactsAsync = ref.watch(personalEmergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Wellbeing'),
        backgroundColor: Colors.red.shade700,
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
              ref.invalidate(activeAlertsProvider);
              ref.invalidate(personalEmergencyContactsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Emergency Alerts Banner
            activeAlertsAsync.when(
              data: (alerts) {
                if (alerts.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade800),
                            const SizedBox(width: 8),
                            Text(
                              'Active Emergency Alerts',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${alerts.length} active alert(s)',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.push('/safety/emergency'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View Alerts'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  'Emergency',
                  Icons.warning,
                  Colors.red,
                  () => context.push('/safety/emergency'),
                ),
                _buildActionCard(
                  context,
                  'Counseling',
                  Icons.psychology,
                  Colors.blue,
                  () => context.push('/safety/counseling'),
                ),
                _buildActionCard(
                  context,
                  'Check-In',
                  Icons.favorite,
                  Colors.pink,
                  () => context.push('/safety/check-in'),
                ),
                _buildActionCard(
                  context,
                  'Resources',
                  Icons.library_books,
                  Colors.green,
                  () => context.push('/safety/resources'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Emergency Contacts
            Text(
              'Emergency Contacts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            contactsAsync.when(
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('No emergency contacts available'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => context.push('/safety/emergency'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Emergency Contact'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Show first 3 contacts
                final displayContacts = contacts.take(3).toList();
                return Column(
                  children: [
                    ...displayContacts.map((contact) => _buildPersonalContactCard(context, contact)),
                    if (contacts.length > 3)
                      TextButton(
                        onPressed: () => context.push('/safety/emergency'),
                        child: Text('View all ${contacts.length} contacts'),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorDisplayWidget(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(personalEmergencyContactsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalContactCard(BuildContext context, UserPersonalEmergencyContact contact) {
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
        title: Row(
          children: [
            Expanded(child: Text(contact.name)),
            if (contact.isPrimary)
              Chip(
                label: const Text('Primary', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade700),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            if (contact.relationship != null)
              Text(
                contact.relationship!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.warning, color: Colors.orange),
          tooltip: 'Send Emergency Alert',
          onPressed: () {
            // Navigate to emergency screen to send alert
            context.push('/safety/emergency');
          },
        ),
        onTap: () {
          // Navigate to emergency screen to manage contacts
          context.push('/safety/emergency');
        },
      ),
    );
  }
}


