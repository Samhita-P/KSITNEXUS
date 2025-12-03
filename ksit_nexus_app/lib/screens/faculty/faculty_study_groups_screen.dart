import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../models/study_group_model.dart';

class FacultyStudyGroupsScreen extends ConsumerStatefulWidget {
  const FacultyStudyGroupsScreen({super.key});

  @override
  ConsumerState<FacultyStudyGroupsScreen> createState() => _FacultyStudyGroupsScreenState();
}

class _FacultyStudyGroupsScreenState extends ConsumerState<FacultyStudyGroupsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedTab = 'all';
            break;
          case 1:
            _selectedTab = 'active';
            break;
          case 2:
            _selectedTab = 'reported';
            break;
          case 3:
            _selectedTab = 'closed';
            break;
        }
      });
    });
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
        title: const Text('Study Groups Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Reported'),
            Tab(text: 'Closed'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                // Invalidate all filter variants to ensure fresh data
                ref.invalidate(facultyStudyGroupsProvider);
                // Also refresh the current filter
                await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier).refresh(_selectedTab);
              },
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsList('all'),
          _buildGroupsList('active'),
          _buildGroupsList('reported'),
          _buildGroupsList('closed'),
        ],
      ),
      ),
    );
  }

  Widget _buildGroupsList(String filter) {
    return ResponsiveContainer(
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
          final studyGroupsAsync = ref.watch(facultyStudyGroupsProvider(filter));
          
          return studyGroupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return _buildEmptyState(filter);
              }
              
              // Sort by created_at descending (most recent first) as backup
              final sortedGroups = List<StudyGroup>.from(groups);
              sortedGroups.sort((a, b) {
                // Most recent first (descending order)
                return b.createdAt.compareTo(a.createdAt);
              });
              
              return RefreshIndicator(
                onRefresh: () async {
                  // Invalidate all filter variants to ensure fresh data
                  ref.invalidate(facultyStudyGroupsProvider);
                  // Also refresh the current filter
                  await ref.read(facultyStudyGroupsProvider(filter).notifier).refresh(filter);
                },
                child: ListView.builder(
                  padding: Responsive.padding(context),
                  itemCount: sortedGroups.length,
                  itemBuilder: (context, index) {
                    final group = sortedGroups[index];
                    return _buildGroupCard(group, filter);
                  },
                ),
              );
            },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load study groups',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $error',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(facultyStudyGroupsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }


  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;
    
    switch (filter) {
      case 'active':
        title = 'No Active Groups';
        subtitle = 'There are no active study groups at the moment.';
        icon = Icons.group_outlined;
        iconColor = Colors.green;
        break;
      case 'reported':
        title = 'No Reported Groups';
        subtitle = 'No study groups have been reported for review.';
        icon = Icons.flag_outlined;
        iconColor = Colors.orange;
        break;
      case 'closed':
        title = 'No Closed Groups';
        subtitle = 'No study groups have been closed.';
        icon = Icons.group_off_outlined;
        iconColor = Colors.red;
        break;
      case 'all':
      default:
        title = 'No Study Groups';
        subtitle = 'No study groups have been created yet.';
        icon = Icons.group_outlined;
        iconColor = AppTheme.primaryColor;
        break;
    }
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 4,
        shadowColor: AppTheme.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderGray.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(StudyGroup group, String filter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: AppTheme.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderGray.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with group name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name ?? 'Unnamed Group',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                _buildStatusChip(group.status ?? 'unknown'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Subject and level
            Row(
              children: [
                Icon(
                  Icons.subject,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  group.subject ?? 'No Subject',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.school,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  group.level ?? group.difficultyLevel ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            if (group.description != null && group.description!.isNotEmpty)
              Text(
                group.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            
            const SizedBox(height: 12),
            
            // Stats row
            Row(
              children: [
                _buildStatItem(
                  Icons.people,
                  '${group.memberCount ?? group.currentMemberCount ?? 0}/${group.maxMembers ?? 0}',
                  'Members',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  Icons.visibility,
                  (group.isPublic ?? false) ? 'Public' : 'Private',
                  'Visibility',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  Icons.calendar_today,
                  _formatDate(group.createdAt),
                  'Created',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons based on filter
            Row(
              children: _buildActionButtons(group, filter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.success;
        label = 'Active';
        break;
      case 'closed':
        color = AppTheme.error;
        label = 'Closed';
        break;
      case 'reported':
        color = AppTheme.warning;
        label = 'Reported';
        break;
      default:
        color = AppTheme.textTertiary;
        label = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(StudyGroup group, String filter) {
    List<Widget> buttons = [];
    
    switch (filter) {
      case 'active':
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _reportGroup(group),
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _closeGroup(group),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ]);
        break;
      case 'reported':
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _approveGroup(group),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _rejectGroup(group),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ]);
        break;
      case 'closed':
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _reopenGroup(group),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reopen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ]);
        break;
      case 'all':
      default:
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _viewGroupDetails(group),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ]);
        break;
    }
    
    return buttons;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    // Check if same day (today)
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Format: DD/MM/YYYY
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  // Action methods
  void _reportGroup(StudyGroup group) {
    final issueController = TextEditingController();
    final contentController = TextEditingController();
    final warningController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReportGroupDialog(
        group: group,
        issueController: issueController,
        contentController: contentController,
        warningController: warningController,
        onReport: (issueDescription, contentToRemove, warningMessage) async {
          try {
            await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier)
                .reportGroup(
                  group.id,
                  issueDescription,
                  contentToRemove,
                  warningMessage,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group reported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Wait a moment for the data to refresh, then switch to reported tab
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                _tabController.animateTo(2); // Index 2 is "Reported" tab
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error reporting group: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _closeGroup(StudyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Group'),
        content: Text('Are you sure you want to close "${group.name ?? 'Unnamed Group'}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier)
                    .rejectGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group closed successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to close group: $e')),
                  );
                }
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approveGroup(StudyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Group'),
        content: Text('Are you sure you want to approve "${group.name ?? 'Unnamed Group'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier)
                    .approveGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group approved successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to approve group: $e')),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectGroup(StudyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Group'),
        content: Text('Are you sure you want to reject "${group.name ?? 'Unnamed Group'}"? This will close the group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier)
                    .rejectGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group rejected successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reject group: $e')),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _reopenGroup(StudyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Group'),
        content: Text('Are you sure you want to reopen "${group.name ?? 'Unnamed Group'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(facultyStudyGroupsProvider(_selectedTab).notifier)
                    .reopenGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group reopened successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reopen group: $e')),
                  );
                }
              }
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
  }

  void _viewGroupDetails(StudyGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name ?? 'Unnamed Group'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status and visibility
              Row(
                children: [
                  _buildStatusChip(group.status ?? 'unknown'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (group.isPublic ?? false) ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (group.isPublic ?? false) ? 'Public' : 'Private',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Subject and level
              _buildDetailRow('Subject', group.subject ?? 'No Subject', Icons.subject),
              _buildDetailRow('Level', group.level ?? group.difficultyLevel ?? 'Unknown', Icons.school),
              _buildDetailRow('Members', '${group.memberCount ?? group.currentMemberCount ?? 0}/${group.maxMembers ?? 0}', Icons.people),
              _buildDetailRow('Created', _formatDate(group.createdAt), Icons.calendar_today),
              _buildDetailRow('Updated', _formatDate(group.updatedAt), Icons.update),
              
              if (group.creatorName != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Creator', group.creatorName!, Icons.person),
              ],
              
              if (group.description != null && group.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              
              if (group.isReported == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reported Group',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (group.reportReason != null && group.reportReason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${group.reportReason}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (group.reportedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reported: ${_formatDate(group.reportedAt!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              if (group.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tags:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: group.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (group.status == 'active') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _reportGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Report'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _closeGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Group'),
            ),
          ],
          if (group.status == 'reported') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
          if (group.status == 'closed') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _reopenGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reopen'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGroupDialog extends StatefulWidget {
  final StudyGroup group;
  final TextEditingController issueController;
  final TextEditingController contentController;
  final TextEditingController warningController;
  final Future<void> Function(String issueDescription, String contentToRemove, String warningMessage) onReport;

  const _ReportGroupDialog({
    required this.group,
    required this.issueController,
    required this.contentController,
    required this.warningController,
    required this.onReport,
  });

  @override
  State<_ReportGroupDialog> createState() => _ReportGroupDialogState();
}

class _ReportGroupDialogState extends State<_ReportGroupDialog> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update button state
    widget.issueController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.issueController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = widget.issueController.text.trim().isNotEmpty && !_isSubmitting;

    return AlertDialog(
      elevation: 8,
      shadowColor: AppTheme.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flag, color: AppTheme.warning, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Report Group',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporting: ${widget.group.name ?? 'Unnamed Group'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject: ${widget.group.subject ?? 'No Subject'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Issue description
            Text(
              'Issue Description *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.issueController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the issue with this study group...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {}); // Update button state when text changes
              },
            ),
            
            const SizedBox(height: 16),
            
            // Content to remove
            Text(
              'Content to Remove',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.contentController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Specify which content should be removed...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Warning message
            Text(
              'Warning Message to Admin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.warningController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write a warning message to send to the group admin...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.info.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info, color: AppTheme.info, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This group will be moved to the "Reported" tab and the admin will be notified.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: canSubmit ? () async {
            setState(() {
              _isSubmitting = true;
            });
            
            try {
              await widget.onReport(
                widget.issueController.text.trim(),
                widget.contentController.text.trim(),
                widget.warningController.text.trim(),
              );
              
              if (mounted) {
                Navigator.pop(context);
              }
            } catch (e) {
              setState(() {
                _isSubmitting = false;
              });
              // Error handling is done in the parent widget
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? AppTheme.warning : AppTheme.borderGray,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: canSubmit ? 2 : 0,
          ),
          child: _isSubmitting 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Report Group',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ],
    );
  }
}
