import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../providers/data_providers.dart';
import '../../models/complaint_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../services/file_service.dart';

class ComplaintFormScreen extends ConsumerStatefulWidget {
  final Complaint? complaint;
  
  const ComplaintFormScreen({super.key, this.complaint});

  @override
  ConsumerState<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends ConsumerState<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _fileService = FileService();
  bool _isLoading = false;
  bool _isAnonymous = false;
  List<File> _attachments = [];

  @override
  Widget build(BuildContext context) {
    // Get current user info to pre-populate contact fields
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    
    // Update form fields with user data after form is built
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _formKey.currentState != null) {
          // Use patchValue to update form fields with user data
          _formKey.currentState!.patchValue({
            'contact_email': currentUser.email,
            'contact_phone': currentUser.phoneNumber ?? '',
          });
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.complaint == null ? 'Submit Complaint' : 'Edit Complaint'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Anonymous submission checkbox
              FormBuilderCheckbox(
                name: 'is_anonymous',
                title: const Text('Submit Anonymously'),
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Contact email - auto-populated from user profile
              FormBuilderTextField(
                name: 'contact_email',
                key: const Key('contact_email_field'),
                initialValue: currentUser?.email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Contact Email *',
                  hintText: 'your.email@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'Contact email is required'),
                  FormBuilderValidators.email(errorText: 'Please enter a valid email address'),
                ]),
              ),
              const SizedBox(height: 16),
              
              // Contact phone - auto-populated from user profile
              FormBuilderTextField(
                name: 'contact_phone',
                key: const Key('contact_phone_field'),
                initialValue: currentUser?.phoneNumber ?? '',
                decoration: const InputDecoration(
                  labelText: 'Contact Phone *',
                  hintText: 'Your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'Contact phone is required'),
                  FormBuilderValidators.minLength(10, errorText: 'Phone number must be at least 10 digits'),
                ]),
              ),
              const SizedBox(height: 16),
              
              // Title
              FormBuilderTextField(
                name: 'title',
                key: const Key('title_field'),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(5),
                ]),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              FormBuilderTextField(
                name: 'description',
                key: const Key('description_field'),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed description of the issue',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(20),
                ]),
              ),
              
              const SizedBox(height: 16),
              
              // Category
              FormBuilderDropdown<String>(
                name: 'category',
                key: const Key('category_dropdown'),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'academic', child: Text('Academic')),
                  DropdownMenuItem(value: 'infrastructure', child: Text('Infrastructure')),
                  DropdownMenuItem(value: 'hostel', child: Text('Hostel')),
                  DropdownMenuItem(value: 'cafeteria', child: Text('Cafeteria')),
                  DropdownMenuItem(value: 'transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'library', child: Text('Library')),
                  DropdownMenuItem(value: 'sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                validator: FormBuilderValidators.required(),
              ),
              
              const SizedBox(height: 16),
              
              // Priority
              FormBuilderDropdown<String>(
                name: 'urgency',
                key: const Key('priority_dropdown'),
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                validator: FormBuilderValidators.required(),
              ),
              
              const SizedBox(height: 16),
              
              // Location
              FormBuilderTextField(
                name: 'location',
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where did this issue occur?',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Attachments
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 8),
                          const Text('Attach Files'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Files'),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._attachments.map((file) => ListTile(
                          leading: const Icon(Icons.attachment),
                          title: Text(file.path.split('/').last),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                _attachments.remove(file);
                              });
                            },
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              LoadingButton(
                onPressed: _isLoading ? null : _submitComplaint,
                isLoading: _isLoading,
                child: Text(widget.complaint == null ? 'Submit Complaint' : 'Update Complaint'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt', 'mp4', 'avi', 'mov', 'mp3', 'wav'];
      final files = await _fileService.pickMultipleFiles(allowedExtensions: allowedExtensions);

      if (files.isNotEmpty) {
        setState(() {
          _attachments = files;
        });
        
        if (mounted) {
          SuccessSnackbar.show(context, '${_attachments.length} file(s) selected');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Error picking files: $e');
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        final apiService = ref.read(apiServiceProvider);
        final authState = ref.read(authStateProvider);
        final currentUser = authState.user;
        
        final complaintRequest = ComplaintCreateRequest(
          title: formData['title'],
          description: formData['description'] ?? '',
          category: formData['category'],
          urgency: formData['urgency'],
          location: formData['location'] ?? '',
          contactEmail: formData['contact_email']?.toString().trim().isNotEmpty == true 
              ? formData['contact_email'] 
              : currentUser?.email,
          contactPhone: formData['contact_phone']?.toString().trim().isNotEmpty == true 
              ? formData['contact_phone'] 
              : currentUser?.phoneNumber,
          attachments: _attachments.isNotEmpty ? _attachments.map((file) => file.path).toList() : null,
        );

        if (widget.complaint == null) {
          await apiService.createComplaint(complaintRequest);
          if (mounted) {
            ErrorSnackbar.show(context, 'Complaint submitted successfully!', isError: false);
            context.pop();
          }
        } else {
          // TODO: Implement complaint update functionality
          if (mounted) {
            ErrorSnackbar.show(context, 'Complaint update not implemented yet');
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Error submitting complaint: $e');
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
