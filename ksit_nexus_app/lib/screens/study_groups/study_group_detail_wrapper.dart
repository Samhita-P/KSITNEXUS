import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_providers.dart';
import '../../models/study_group_model.dart';
import '../../theme/app_theme.dart';
import 'study_groups_screen.dart';

class StudyGroupDetailRouteWrapper extends ConsumerStatefulWidget {
  final int groupId;

  const StudyGroupDetailRouteWrapper({super.key, required this.groupId});

  @override
  ConsumerState<StudyGroupDetailRouteWrapper> createState() => _StudyGroupDetailRouteWrapperState();
}

class _StudyGroupDetailRouteWrapperState extends ConsumerState<StudyGroupDetailRouteWrapper> {
  StudyGroup? _group;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ref.read(apiServiceProvider);
      final groups = await apiService.getStudyGroups();
      final group = groups.firstWhere(
        (g) => g.id == widget.groupId,
        orElse: () => throw Exception('Study group not found'),
      );

      setState(() {
        _group = group;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Group'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/study-groups');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadGroup();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Group'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/study-groups');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadGroup();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Study group not found',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return StudyGroupDetailsScreen(group: _group!);
  }
}
















