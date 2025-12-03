import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../models/notice_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/error_snackbar.dart';

class NoticeDetailScreen extends ConsumerStatefulWidget {
  final int noticeId;
  
  const NoticeDetailScreen({
    super.key,
    required this.noticeId,
  });

  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  Notice? _notice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotice();
  }

  Future<void> _loadNotice() async {
    // Don't try to load if noticeId is 0 or invalid
    if (widget.noticeId <= 0) {
      if (mounted) {
        setState(() {
          _error = 'Invalid notice ID';
          _isLoading = false;
        });
        // Navigate back to notices list after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/notices');
          }
        });
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get the notice from the API
      final apiService = ref.read(apiServiceProvider);
      final notice = await apiService.getNoticeById(widget.noticeId);
      
      if (mounted) {
        setState(() {
          _notice = notice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ErrorSnackbar.show(context, 'Failed to load notice: ${e.toString()}');
        // Navigate back to notices list if notice not found
        if (e.toString().contains('404') || e.toString().contains('does not exist')) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/notices');
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate back to notices list instead of browser back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/notices');
            }
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Notice Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/notices');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotice,
          ),
        ],
      ),
      body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading notice details...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notice',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotice,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notice == null) {
      return const Center(
        child: Text('Notice not found'),
      );
    }

    return ResponsiveContainer(
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
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: Responsive.padding(
                context,
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppTheme.primaryColor,
                        size: Responsive.value(
                          context: context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 24,
                        ),
                      ),
                      SizedBox(width: Responsive.value(
                        context: context,
                        mobile: 6,
                        tablet: 8,
                        desktop: 8,
                      )),
                      Expanded(
                        child: Text(
                          _notice!.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            fontSize: Responsive.value(
                              context: context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 24,
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 12,
                  )),
                  
                  // Status and Priority - Responsive Wrap
                  Wrap(
                    spacing: Responsive.value(
                      context: context,
                      mobile: 6,
                      tablet: 8,
                      desktop: 8,
                    ),
                    runSpacing: Responsive.value(
                      context: context,
                      mobile: 6,
                      tablet: 8,
                      desktop: 8,
                    ),
                    children: [
                      _buildStatusChip(_notice!.status, context),
                      _buildPriorityChip(_notice!.priority, context),
                      if (_notice!.isPinned)
                        _buildPinnedChip(context),
                    ],
                  ),
                  
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  )),
                  
                  // Author and Date Info - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = Responsive.isMobile(context);
                      final isSmallScreen = constraints.maxWidth < 350;
                      
                      if (isSmallScreen) {
                        // Stack vertically on very small screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'By ${_notice!.createdByName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatDate(_notice!.createdAt, compact: isMobile),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Horizontal layout on larger screens
                        return Wrap(
                          spacing: isMobile ? 8 : 16,
                          runSpacing: isMobile ? 4 : 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'By ${_notice!.createdByName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatDate(_notice!.createdAt, compact: isMobile),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  
                  if (_notice!.expiresAt != null) ...[
                    SizedBox(height: Responsive.value(
                      context: context,
                      mobile: 6,
                      tablet: 8,
                      desktop: 8,
                    )),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: Responsive.value(
                            context: context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 16,
                          ),
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Expires: ${_formatDate(_notice!.expiresAt!, compact: Responsive.isMobile(context))}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: Responsive.value(
                                context: context,
                                mobile: 11,
                                tablet: 12,
                                desktop: 12,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content Card
          Card(
            elevation: 2,
            child: Padding(
              padding: Responsive.padding(
                context,
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: Responsive.value(
                        context: context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 12,
                  )),
                  Text(
                    _notice!.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: Responsive.value(
                        context: context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: Responsive.value(
            context: context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          )),
          
          // Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: Responsive.padding(
                context,
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notice Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: Responsive.value(
                        context: context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.value(
                    context: context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 12,
                  )),
                  
                  _buildDetailRow('Category', _notice!.categoryDisplayName, context),
                  _buildDetailRow('Priority', _notice!.priorityDisplayName, context),
                  _buildDetailRow('Target Audience', _notice!.targetAudience ?? 'All Users', context),
                  _buildDetailRow('Views', _notice!.viewCount.toString(), context),
                  _buildDetailRow('Created', _formatDate(_notice!.createdAt, compact: Responsive.isMobile(context)), context),
                  _buildDetailRow('Updated', _formatDate(_notice!.updatedAt, compact: Responsive.isMobile(context)), context),
                  
                  if (_notice!.attachmentUrl != null && _notice!.attachmentUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildAttachmentSection(),
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

  Widget _buildStatusChip(String status, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'published':
        color = Colors.green;
        label = 'Published';
        break;
      case 'draft':
        color = Colors.orange;
        label = 'Draft';
        break;
      case 'archived':
        color = Colors.grey;
        label = 'Archived';
        break;
      default:
        color = Colors.blue;
        label = status;
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
    );
  }

  Widget _buildPriorityChip(String priority, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    Color color;
    String label;
    
    switch (priority.toLowerCase()) {
      case 'urgent':
        color = Colors.red;
        label = 'Urgent';
        break;
      case 'high':
        color = Colors.orange;
        label = 'High';
        break;
      case 'medium':
        color = Colors.blue;
        label = 'Medium';
        break;
      case 'low':
        color = Colors.green;
        label = 'Low';
        break;
      default:
        color = Colors.grey;
        label = priority;
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
    );
  }

  Widget _buildPinnedChip(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Chip(
      label: Text(
        'Pinned',
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.purple,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.value(
          context: context,
          mobile: 3.0,
          tablet: 4.0,
          desktop: 4.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Responsive.value(
              context: context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isMobile ? 13 : 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // TODO: Handle attachment download
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attachment download functionality coming soon!'),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notice!.attachmentName ?? 'Download File',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.download,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        ],
      );
  }

  String _formatDate(DateTime date, {bool compact = false}) {
    if (compact) {
      // Compact format for mobile: "14/11/25 13:40"
      return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
