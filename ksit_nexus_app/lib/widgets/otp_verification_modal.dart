import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../providers/data_providers.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_button.dart';
import '../widgets/error_snackbar.dart';

class OTPVerificationModal extends ConsumerStatefulWidget {
  final String email;
  final String type; // 'register', 'login', 'reset_password'
  final VoidCallback? onSuccess;

  const OTPVerificationModal({
    super.key,
    required this.email,
    required this.type,
    this.onSuccess,
  });

  @override
  ConsumerState<OTPVerificationModal> createState() => _OTPVerificationModalState();
}

class _OTPVerificationModalState extends ConsumerState<OTPVerificationModal> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOTP() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final formData = _formKey.currentState!.value;
        final otp = formData['otp'] as String;
        
        await ref.read(authStateProvider.notifier).verifyOTP(widget.email, otp);
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
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

  Future<void> _handleResendOTP() async {
    setState(() => _isResending = true);
    
    try {
      await ref.read(authStateProvider.notifier).requestOTP(widget.email, widget.type);
      if (mounted) {
        SuccessSnackbar.show(context, 'OTP sent successfully!');
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, 'Failed to resend OTP: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.verified_user,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'We\'ve sent a verification code to\n${widget.email}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // OTP Form
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'otp',
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '123456',
                      prefixIcon: Icon(Icons.security),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(6),
                      FormBuilderValidators.maxLength(6),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  
                  LoadingButton(
                    onPressed: _handleVerifyOTP,
                    isLoading: _isLoading,
                    child: const Text('Verify OTP'),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Didn\'t receive the code? '),
                      if (_resendCountdown > 0)
                        Text(
                          'Resend in ${_resendCountdown}s',
                          style: const TextStyle(color: AppTheme.grey500),
                        )
                      else
                        TextButton(
                          onPressed: _isResending ? null : _handleResendOTP,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Resend OTP'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show OTP modal
void showOTPVerificationModal(
  BuildContext context, {
  required String email,
  required String type,
  VoidCallback? onSuccess,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => OTPVerificationModal(
      email: email,
      type: type,
      onSuccess: onSuccess,
    ),
  );
}
