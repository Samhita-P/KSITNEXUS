import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';
import '../../services/file_service.dart';
import '../../utils/image_url_helper.dart';
import '../auth/two_factor_setup_screen.dart';
import '../auth/device_sessions_screen.dart';
import '../auth/change_password_screen.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _fileService = FileService();
  bool _isLoading = false;
  bool _isEditing = false;
  int _formKeyValue = 0; // Counter to force form rebuild

  // List of valid branch options
  static const List<String> _branchOptions = [
    'Computer Science and Engineering',
    'Electronics and Communication Engineering',
    'Electrical and Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Information Science and Engineering',
    'Telecommunication Engineering',
    'Aerospace Engineering',
    'Chemical Engineering',
    'Biotechnology',
    'General',
  ];

  /// Normalize branch value to match dropdown items
  /// Maps common variations to exact dropdown values
  String _normalizeBranch(String? branch) {
    if (branch == null || branch.isEmpty || branch.trim().isEmpty) {
      print('Normalizing branch: null/empty -> General');
      return 'General';
    }
    
    final trimmed = branch.trim();
    final normalized = trimmed.toLowerCase();
    
    print('Normalizing branch: "$trimmed" (normalized: "$normalized")');
    
    // Exact match check (case-insensitive) - check if normalized matches any option
    for (final option in _branchOptions) {
      final optionNormalized = option.toLowerCase();
      if (optionNormalized == normalized) {
        print('Found exact match: "$trimmed" -> "$option"');
        return option;
      }
    }
    
    // Partial match for common variations
    // Check if normalized contains key words from each branch
    // Order matters - check more specific matches first
    
    // Computer Science variations
    if ((normalized.contains('computer') && normalized.contains('science')) ||
        normalized == 'cse' ||
        normalized == 'cs') {
      print('Found partial match (computer + science): "$trimmed" -> "Computer Science and Engineering"');
      return 'Computer Science and Engineering';
    }
    
    // Electronics and Communication variations
    if ((normalized.contains('electronics') && normalized.contains('communication')) ||
        normalized.contains('ece') ||
        (normalized.contains('electronics') && !normalized.contains('electrical'))) {
      print('Found partial match (electronics + communication): "$trimmed" -> "Electronics and Communication Engineering"');
      return 'Electronics and Communication Engineering';
    }
    
    // Electrical and Electronics variations
    if (normalized.contains('electrical') && normalized.contains('electronics')) {
      print('Found partial match (electrical + electronics): "$trimmed" -> "Electrical and Electronics Engineering"');
      return 'Electrical and Electronics Engineering';
    } else if (normalized.contains('eee') || normalized == 'electrical') {
      print('Found partial match (electrical): "$trimmed" -> "Electrical and Electronics Engineering"');
      return 'Electrical and Electronics Engineering';
    }
    
    // Information Science variations
    if ((normalized.contains('information') && normalized.contains('science')) ||
        normalized == 'ise') {
      print('Found partial match (information + science): "$trimmed" -> "Information Science and Engineering"');
      return 'Information Science and Engineering';
    }
    
    // Mechanical variations
    if (normalized.contains('mechanical') || normalized == 'mech') {
      print('Found partial match (mechanical): "$trimmed" -> "Mechanical Engineering"');
      return 'Mechanical Engineering';
    }
    
    // Civil variations
    if (normalized.contains('civil') || normalized == 'ce') {
      print('Found partial match (civil): "$trimmed" -> "Civil Engineering"');
      return 'Civil Engineering';
    }
    
    // Telecommunication variations
    if (normalized.contains('telecommunication') || normalized == 'tce') {
      print('Found partial match (telecommunication): "$trimmed" -> "Telecommunication Engineering"');
      return 'Telecommunication Engineering';
    }
    
    // Aerospace variations
    if (normalized.contains('aerospace') || normalized.contains('aero')) {
      print('Found partial match (aerospace): "$trimmed" -> "Aerospace Engineering"');
      return 'Aerospace Engineering';
    }
    
    // Chemical variations
    if (normalized.contains('chemical') || normalized == 'chem') {
      print('Found partial match (chemical): "$trimmed" -> "Chemical Engineering"');
      return 'Chemical Engineering';
    }
    
    // Biotechnology variations
    if (normalized.contains('biotechnology') || normalized == 'biotech' || normalized == 'bio') {
      print('Found partial match (biotechnology): "$trimmed" -> "Biotechnology"');
      return 'Biotechnology';
    }
    
    // General variations
    if (normalized == 'general' || normalized.isEmpty) {
      print('Found exact match for General: "$trimmed" -> "General"');
      return 'General';
    }
    
    // Default fallback - always return a valid option
    print('No match found for "$trimmed", using default: "General"');
    // Double-check that we're returning a valid option
    if (_branchOptions.contains('General')) {
      return 'General';
    }
    // If General is not available (shouldn't happen), return the first option
    return _branchOptions.isNotEmpty ? _branchOptions.first : 'General';
  }

  @override
  void initState() {
    super.initState();
    // Refresh auth state when profile screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).refreshAuthState().then((_) {
        // After auth state is refreshed, populate form with the data
        _populateFormWithUserData();
      });
    });
  }
  
  void _populateFormWithUserData() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    
    if (user != null && mounted) {
      print('Populating form with user data: ${user.email}');
      print('Student profile ID: ${user.studentProfile?.studentId}');
      print('Year of study: ${user.studentProfile?.yearOfStudy}');
      print('Branch: ${user.studentProfile?.branch}');
      
      final values = {
        'firstName': user.firstName ?? '',
        'lastName': user.lastName ?? '',
        'email': user.email,
        'phoneNumber': user.phoneNumber ?? '',
        if (user.isStudent) ...{
          'studentId': user.studentProfile?.studentId ?? '',
          'yearOfStudy': user.studentProfile?.yearOfStudy ?? 1,
          'branch': _normalizeBranch(user.studentProfile?.branch),
          'section': user.studentProfile?.section ?? '',
          'bio': user.studentProfile?.bio ?? '',
          'interests': user.studentProfile?.interests.join(', ') ?? '',
        },
      };
      
      print('Setting form values: $values');
      _formKey.currentState?.patchValue(values);
      print('Form values set!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    print('Profile screen - Auth state: isLoading=${authState.isLoading}, isAuthenticated=${authState.isAuthenticated}, user=${authState.user?.email}');
    
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view your profile'),
        ),
      );
    }

    final user = authState.user!;

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
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Navigate based on user role
              if (user.isStudent) {
                context.go('/home');
              } else {
                context.go('/faculty-dashboard');
              }
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(authStateProvider.notifier).refreshAuthState();
            },
            tooltip: 'Refresh',
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
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
            // Profile Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: ImageUrlHelper.getProfilePictureUrl(
                            user.studentProfile?.profilePicture ?? user.facultyProfile?.profilePicture
                          ) != null
                              ? NetworkImage(ImageUrlHelper.getProfilePictureUrl(
                                  user.studentProfile?.profilePicture ?? user.facultyProfile?.profilePicture
                                )!)
                              : null,
                          child: user.studentProfile?.profilePicture == null &&
                                  user.facultyProfile?.profilePicture == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // User Info
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isStudent
                            ? AppTheme.success.withOpacity(0.1)
                            : user.isFaculty
                                ? AppTheme.info.withOpacity(0.1)
                                : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        (user.userType ?? 'unknown').toUpperCase(),
                        style: TextStyle(
                          color: user.isStudent
                              ? AppTheme.success
                              : user.isFaculty
                                  ? AppTheme.info
                                  : AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Profile Form
            Card(
              key: ValueKey('profile_form_${user.id}_${_formKeyValue}'),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Builder(
                  builder: (context) {
                    // Ensure branch is normalized before creating the form
                    final normalizedBranch = user.isStudent 
                        ? _normalizeBranch(user.studentProfile?.branch)
                        : 'General';
                    final yearOfStudy = user.isStudent 
                        ? (user.studentProfile?.yearOfStudy ?? 1)
                        : 1;
                    
                    // Validate that normalizedBranch is in the options list
                    // FormBuilderDropdown requires exact match, so ensure it's valid
                    final validBranch = _branchOptions.contains(normalizedBranch) 
                        ? normalizedBranch 
                        : 'General';
                    
                    // Validate that yearOfStudy is valid (1-4)
                    final validYearOfStudy = (yearOfStudy >= 1 && yearOfStudy <= 4) 
                        ? yearOfStudy 
                        : 1;
                    
                    // Double-check: if normalizedBranch is not in options, use General
                    final finalBranch = _branchOptions.contains(validBranch) ? validBranch : 'General';
                    
                    print('Building form - Original branch: "${user.studentProfile?.branch}"');
                    print('  -> Normalized: "$normalizedBranch"');
                    print('  -> Valid: "$validBranch"');
                    print('  -> Final: "$finalBranch"');
                    print('  -> Is in options: ${_branchOptions.contains(finalBranch)}');
                    print('Year of study: $yearOfStudy -> valid: $validYearOfStudy');
                    
                    // Build initial values map
                    final initialValues = <String, dynamic>{
                      'firstName': user.firstName ?? '',
                      'lastName': user.lastName ?? '',
                      'email': user.email,
                      'phoneNumber': user.phoneNumber ?? '',
                    };
                    
                    if (user.isStudent) {
                      initialValues.addAll({
                        'studentId': user.studentProfile?.studentId ?? '',
                        'yearOfStudy': validYearOfStudy,
                        'branch': finalBranch, // Always use validated branch
                        'section': user.studentProfile?.section ?? '',
                        'bio': user.studentProfile?.bio ?? '',
                        'interests': user.studentProfile?.interests.join(', ') ?? '',
                      });
                    }
                    
                    print('Initial values: $initialValues');
                    
                    return FormBuilder(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      initialValue: initialValues,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'firstName',
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              enabled: _isEditing,
                              validator: FormBuilderValidators.compose([
                                // No validation required - all fields are optional
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'lastName',
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              enabled: _isEditing,
                              validator: FormBuilderValidators.compose([
                                // No validation required - all fields are optional
                              ]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      FormBuilderTextField(
                        name: 'email',
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        enabled: false, // Email cannot be changed
                      ),
                      const SizedBox(height: 16),
                      
                      FormBuilderTextField(
                        name: 'phoneNumber',
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        enabled: _isEditing,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                      
                      // Student profile fields INSIDE the form
                      if (user.isStudent) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Academic Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderTextField(
                          name: 'studentId',
                          decoration: InputDecoration(
                            labelText: 'Student ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderDropdown<int>(
                          name: 'yearOfStudy',
                          decoration: InputDecoration(
                            labelText: 'Year of Study *',
                            prefixIcon: Icon(Icons.school_outlined),
                            hintText: 'Select year',
                          ),
                          enabled: _isEditing,
                          items: [1, 2, 3, 4]
                              .map((year) => DropdownMenuItem(
                                    value: year,
                                    child: Text('Year $year'),
                                  ))
                              .toList(),
                          validator: _isEditing
                              ? FormBuilderValidators.required(errorText: 'Year of study is required')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderDropdown<String>(
                          name: 'branch',
                          decoration: InputDecoration(
                            labelText: 'Branch *',
                            prefixIcon: Icon(Icons.engineering_outlined),
                            hintText: 'Select branch',
                          ),
                          enabled: _isEditing,
                          items: _branchOptions
                              .map((branch) => DropdownMenuItem(
                                    value: branch,
                                    child: Text(branch),
                                  ))
                              .toList(),
                          validator: _isEditing
                              ? FormBuilderValidators.required(errorText: 'Branch is required')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderTextField(
                          name: 'section',
                          decoration: InputDecoration(
                            labelText: 'Section (Optional)',
                            prefixIcon: Icon(Icons.group_outlined),
                            hintText: 'e.g., A, B, C',
                          ),
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderTextField(
                          name: 'bio',
                          decoration: InputDecoration(
                            labelText: 'Bio (Optional)',
                            prefixIcon: Icon(Icons.description_outlined),
                            hintText: 'Tell us about yourself...',
                          ),
                          enabled: _isEditing,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        FormBuilderTextField(
                          name: 'interests',
                          decoration: InputDecoration(
                            labelText: 'Interests (Optional)',
                            prefixIcon: Icon(Icons.favorite_outline),
                            hintText: 'e.g., Programming, Music, Sports',
                          ),
                          enabled: _isEditing,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
            
            const SizedBox(height: 24),
            
            // Security Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.security, color: AppTheme.primaryColor),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Add an extra layer of security'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TwoFactorSetupScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.devices, color: AppTheme.primaryColor),
                      title: const Text('Device Sessions'),
                      subtitle: const Text('Manage your active devices'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DeviceSessionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_isEditing) ...[
              LoadingButton(
                onPressed: _saveProfile,
                isLoading: _isLoading,
                child: const Text('Save Changes'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change Password'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildStudentProfileInline(StudentProfile? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Student ID
            FormBuilderTextField(
              name: 'studentId',
              decoration: InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              validator: FormBuilderValidators.compose([
                // No validation required - all fields are optional
              ]),
            ),
            const SizedBox(height: 16),
            
            // Year of Study
            FormBuilderTextField(
              name: 'yearOfStudy',
              decoration: InputDecoration(
                labelText: 'Year of Study',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
                hintText: 'e.g., 1, 2, 3, 4',
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                if (_isEditing) FormBuilderValidators.required(),
                if (_isEditing) FormBuilderValidators.numeric(),
                if (_isEditing) FormBuilderValidators.min(1),
                if (_isEditing) FormBuilderValidators.max(4),
              ]),
            ),
            const SizedBox(height: 16),
            
            // Branch
            FormBuilderTextField(
              name: 'branch',
              decoration: InputDecoration(
                labelText: 'Branch',
                prefixIcon: Icon(Icons.engineering_outlined),
                border: OutlineInputBorder(),
                hintText: 'e.g., Computer Science, Electronics',
              ),
              enabled: _isEditing,
              validator: FormBuilderValidators.compose([
                // No validation required - all fields are optional
              ]),
            ),
            const SizedBox(height: 16),
            
            // Section (optional)
            FormBuilderTextField(
              name: 'section',
              decoration: InputDecoration(
                labelText: 'Section (Optional)',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
                hintText: 'e.g., A, B, C',
              ),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            
            // Bio (optional)
            FormBuilderTextField(
              name: 'bio',
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
                hintText: 'Tell us about yourself...',
              ),
              enabled: _isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Interests (optional)
            FormBuilderTextField(
              name: 'interests',
              decoration: InputDecoration(
                labelText: 'Interests (Optional)',
                prefixIcon: Icon(Icons.favorite_outline),
                border: OutlineInputBorder(),
                hintText: 'e.g., Programming, Music, Sports',
              ),
              enabled: _isEditing,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFacultyProfile(FacultyProfile? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            if (profile != null) ...[
              _buildInfoRow('Employee ID', profile.employeeId),
              _buildInfoRow('Department', profile.department),
              _buildInfoRow('Designation', profile.designation),
              if (profile.bio != null && profile.bio!.isNotEmpty)
                _buildInfoRow('Bio', profile.bio!),
              if (profile.specializations.isNotEmpty)
                _buildInfoRow('Specializations', profile.specializations.join(', ')),
            ] else ...[
              _buildInfoRow('Employee ID', 'Not available'),
              _buildInfoRow('Department', 'Not available'),
              _buildInfoRow('Designation', 'Not available'),
              const SizedBox(height: 16),
              Text(
                'Complete your professional profile to see detailed information.',
                style: TextStyle(
                  color: AppTheme.grey600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Future<void> _pickProfilePicture() async {
    try {
      final image = await _fileService.pickImageFromGallery();
      if (image != null) {
        setState(() => _isLoading = true);
        
        // Upload profile picture to backend
        final apiService = ref.read(apiServiceProvider);
        final imageUrl = await apiService.uploadProfilePictureFromFile(image);
        
        // Update user profile with new image URL
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.updateProfilePicture(imageUrl);
        
        if (mounted) {
          SuccessSnackbar.show(context, 'Profile picture updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to update profile picture: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        print('Form data captured: $formData'); // Debug logging
        final apiService = ref.read(apiServiceProvider);
        final authNotifier = ref.read(authStateProvider.notifier);
        
        // Safely extract form data with null safety
        final firstName = formData['firstName']?.toString() ?? '';
        final lastName = formData['lastName']?.toString() ?? '';
        final phoneNumber = formData['phoneNumber']?.toString();
        
        print('Extracted basic data - firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber'); // Debug logging
        
        // All fields are now optional - no validation required
        
        // Update basic profile information
        await authNotifier.updateProfile(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        );
        
        // Update student profile if user is a student
        final authState = ref.read(authStateProvider);
        print('User type: ${authState.user?.userType}'); // Debug logging
        print('Has student profile: ${authState.user?.studentProfile != null}'); // Debug logging
        if (authState.user?.userType == 'student') {
          final studentId = formData['studentId']?.toString().trim() ?? '';
          final yearOfStudyValue = formData['yearOfStudy'];
          final branch = formData['branch']?.toString().trim() ?? '';
          final section = formData['section']?.toString().trim();
          final bio = formData['bio']?.toString().trim();
          final interestsStr = formData['interests']?.toString().trim();
          
          // Parse year of study - handle both int and string
          int yearOfStudy = 1;
          if (yearOfStudyValue != null) {
            if (yearOfStudyValue is int) {
              yearOfStudy = yearOfStudyValue;
            } else if (yearOfStudyValue is String && yearOfStudyValue.isNotEmpty) {
              try {
                yearOfStudy = int.parse(yearOfStudyValue);
              } catch (e) {
                print('Invalid year of study: $yearOfStudyValue');
                yearOfStudy = 1;
              }
            }
          }
          
          // Validate required fields
          if (branch.isEmpty) {
            if (mounted) {
              ErrorSnackbar.show(context, 'Branch is required');
              setState(() => _isLoading = false);
            }
            return;
          }
          
          // Parse interests
          List<String>? interests;
          if (interestsStr != null && interestsStr.isNotEmpty) {
            interests = interestsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          
          print('Saving student profile - studentId: $studentId, yearOfStudy: $yearOfStudy, branch: $branch, section: $section'); // Debug logging
          
          final currentUser = ref.read(authStateProvider).user;
          if (currentUser != null) {
            try {
              // Always try to update/create student profile with the provided data
              final finalStudentId = studentId.isNotEmpty ? studentId : 'STU_${currentUser.id}';
              
              try {
                // First try to update existing profile
                await apiService.updateStudentProfile(
                  studentId: finalStudentId,
                  yearOfStudy: yearOfStudy,
                  branch: branch,
                  section: section?.isNotEmpty == true ? section : null,
                  bio: bio?.isNotEmpty == true ? bio : null,
                  interests: interests,
                );
                print('Student profile updated successfully'); // Debug logging
              } catch (e) {
                print('Student profile update failed: $e'); // Debug logging
                // If update fails (profile doesn't exist), create it
                try {
                  await apiService.createStudentProfile(
                    studentId: finalStudentId,
                    yearOfStudy: yearOfStudy,
                    branch: branch,
                    section: section?.isNotEmpty == true ? section : null,
                    bio: bio?.isNotEmpty == true ? bio : null,
                    interests: interests,
                  );
                  print('Student profile created successfully'); // Debug logging
                } catch (createError) {
                  print('Student profile creation also failed: $createError'); // Debug logging
                  rethrow; // Rethrow to show error to user
                }
              }
            } catch (e) {
              print('Error saving student profile: $e'); // Debug logging
              if (mounted) {
                ErrorSnackbar.show(context, 'Failed to update student profile: ${e.toString()}');
                setState(() => _isLoading = false);
              }
              return;
            }
          }
        }
        
        // Refresh auth state to get updated data
        await authNotifier.refreshAuthState();
        
        // Wait for the state to be updated
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Turn off editing mode and refresh form
        if (mounted) {
          // Increment form key to force rebuild with fresh data
          setState(() {
            _isEditing = false;
            _formKeyValue++; // Force form rebuild with new data
          });
          
          // Wait a bit for the rebuild, then show success message
          await Future.delayed(const Duration(milliseconds: 100));
          
          SuccessSnackbar.show(context, 'Profile updated successfully!');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Failed to update profile: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _cancelEdit() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    
    // Reset form to original values
    if (user != null) {
      _formKey.currentState?.patchValue({
        'firstName': user.firstName ?? '',
        'lastName': user.lastName ?? '',
        'email': user.email,
        'phoneNumber': user.phoneNumber ?? '',
        if (user.isStudent) ...{
          'studentId': user.studentProfile?.studentId ?? '',
          'yearOfStudy': user.studentProfile?.yearOfStudy ?? 1,
          'branch': _normalizeBranch(user.studentProfile?.branch),
          'section': user.studentProfile?.section ?? '',
          'bio': user.studentProfile?.bio ?? '',
          'interests': user.studentProfile?.interests.join(', ') ?? '',
        },
      });
    }
    
    setState(() => _isEditing = false);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}