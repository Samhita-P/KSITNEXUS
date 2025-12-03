import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../providers/data_providers.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final _registerFormKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  
  final AuthService _authService = AuthService(ApiService());
  final BiometricService _biometricService = BiometricService();
  
  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }
  
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
        });
      }
    } catch (e) {
      // Biometric not available or error checking
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
          _isBiometricEnabled = false;
        });
      }
    }
  }
  
  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _authService.loginWithBiometric();
      if (mounted && user != null) {
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.refreshAuthState();
        
        // Route based on user type
        if (user.isFaculty) {
          context.go('/faculty-dashboard');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Biometric login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = Responsive.value(
      context: context,
      mobile: 80.0,
      tablet: 100.0,
      desktop: 120.0,
    );
    
    final cardMaxWidth = Responsive.value(
      context: context,
      mobile: double.infinity,
      tablet: 500.0,
      desktop: 550.0,
      largeDesktop: 600.0,
    );
    
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.school,
                    size: logoSize * 0.6,
                    color: AppTheme.white,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32)),
                Text(
                  'KSIT NEXUS',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.fontSize(context, 32),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 8, tablet: 12)),
                Text(
                  'Your Academic Hub',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    fontSize: Responsive.fontSize(context, 16),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 48, tablet: 56)),

                // Login/Register Card
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.shadowLarge,
                  ),
                  child: Column(
                    children: [
                      // Toggle Buttons
                      Container(
                        margin: EdgeInsets.all(Responsive.spacing(context, mobile: 20, tablet: 24)),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLoginMode = true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.value(context: context, mobile: 14.0, tablet: 16.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isLoginMode ? AppTheme.primaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Login',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _isLoginMode ? AppTheme.white : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.fontSize(context, 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLoginMode = false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.value(context: context, mobile: 14.0, tablet: 16.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode ? AppTheme.primaryBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Register',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: !_isLoginMode ? AppTheme.white : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.fontSize(context, 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Content
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          Responsive.value(context: context, mobile: 24.0, tablet: 32.0),
                          8,
                          Responsive.value(context: context, mobile: 24.0, tablet: 32.0),
                          Responsive.value(context: context, mobile: 24.0, tablet: 32.0),
                        ),
                        child: _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FormBuilder(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            name: 'email',
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ]),
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: 'password',
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(6),
            ]),
          ),
          const SizedBox(height: 28),
          LoadingButton(
            onPressed: _handleLogin,
            isLoading: _isLoading,
            child: const Text('Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.go('/forgot-password');
            },
            child: Text(
              'Forgot Password?',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          // Biometric Login Button
          if (_isBiometricAvailable && _isBiometricEnabled) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleBiometricLogin,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Login with Biometric'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: FormBuilder(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'firstName',
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'lastName',
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'email',
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'phoneNumber',
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryBlue),
                hintText: 'Enter your phone number',
              ),
              keyboardType: TextInputType.phone,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(10),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderDropdown<String>(
              name: 'userType',
              decoration: InputDecoration(
                labelText: 'User Type',
                prefixIcon: Icon(Icons.group_outlined, color: AppTheme.primaryBlue),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
              ],
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'password',
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(6),
              ]),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'confirmPassword',
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(6),
              ]),
            ),
            const SizedBox(height: 28),
            LoadingButton(
              onPressed: _handleRegister,
              isLoading: _isLoading,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _loginFormKey.currentState!.value;
        final email = formData['email'] as String;
        final password = formData['password'] as String;

        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.login(email, password); // Using email as username

        if (mounted) {
          // Get the user directly from the login response, don't refresh yet
          // The login method already sets the user in authState
          final authState = ref.read(authStateProvider);
          final user = authState.user;
          
          // Debug logging
          print('=== LOGIN ROUTING DEBUG ===');
          print('User: ${user?.email}');
          print('UserType (raw): ${user?.userType}');
          print('UserType (lowercase): ${user?.userType?.toLowerCase()}');
          print('isFaculty: ${user?.isFaculty}');
          print('isStudent: ${user?.isStudent}');
          print('isAdmin: ${user?.isAdmin}');
          print('Has student profile: ${user?.studentProfile != null}');
          print('Has faculty profile: ${user?.facultyProfile != null}');
          print('===========================');
          
          // Route based on user type - check userType directly for reliability
          if (user != null) {
            final userType = user.userType?.toLowerCase()?.trim() ?? '';
            final hasStudentProfile = user.studentProfile != null;
            final hasFacultyProfile = user.facultyProfile != null;
            
            print('Routing decision - userType: "$userType"');
            print('Has student profile: $hasStudentProfile');
            print('Has faculty profile: $hasFacultyProfile');
            
            // Primary check: userType string (MUST BE FIRST)
            if (userType == 'faculty' || userType == 'admin') {
              print('✓ UserType is "$userType" -> Navigating to faculty dashboard');
              context.go('/faculty-dashboard');
              return; // Exit early to prevent further checks
            } else if (userType == 'student') {
              print('✓ UserType is "student" -> Navigating to student home');
              context.go('/home');
              return; // Exit early to prevent further checks
            } 
            // Fallback 1: Check profile existence (more reliable than getters)
            else if (hasFacultyProfile) {
              print('⚠ UserType is empty/null but hasFacultyProfile=true -> Navigating to faculty dashboard');
              context.go('/faculty-dashboard');
              return;
            } else if (hasStudentProfile) {
              print('⚠ UserType is empty/null but hasStudentProfile=true -> Navigating to student home');
              context.go('/home');
              return;
            }
            // Fallback 2: use getter methods
            else if (user.isFaculty) {
              print('⚠ UserType string is empty/null but isFaculty=true -> Navigating to faculty dashboard');
              context.go('/faculty-dashboard');
              return;
            } else if (user.isStudent) {
              print('⚠ UserType string is empty/null but isStudent=true -> Navigating to student home');
              context.go('/home');
              return;
            } else {
              // Default to home if userType is not set or unknown
              print('⚠ UserType not set or unknown ("$userType"), defaulting to home');
              context.go('/home');
            }
          } else {
            print('✗ User is null after login, defaulting to home');
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Login failed: ${e.toString()}');
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

  Future<void> _handleRegister() async {
    if (_registerFormKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _registerFormKey.currentState!.value;
        final password = formData['password'] as String;
        final confirmPassword = formData['confirmPassword'] as String;

        if (password != confirmPassword) {
          throw Exception('Passwords do not match');
        }

        final authNotifier = ref.read(authStateProvider.notifier);
        final registerRequest = RegisterRequest(
          username: formData['email'] as String,
          email: formData['email'] as String,
          password: password,
          firstName: formData['firstName'] as String,
          lastName: formData['lastName'] as String,
          userType: formData['userType'] as String,
          phoneNumber: formData['phoneNumber'] as String,
        );
        final response = await authNotifier.register(registerRequest);

        if (mounted) {
          // Show success message and redirect to register screen for OTP verification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful! Please check your phone for OTP verification.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to OTP verification screen
          context.go('/otp-verification?userId=${response['user_id']}&phoneNumber=${response['otp_sent_to']}&userType=${formData['userType']}');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(context, 'Registration failed: ${e.toString()}');
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