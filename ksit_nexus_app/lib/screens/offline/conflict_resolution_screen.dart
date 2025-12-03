import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/conflict_resolution_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  ConsumerState<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends ConsumerState<ConflictResolutionScreen> {
  final ConflictResolutionService _conflictService = ConflictResolutionService(
    SharedPreferences.getInstance() as SharedPreferences,
  );
  
  bool _isLoading = false;
  List<ConflictData> _conflicts = [];
  Map<String, ConflictResolutionStrategy> _selectedStrategies = {};

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    setState(() => _isLoading = true);
    
    try {
      final conflicts = await _conflictService.getPendingConflicts();
      setState(() => _conflicts = conflicts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conflicts: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveConflict(String conflictId, ConflictResolutionStrategy strategy) async {
    setState(() => _isLoading = true);
    
    try {
      await _conflictService.resolveConflict(conflictId, strategy);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conflict resolved successfully')),
        );
        _loadConflicts(); // Reload conflicts
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving conflict: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showMergeDialog(ConflictData conflict) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MergeConflictDialog(conflict: conflict),
    );
    
    if (result != null) {
      await _resolveConflict(conflict.id, ConflictResolutionStrategy.merge, mergedData: result);
    }
  }

  String _getConflictTypeDisplayName(String type) {
    switch (type) {
      case 'complaints':
        return 'Complaints';
      case 'reservations':
        return 'Reservations';
      case 'study_groups':
        return 'Study Groups';
      case 'notices':
        return 'Notices';
      case 'feedback':
        return 'Feedback';
      default:
        return type.toUpperCase();
    }
  }

  IconData _getConflictTypeIcon(String type) {
    switch (type) {
      case 'complaints':
        return Icons.report_problem;
      case 'reservations':
        return Icons.event_seat;
      case 'study_groups':
        return Icons.group;
      case 'notices':
        return Icons.notifications;
      case 'feedback':
        return Icons.star;
      default:
        return Icons.sync_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflict Resolution'),
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
        actions: [
          if (_conflicts.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : () async {
                // Auto-resolve all conflicts
                setState(() => _isLoading = true);
                try {
                  await _conflictService.autoResolveConflicts(_conflicts);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All conflicts auto-resolved')),
                    );
                    _loadConflicts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error auto-resolving: $e')),
                    );
                  }
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text(
                'Auto-Resolve All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: double.infinity,
          desktop: 1200,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: _isLoading && _conflicts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _conflicts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No conflicts found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All your data is in sync',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: Responsive.padding(context),
                  itemCount: _conflicts.length,
                  itemBuilder: (context, index) {
                    final conflict = _conflicts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getConflictTypeIcon(conflict.type),
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getConflictTypeDisplayName(conflict.type),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'CONFLICT',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            if (conflict.conflictReason != null) ...[
                              Text(
                                conflict.conflictReason!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            Text(
                              'Server: ${conflict.serverTimestamp.toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Client: ${conflict.clientTimestamp.toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            // Resolution buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _resolveConflict(
                                              conflict.id,
                                              ConflictResolutionStrategy.serverWins,
                                            ),
                                    icon: const Icon(Icons.cloud, size: 16),
                                    label: const Text('Server'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _resolveConflict(
                                              conflict.id,
                                              ConflictResolutionStrategy.clientWins,
                                            ),
                                    icon: const Icon(Icons.phone_android, size: 16),
                                    label: const Text('Client'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _showMergeDialog(conflict),
                                    icon: const Icon(Icons.merge, size: 16),
                                    label: const Text('Merge'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class MergeConflictDialog extends StatefulWidget {
  final ConflictData conflict;

  const MergeConflictDialog({super.key, required this.conflict});

  @override
  State<MergeConflictDialog> createState() => _MergeConflictDialogState();
}

class _MergeConflictDialogState extends State<MergeConflictDialog> {
  Map<String, dynamic> _mergedData = {};

  @override
  void initState() {
    super.initState();
    _mergedData = Map<String, dynamic>.from(widget.conflict.serverData);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Merge ${widget.conflict.type}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose which fields to keep:'),
            const SizedBox(height: 16),
            
            // Show mergeable fields
            ...widget.conflict.serverData.entries.map((entry) {
              final key = entry.key;
              final serverValue = entry.value;
              final clientValue = widget.conflict.clientData[key];
              
              if (serverValue != clientValue) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        // Server value
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Server:', style: TextStyle(fontSize: 12)),
                              Text(serverValue?.toString() ?? 'null'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Client value
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Client:', style: TextStyle(fontSize: 12)),
                              Text(clientValue?.toString() ?? 'null'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Radio buttons for selection
                        Row(
                          children: [
                            Radio<String>(
                              value: 'server',
                              groupValue: _mergedData[key] == serverValue ? 'server' : 'client',
                              onChanged: (value) {
                                setState(() {
                                  _mergedData[key] = serverValue;
                                });
                              },
                            ),
                            const Text('Server'),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'client',
                              groupValue: _mergedData[key] == clientValue ? 'client' : 'server',
                              onChanged: (value) {
                                setState(() {
                                  _mergedData[key] = clientValue;
                                });
                              },
                            ),
                            const Text('Client'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_mergedData),
          child: const Text('Merge'),
        ),
      ],
    );
  }
}
