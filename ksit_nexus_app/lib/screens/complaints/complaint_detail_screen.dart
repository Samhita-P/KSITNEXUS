import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/complaint_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final Complaint complaint;
  
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint #${widget.complaint.complaintId}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/complaints');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(complaintsProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/complaints/edit/${widget.complaint.id}');
            },
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 800,
          desktop: 900,
        ),
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Priority Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.complaint.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(widget.complaint.status),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(widget.complaint.urgency),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.complaint.urgency.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Complaint Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.complaint.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.complaint.description ?? "No description provided",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 16),
                        const SizedBox(width: 8),
                        Text('Category: ${_getCategoryText(widget.complaint.category)}'),
                      ],
                    ),
                    if (widget.complaint.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Text('Location: ${widget.complaint.location ?? "No location"}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text('Assigned To: ${widget.complaint.assignedToName ?? "Unassigned"}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text('Submitted: ${_formatDate(widget.complaint.submittedAt)}'),
                      ],
                    ),
                    if (widget.complaint.updatedAt != widget.complaint.submittedAt) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.update, size: 16),
                          const SizedBox(width: 8),
                          Text('Updated: ${_formatDate(widget.complaint.updatedAt)}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Admin Section (if user is admin)
            if (_isAdmin()) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Status Update
                      FormBuilderDropdown<String>(
                        name: 'status',
                        decoration: const InputDecoration(
                          labelText: 'Update Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                          DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                          DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        initialValue: widget.complaint.status,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Admin Notes
                      FormBuilderTextField(
                        name: 'admin_notes',
                        decoration: const InputDecoration(
                          labelText: 'Add Notes',
                          hintText: 'Add admin notes or response',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      LoadingButton(
                        onPressed: _isLoading ? null : _updateStatus,
                        isLoading: _isLoading,
                        child: const Text('Update Status'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Attachments (if any)
            if (widget.complaint.attachments?.isNotEmpty == true) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attachments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...widget.complaint.attachments!.map((attachment) => ListTile(
                        leading: const Icon(Icons.attachment),
                        title: Text(attachment.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadAttachment(attachment),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isAdmin() {
    // This would check if the current user is an admin
    // For now, return false as we don't have user context
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'infrastructure':
        return 'Infrastructure';
      case 'hostel':
        return 'Hostel';
      case 'cafeteria':
        return 'Cafeteria';
      case 'transport':
        return 'Transport';
      case 'library':
        return 'Library';
      case 'sports':
        return 'Sports';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This would update the complaint status
      // Implementation would depend on the API service
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (mounted) {
        ErrorSnackbar.show(context, 'Status updated successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Error updating status: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAttachment(dynamic attachment) async {
    // This would download the attachment
    // Implementation would depend on the file service
    ErrorSnackbar.show(context, 'Download functionality not implemented yet');
  }
}
