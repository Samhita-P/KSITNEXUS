import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../providers/data_providers.dart';
import '../../models/complaint_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';
import '../../services/file_service.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _fileService = FileService();
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to tab changes to refresh data when switching to My Complaints tab
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // When switching to My Complaints tab (index 1), refresh the data
    if (_tabController.index == 1) {
      // Small delay to ensure tab is fully visible
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          ref.read(complaintsProvider.notifier).refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Submit Complaint'),
            Tab(text: 'My Complaints'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(complaintsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitComplaintTab(),
          _buildMyComplaintsTab(),
        ],
      ),
    );
  }

  Widget _buildSubmitComplaintTab() {
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: 700,
        desktop: 800,
      ),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
            child: _ComplaintForm(
              onSubmitted: _handleComplaintSubmission,
              selectedFiles: _selectedFiles,
              onFilesChanged: (files) {
                setState(() {
                  _selectedFiles = files;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyComplaintsTab() {
    final complaintsAsync = ref.watch(complaintsProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: complaintsAsync.when(
        data: (complaints) => complaints.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No complaints submitted yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: Responsive.padding(context),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return _ComplaintCard(
                  complaint: complaint,
                  onTap: () => _showComplaintDetails(complaint),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load complaints',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(complaintsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _handleComplaintSubmission(ComplaintCreateRequest request) async {
    try {
      await ref.read(complaintsProvider.notifier).createComplaint(request);
      // Wait a moment for backend to process
      await Future.delayed(const Duration(milliseconds: 500));
      // Force refresh to ensure we get the latest data
      await ref.read(complaintsProvider.notifier).refresh();
      // Wait for the state to update
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _selectedFiles.clear();
      });
      _tabController.animateTo(1);
      SuccessSnackbar.show(context, 'Complaint submitted successfully!');
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to submit complaint: ${e.toString()}');
    }
  }

  void _showComplaintDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => _ComplaintDetailsDialog(complaint: complaint),
    );
  }
}

class _ComplaintForm extends ConsumerStatefulWidget {
  final Function(ComplaintCreateRequest) onSubmitted;
  final List<File> selectedFiles;
  final Function(List<File>) onFilesChanged;

  const _ComplaintForm({
    required this.onSubmitted,
    required this.selectedFiles,
    required this.onFilesChanged,
  });

  @override
  ConsumerState<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends ConsumerState<_ComplaintForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _fileService = FileService();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        final authState = ref.read(authStateProvider);
        final currentUser = authState.user;
        
        // Upload files if any
        List<String> attachmentUrls = [];
        for (final file in widget.selectedFiles) {
          final url = await _fileService.uploadComplaintAttachment(file);
          attachmentUrls.add(url);
        }
        
        // Get contact email and phone, fallback to user profile if empty
        final contactEmail = formData['contactEmail']?.toString().trim();
        final contactPhone = formData['contactPhone']?.toString().trim();
        
        final request = ComplaintCreateRequest(
          category: formData['category'] ?? '',
          title: formData['title'] ?? '',
          description: formData['description'] ?? '',
          urgency: formData['urgency'] ?? '',
          contactEmail: (contactEmail?.isNotEmpty == true) ? contactEmail : currentUser?.email,
          contactPhone: (contactPhone?.isNotEmpty == true) ? contactPhone : currentUser?.phoneNumber,
          location: formData['location']?.toString().trim().isEmpty == true ? null : formData['location']?.toString().trim(),
          attachments: attachmentUrls.isNotEmpty ? attachmentUrls : null,
        );
        
        widget.onSubmitted(request);
      } catch (e) {
        ErrorSnackbar.show(context, 'Failed to submit complaint: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final files = await _fileService.pickMultipleFiles(
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt', 'mp4', 'avi', 'mov', 'mp3', 'wav'],
      );
      if (files.isNotEmpty) {
        widget.onFilesChanged(files);
        SuccessSnackbar.show(context, '${files.length} file(s) selected');
      }
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to pick files: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info to pre-populate contact fields
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    
    // Update form fields with user data after form is built
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _formKey.currentState != null) {
          // Use patchValue to update form fields with user data
          _formKey.currentState!.patchValue({
            'contactEmail': currentUser.email,
            'contactPhone': currentUser.phoneNumber ?? '',
          });
        }
      });
    }
    
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit Anonymous Complaint',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your identity will remain anonymous. Provide contact details only if you want follow-up.',
            style: TextStyle(color: AppTheme.grey600),
          ),
          const SizedBox(height: 24),
          
          FormBuilderDropdown<String>(
            name: 'category',
            decoration: const InputDecoration(
              labelText: 'Category *',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'academic', child: Text('Academic')),
              DropdownMenuItem(value: 'infrastructure', child: Text('Infrastructure')),
              DropdownMenuItem(value: 'hostel', child: Text('Hostel')),
              DropdownMenuItem(value: 'cafeteria', child: Text('Cafeteria')),
              DropdownMenuItem(value: 'transport', child: Text('Transport')),
              DropdownMenuItem(value: 'library', child: Text('Library')),
              DropdownMenuItem(value: 'sports', child: Text('Sports')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'title',
            decoration: const InputDecoration(
              labelText: 'Complaint Title *',
              prefixIcon: Icon(Icons.title),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(10),
            ]),
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'description',
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(Icons.description_outlined),
              hintText: 'Please provide detailed description of the issue...',
            ),
            maxLines: 5,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(20),
            ]),
          ),
          const SizedBox(height: 16),
          
          FormBuilderDropdown<String>(
            name: 'urgency',
            decoration: const InputDecoration(
              labelText: 'Urgency Level *',
              prefixIcon: Icon(Icons.priority_high),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
            ],
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'location',
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
              hintText: 'Where did this issue occur?',
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'contactEmail',
                  initialValue: currentUser?.email ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Contact Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'Contact email is required'),
                    FormBuilderValidators.email(errorText: 'Please enter a valid email address'),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'contactPhone',
                  initialValue: currentUser?.phoneNumber ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'Contact phone is required'),
                    FormBuilderValidators.minLength(10, errorText: 'Phone number must be at least 10 digits'),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // File Attachments
          if (widget.selectedFiles.isNotEmpty) ...[
            Text(
              'Attachments (${widget.selectedFiles.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.selectedFiles.map((file) => Card(
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(file.path.split('/').last),
                subtitle: Text(_fileService.getFileSize(file)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: AppTheme.error),
                  onPressed: () {
                    setState(() {
                      widget.selectedFiles.remove(file);
                    });
                    widget.onFilesChanged(widget.selectedFiles);
                  },
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('Add Attachments'),
          ),
          const SizedBox(height: 24),
          
          LoadingButton(
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            child: const Text('Submit Complaint'),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;

  const _ComplaintCard({
    required this.complaint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(complaint.status),
            color: _getStatusColor(complaint.status),
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(complaint.description ?? "No description provided"),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(complaint.status),
                const SizedBox(width: 8),
                _buildUrgencyChip(complaint.urgency),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(complaint.submittedAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grey600,
              ),
            ),
            if (complaint.attachments?.isNotEmpty == true)
              const Icon(
                Icons.attach_file,
                size: 16,
                color: AppTheme.grey500,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        complaint.statusDisplayName,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getUrgencyColor(urgency).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        complaint.urgencyDisplayName,
        style: TextStyle(
          color: _getUrgencyColor(urgency),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted': return AppTheme.info;
      case 'under_review': return AppTheme.warning;
      case 'in_progress': return AppTheme.primaryColor;
      case 'resolved': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      case 'closed': return AppTheme.grey500;
      default: return AppTheme.grey500;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low': return AppTheme.success;
      case 'medium': return AppTheme.warning;
      case 'high': return AppTheme.error;
      case 'urgent': return AppTheme.error;
      default: return AppTheme.grey500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted': return Icons.send;
      case 'under_review': return Icons.visibility;
      case 'in_progress': return Icons.hourglass_empty;
      case 'resolved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'closed': return Icons.close;
      default: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ComplaintDetailsDialog extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintDetailsDialog({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: Text('Complaint #${complaint.complaintId}'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow('Category', complaint.categoryDisplayName),
                    _buildDetailRow('Status', complaint.statusDisplayName),
                    _buildDetailRow('Urgency', complaint.urgencyDisplayName),
                    _buildDetailRow('Submitted', _formatDateTime(complaint.submittedAt)),
                    _buildDetailRow('Location', complaint.location ?? "No location"),
                    _buildDetailRow('Assigned To', complaint.assignedToName ?? "Unassigned"),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(complaint.description ?? "No description provided"),
                    
                    if (complaint.attachments?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      ...complaint.attachments!.map((attachment) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.attach_file),
                          title: Text(attachment.fileName),
                          subtitle: Text('${attachment.fileSize} bytes'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              // TODO: Implement file download
                            },
                          ),
                        ),
                      )),
                    ],
                    
                    if (complaint.updates?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Updates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      ...complaint.updates!.map((update) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.update, color: AppTheme.primaryColor),
                          ),
                          title: Text(update.statusDisplayName),
                          subtitle: Text(update.comment ?? 'No comment'),
                          trailing: Text(
                            _formatDateTime(update.updatedAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.grey700,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.grey800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}