import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/two_factor_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_button.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  final BiometricService _biometricService = BiometricService();
  
  bool _isLoading = false;
  bool _is2FASetup = false;
  bool _isBiometricEnabled = false;
  Map<String, dynamic>? _setupData;
  String _verificationCode = '';
  final TextEditingController _codeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await _twoFactorService.get2FAStatus();
      final biometricStatus = await _biometricService.getBiometricStatus();
      
      setState(() {
        _is2FASetup = status['is_enabled'] ?? false;
        _isBiometricEnabled = biometricStatus['isEnabled'] ?? false;
      });
    } catch (e) {
      if (mounted) {
        // Don't show error for authentication issues, just set default values
        if (e.toString().contains('User not authenticated')) {
          setState(() {
            _is2FASetup = false;
            _isBiometricEnabled = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking status: $e')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setup2FA() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _twoFactorService.setup2FA();
      setState(() {
        _setupData = data;
        _is2FASetup = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verify2FA() async {
    if (_verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await _twoFactorService.verify2FA(_verificationCode);
      
      if (result['enabled'] == true) {
        await _twoFactorService.set2FAEnabledLocally(true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA enabled successfully!')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);
    
    try {
      // First check if biometric is available
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          // Check if running on web
          final isWeb = kIsWeb;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isWeb 
                  ? 'Biometric authentication is not supported in web browsers. Please use the mobile app.'
                  : 'Biometric authentication is not available on this device'
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Check available biometric types
      final availableTypes = await _biometricService.getAvailableBiometricNames();
      print('Available biometric types: $availableTypes');

      final success = await _biometricService.enableBiometric();
      
      if (success) {
        setState(() => _isBiometricEnabled = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enable biometric authentication. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error enabling biometric: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: const Text('Security Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              maxWidth: Responsive.value(
                context: context,
                mobile: double.infinity,
                tablet: 700,
                desktop: 800,
              ),
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                padding: Responsive.padding(context),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Two-Factor Authentication Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Two-Factor Authentication',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _is2FASetup
                                ? '2FA is enabled. Your account is protected with an additional security layer.'
                                : 'Add an extra layer of security to your account using an authenticator app.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (!_is2FASetup && _setupData == null) ...[
                            LoadingButton(
                              onPressed: _setup2FA,
                              isLoading: _isLoading,
                              child: const Text('Setup 2FA'),
                            ),
                          ] else if (_setupData != null) ...[
                            // QR Code Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Scan this QR code with your authenticator app:',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_setupData!['qr_code'] != null)
                                    Image.network(
                                      _setupData!['qr_code'],
                                      height: 200,
                                      width: 200,
                                    ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Or enter this secret key manually:',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: SelectableText(
                                      _setupData!['secret_key'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Verification Code Input
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'Enter 6-digit code from authenticator app',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              onChanged: (value) {
                                setState(() => _verificationCode = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            LoadingButton(
                              onPressed: _verificationCode.length == 6 ? _verify2FA : null,
                              isLoading: _isLoading,
                              child: const Text('Verify & Enable 2FA'),
                            ),
                          ] else ...[
                            // 2FA is already enabled
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Two-Factor Authentication is enabled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Biometric Authentication Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fingerprint,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Biometric Authentication',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isBiometricEnabled
                                ? 'Biometric authentication is enabled. You can use your fingerprint or face to quickly access the app.'
                                : 'Enable biometric authentication for quick and secure access to your account.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (!_isBiometricEnabled) ...[
                            LoadingButton(
                              onPressed: _enableBiometric,
                              isLoading: _isLoading,
                              child: const Text('Enable Biometric Auth'),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Biometric Authentication is enabled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Security Tips
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Security Tips',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Keep your backup codes in a safe place\n'
                            '• Use a strong, unique password\n'
                            '• Enable biometric authentication for convenience\n'
                            '• Regularly review your active sessions\n'
                            '• Log out from devices you no longer use',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                ],
              ),
            ),
          ),
        ],
              ),
            ),
            ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
