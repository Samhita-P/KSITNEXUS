import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ksit_nexus_app/main.dart';
import 'package:ksit_nexus_app/screens/auth/login_screen.dart';
import 'package:ksit_nexus_app/screens/auth/register_screen.dart';
import 'package:ksit_nexus_app/screens/home/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    testWidgets('Complete login flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Verify we start at login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter login credentials
      await tester.enterText(find.byKey(Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');

      // Tap login button
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify we navigate to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Complete registration flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Navigate to register screen
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify we're on register screen
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Fill registration form
      await tester.enterText(find.byKey(Key('username_field')), 'newuser');
      await tester.enterText(find.byKey(Key('email_field')), 'newuser@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'newpass123');
      await tester.enterText(find.byKey(Key('confirm_password_field')), 'newpass123');
      await tester.enterText(find.byKey(Key('first_name_field')), 'New');
      await tester.enterText(find.byKey(Key('last_name_field')), 'User');

      // Select user type
      await tester.tap(find.byKey(Key('user_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      // Submit registration
      await tester.tap(find.byKey(Key('register_button')));
      await tester.pumpAndSettle();

      // Verify we navigate to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Login with 2FA flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Enter login credentials
      await tester.enterText(find.byKey(Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');

      // Tap login button
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify 2FA screen appears
      expect(find.text('Two-Factor Authentication'), findsOneWidget);
      expect(find.text('Enter 6-digit code'), findsOneWidget);

      // Enter 2FA code
      await tester.enterText(find.byKey(Key('otp_field')), '123456');

      // Tap verify button
      await tester.tap(find.byKey(Key('verify_button')));
      await tester.pumpAndSettle();

      // Verify we navigate to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Login with biometric authentication', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Tap biometric login button
      await tester.tap(find.byKey(Key('biometric_login_button')));
      await tester.pumpAndSettle();

      // Verify biometric prompt appears
      expect(find.text('Use Biometric Authentication'), findsOneWidget);

      // Simulate successful biometric authentication
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify we navigate to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Registration validation', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Navigate to register screen
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.byKey(Key('register_button')));
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      // Fill form with invalid data
      await tester.enterText(find.byKey(Key('username_field')), 'a'); // Too short
      await tester.enterText(find.byKey(Key('email_field')), 'invalid-email'); // Invalid email
      await tester.enterText(find.byKey(Key('password_field')), '123'); // Too short
      await tester.enterText(find.byKey(Key('confirm_password_field')), '456'); // Mismatch

      await tester.tap(find.byKey(Key('register_button')));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Password visibility toggle', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Enter password
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');

      // Verify password is hidden initially
      final passwordField = tester.widget<TextFormField>(find.byKey(Key('password_field')));
      expect(passwordField.obscureText, true);

      // Tap visibility toggle
      await tester.tap(find.byKey(Key('password_visibility_toggle')));
      await tester.pumpAndSettle();

      // Verify password is now visible
      final passwordFieldVisible = tester.widget<TextFormField>(find.byKey(Key('password_field')));
      expect(passwordFieldVisible.obscureText, false);
    });

    testWidgets('Remember me functionality', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Check remember me checkbox
      await tester.tap(find.byKey(Key('remember_me_checkbox')));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');

      // Login
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Logout
      await tester.tap(find.byKey(Key('logout_button')));
      await tester.pumpAndSettle();

      // Verify username is remembered
      final usernameField = tester.widget<TextFormField>(find.byKey(Key('username_field')));
      expect(usernameField.controller?.text, 'testuser');
    });

    testWidgets('Forgot password flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify forgot password screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);

      // Enter email
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');

      // Submit
      await tester.tap(find.byKey(Key('reset_password_button')));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Password reset email sent'), findsOneWidget);
    });

    testWidgets('Session timeout handling', (WidgetTester tester) async {
      // Start the app and login
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Simulate session timeout by waiting
      await tester.pump(Duration(minutes: 30));

      // Try to perform an action
      await tester.tap(find.byKey(Key('profile_button')));
      await tester.pumpAndSettle();

      // Verify we're redirected to login
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Session expired. Please login again.'), findsOneWidget);
    });

    testWidgets('Network error handling', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(ProviderScope(child: KSITNexusApp()));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(Key('username_field')), 'testuser');
      await tester.enterText(find.byKey(Key('password_field')), 'testpass123');

      // Simulate network error by tapping login
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Network error. Please check your connection.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify we try again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
