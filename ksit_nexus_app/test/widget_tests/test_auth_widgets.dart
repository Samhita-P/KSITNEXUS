import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ksit_nexus_app/screens/auth/login_screen.dart';
import 'package:ksit_nexus_app/screens/auth/register_screen.dart';
import 'package:ksit_nexus_app/screens/auth/two_factor_setup_screen.dart';
import 'package:ksit_nexus_app/screens/auth/device_sessions_screen.dart';
import 'package:ksit_nexus_app/widgets/otp_verification_modal.dart';
import 'package:ksit_nexus_app/widgets/loading_button.dart';
import 'package:ksit_nexus_app/services/auth_service.dart';
import 'package:ksit_nexus_app/services/two_factor_service.dart';
import 'package:ksit_nexus_app/services/biometric_service.dart';

import 'test_auth_widgets.mocks.dart';

@GenerateMocks([AuthService, TwoFactorService, BiometricService])
void main() {
  group('Authentication Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockTwoFactorService mockTwoFactorService;
    late MockBiometricService mockBiometricService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTwoFactorService = MockTwoFactorService();
      mockBiometricService = MockBiometricService();
    });

    testWidgets('LoginScreen displays login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify login form elements are present
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Username and password
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('LoginScreen shows loading state', (WidgetTester tester) async {
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => throw Exception('Network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).last, 'password');

      // Tap login button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('RegisterScreen displays registration form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Verify registration form elements
      expect(find.text('Register'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6)); // All form fields
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify validation errors are shown
      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('OTPVerificationModal displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OTPVerificationModal(
              email: 'test@example.com',
              onVerify: (otp) async {},
              onResend: () async {},
            ),
          ),
        ),
      );

      // Verify OTP modal elements
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
    });

    testWidgets('OTPVerificationModal validates OTP input', (WidgetTester tester) async {
      bool verifyCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OTPVerificationModal(
              email: 'test@example.com',
              onVerify: (otp) async {
                verifyCalled = true;
              },
              onResend: () async {},
            ),
          ),
        ),
      );

      // Enter invalid OTP (too short)
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Verify'));
      await tester.pump();

      // Verify validation error
      expect(find.text('Please enter a 6-digit OTP'), findsOneWidget);
      expect(verifyCalled, false);

      // Enter valid OTP
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(verifyCalled, true);
    });

    testWidgets('TwoFactorSetupScreen displays 2FA setup', (WidgetTester tester) async {
      when(mockTwoFactorService.get2FAStatus())
          .thenAnswer((_) async => {'is_enabled': false});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            twoFactorServiceProvider.overrideWithValue(mockTwoFactorService),
            biometricServiceProvider.overrideWithValue(mockBiometricService),
          ],
          child: MaterialApp(
            home: TwoFactorSetupScreen(),
          ),
        ),
      );

      // Verify 2FA setup elements
      expect(find.text('Security Settings'), findsOneWidget);
      expect(find.text('Two-Factor Authentication'), findsOneWidget);
      expect(find.text('Biometric Authentication'), findsOneWidget);
      expect(find.text('Setup 2FA'), findsOneWidget);
    });

    testWidgets('TwoFactorSetupScreen shows QR code after setup', (WidgetTester tester) async {
      when(mockTwoFactorService.get2FAStatus())
          .thenAnswer((_) async => {'is_enabled': false});
      when(mockTwoFactorService.setup2FA())
          .thenAnswer((_) async => {
                'secret_key': 'TEST123456789',
                'qr_code': 'data:image/png;base64,test',
                'backup_codes': ['ABC123', 'DEF456']
              });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            twoFactorServiceProvider.overrideWithValue(mockTwoFactorService),
            biometricServiceProvider.overrideWithValue(mockBiometricService),
          ],
          child: MaterialApp(
            home: TwoFactorSetupScreen(),
          ),
        ),
      );

      // Tap setup 2FA button
      await tester.tap(find.text('Setup 2FA'));
      await tester.pump();

      // Verify QR code is displayed
      expect(find.text('Scan this QR code with your authenticator app:'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Or enter this secret key manually:'), findsOneWidget);
    });

    testWidgets('DeviceSessionsScreen displays device sessions', (WidgetTester tester) async {
      when(mockTwoFactorService.getActiveSessions())
          .thenAnswer((_) async => [
                {
                  'id': 1,
                  'device_name': 'iPhone 12',
                  'device_type': 'mobile',
                  'ip_address': '192.168.1.1',
                  'last_activity': '2024-01-15T10:00:00Z',
                  'is_active': true,
                },
                {
                  'id': 2,
                  'device_name': 'MacBook Pro',
                  'device_type': 'desktop',
                  'ip_address': '192.168.1.2',
                  'last_activity': '2024-01-15T09:00:00Z',
                  'is_active': true,
                },
              ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            twoFactorServiceProvider.overrideWithValue(mockTwoFactorService),
          ],
          child: MaterialApp(
            home: DeviceSessionsScreen(),
          ),
        ),
      );

      // Verify device sessions are displayed
      expect(find.text('Device Sessions'), findsOneWidget);
      expect(find.text('iPhone 12'), findsOneWidget);
      expect(find.text('MacBook Pro'), findsOneWidget);
      expect(find.text('CURRENT DEVICE'), findsOneWidget);
    });

    testWidgets('LoadingButton shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {
                await Future.delayed(Duration(seconds: 1));
              },
              isLoading: false,
              child: Text('Test Button'),
            ),
          ),
        ),
      );

      // Verify button is not loading initially
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap button
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingButton is disabled when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {},
              isLoading: true,
              child: Text('Loading Button'),
            ),
          ),
        ),
      );

      // Verify button is disabled when loading
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
