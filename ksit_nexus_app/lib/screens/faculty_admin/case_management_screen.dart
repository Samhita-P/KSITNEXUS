import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/faculty_admin_models.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state.dart';
import '../../providers/data_providers.dart';

final casesProvider = FutureProvider.family<List<Case>, Map<String, String?>>((ref, filters) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCases(
    status: filters['status'],
    priority: filters['priority'],
    myCases: filters['my_cases'] == 'true',
  );
});

final casesAtRiskProvider = FutureProvider<List<Case>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCasesAtRisk();
});

class CaseManagementScreen extends ConsumerStatefulWidget {
  const CaseManagementScreen({super.key});

  @override
  ConsumerState<CaseManagementScreen> createState() => _CaseManagementScreenState();
}

class _CaseManagementScreenState extends ConsumerState<CaseManagementScreen> {
  String? _selectedStatus;
  String? _selectedPriority;
  bool _myCasesOnly = false;

  @override
  Widget build(BuildContext context) {
    final filters = {
      'status': _selectedStatus,
      'priority': _selectedPriority,
      'my_cases': _myCasesOnly ? 'true' : null,
    };
    final casesAsync = ref.watch(casesProvider(filters));
    final atRiskAsync = ref.watch(casesAtRiskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(casesProvider(filters));
              ref.invalidate(casesAtRiskProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create case screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // At Risk Cases Banner
          atRiskAsync.when(
            data: (atRiskCases) {
              if (atRiskCases.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${atRiskCases.length} case(s) at risk of SLA breach',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Show at-risk cases
                        },
                        child: const Text('View'),
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
          
          // Cases List
          Expanded(
            child: casesAsync.when(
              data: (cases) {
                if (cases.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.folder_open,
                    title: 'No Cases',
                    message: 'No cases found matching your filters.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(casesProvider(filters));
                    ref.invalidate(casesAtRiskProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      final case_ = cases[index];
                      return _buildCaseCard(context, case_);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorDisplayWidget(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(casesProvider(filters));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, Case case_) {
    Color statusColor;
    switch (case_.status) {
      case 'new':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color priorityColor;
    switch (case_.priority) {
      case 'urgent':
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to case detail screen
        },
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
                      case_.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(case_.status.toUpperCase()),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                case_.caseId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                case_.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(case_.priority.toUpperCase()),
                    backgroundColor: priorityColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (case_.slaStatus == 'at_risk' || case_.slaStatus == 'breached')
                    Chip(
                      label: Text(case_.slaStatus.toUpperCase()),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      labelStyle: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  const Spacer(),
                  if (case_.assignedToName != null)
                    Text(
                      'Assigned: ${case_.assignedToName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Cases'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'new', child: Text('New')),
                    DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('My Cases Only'),
                  value: _myCasesOnly,
                  onChanged: (value) {
                    setState(() {
                      _myCasesOnly = value ?? false;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedPriority = null;
                _myCasesOnly = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}


