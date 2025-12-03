import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';
import '../../providers/data_providers.dart';
import '../../models/meeting_model.dart';

class ScheduleMeetingScreen extends ConsumerStatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  ConsumerState<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends ConsumerState<ScheduleMeetingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

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

  Future<void> _handleScheduleMeeting() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // Create meeting request
        final meetingRequest = MeetingCreateRequest(
          title: formData['title'] as String,
          description: formData['description'] as String,
          type: formData['type'] as String,
          location: formData['location'] as String,
          scheduledDate: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
          duration: formData['duration'] as String,
          audience: formData['audience'] as String,
          notes: formData['notes'] as String?,
        );
        
        // Create meeting via API
        print('Creating meeting with request: ${meetingRequest.toJson()}');
        await ref.read(meetingsProvider.notifier).createMeeting(meetingRequest);
        print('Meeting created successfully');
        
        if (mounted) {
          SuccessSnackbar.show(context, 'Meeting scheduled successfully!');
          // Switch to view meetings tab
          _tabController.animateTo(1);
          // Reset form
          _formKey.currentState?.reset();
          setState(() {
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
          });
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to schedule meeting: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
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
        title: const Text('Schedule Meeting'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/faculty-dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Schedule Meeting'),
            Tab(text: 'View Meetings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(meetingsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleMeetingTab(),
          _buildViewMeetingsTab(),
        ],
      ),
      ),
    );
  }

  Widget _buildScheduleMeetingTab() {
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
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Meeting Title
                    FormBuilderTextField(
                      name: 'title',
                      decoration: const InputDecoration(
                        labelText: 'Meeting Title *',
                        hintText: 'Enter meeting title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(5),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    
                    // Meeting Description
                    FormBuilderTextField(
                      name: 'description',
                      decoration: const InputDecoration(
                        labelText: 'Meeting Description *',
                        hintText: 'Enter meeting description and agenda',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      maxLines: 4,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(10),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    
                    // Meeting Type
                    FormBuilderDropdown<String>(
                      name: 'type',
                      decoration: const InputDecoration(
                        labelText: 'Meeting Type *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'faculty', child: Text('Faculty Meeting')),
                        DropdownMenuItem(value: 'department', child: Text('Department Meeting')),
                        DropdownMenuItem(value: 'committee', child: Text('Committee Meeting')),
                        DropdownMenuItem(value: 'student', child: Text('Student Meeting')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    FormBuilderTextField(
                      name: 'location',
                      decoration: const InputDecoration(
                        labelText: 'Meeting Location *',
                        hintText: 'Enter meeting location (e.g., Conference Room A)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(3),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Selection
                    Text(
                      'Meeting Date',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Selection
                    Text(
                      'Meeting Time',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Duration
                    FormBuilderDropdown<String>(
                      name: 'duration',
                      decoration: const InputDecoration(
                        labelText: 'Meeting Duration *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: '30', child: Text('30 minutes')),
                        DropdownMenuItem(value: '60', child: Text('1 hour')),
                        DropdownMenuItem(value: '90', child: Text('1.5 hours')),
                        DropdownMenuItem(value: '120', child: Text('2 hours')),
                        DropdownMenuItem(value: '180', child: Text('3 hours')),
                      ],
                      validator: FormBuilderValidators.required(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participants',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target Audience
                    FormBuilderDropdown<String>(
                      name: 'audience',
                      decoration: const InputDecoration(
                        labelText: 'Target Audience *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all_faculty', child: Text('All Faculty')),
                        DropdownMenuItem(value: 'department', child: Text('Department Only')),
                        DropdownMenuItem(value: 'committee', child: Text('Committee Members')),
                        DropdownMenuItem(value: 'specific', child: Text('Specific People')),
                      ],
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Additional Notes
                    FormBuilderTextField(
                      name: 'notes',
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Any special instructions or requirements',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    onPressed: _handleScheduleMeeting,
                    isLoading: _isLoading,
                    child: const Text('Schedule Meeting'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/faculty-dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
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

  Widget _buildViewMeetingsTab() {
    final meetingsAsync = ref.watch(meetingsProvider);

    return ResponsiveContainer(
      maxWidth: Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: double.infinity,
        desktop: 1400,
      ),
      padding: EdgeInsets.zero,
      centerContent: false,
      child: meetingsAsync.when(
        data: (meetings) => meetings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 64,
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No meetings scheduled',
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
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(meeting.status).withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(meeting.status),
                        color: _getStatusColor(meeting.status),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (meeting.isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(meeting.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                meeting.statusDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(meeting.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                meeting.typeDisplayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meeting.scheduledDate.day}/${meeting.scheduledDate.month}/${meeting.scheduledDate.year} at ${meeting.scheduledDate.hour.toString().padLeft(2, '0')}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showMeetingDetails(meeting);
                    },
                  ),
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
              'Failed to load meetings',
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
                ref.read(meetingsProvider.notifier).refresh();
              },
            child: const Text('Retry'),
          ),
        ],
      ),
      ),
      ),
    );
  }

  void _showMeetingDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', meeting.description),
              _buildDetailRow('Type', meeting.typeDisplayName),
              _buildDetailRow('Location', meeting.location),
              _buildDetailRow('Date & Time', '${meeting.scheduledDate.day}/${meeting.scheduledDate.month}/${meeting.scheduledDate.year} at ${meeting.scheduledDate.hour.toString().padLeft(2, '0')}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}'),
              _buildDetailRow('Duration', '${meeting.duration} minutes'),
              _buildDetailRow('Audience', meeting.audienceDisplayName),
              _buildDetailRow('Status', meeting.statusDisplayName),
              if (meeting.notes != null && meeting.notes!.isNotEmpty)
                _buildDetailRow('Notes', meeting.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.grey700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.grey600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.event;
      case 'ongoing':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }
}
