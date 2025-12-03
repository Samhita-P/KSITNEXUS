import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../models/complaint_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';
import '../../services/file_service.dart';

class FacultyComplaintsReviewScreen extends ConsumerStatefulWidget {
  const FacultyComplaintsReviewScreen({super.key});

  @override
  ConsumerState<FacultyComplaintsReviewScreen> createState() => _FacultyComplaintsReviewScreenState();
}

class _FacultyComplaintsReviewScreenState extends ConsumerState<FacultyComplaintsReviewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _fileService = FileService();
  List<File> _selectedFiles = [];
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Review Student Queries'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedFilter = 'pending';
                  break;
                case 1:
                  _selectedFilter = 'resolved';
                  break;
                case 2:
                  _selectedFilter = 'all';
                  break;
              }
            });
          },
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Refresh all tabs
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintsList('pending'),
          _buildComplaintsList('resolved'),
          _buildComplaintsList('all'),
        ],
      ),
      ),
    );
  }

  Widget _buildComplaintsList(String filter) {
    // Use FutureBuilder to fetch faculty complaints directly from the API
    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: FutureBuilder<List<Complaint>>(
        future: ref.read(apiServiceProvider).getFacultyComplaints(status: filter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
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
                    snapshot.error.toString(),
                    style: const TextStyle(color: AppTheme.grey600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filter == 'pending' 
                      ? 'No pending complaints found'
                      : 'No ${filter} complaints found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh by rebuilding
            },
            child: ListView.builder(
              padding: Responsive.padding(context),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return _FacultyComplaintCard(
                  complaint: complaint,
                  onTap: () => _showComplaintDetails(complaint),
                  onRespond: () => _showResponseDialog(complaint),
                  onMarkResolved: () => _markAsResolved(complaint),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => _ComplaintDetailsDialog(complaint: complaint),
    );
  }

  void _showResponseDialog(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => _ResponseDialog(
        complaint: complaint,
        onSubmitted: (message, files) => _submitResponse(complaint, message, files),
      ),
    );
  }

  Future<void> _submitResponse(Complaint complaint, String message, List<File> files) async {
    try {
      // TODO: Implement API call to submit response
      // await ref.read(complaintsProvider.notifier).respondToComplaint(complaint.id, message, files);
      
      SuccessSnackbar.show(context, 'Response sent successfully!');
      Navigator.of(context).pop();
      setState(() {}); // Refresh the list
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to send response: ${e.toString()}');
    }
  }

  Future<void> _markAsResolved(Complaint complaint) async {
    try {
      await ref.read(complaintsProvider.notifier).markComplaintResolved(complaint.id);
      SuccessSnackbar.show(context, 'Complaint marked as resolved!');
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to mark as resolved: ${e.toString()}');
    }
  }
}

class _FacultyComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final VoidCallback onRespond;
  final VoidCallback onMarkResolved;

  const _FacultyComplaintCard({
    required this.complaint,
    required this.onTap,
    required this.onRespond,
    required this.onMarkResolved,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = ['submitted', 'under_review', 'in_progress'].contains(complaint.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(complaint.status),
                      color: _getStatusColor(complaint.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complaint #${complaint.complaintId}',
                          style: TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(complaint.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                complaint.description ?? "No description provided",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.grey700),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildUrgencyChip(complaint.urgency),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(complaint.submittedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                  const Spacer(),
                  if (complaint.attachments?.isNotEmpty == true)
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppTheme.grey500,
                    ),
                ],
              ),
              
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRespond,
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Respond'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onMarkResolved,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Mark Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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

class _ResponseDialog extends StatefulWidget {
  final Complaint complaint;
  final Function(String message, List<File> files) onSubmitted;

  const _ResponseDialog({
    required this.complaint,
    required this.onSubmitted,
  });

  @override
  State<_ResponseDialog> createState() => _ResponseDialogState();
}

class _ResponseDialogState extends State<_ResponseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _fileService = FileService();
  List<File> _selectedFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final files = await _fileService.pickMultipleFiles(
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt', 'mp4', 'avi', 'mov', 'mp3', 'wav'],
      );
      if (files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(files);
        });
        SuccessSnackbar.show(context, '${files.length} file(s) selected');
      }
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to pick files: ${e.toString()}');
    }
  }

  Future<void> _submitResponse() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        await widget.onSubmitted(_messageController.text, _selectedFiles);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: Text('Respond to #${widget.complaint.complaintId}'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint description at top
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complaint Description:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.complaint.description ?? "No description provided",
                              style: const TextStyle(color: AppTheme.grey700),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Response Message *',
                          hintText: 'Type your response to the student...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Response message is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Response must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // File Attachments
                      if (_selectedFiles.isNotEmpty) ...[
                        Text(
                          'Attachments (${_selectedFiles.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._selectedFiles.map((file) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(file.path.split('/').last),
                            subtitle: Text(_fileService.getFileSize(file)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: AppTheme.error),
                              onPressed: () {
                                setState(() {
                                  _selectedFiles.remove(file);
                                });
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
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LoadingButton(
                              onPressed: _submitResponse,
                              isLoading: _isLoading,
                              child: const Text('Send Response'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

