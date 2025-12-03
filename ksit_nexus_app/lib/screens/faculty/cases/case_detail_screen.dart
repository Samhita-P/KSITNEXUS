import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/data_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive.dart';
import '../../../models/faculty_admin_models.dart';
import '../../../widgets/error_snackbar.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  final int caseId;
  
  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _commentController = TextEditingController();
  bool _isInternal = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(caseProvider(widget.caseId));
    final updatesAsync = ref.watch(caseUpdatesProvider(widget.caseId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/faculty-dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(caseProvider(widget.caseId));
              ref.refresh(caseUpdatesProvider(widget.caseId));
              ref.refresh(casesProvider);
            },
          ),
        ],
      ),
      body: caseAsync.when(
        data: (case_) => _buildCaseDetail(context, case_, updatesAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildCaseDetail(BuildContext context, Case case_, AsyncValue<List<CaseUpdate>> updatesAsync) {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1200,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case Header Card
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(case_.status),
                    _getStatusColor(case_.status).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(case_.status).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          case_.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                          vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          case_.priority.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (case_.slaStatus == 'breached')
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SLA BREACHED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        )
                      else if (case_.slaStatus == 'at_risk')
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.spacing(context, mobile: 12, tablet: 16),
                            vertical: Responsive.spacing(context, mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AT RISK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(context, 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                  Text(
                    case_.caseId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 16),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  Text(
                    case_.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 22),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Case Information
            Text(
              'Case Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Description',
                      case_.description,
                      Icons.description,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildInfoRow(
                      context,
                      'Case Type',
                      case_.caseType,
                      Icons.category,
                    ),
                    if (case_.assignedToName != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Assigned To',
                        case_.assignedToName!,
                        Icons.person,
                      ),
                    ],
                    if (case_.createdByName != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Created By',
                        case_.createdByName!,
                        Icons.person_outline,
                      ),
                    ],
                    if (case_.department != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Department',
                        case_.department!,
                        Icons.business,
                      ),
                    ],
                    if (case_.category != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Category',
                        case_.category!,
                        Icons.label,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // SLA Information
            Text(
              'SLA Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'SLA Status',
                      case_.slaStatus.replaceAll('_', ' ').toUpperCase(),
                      Icons.timelapse,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildInfoRow(
                      context,
                      'SLA Target Hours',
                      '${case_.slaTargetHours} hours',
                      Icons.schedule,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    _buildInfoRow(
                      context,
                      'SLA Start Time',
                      DateFormat('MMM dd, yyyy HH:mm').format(case_.slaStartTime),
                      Icons.access_time,
                    ),
                    if (case_.slaBreachTime != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'SLA Breach Time',
                        DateFormat('MMM dd, yyyy HH:mm').format(case_.slaBreachTime!),
                        Icons.warning,
                      ),
                    ],
                    if (case_.resolutionTimeHours != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                      _buildInfoRow(
                        context,
                        'Resolution Time',
                        '${case_.resolutionTimeHours!.toStringAsFixed(1)} hours',
                        Icons.check_circle,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Case Updates
            Text(
              'Case Updates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.fontSize(context, 18),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            
            // Add Comment Form
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Update',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 16),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          FormBuilderTextField(
                            name: 'comment',
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Comment *',
                              hintText: 'Enter your comment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 4,
                            validator: FormBuilderValidators.required(
                              errorText: 'Comment is required',
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          FormBuilderCheckbox(
                            name: 'is_internal',
                            title: const Text('Internal Note (not visible to case creator)'),
                            initialValue: false,
                            onChanged: (value) {
                              setState(() {
                                _isInternal = value ?? false;
                              });
                            },
                          ),
                          SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleAddUpdate(context, widget.caseId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.spacing(context, mobile: 16, tablet: 20),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Add Update',
                                      style: TextStyle(
                                        fontSize: Responsive.fontSize(context, 16),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
            
            // Updates List
            updatesAsync.when(
              data: (updates) {
                if (updates.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: Responsive.padding(context),
                      child: Text(
                        'No updates yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey600,
                          fontSize: Responsive.fontSize(context, 14),
                        ),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: updates.map((update) => _buildUpdateCard(context, update)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading updates: $error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.error,
                    fontSize: Responsive.fontSize(context, 14),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey600,
                  fontSize: Responsive.fontSize(context, 12),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6)),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(BuildContext context, CaseUpdate update) {
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 12, tablet: 16)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  update.isInternal ? Icons.lock : Icons.comment,
                  size: 20,
                  color: update.isInternal ? AppTheme.grey600 : AppTheme.primaryColor,
                ),
                SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Text(
                  update.updatedByName ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 16),
                  ),
                ),
                const Spacer(),
                if (update.isInternal)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                      vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'INTERNAL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: Responsive.fontSize(context, 10),
                      ),
                    ),
                  ),
              ],
            ),
            if (update.statusChange != null || update.priorityChange != null) ...[
              SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
              Row(
                children: [
                  if (update.statusChange != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(update.statusChange!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status: ${update.statusChange!.replaceAll('_', ' ').toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(update.statusChange!),
                          fontSize: Responsive.fontSize(context, 12),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12)),
                  ],
                  if (update.priorityChange != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(context, mobile: 8, tablet: 12),
                        vertical: Responsive.spacing(context, mobile: 4, tablet: 6),
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(update.priorityChange!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Priority: ${update.priorityChange!.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getPriorityColor(update.priorityChange!),
                          fontSize: Responsive.fontSize(context, 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Text(
              update.comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: Responsive.fontSize(context, 14),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                SizedBox(width: Responsive.spacing(context, mobile: 4, tablet: 8)),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(update.createdAt),
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

  Future<void> _handleAddUpdate(BuildContext context, int caseId) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        
        final apiService = ref.read(apiServiceProvider);
        await apiService.createCaseUpdate(caseId, {
          'comment': formData['comment'],
          'is_internal': _isInternal,
        });
        
        if (mounted) {
          SuccessSnackbar.show(context, 'Update added successfully!');
          _commentController.clear();
          _formKey.currentState?.reset();
          ref.refresh(caseUpdatesProvider(caseId));
          ref.refresh(caseProvider(caseId));
          ref.refresh(casesProvider);
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to add update: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
          Text(
            'Error Loading Case',
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
              ref.refresh(caseProvider(widget.caseId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}













