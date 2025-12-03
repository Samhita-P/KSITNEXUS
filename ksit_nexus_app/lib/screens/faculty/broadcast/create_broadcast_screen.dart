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

class CreateBroadcastScreen extends ConsumerStatefulWidget {
  const CreateBroadcastScreen({super.key});

  @override
  ConsumerState<CreateBroadcastScreen> createState() => _CreateBroadcastScreenState();
}

class _CreateBroadcastScreenState extends ConsumerState<CreateBroadcastScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _scheduleForLater = false;
  bool _setExpiry = false;
  
  final List<String> _broadcastTypes = [
    'announcement',
    'event',
    'alert',
    'news',
    'maintenance',
  ];
  
  final List<String> _priorityLevels = [
    'normal',
    'important',
    'urgent',
    'critical',
  ];
  
  final List<String> _targetAudiences = [
    'all',
    'students',
    'faculty',
    'staff',
    'specific',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Broadcast'),
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
              // Refresh broadcasts
              ref.invalidate(broadcastsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 800,
          desktop: 1000,
        ),
        padding: EdgeInsets.zero,
        centerContent: false,
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 20),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Title
                FormBuilderTextField(
                  name: 'title',
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter broadcast title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'Title is required',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Content
                FormBuilderTextField(
                  name: 'content',
                  decoration: InputDecoration(
                    labelText: 'Content *',
                    hintText: 'Enter broadcast content',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  validator: FormBuilderValidators.required(
                    errorText: 'Content is required',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Broadcast Type
                FormBuilderDropdown<String>(
                  name: 'broadcast_type',
                  decoration: InputDecoration(
                    labelText: 'Broadcast Type *',
                    hintText: 'Select broadcast type',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _broadcastTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type[0].toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  validator: FormBuilderValidators.required(
                    errorText: 'Broadcast type is required',
                  ),
                  initialValue: 'announcement',
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Priority
                FormBuilderDropdown<String>(
                  name: 'priority',
                  decoration: InputDecoration(
                    labelText: 'Priority *',
                    hintText: 'Select priority level',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _priorityLevels
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority[0].toUpperCase() + priority.substring(1)),
                          ))
                      .toList(),
                  validator: FormBuilderValidators.required(
                    errorText: 'Priority is required',
                  ),
                  initialValue: 'normal',
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
                
                Text(
                  'Targeting',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 20),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Target Audience
                FormBuilderDropdown<String>(
                  name: 'target_audience',
                  decoration: InputDecoration(
                    labelText: 'Target Audience *',
                    hintText: 'Select target audience',
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _targetAudiences
                      .map((audience) => DropdownMenuItem(
                            value: audience,
                            child: Text(_getTargetAudienceLabel(audience)),
                          ))
                      .toList(),
                  validator: FormBuilderValidators.required(
                    errorText: 'Target audience is required',
                  ),
                  initialValue: 'all',
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Target Departments (optional)
                FormBuilderTextField(
                  name: 'target_departments',
                  decoration: InputDecoration(
                    labelText: 'Target Departments (comma-separated)',
                    hintText: 'e.g., Computer Science, Electronics',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Target Courses (optional)
                FormBuilderTextField(
                  name: 'target_courses',
                  decoration: InputDecoration(
                    labelText: 'Target Courses (comma-separated)',
                    hintText: 'e.g., CS101, EE201',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
                
                Text(
                  'Scheduling',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 20),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Schedule for Later
                FormBuilderCheckbox(
                  name: 'schedule_for_later',
                  title: const Text('Schedule for Later'),
                  initialValue: false,
                  onChanged: (value) {
                    setState(() {
                      _scheduleForLater = value ?? false;
                    });
                  },
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                
                // Scheduled At
                if (_scheduleForLater)
                  FormBuilderDateTimePicker(
                    name: 'scheduled_at',
                    decoration: InputDecoration(
                      labelText: 'Scheduled At *',
                      hintText: 'Select scheduled time',
                      prefixIcon: const Icon(Icons.schedule),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _scheduleForLater
                        ? FormBuilderValidators.required(
                            errorText: 'Scheduled time is required',
                          )
                        : null,
                    initialValue: DateTime.now().add(const Duration(hours: 1)),
                    inputType: InputType.both,
                    format: DateFormat('yyyy-MM-dd HH:mm'),
                  ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Set Expiry
                FormBuilderCheckbox(
                  name: 'set_expiry',
                  title: const Text('Set Expiry Date'),
                  initialValue: false,
                  onChanged: (value) {
                    setState(() {
                      _setExpiry = value ?? false;
                    });
                  },
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16)),
                
                // Expires At
                if (_setExpiry)
                  FormBuilderDateTimePicker(
                    name: 'expires_at',
                    decoration: InputDecoration(
                      labelText: 'Expires At *',
                      hintText: 'Select expiry time',
                      prefixIcon: const Icon(Icons.event_busy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _setExpiry
                        ? FormBuilderValidators.required(
                            errorText: 'Expiry time is required',
                          )
                        : null,
                    initialValue: DateTime.now().add(const Duration(days: 7)),
                    inputType: InputType.both,
                    format: DateFormat('yyyy-MM-dd HH:mm'),
                  ),
                SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
                
                Text(
                  'Publish Options',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 20),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20)),
                
                // Publish Immediately
                FormBuilderCheckbox(
                  name: 'publish_immediately',
                  title: const Text('Publish Immediately'),
                  initialValue: true,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 32, tablet: 40)),
                
                // Submit Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.spacing(context, mobile: 16, tablet: 20),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.spacing(context, mobile: 12, tablet: 16)),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
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
                                'Create Broadcast',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTargetAudienceLabel(String audience) {
    switch (audience) {
      case 'all':
        return 'All Users';
      case 'students':
        return 'Students Only';
      case 'faculty':
        return 'Faculty Only';
      case 'staff':
        return 'Staff Only';
      case 'specific':
        return 'Specific Users/Groups';
      default:
        return audience;
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        
        final data = {
          'title': formData['title'],
          'content': formData['content'],
          'broadcast_type': formData['broadcast_type'] ?? 'announcement',
          'priority': formData['priority'] ?? 'normal',
          'target_audience': formData['target_audience'] ?? 'all',
          if (formData['target_departments'] != null && formData['target_departments'].toString().isNotEmpty)
            'target_departments': (formData['target_departments'] as String)
                .split(',')
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty)
                .toList(),
          if (formData['target_courses'] != null && formData['target_courses'].toString().isNotEmpty)
            'target_courses': (formData['target_courses'] as String)
                .split(',')
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList(),
          if (formData['scheduled_at'] != null)
            'scheduled_at': (formData['scheduled_at'] as DateTime).toIso8601String(),
          if (formData['expires_at'] != null)
            'expires_at': (formData['expires_at'] as DateTime).toIso8601String(),
          'is_published': formData['publish_immediately'] ?? false,
        };

        final broadcast = await ref.read(broadcastsProvider.notifier).createBroadcast(data);
        
        // If publish immediately is checked, publish the broadcast
        if (formData['publish_immediately'] == true) {
          await ref.read(broadcastsProvider.notifier).publishBroadcast(broadcast.id);
        }
        
        if (mounted) {
          SuccessSnackbar.show(context, 'Broadcast created successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to create broadcast: ${e.toString()}');
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
}













