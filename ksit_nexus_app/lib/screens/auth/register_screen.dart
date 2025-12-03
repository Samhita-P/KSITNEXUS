import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../providers/data_providers.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _otpFormKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showOTPForm = false;
  int? _userId;
  String? _otpSentTo;
  String? _selectedUserType = null; // Initialize to null
  final ValueNotifier<String?> _userTypeNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // Check for URL parameters to show OTP form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final step = uri.queryParameters['step'];
      final email = uri.queryParameters['email'];
      final userIdStr = uri.queryParameters['user_id'];
      
      if (step == 'otp' && email != null && userIdStr != null) {
        setState(() {
          _showOTPForm = true;
          _userId = int.tryParse(userIdStr);
          _otpSentTo = email;
        });
      }
      
      // Initialize userType from form field if available
      final formUserType = _formKey.currentState?.fields['userType']?.value as String?;
      if (formUserType != null && formUserType != _selectedUserType) {
        setState(() {
          _selectedUserType = formUserType;
        });
      }
    });
  }

  @override
  void dispose() {
    _userTypeNotifier.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildUSNField() {
    // Check if student is selected - use state variable directly
    // This will rebuild when _selectedUserType changes via setState
    final isStudent = _selectedUserType == 'student';
    
    print('_buildUSNField: _selectedUserType=$_selectedUserType, isStudent=$isStudent'); // Debug
    
    if (!isStudent) {
      return const SizedBox.shrink();
    }
    
    // Return USN field when student is selected
    return Column(
      key: const ValueKey('usn_field_widget'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormBuilderTextField(
          name: 'usn',
          decoration: _getInputDecoration('USN (University Seat Number)', Icons.badge_outlined),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'USN is required for students'),
            FormBuilderValidators.minLength(5, errorText: 'USN must be at least 5 characters'),
            (value) {
              if (value != null && value.isNotEmpty) {
                final usnPattern = RegExp(r'^[A-Z0-9]+$');
                if (!usnPattern.hasMatch(value)) {
                  return 'USN must contain only uppercase letters and numbers';
                }
              }
              return null;
            },
          ]),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            // Convert to uppercase automatically
            if (value != null && value.isNotEmpty) {
              final upperValue = value.toUpperCase();
              if (value != upperValue) {
                _formKey.currentState?.fields['usn']?.didChange(upperValue);
              }
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        
        // USN is now optional during registration - will be collected after OTP verification
        final userType = formData['userType'] as String;
        final usn = formData['usn'] as String?;
        
        final request = RegisterRequest(
          username: formData['username'],
          email: formData['email'],
          password: formData['password'],
          firstName: formData['firstName'],
          lastName: formData['lastName'],
          userType: userType,
          phoneNumber: formData['phoneNumber'],
          usn: null, // USN will be collected after OTP verification
        );
        
        final response = await ref.read(authStateProvider.notifier).register(request);
        
        if (mounted) {
          // Check if OTP verification is required
          if (response['requires_verification'] == true && response['otp_sent_to'] != null) {
            // Navigate to OTP verification screen
            context.go('/otp-verification?userId=${response['user_id']}&phoneNumber=${response['otp_sent_to']}&userType=${formData['userType']}');
          } else {
            // Registration completed without OTP verification, route based on user type
            final userType = formData['userType'] as String;
            if (userType == 'faculty') {
              context.go('/faculty-dashboard');
            } else {
              context.go('/home');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Registration failed: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleOTPVerification() async {
    if (_otpFormKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _otpFormKey.currentState!.value;
        final otp = formData['otp'] as String;
        
        await ref.read(authStateProvider.notifier).verifyRegistrationOTP(_userId!, otp);
        
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'OTP verification failed: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showOTPForm ? 'Verify OTP' : 'Register'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.value(
          context: context,
          mobile: double.infinity,
          tablet: 550,
          desktop: 600,
        ),
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
              child: _showOTPForm ? _buildOTPForm() : _buildRegistrationForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    // Keep form key for state management, but wrap in Builder to force rebuild
    return FormBuilder(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24)),
                    
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'firstName',
                            decoration: _getInputDecoration('First Name', Icons.person_outline),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(2),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'lastName',
                            decoration: _getInputDecoration('Last Name', Icons.person_outline),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(2),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    FormBuilderTextField(
                      name: 'username',
                      decoration: _getInputDecoration('Username', Icons.person_outline),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(3),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    
                    FormBuilderTextField(
                      name: 'email',
                      decoration: _getInputDecoration('Email', Icons.email_outlined),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    
                    FormBuilderTextField(
                      name: 'phoneNumber',
                      decoration: _getInputDecoration('Phone Number', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(10),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    
                    FormBuilderDropdown<String>(
                      name: 'userType',
                      decoration: _getInputDecoration('User Type', Icons.group_outlined),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                      ],
                      validator: FormBuilderValidators.required(),
                      onChanged: (value) {
                        if (value != null) {
                          print('🔵 User type changed to: $value'); // Debug
                          // Update both state and notifier IMMEDIATELY
                          _selectedUserType = value;
                          _userTypeNotifier.value = value;
                          setState(() {}); // Force rebuild
                          print('🔵 State updated. _selectedUserType: $_selectedUserType, notifier: ${_userTypeNotifier.value}'); // Debug
                          // Clear USN field when switching away from student
                          if (value != 'student') {
                            Future.microtask(() {
                              if (_formKey.currentState?.fields['usn'] != null && mounted) {
                                _formKey.currentState?.fields['usn']?.didChange(null);
                                _formKey.currentState?.fields['usn']?.reset();
                              }
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Show USN field only when Student is selected
                    // Use ValueListenableBuilder to watch user type changes
                    ValueListenableBuilder<String?>(
                      valueListenable: _userTypeNotifier,
                      builder: (context, userType, child) {
                        // Directly check the userType from notifier
                        final isStudent = userType == 'student';
                        print('🔵 ValueListenableBuilder: userType=$userType, isStudent=$isStudent'); // Debug
                        
                        if (!isStudent) {
                          return const SizedBox.shrink();
                        }
                        
                        // Return USN field when student is selected
                        return Column(
                          key: const ValueKey('usn_field_widget'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FormBuilderTextField(
                              name: 'usn',
                              decoration: _getInputDecoration('USN (University Seat Number)', Icons.badge_outlined),
                              validator: FormBuilderValidators.compose([
                                // USN is optional during registration - will be collected after OTP
                                FormBuilderValidators.minLength(5, errorText: 'USN must be at least 5 characters'),
                                (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final usnPattern = RegExp(r'^[A-Z0-9]+$');
                                    if (!usnPattern.hasMatch(value)) {
                                      return 'USN must contain only uppercase letters and numbers';
                                    }
                                  }
                                  return null;
                                },
                              ]),
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) {
                                // Convert to uppercase automatically
                                if (value != null && value.isNotEmpty) {
                                  final upperValue = value.toUpperCase();
                                  if (value != upperValue) {
                                    _formKey.currentState?.fields['usn']?.didChange(upperValue);
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                    
                    FormBuilderTextField(
                      name: 'password',
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(6),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    
                    LoadingButton(
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildOTPForm() {
    return FormBuilder(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Verify Your Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          Text(
            'We have sent a verification code to:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            _otpSentTo ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          FormBuilderTextField(
            name: 'otp',
            decoration: _getInputDecoration('Enter OTP', Icons.security),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(6),
              FormBuilderValidators.maxLength(6),
            ]),
          ),
          const SizedBox(height: 20),
          
          LoadingButton(
            onPressed: _handleOTPVerification,
            isLoading: _isLoading,
            child: const Text('Verify OTP'),
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () {
              setState(() {
                _showOTPForm = false;
                _userId = null;
                _otpSentTo = null;
              });
            },
            child: const Text('Back to Registration'),
          ),
        ],
      ),
    );
  }
}