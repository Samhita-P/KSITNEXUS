import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ksit_nexus_app/screens/complaints/complaints_screen.dart';
import 'package:ksit_nexus_app/screens/complaints/complaint_form_screen.dart';
import 'package:ksit_nexus_app/screens/complaints/complaint_detail_screen.dart';
import 'package:ksit_nexus_app/models/complaint_model.dart';
import 'package:ksit_nexus_app/models/user_model.dart';
import 'package:ksit_nexus_app/services/api_service.dart';

import 'test_complaint_widgets.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('Complaint Widget Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('ComplaintsScreen displays complaint list', (WidgetTester tester) async {
      final mockComplaints = [
        Complaint(
          id: 1,
          complaintId: 'CMP001',
          title: 'Test Complaint 1',
          description: 'Description 1',
          category: 'academic',
          urgency: 'high',
          status: 'submitted',
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Complaint(
          id: 2,
          complaintId: 'CMP002',
          title: 'Test Complaint 2',
          description: 'Description 2',
          category: 'administrative',
          urgency: 'medium',
          status: 'under_review',
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockApiService.getComplaints())
          .thenAnswer((_) async => mockComplaints);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify complaint list elements
      expect(find.text('Complaints'), findsOneWidget);
      expect(find.text('Test Complaint 1'), findsOneWidget);
      expect(find.text('Test Complaint 2'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
    });

    testWidgets('ComplaintsScreen shows filter options', (WidgetTester tester) async {
      when(mockApiService.getComplaints())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify filter options
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Administrative'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('ComplaintsScreen filters by category', (WidgetTester tester) async {
      final mockComplaints = [
        Complaint(
          id: 1,
          title: 'Academic Complaint',
          description: 'Description 1',
          category: 'academic',
          priority: 'high',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Complaint(
          id: 2,
          title: 'Administrative Complaint',
          description: 'Description 2',
          category: 'administrative',
          priority: 'medium',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockApiService.getComplaints())
          .thenAnswer((_) async => mockComplaints);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Academic filter
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();

      // Verify only academic complaints are shown
      expect(find.text('Academic Complaint'), findsOneWidget);
      expect(find.text('Administrative Complaint'), findsNothing);
    });

    testWidgets('ComplaintFormScreen displays form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintFormScreen(),
          ),
        ),
      );

      // Verify form elements
      expect(find.text('Submit Complaint'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('ComplaintFormScreen validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintFormScreen(),
          ),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Verify validation errors
      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
    });

    testWidgets('ComplaintFormScreen submits valid complaint', (WidgetTester tester) async {
      when(mockApiService.createComplaint(any))
          .thenAnswer((_) async =>         Complaint(
          id: 1,
          complaintId: 'CMP001',
          title: 'Test Complaint',
          description: 'Test Description',
          category: 'academic',
          urgency: 'high',
          status: 'submitted',
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintFormScreen(),
          ),
        ),
      );

      // Fill form
      await tester.enterText(find.byKey(Key('title_field')), 'Test Complaint');
      await tester.enterText(find.byKey(Key('description_field')), 'Test Description');
      
      // Select category
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();

      // Select priority
      await tester.tap(find.text('Priority'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify API was called
      verify(mockApiService.createComplaint(any)).called(1);
    });

    testWidgets('ComplaintDetailScreen displays complaint details', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        title: 'Test Complaint',
        description: 'This is a test complaint description',
        category: 'academic',
        priority: 'high',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailScreen(complaint: complaint),
        ),
      );

      // Verify complaint details are displayed
      expect(find.text('Test Complaint'), findsOneWidget);
      expect(find.text('This is a test complaint description'), findsOneWidget);
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('ComplaintDetailScreen shows status update for admin', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        title: 'Test Complaint',
        description: 'Test description',
        category: 'academic',
        priority: 'high',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock admin user
      when(mockApiService.getCurrentUser())
          .thenAnswer((_) async => User(
                id: 1,
                username: 'admin',
                email: 'admin@example.com',
                firstName: 'Admin',
                lastName: 'User',
                userType: 'admin',
                isVerified: true,
                dateJoined: DateTime.now(),
              ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintDetailScreen(complaint: complaint),
          ),
        ),
      );

      // Verify admin controls are shown
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('Add Notes'), findsOneWidget);
    });

    testWidgets('ComplaintFormScreen supports file attachment', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintFormScreen(),
          ),
        ),
      );

      // Verify file attachment option
      expect(find.text('Attach Files'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('ComplaintFormScreen supports anonymous submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintFormScreen(),
          ),
        ),
      );

      // Verify anonymous option
      expect(find.text('Submit Anonymously'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('ComplaintsScreen shows search functionality', (WidgetTester tester) async {
      when(mockApiService.getComplaints())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('ComplaintsScreen handles empty state', (WidgetTester tester) async {
      when(mockApiService.getComplaints())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No complaints found'), findsOneWidget);
      expect(find.text('Submit your first complaint'), findsOneWidget);
    });

    testWidgets('ComplaintsScreen shows loading state', (WidgetTester tester) async {
      when(mockApiService.getComplaints())
          .thenAnswer((_) async {
            await Future.delayed(Duration(seconds: 1));
            return [];
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ComplaintDetailScreen handles null description', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        complaintId: 'CMP001',
        title: 'Test Complaint',
        description: null, // Null description
        category: 'academic',
        urgency: 'high',
        status: 'submitted',
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailScreen(complaint: complaint),
        ),
      );

      // Verify null description is handled gracefully
      expect(find.text('No description provided'), findsOneWidget);
    });

    testWidgets('ComplaintDetailScreen handles null location', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        complaintId: 'CMP001',
        title: 'Test Complaint',
        description: 'Test description',
        category: 'academic',
        urgency: 'high',
        status: 'submitted',
        location: null, // Null location
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailScreen(complaint: complaint),
        ),
      );

      // Verify null location is handled gracefully
      expect(find.text('No location'), findsOneWidget);
    });

    testWidgets('ComplaintDetailScreen handles null assignedToName', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        complaintId: 'CMP001',
        title: 'Test Complaint',
        description: 'Test description',
        category: 'academic',
        urgency: 'high',
        status: 'submitted',
        assignedToName: null, // Null assignedToName
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailScreen(complaint: complaint),
        ),
      );

      // Verify null assignedToName is handled gracefully
      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('ComplaintsScreen dialog handles null fields', (WidgetTester tester) async {
      final complaint = Complaint(
        id: 1,
        complaintId: 'CMP001',
        title: 'Test Complaint',
        description: 'Test description',
        category: 'academic',
        urgency: 'high',
        status: 'submitted',
        location: null, // Null location
        assignedToName: null, // Null assignedToName
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockApiService.getComplaints())
          .thenAnswer((_) async => [complaint]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: ComplaintsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on complaint to open dialog
      await tester.tap(find.text('Test Complaint'));
      await tester.pumpAndSettle();

      // Verify null fields are handled gracefully in dialog
      expect(find.text('No location'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
    });
  });
}
