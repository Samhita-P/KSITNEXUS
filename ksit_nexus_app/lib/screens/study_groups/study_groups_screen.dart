import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/data_providers.dart';
import '../../models/study_group_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../services/file_service.dart';

class StudyGroupsScreen extends ConsumerStatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  ConsumerState<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends ConsumerState<StudyGroupsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
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
            Tab(text: 'All Groups'),
            Tab(text: 'My Groups'),
            Tab(text: 'Create Group'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(studyGroupsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllGroupsTab(),
          _buildMyGroupsTab(),
          _buildCreateGroupTab(),
        ],
      ),
    );
  }

  Widget _buildAllGroupsTab() {
    final groupsAsync = ref.watch(studyGroupsProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: groupsAsync.when(
        data: (groups) => groups.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No study groups found',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _StudyGroupCard(
                  group: group,
                  onTap: () => _showGroupDetails(group),
                  onJoin: () => _joinGroup(group.id),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                'Failed to load study groups',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(
                    color: AppTheme.grey700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(studyGroupsProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    final groupsAsync = ref.watch(studyGroupsProvider);

    return groupsAsync.when(
      data: (groups) {
        // Filter groups where user is a member
        final myGroups = groups.where((group) => group.isMember == true).toList();
        
        return myGroups.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'You haven\'t joined any study groups yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: myGroups.length,
                itemBuilder: (context, index) {
                  final group = myGroups[index];
                  return _StudyGroupCard(
                    group: group,
                    onTap: () => _showGroupDetails(group),
                    onLeave: () => _leaveGroup(group.id),
                    isMyGroup: true,
                  );
                },
              );
      },
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
              'Failed to load your study groups',
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
                ref.read(studyGroupsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGroupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _CreateGroupForm(
            onSubmitted: _handleGroupCreation,
          ),
        ),
      ),
    );
  }

  Future<void> _joinGroup(int groupId) async {
    try {
      await ref.read(studyGroupsProvider.notifier).joinStudyGroup(groupId);
      if (mounted) {
        SuccessSnackbar.show(context, 'Successfully joined the study group!');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to join study group: ${e.toString()}');
      }
    }
  }

  Future<void> _leaveGroup(int groupId) async {
    try {
      await ref.read(studyGroupsProvider.notifier).leaveStudyGroup(groupId);
      if (mounted) {
        SuccessSnackbar.show(context, 'Successfully left the study group!');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to leave study group: ${e.toString()}');
      }
    }
  }

  Future<void> _handleGroupCreation(StudyGroupCreateRequest request) async {
    try {
      await ref.read(studyGroupsProvider.notifier).createStudyGroup(request);
      if (mounted) {
        _tabController.animateTo(0);
        SuccessSnackbar.show(context, 'Study group created successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to create study group: ${e.toString()}');
      }
    }
  }

  void _showGroupDetails(StudyGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyGroupDetailsScreen(group: group),
      ),
    );
  }
}

