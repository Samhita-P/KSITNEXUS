import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/data_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    print('ForgotPasswordScreen: Send OTP button pressed');
    
    // Validate phone number manually
    final phoneNumber = _phoneController.text.trim();
    print('ForgotPasswordScreen: Phone number: $phoneNumber');
    
    if (phoneNumber.isEmpty) {
      print('ForgotPasswordScreen: Phone number is empty');
      setState(() {
        _errorMessage = 'Phone number is required';
      });
      return;
    }
    
    if (phoneNumber.length < 10) {
      print('ForgotPasswordScreen: Phone number too short');
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    print('ForgotPasswordScreen: Starting password reset request');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('ForgotPasswordScreen: Getting auth service');
      final authService = ref.read(authServiceProvider);
      print('ForgotPasswordScreen: Calling requestPasswordResetOTP');
      await authService.requestPasswordResetOTP(phoneNumber);
      
      print('ForgotPasswordScreen: OTP request successful');
      setState(() {
        _successMessage = 'OTP sent successfully to $phoneNumber';
      });
      
      // Navigate to OTP verification screen
      if (mounted) {
        print('ForgotPasswordScreen: Navigating to OTP verification');
        context.go('/otp-verification?phoneNumber=$phoneNumber&purpose=password_reset');
      }
    } catch (e) {
      print('ForgotPasswordScreen: Error occurred: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        print('ForgotPasswordScreen: Setting loading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       kToolbarHeight - 48, // Account for app bar and padding
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Icon
            Icon(
              Icons.lock_reset,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Reset Your Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'Enter your phone number and we\'ll send you a verification code to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Phone Number Field
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your registered phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                _requestPasswordReset();
              },
            ),
            const SizedBox(height: 24),
            
            // Success Message
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Send OTP Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestPasswordReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Back to Login
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: Colors.black54,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}