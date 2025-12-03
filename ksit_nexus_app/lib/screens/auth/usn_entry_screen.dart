import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../services/api_service.dart';
import '../../providers/data_providers.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/success_snackbar.dart';

class USNEntryScreen extends ConsumerStatefulWidget {
  final int userId;
  
  const USNEntryScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<USNEntryScreen> createState() => _USNEntryScreenState();
}

class _USNEntryScreenState extends ConsumerState<USNEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usnController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usnController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSubmitUSN() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final usn = _usnController.text.trim().toUpperCase();
      
      // Verify and update USN
      await apiService.verifyAndUpdateUSN(widget.userId, usn);
      
      if (mounted) {
        SuccessSnackbar.show(context, 'USN verified successfully!');
        
        // Refresh user data
        await ref.read(authStateProvider.notifier).checkAuthStatus();
        
        // Navigate to dashboard
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter USN'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: Responsive.padding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 24, tablet: 28, desktop: 32)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Verify Your USN',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24)),
                      
                      Text(
                        'Please enter your University Seat Number (USN) to complete your registration.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: _usnController,
                        decoration: InputDecoration(
                          labelText: 'USN (University Seat Number)',
                          hintText: 'Enter your USN',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'USN is required';
                          }
                          if (value.trim().length < 5) {
                            return 'USN must be at least 5 characters';
                          }
                          final usnPattern = RegExp(r'^[A-Z0-9]+$');
                          if (!usnPattern.hasMatch(value.trim().toUpperCase())) {
                            return 'USN must contain only uppercase letters and numbers';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Convert to uppercase automatically
                          if (value.isNotEmpty) {
                            final upperValue = value.toUpperCase();
                            if (value != upperValue) {
                              _usnController.value = TextEditingValue(
                                text: upperValue,
                                selection: TextSelection.collapsed(offset: upperValue.length),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      LoadingButton(
                        onPressed: _verifyAndSubmitUSN,
                        isLoading: _isLoading,
                        child: const Text('Verify USN'),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Your USN will be verified against the university database. If your USN is not found, please contact support.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

