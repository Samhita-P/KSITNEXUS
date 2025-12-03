import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';
import 'case_detail_screen.dart';
import 'case_analytics_screen.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> with TickerProviderStateMixin {
  String _statusFilter = 'all'; // all, new, assigned, in_progress, pending, resolved, closed, escalated
  String _priorityFilter = 'all'; // all, low, medium, high, urgent, critical
  bool _myCasesOnly = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: const Text('Case Management'),
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
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CaseAnalyticsScreen(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: Icon(_myCasesOnly ? Icons.person : Icons.people),
            onPressed: () {
              setState(() {
                _myCasesOnly = !_myCasesOnly;
              });
              ref.read(casesProvider.notifier).refresh(myCases: _myCasesOnly);
            },
            tooltip: _myCasesOnly ? 'Show All Cases' : 'Show My Cases',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(casesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Cases'),
            Tab(text: 'Filters'),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            // Cases Tab
            Consumer(
              builder: (context, ref, child) {
                final casesAsync = ref.watch(casesProvider);
                
                return casesAsync.when(
                  data: (cases) {
                    final filteredCases = _filterCases(cases);
                    
                    if (filteredCases.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.refresh(casesProvider);
                      },
                      child: ListView.builder(
                        padding: Responsive.padding(context),
                        itemCount: filteredCases.length,
                        itemBuilder: (context, index) {
                          return _buildCaseCard(context, filteredCases[index]);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(context, error.toString()),
                );
              },
            ),
            // Filters Tab
            _buildFiltersTab(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
        ref.read(casesProvider.notifier).refresh(
          status: value == 'all' ? null : value,
        );
        // Switch to Cases tab after selecting filter
        _tabController.animateTo(0);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 16, tablet: 20),
          vertical: Responsive.spacing(context, mobile: 10, tablet: 12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.grey200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.grey400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.grey700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.fontSize(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _priorityFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priorityFilter = value;
        });
        ref.read(casesProvider.notifier).refresh(
          priority: value == 'all' ? null : value,
        );
        // Switch to Cases tab after selecting filter
        _tabController.animateTo(0);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, mobile: 16, tablet: 20),
          vertical: Responsive.spacing(context, mobile: 10, tablet: 12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.grey200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.grey400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.grey700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: Responsive.fontSize(context, 14),
          ),
        ),
      ),
    );
  }

  List<Case> _filterCases(List<Case> cases) {
    List<Case> filtered = cases;
    
    if (_statusFilter != 'all') {
      filtered = filtered.where((c) => c.status == _statusFilter).toList();
    }
    
    if (_priorityFilter != 'all') {
      filtered = filtered.where((c) => c.priority == _priorityFilter).toList();
    }
    
    return filtered;
  }

  Widget _buildCaseCard(BuildContext context, Case case_) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(caseId: case_.id),
            ),
          ).then((_) {
            ref.refresh(casesProvider);
          });
        },
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12, tablet: 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(case_.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      case_.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(case_.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      case_.priority.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (case_.slaStatus == 'breached')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SLA BREACHED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (case_.slaStatus == 'at_risk')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'AT RISK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Row(
                children: [
                  Text(
                    case_.caseId,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 14),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 6, tablet: 8),
                      vertical: Responsive.spacing(context, mobile: 2, tablet: 4),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      case_.caseType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: Responsive.fontSize(context, 10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Text(
                case_.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 18),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 8)),
              Text(
                case_.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (case_.tags.isNotEmpty) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Wrap(
                  spacing: Responsive.spacing(context, mobile: 4, tablet: 8),
                  runSpacing: Responsive.spacing(context, mobile: 4, tablet: 8),
                  children: case_.tags.map((tag) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: Responsive.fontSize(context, 12),
                      ),
                    ),
                  )).toList(),
                ),
              ],
              SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
              Row(
                children: [
                  if (case_.assignedToName != null) ...[
                    _buildInfoChip(
                      context,
                      'Assigned: ${case_.assignedToName}',
                      Icons.person_outline,
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  ],
                  _buildInfoChip(
                    context,
                    'Priority Score: ${case_.priorityScore}',
                    Icons.star_outline,
                  ),
                  SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  _buildInfoChip(
                    context,
                    '${case_.updatesCount} updates',
                    Icons.comment_outlined,
                  ),
                ],
              ),
              if (case_.slaBreachTime != null) ...[
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                    SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                    Text(
                      'SLA Breach: ${_formatDateTime(case_.slaBreachTime!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                        fontSize: Responsive.fontSize(context, 12),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.grey600),
                  SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                  Text(
                    'Created: ${_formatDateTime(case_.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.grey600),
        SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 6)),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grey600,
            fontSize: Responsive.fontSize(context, 12),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.yellow.shade700;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      case 'critical':
        return Colors.red.shade900;
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
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Case Status Filters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 8, tablet: 12),
            runSpacing: Responsive.spacing(context, mobile: 8, tablet: 12),
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip('new', 'New'),
              _buildFilterChip('assigned', 'Assigned'),
              _buildFilterChip('in_progress', 'In Progress'),
              _buildFilterChip('pending', 'Pending'),
              _buildFilterChip('resolved', 'Resolved'),
              _buildFilterChip('closed', 'Closed'),
              _buildFilterChip('escalated', 'Escalated'),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
          Text(
            'Priority Filters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
          Wrap(
            spacing: Responsive.spacing(context, mobile: 8, tablet: 12),
            runSpacing: Responsive.spacing(context, mobile: 8, tablet: 12),
            children: [
              _buildPriorityChip('all', 'All'),
              _buildPriorityChip('low', 'Low'),
              _buildPriorityChip('medium', 'Medium'),
              _buildPriorityChip('high', 'High'),
              _buildPriorityChip('urgent', 'Urgent'),
              _buildPriorityChip('critical', 'Critical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: Responsive.padding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: Responsive.value(context: context, mobile: 64, tablet: 80, desktop: 96),
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                    Text(
                      'No Cases',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.grey600,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 20),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                    Text(
                      _myCasesOnly 
                          ? 'You don\'t have any assigned cases. Tap the person icon above to view all cases.'
                          : 'No cases available in the system. Cases are created when students submit complaints or when faculty create them manually.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grey500,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_myCasesOnly) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _myCasesOnly = false;
                          });
                          ref.read(casesProvider.notifier).refresh(myCases: false);
                        },
                        icon: const Icon(Icons.people),
                        label: const Text('View All Cases'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 20, tablet: 24),
                            vertical: Responsive.spacing(context, mobile: 12, tablet: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            'Error Loading Cases',
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
              ref.refresh(casesProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