class _StudyGroupCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final bool isMyGroup;

  const _StudyGroupCard({
    required this.group,
    required this.onTap,
    this.onJoin,
    this.onLeave,
    this.isMyGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.group,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name ?? 'Untitled Group',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          group.subjectDisplayName,
                          style: const TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (group.isPublic ?? false)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Public',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Private',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                group.description ?? 'No description available',
                style: const TextStyle(color: AppTheme.grey800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildInfoChip(
                    Icons.people,
                    '${group.currentMemberCount}/${group.maxMembers ?? 10}',
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.school,
                    group.difficultyDisplayName,
                    AppTheme.info,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.person,
                    group.creatorName ?? 'Unknown',
                    AppTheme.grey600,
                  ),
                ],
              ),
              
              if (group.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: group.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppTheme.grey700,
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created ${_formatDate(group.createdAt)}',
                    style: const TextStyle(
                      color: AppTheme.grey600,
                      fontSize: 12,
                    ),
                  ),
                  if (isMyGroup && onLeave != null)
                    TextButton.icon(
                      onPressed: onLeave,
                      icon: const Icon(Icons.exit_to_app, size: 16),
                      label: const Text('Leave'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                      ),
                    )
                  else if (!isMyGroup && onJoin != null && group.canJoin)
                    ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Join'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    )
                  else if (!group.canJoin)
                    const Text(
                      'Group Full',
                      style: TextStyle(
                        color: AppTheme.grey500,
                        fontSize: 12,
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _CreateGroupForm extends StatefulWidget {
  final Function(StudyGroupCreateRequest) onSubmitted;

  const _CreateGroupForm({required this.onSubmitted});

  @override
  State<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<_CreateGroupForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Study Group',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a study group to collaborate with fellow students.',
            style: TextStyle(color: AppTheme.grey600),
          ),
          const SizedBox(height: 24),
          
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(
              labelText: 'Group Name *',
              prefixIcon: Icon(Icons.group_outlined),
              hintText: 'e.g., Advanced Mathematics Study Group',
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(5),
            ]),
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'description',
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(Icons.description_outlined),
              hintText: 'Describe the purpose and goals of this study group...',
            ),
            maxLines: 4,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(20),
            ]),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: FormBuilderDropdown<String>(
                  name: 'subject',
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mathematics', child: Text('Mathematics')),
                    DropdownMenuItem(value: 'physics', child: Text('Physics')),
                    DropdownMenuItem(value: 'chemistry', child: Text('Chemistry')),
                    DropdownMenuItem(value: 'computer_science', child: Text('Computer Science')),
                    DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                    DropdownMenuItem(value: 'mechanical', child: Text('Mechanical')),
                    DropdownMenuItem(value: 'civil', child: Text('Civil')),
                    DropdownMenuItem(value: 'electrical', child: Text('Electrical')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderDropdown<String>(
                  name: 'difficultyLevel',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty *',
                    prefixIcon: Icon(Icons.trending_up_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  ],
                  validator: FormBuilderValidators.required(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          FormBuilderSlider(
            name: 'maxMembers',
            initialValue: 5.0,
            min: 2.0,
            max: 20.0,
            divisions: 18,
            label: 'Maximum Members',
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.grey300,
            decoration: const InputDecoration(
              labelText: 'Maximum Members',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          
          FormBuilderCheckbox(
            name: 'isPublic',
            title: const Text('Make this group public (visible to all students)'),
            initialValue: true,
          ),
          const SizedBox(height: 16),
          
          // Tags
          Text(
            'Tags (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getAvailableTags().map((tag) => FilterChip(
              label: Text(tag),
              selected: _selectedTags.contains(tag),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
          
          LoadingButton(
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            child: const Text('Create Study Group'),
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableTags() {
    return [
      'Exam Preparation',
      'Project Work',
      'Assignment Help',
      'Concept Discussion',
      'Problem Solving',
      'Group Study',
      'Peer Learning',
      'Research',
      'Coding',
      'Lab Work',
    ];
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // Debug: Form data validation
        
        final request = StudyGroupCreateRequest(
          name: formData['name'] ?? '',
          description: formData['description'] ?? '',
          subject: formData['subject'] ?? '',
          difficultyLevel: formData['difficultyLevel'] ?? 'beginner',
          maxMembers: (formData['maxMembers'] as double?)?.toInt() ?? 5,
          isPublic: formData['isPublic'] ?? true,
          tags: _selectedTags,
        );
        
        widget.onSubmitted(request);
      } catch (e) {
        ErrorSnackbar.show(context, 'Failed to create study group: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Form validation failed
      ErrorSnackbar.show(context, 'Please fill in all required fields correctly');
    }
  }
}

class StudyGroupDetailsScreen extends ConsumerStatefulWidget {
  final StudyGroup group;

  const StudyGroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<StudyGroupDetailsScreen> createState() => _StudyGroupDetailsScreenState();
}

class _StudyGroupDetailsScreenState extends ConsumerState<StudyGroupDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  List<GroupMessage> _messages = [];
  bool _isLoadingMessages = false;
  
  // Track current group state
  late StudyGroup _currentGroup;
  bool _isJoining = false;
  int _eventsRefreshKey = 0;
  int _resourcesRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _currentGroup = widget.group;
    _loadMessages();
  }

  void _onTabChanged() {
    // When switching to Events tab (index 2) or Resources tab (index 3), refresh the data
    if (_tabController.index == 2) {
      // Events tab
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _eventsRefreshKey++;
          });
        }
      });
    } else if (_tabController.index == 3) {
      // Resources tab
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _resourcesRefreshKey++;
          });
        }
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final messages = await apiService.getStudyGroupMessages(_currentGroup.id);
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMessages = false;
      });
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to load messages: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      final apiService = ref.read(apiServiceProvider);
      final request = GroupMessageCreateRequest(
        message: messageText,
        messageType: 'text',
      );
      
      final newMessage = await apiService.sendStudyGroupMessage(_currentGroup.id, request);
      
      setState(() {
        _messages.add(newMessage);
      });
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to send message: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGroup.name ?? 'Untitled Group'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Chat'),
            Tab(text: 'Resources'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChatTab(),
          _buildResourcesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Subject', _currentGroup.subjectDisplayName),
                  _buildInfoRow('Difficulty', _currentGroup.difficultyDisplayName),
                  _buildInfoRow('Members', '${_currentGroup.currentMemberCount ?? 0}/${_currentGroup.maxMembers ?? 10}'),
                  _buildInfoRow('Type', (_currentGroup.isPublic ?? false) ? 'Public' : 'Private'),
                  _buildInfoRow('Created by', _currentGroup.creatorName ?? 'Unknown'),
                  _buildInfoRow('Created', _formatDate(_currentGroup.createdAt)),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_currentGroup.description ?? 'No description available'),
                  
                  if (_currentGroup.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _currentGroup.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Join Group Button
          _buildJoinGroupButton(),
          
          const SizedBox(height: 16),
          
          // Members
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members (${_currentGroup.members.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._currentGroup.members.map((member) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        (member.userName?.isNotEmpty == true ? member.userName![0] : '?').toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member.userName ?? 'Unknown User'),
                    subtitle: Text((member.role ?? 'member').toUpperCase()),
                    trailing: member.isAdmin
                        ? const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor)
                        : null,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(
                      color: AppTheme.grey500,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _ChatMessageBubble(message: message);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourcesTab() {
    return Column(
      children: [
        // Add Resource Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showFileUploadDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Resource'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Resources List
        Expanded(
          child: FutureBuilder<List<GroupResource>>(
            key: ValueKey('resources_$_resourcesRefreshKey'),
            future: _loadResources(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading resources: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final resources = snapshot.data ?? [];
              
              if (resources.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No resources uploaded yet'),
                      SizedBox(height: 8),
                      Text('Click "Add Resource" to upload files'),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: resources.length,
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getResourceIcon(resource.fileType),
                      title: Text(resource.fileName ?? 'Unknown File'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (resource.description?.isNotEmpty == true)
                            Text(resource.description!),
                          Text('${_formatFileSize(resource.fileSize)} • ${resource.uploadedByName ?? 'Unknown User'} • ${_formatDateTime(resource.uploadedAt)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadResource(resource),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showResourceInfo(resource),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Create Event Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Events List
        Expanded(
          child: FutureBuilder<List<GroupEvent>>(
            key: ValueKey('events_$_eventsRefreshKey'),
            future: _loadEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading events: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final events = snapshot.data ?? [];
              
              if (events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No events scheduled yet'),
                      SizedBox(height: 8),
                      Text('Click "Create Event" to schedule an event'),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getEventIcon(event.eventType),
                      title: Text(event.title ?? 'Untitled Event'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.description?.isNotEmpty == true)
                            Text(event.description!),
                          Text('${_formatDateTime(event.startTime)} • ${event.location ?? 'No location'}'),
                          if (event.meetingLink?.isNotEmpty == true)
                            Text('Meeting Link: ${event.meetingLink}'),
                          Text('Created by: ${event.createdBy ?? 'Unknown User'}'),
                        ],
                      ),
                      trailing: _getEventStatusIcon(event),
                      onTap: () => _showEventDetails(event),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildJoinGroupButton() {
    // Don't show join button if user is already a member
    if (_currentGroup.isMember == true) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You are a member of this group',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _leaveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave Group'),
              ),
            ],
          ),
        ),
      );
    }

    // Show join button based on group type and join status
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = AppTheme.primaryColor;

    if (_currentGroup.isFull == true) {
      buttonText = 'Group is Full';
      onPressed = null;
      buttonColor = Colors.grey;
    } else if (_currentGroup.joinStatus == 'pending') {
      buttonText = 'Join Request Pending';
      onPressed = null;
      buttonColor = Colors.orange;
    } else if (_currentGroup.joinStatus == 'approved') {
      buttonText = 'Join Request Approved';
      onPressed = null;
      buttonColor = Colors.green;
    } else if (_currentGroup.joinStatus == 'rejected') {
      buttonText = 'Join Request Rejected';
      onPressed = _requestToJoinGroup;
      buttonColor = Colors.red;
    } else {
      // No join request yet
      if (_currentGroup.isPublic == true) {
        buttonText = _isJoining ? 'Joining...' : 'Join Group';
        onPressed = _isJoining ? null : _joinGroup;
      } else {
        buttonText = _isJoining ? 'Sending Request...' : 'Request to Join';
        onPressed = _isJoining ? null : _requestToJoinGroup;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _currentGroup.isPublic == true ? Icons.public : Icons.lock,
                  color: _currentGroup.isPublic == true ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentGroup.isPublic == true 
                        ? 'This is a public group. You can join directly.'
                        : 'This is a private group. You need admin approval to join.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Join Group methods
  Future<void> _joinGroup() async {
    if (_isJoining) return;
    
    setState(() {
      _isJoining = true;
    });
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.joinStudyGroup(_currentGroup.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Successfully joined the group')),
        );
        
        // Update the current group with the response data if available
        if (response['group'] != null) {
          final updatedGroup = StudyGroup.fromJson(response['group']);
          setState(() {
            _currentGroup = updatedGroup;
          });
        } else {
          // Fallback: refresh the group data
          await _loadGroupData();
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a "already a member" error
        String errorMessage = 'Failed to join group: $e';
        if (e.toString().contains('already a member')) {
          errorMessage = 'You are already a member of this group';
          // Refresh the group data to show correct state
          await _loadGroupData();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _requestToJoinGroup() async {
    // Show dialog for join request message
    final messageController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request to Join Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is a private group. Send a message to the admin explaining why you want to join:'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Tell the admin why you want to join this group...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isJoining = true;
      });
      
      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.joinStudyGroup(
          _currentGroup.id,
          message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Join request sent')),
          );
          
          // Update the current group with the response data if available
          if (response['group'] != null) {
            final updatedGroup = StudyGroup.fromJson(response['group']);
            setState(() {
              _currentGroup = updatedGroup;
            });
          } else {
            // Fallback: refresh the group data
            await _loadGroupData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send join request: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
    }
  }

  Future<void> _leaveGroup() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isJoining = true;
      });
      
      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.leaveStudyGroup(_currentGroup.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Successfully left the group')),
          );
          
          // Update the current group with the response data if available
          if (response['group'] != null) {
            final updatedGroup = StudyGroup.fromJson(response['group']);
            setState(() {
              _currentGroup = updatedGroup;
            });
          } else {
            // Fallback: refresh the group data
            await _loadGroupData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave group: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final groups = await apiService.getStudyGroups();
      
      // Find the current group in the updated list
      final updatedGroup = groups.firstWhere(
        (group) => group.id == _currentGroup.id,
        orElse: () => _currentGroup,
      );
      
      if (mounted) {
        setState(() {
          _currentGroup = updatedGroup;
        });
        print('Group data refreshed - isMember: ${updatedGroup.isMember}, memberCount: ${updatedGroup.currentMemberCount}');
      }
    } catch (e) {
      print('Error refreshing group data: $e');
    }
  }

  // Resource-related helper methods
  Future<List<GroupResource>> _loadResources() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getStudyGroupResources(_currentGroup.id);
    } catch (e) {
      print('Error loading resources: $e');
      rethrow;
    }
  }

  void _showFileUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _FileUploadDialog(
        groupId: _currentGroup.id,
        onUploaded: () {
          // Increment refresh key to force FutureBuilder to rebuild
          setState(() {
            _resourcesRefreshKey++;
          });
        },
      ),
    );
  }

  Widget _getResourceIcon(String? fileType) {
    switch (fileType) {
      case 'document':
        return const Icon(Icons.description, color: Colors.blue);
      case 'image':
        return const Icon(Icons.image, color: Colors.green);
      case 'video':
        return const Icon(Icons.video_file, color: Colors.red);
      case 'link':
        return const Icon(Icons.link, color: Colors.orange);
      default:
        return const Icon(Icons.attach_file, color: Colors.grey);
    }
  }

  String _formatFileSize(int? fileSize) {
    if (fileSize == null) return 'Unknown size';
    
    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  void _downloadResource(GroupResource resource) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.downloadStudyGroupResource(resource);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showResourceInfo(GroupResource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource.fileName ?? 'Resource Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${resource.fileType ?? 'Unknown'}'),
            Text('Size: ${_formatFileSize(resource.fileSize)}'),
            Text('Uploaded by: ${resource.uploadedByName ?? 'Unknown User'}'),
            Text('Uploaded: ${_formatDateTime(resource.uploadedAt)}'),
            if (resource.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(resource.description!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  // Event-related helper methods
  Future<List<GroupEvent>> _loadEvents() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getStudyGroupEvents(_currentGroup.id);
    } catch (e) {
      print('Error loading events: $e');
      rethrow;
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateEventDialog(
        groupId: _currentGroup.id,
        onEventCreated: () {
          // Increment refresh key to force FutureBuilder to rebuild
          setState(() {
            _eventsRefreshKey++;
          });
        },
      ),
    );
  }

  Widget _getEventIcon(String? eventType) {
    switch (eventType) {
      case 'study_session':
        return const Icon(Icons.school, color: Colors.orange);
      case 'exam_prep':
        return const Icon(Icons.quiz, color: Colors.red);
      case 'project_meeting':
        return const Icon(Icons.video_call, color: Colors.blue);
      case 'discussion':
        return const Icon(Icons.forum, color: Colors.green);
      case 'other':
        return const Icon(Icons.event, color: Colors.grey);
      default:
        return const Icon(Icons.event, color: Colors.grey);
    }
  }

  Widget _getEventStatusIcon(GroupEvent event) {
    final now = DateTime.now();
    if (event.startTime.isAfter(now)) {
      return const Icon(Icons.schedule, color: AppTheme.info);
    } else if (event.endTime != null && event.endTime!.isAfter(now)) {
      return const Icon(Icons.play_circle, color: AppTheme.success);
    } else {
      return const Icon(Icons.check_circle, color: AppTheme.grey500);
    }
  }

  void _showEventDetails(GroupEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title ?? 'Event Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.description?.isNotEmpty == true) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(event.description!),
                const SizedBox(height: 8),
              ],
              Text('Type: ${event.eventType ?? 'General'}'),
              Text('Start: ${_formatDateTime(event.startTime)}'),
              if (event.endTime != null)
                Text('End: ${_formatDateTime(event.endTime!)}'),
              if (event.location?.isNotEmpty == true)
                Text('Location: ${event.location}'),
              if (event.meetingLink?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                const Text('Meeting Link:', style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _launchUrl(event.meetingLink!),
                  child: Text(
                    event.meetingLink!,
                    style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
              ],
              if (event.maxAttendees != null)
                Text('Max Attendees: ${event.maxAttendees}'),
              Text('Created by: ${event.createdBy ?? 'Unknown User'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (event.meetingLink?.isNotEmpty == true)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchUrl(event.meetingLink!);
              },
              child: const Text('Join Meeting'),
            ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch URL: $url');
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
  }
}

class _CreateEventDialog extends ConsumerStatefulWidget {
  final int groupId;
  final VoidCallback onEventCreated;

  const _CreateEventDialog({
    required this.groupId,
    required this.onEventCreated,
  });

  @override
  ConsumerState<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  String _selectedEventType = 'study_session';
  DateTime _selectedStartTime = DateTime.now().add(const Duration(hours: 1));
  DateTime? _selectedEndTime;
  bool _isCreating = false;

  final List<String> _eventTypes = [
    'study_session',
    'exam_prep',
    'project_meeting',
    'discussion',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Group Discussion on Calculus',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Event Type
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getEventTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what this event is about...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Start Time
              ListTile(
                title: const Text('Start Time *'),
                subtitle: Text(_formatDateTime(_selectedStartTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartTime,
              ),
              const SizedBox(height: 8),
              
              // End Time
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(_selectedEndTime != null 
                    ? _formatDateTime(_selectedEndTime!) 
                    : 'Optional'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndTime,
              ),
              const SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Room 101, Library, Online',
                ),
              ),
              const SizedBox(height: 16),
              
              // Meeting Link
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., https://meet.google.com/abc-defg-hij',
                ),
              ),
              const SizedBox(height: 16),
              
              // Max Attendees
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(
                  labelText: 'Max Attendees',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
              
              if (_isCreating) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Creating event...'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createEvent,
          child: const Text('Create Event'),
        ),
      ],
    );
  }

  String _getEventTypeDisplayName(String type) {
    switch (type) {
      case 'study_session': return 'Study Session';
      case 'exam_prep': return 'Exam Preparation';
      case 'project_meeting': return 'Project Meeting';
      case 'discussion': return 'Discussion';
      case 'other': return 'Other';
      default: return type;
    }
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedStartTime),
      );
      
      if (time != null) {
        setState(() {
          _selectedStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndTime ?? _selectedStartTime.add(const Duration(hours: 1)),
      firstDate: _selectedStartTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? _selectedStartTime.add(const Duration(hours: 1))),
      );
      
      if (time != null) {
        setState(() {
          _selectedEndTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final request = GroupEventCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? '' 
            : _descriptionController.text.trim(),
        eventType: _selectedEventType,
        startTime: _selectedStartTime,
        endTime: _selectedEndTime,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        meetingLink: _meetingLinkController.text.trim().isEmpty 
            ? null 
            : _meetingLinkController.text.trim(),
        maxAttendees: _maxAttendeesController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_maxAttendeesController.text.trim()),
      );

      print('Creating event with request: ${request.toJson()}');
      print('Title: "${_titleController.text.trim()}"');
      print('Title length: ${_titleController.text.trim().length}');
      print('Title isEmpty: ${_titleController.text.trim().isEmpty}');
      final apiService = ref.read(apiServiceProvider);
      await apiService.createStudyGroupEvent(widget.groupId, request);

      if (mounted) {
        Navigator.pop(context);
        // Wait a moment for backend to process
        await Future.delayed(const Duration(milliseconds: 500));
        // Call the callback to refresh the events list
        widget.onEventCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

class _ChatMessageBubble extends ConsumerWidget {
  final GroupMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user ID to determine if message is from current user
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;
    final isCurrentUser = message.senderId != null && currentUserId != null && message.senderId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                (message.senderName?.isNotEmpty == true ? message.senderName![0] : '?').toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppTheme.primaryColor
                    : AppTheme.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.grey700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message.message ?? 'No message',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : AppTheme.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser
                          ? Colors.white70
                          : AppTheme.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _FileUploadDialog extends ConsumerStatefulWidget {
  final int groupId;
  final VoidCallback onUploaded;

  const _FileUploadDialog({
    required this.groupId,
    required this.onUploaded,
  });

  @override
  ConsumerState<_FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends ConsumerState<_FileUploadDialog> {
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  dynamic _selectedFile; // Changed from File? to dynamic to handle both File and PlatformFile
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Resource'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File Selection
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: _selectFile,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.file_present : Icons.cloud_upload,
                      size: 48,
                      color: _selectedFile != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile != null 
                          ? _getFileName(_selectedFile!)
                          : 'Tap to select file',
                      style: TextStyle(
                        color: _selectedFile != null ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change file',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add a description for this resource...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Category
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Notes, Assignments, Videos...',
              ),
            ),
            
            if (_isUploading) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading...'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedFile != null && !_isUploading ? _uploadFile : null,
          child: const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first; // Store PlatformFile directly
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  String _getFileName(dynamic file) {
    if (file is File) {
      return file.path.split('/').last;
    } else {
      // PlatformFile
      return file.name;
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
              await apiService.uploadStudyGroupResource(
                widget.groupId,
        _selectedFile!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}