import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';
import '../cases/case_detail_screen.dart';

class OperationalAlertsScreen extends ConsumerStatefulWidget {
  const OperationalAlertsScreen({super.key});

  @override
  ConsumerState<OperationalAlertsScreen> createState() => _OperationalAlertsScreenState();
}

class _OperationalAlertsScreenState extends ConsumerState<OperationalAlertsScreen> {
  String _severityFilter = 'warning'; // Default to warning (shows warning + critical)
  bool? _acknowledgedFilter = false; // Default to unacknowledged only
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/faculty-dashboard');
            }
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Operational Alerts'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always navigate to faculty dashboard
            context.go('/faculty-dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(operationalAlertsProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Responsive.value(context: context, mobile: 100, tablet: 110, desktop: 120)),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(context, mobile: 16, tablet: 20),
              vertical: Responsive.spacing(context, mobile: 8, tablet: 10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heading
                Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.spacing(context, mobile: 8, tablet: 10),
                  ),
                  child: Text(
                    'VIEW MORE ALERTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.value(context: context, mobile: 12, tablet: 14),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('warning', 'Urgent'),
                      _buildFilterChip('critical', 'Critical'),
                      _buildFilterChip('all', 'All'),
                      SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                      _buildAcknowledgedChip('unacknowledged', 'Unacknowledged'),
                      _buildAcknowledgedChip('all', 'All'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: double.infinity,
          desktop: 1400,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: Consumer(
          builder: (context, ref, child) {
            // Apply default filters on first load
            if (!_hasInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasInitialized = true;
                  });
                  ref.read(operationalAlertsProvider.notifier).refresh(
                    severity: 'warning',
                    isAcknowledged: false,
                  );
                }
              });
            }
            
            final alertsAsync = ref.watch(operationalAlertsProvider);
            
            return alertsAsync.when(
              data: (alerts) {
                final filteredAlerts = _filterAlerts(alerts);
                
                if (filteredAlerts.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(operationalAlertsProvider);
                  },
                  child: ListView.builder(
                    padding: Responsive.padding(context),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      return _buildAlertCard(context, filteredAlerts[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error.toString()),
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _severityFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _severityFilter = value;
        });
        ref.read(operationalAlertsProvider.notifier).refresh(
          severity: value == 'all' ? null : value,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 4, tablet: 8),
          vertical: Responsive.spacing(context, mobile: 8, tablet: 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.fontSize(context, 12),
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgedChip(String value, String label) {
    bool isSelected = false;
    if (value == 'all' && _acknowledgedFilter == null) {
      isSelected = true;
    } else if (value == 'unacknowledged' && _acknowledgedFilter == false) {
      isSelected = true;
    } else if (value == 'acknowledged' && _acknowledgedFilter == true) {
      isSelected = true;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == 'all') {
            _acknowledgedFilter = null;
          } else if (value == 'unacknowledged') {
            _acknowledgedFilter = false;
          } else if (value == 'acknowledged') {
            _acknowledgedFilter = true;
          }
        });
        ref.read(operationalAlertsProvider.notifier).refresh(
          isAcknowledged: _acknowledgedFilter,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 4, tablet: 8),
          vertical: Responsive.spacing(context, mobile: 8, tablet: 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.fontSize(context, 12),
          ),
        ),
      ),
    );
  }

  List<OperationalAlert> _filterAlerts(List<OperationalAlert> alerts) {
    List<OperationalAlert> filtered = alerts;
    
    if (_severityFilter != 'all') {
      // When "warning" is selected, show both warning and critical
      if (_severityFilter == 'warning') {
        filtered = filtered.where((a) => 
          a.severity == 'warning' || a.severity == 'critical'
        ).toList();
      } else {
        filtered = filtered.where((a) => a.severity == _severityFilter).toList();
      }
    }
    
    if (_acknowledgedFilter != null) {
      filtered = filtered.where((a) => a.isAcknowledged == _acknowledgedFilter).toList();
    }
    
    return filtered;
  }

  Widget _buildAlertCard(BuildContext context, OperationalAlert alert) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      color: _getSeverityColor(alert.severity).withOpacity(0.05),
      shape: Border.all(
        color: _getSeverityColor(alert.severity).withOpacity(0.3),
        width: 1.5,
      ),
      child: InkWell(
        onTap: () {
          if (alert.relatedCase != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CaseDetailScreen(caseId: alert.relatedCase!),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(alert.severity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.spacing(context, mobile: 6, tablet: 8),
                                vertical: Responsive.spacing(context, mobile: 2, tablet: 4),
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(alert.severity),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert.severity.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.fontSize(context, 9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, mobile: 6, tablet: 8)),
                            Text(
                              _getAlertTypeLabel(alert.alertType),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.grey600,
                                fontSize: Responsive.fontSize(context, 11),
                              ),
                            ),
                            const Spacer(),
                            if (alert.isAcknowledged)
                              Icon(Icons.check_circle, color: Colors.green, size: 18)
                            else
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                          ],
                        ),
                        SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 10)),
                        Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 16),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6)),
                        Text(
                          alert.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.grey600,
                            fontSize: Responsive.fontSize(context, 13),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (alert.relatedCase != null) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 10, tablet: 12)),
                Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: AppTheme.primaryColor),
                    SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6)),
                    Text(
                      'Case #${alert.relatedCase}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.fontSize(context, 12),
                      ),
                    ),
                    const Spacer(),
                    if (!alert.isAcknowledged)
                      TextButton.icon(
                        onPressed: () => _handleAcknowledgeAlert(context, alert.id),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Acknowledge'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                            vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else if (!alert.isAcknowledged) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 10, tablet: 12)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAcknowledgeAlert(context, alert.id),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Acknowledge Alert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.spacing(context, mobile: 10, tablet: 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAlertTypeLabel(String alertType) {
    switch (alertType) {
      case 'sla_risk':
        return 'SLA Risk';
      case 'high_volume':
        return 'High Volume';
      case 'resource_shortage':
        return 'Resource Shortage';
      case 'trend_anomaly':
        return 'Trend Anomaly';
      case 'performance_degradation':
        return 'Performance';
      default:
        return alertType;
    }
  }

  Color _getAlertTypeColor(String alertType) {
    switch (alertType) {
      case 'sla_risk':
        return Colors.orange;
      case 'high_volume':
        return Colors.red;
      case 'resource_shortage':
        return Colors.purple;
      case 'trend_anomaly':
        return Colors.yellow.shade700;
      case 'performance_degradation':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    }
  }

  Future<void> _handleAcknowledgeAlert(BuildContext context, int alertId) async {
    try {
      await ref.read(operationalAlertsProvider.notifier).acknowledgeAlert(alertId);
      if (mounted) {
        SuccessSnackbar.show(context, 'Alert acknowledged successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to acknowledge alert: ${e.toString()}');
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Severity'),
              trailing: DropdownButton<String>(
                value: _severityFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (value) {
                  setState(() {
                    _severityFilter = value ?? 'all';
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Acknowledged'),
              trailing: DropdownButton<String?>(
                value: _acknowledgedFilter == null 
                    ? 'all' 
                    : _acknowledgedFilter == true 
                        ? 'acknowledged' 
                        : 'unacknowledged',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'unacknowledged', child: Text('Unacknowledged')),
                  DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value == 'all') {
                      _acknowledgedFilter = null;
                    } else if (value == 'acknowledged') {
                      _acknowledgedFilter = true;
                    } else if (value == 'unacknowledged') {
                      _acknowledgedFilter = false;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(operationalAlertsProvider.notifier).refresh(
                severity: _severityFilter == 'all' ? null : _severityFilter,
                isAcknowledged: _acknowledgedFilter,
              );
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
            color: AppTheme.grey400,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'No Alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Text(
            'No operational alerts at this time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
              fontSize: Responsive.fontSize(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
            color: AppTheme.error,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Alerts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
          Padding(
            padding: Responsive.horizontalPadding(context),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey600,
                fontSize: Responsive.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          ElevatedButton(
            onPressed: () {
              ref.refresh(operationalAlertsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

