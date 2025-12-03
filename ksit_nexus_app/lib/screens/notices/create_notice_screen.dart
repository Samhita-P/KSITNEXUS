import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../providers/data_providers.dart';
import '../../models/notice_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';

class CreateNoticeScreen extends ConsumerStatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  ConsumerState<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends ConsumerState<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isSavingDraft = false;
  String _selectedPriority = 'medium';
  DateTime _selectedDate = DateTime.now();

  Future<void> _handleCreateNotice() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // Create notice request
        final notice = Notice(
          id: DateTime.now().millisecondsSinceEpoch,
          title: formData['title'],
          content: formData['content'],
          priority: _selectedPriority,
          category: formData['category'],
          targetAudience: formData['targetAudience'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdById: 1, // TODO: Get from auth
          createdByName: 'Current User', // TODO: Get from auth
          createdByRole: 'user', // TODO: Get from auth
          isPinned: false,
          viewCount: 0,
          views: [],
          expiresAt: _selectedDate,
          status: 'published', // Set as published when creating
        );
        
        // Create notice request object
        final noticeRequest = NoticeCreateRequest(
          title: formData['title'],
          content: formData['content'],
          category: formData['category'],
          priority: _selectedPriority,
          targetAudience: formData['targetAudience'],
          expiresAt: _selectedDate,
          isPinned: false,
          status: 'published',
        );
        
        // Call the actual API
        final createdNotice = await ref.read(noticesProvider.notifier).createNotice(noticeRequest);
        
        if (mounted) {
          // Refresh the notices list to ensure the new notice is available
          await ref.read(noticesProvider.notifier).refresh();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(createdNotice.id > 0 
                ? 'Notice published successfully! ID: ${createdNotice.id}'
                : 'Notice published successfully!'),
              backgroundColor: Colors.green,
              action: createdNotice.id > 0
                ? SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to notice detail after a short delay to ensure it's available
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          context.go('/notices/${createdNotice.id}');
                        }
                      });
                    },
                  )
                : null,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Navigate to notices list (user can click "View" in snackbar to see detail)
          context.go('/notices');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to publish notice: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isSavingDraft = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // Create draft notice
        final notice = Notice(
          id: DateTime.now().millisecondsSinceEpoch,
          title: formData['title'],
          content: formData['content'],
          priority: _selectedPriority,
          category: formData['category'],
          targetAudience: formData['targetAudience'],
          isActive: false, // Draft is not active
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdById: 1, // TODO: Get from auth
          createdByName: 'Current User', // TODO: Get from auth
          createdByRole: 'user', // TODO: Get from auth
          isPinned: false,
          viewCount: 0,
          views: [],
          expiresAt: _selectedDate,
          status: 'draft', // Set as draft
        );
        
        // Create draft notice request object
        final draftRequest = NoticeCreateRequest(
          title: formData['title'],
          content: formData['content'],
          category: formData['category'],
          priority: _selectedPriority,
          targetAudience: formData['targetAudience'],
          expiresAt: _selectedDate,
          isPinned: false,
          status: 'draft',
        );
        
        // Call the actual API to save draft
        await ref.read(apiServiceProvider).createNotice(draftRequest);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft saved successfully'),
              backgroundColor: Colors.blue,
            ),
          );
          context.go('/notices');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to save draft: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isSavingDraft = false);
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
        title: const Text('Create Notice'),
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
            onPressed: () {
              ref.read(noticesProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveContainer(
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
                        'Notice Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      FormBuilderTextField(
                        name: 'title',
                        decoration: const InputDecoration(
                          labelText: 'Notice Title *',
                          hintText: 'Enter a clear, descriptive title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(5),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      
                      // Content
                      FormBuilderTextField(
                        name: 'content',
                        decoration: const InputDecoration(
                          labelText: 'Notice Content *',
                          hintText: 'Enter the detailed content of the notice',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        maxLines: 5,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(10),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category
                      FormBuilderDropdown<String>(
                        name: 'category',
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'academic', child: Text('Academic')),
                          DropdownMenuItem(value: 'administrative', child: Text('Administrative')),
                          DropdownMenuItem(value: 'event', child: Text('Event')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                        ],
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Target Audience
                      FormBuilderDropdown<String>(
                        name: 'targetAudience',
                        decoration: const InputDecoration(
                          labelText: 'Target Audience *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Users')),
                          DropdownMenuItem(value: 'students', child: Text('Students Only')),
                          DropdownMenuItem(value: 'faculty', child: Text('Faculty & Staff')),
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
                        'Priority & Scheduling',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Priority
                      Text(
                        'Priority Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Low'),
                              value: 'low',
                              groupValue: _selectedPriority,
                              onChanged: (value) {
                                setState(() => _selectedPriority = value!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Medium'),
                              value: 'medium',
                              groupValue: _selectedPriority,
                              onChanged: (value) {
                                setState(() => _selectedPriority = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('High'),
                              value: 'high',
                              groupValue: _selectedPriority,
                              onChanged: (value) {
                                setState(() => _selectedPriority = value!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Urgent'),
                              value: 'urgent',
                              groupValue: _selectedPriority,
                              onChanged: (value) {
                                setState(() => _selectedPriority = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Expiry Date
                      Text(
                        'Notice Expiry Date',
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
                      onPressed: _handleCreateNotice,
                      isLoading: _isLoading,
                      child: const Text('Publish Notice'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSavingDraft ? null : _handleSaveDraft,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSavingDraft
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Draft'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Cancel button
              OutlinedButton(
                onPressed: () => context.go('/notices'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}
