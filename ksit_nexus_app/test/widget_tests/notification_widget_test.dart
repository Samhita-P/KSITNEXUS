import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksit_nexus_app/screens/notifications/notifications_screen.dart';
import 'package:ksit_nexus_app/models/notification_model.dart';
import 'package:ksit_nexus_app/providers/data_providers.dart';

void main() {
  group('Notification Widget Tests', () {
    testWidgets('NotificationScreen displays loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('NotificationScreen displays notification list', (WidgetTester tester) async {
      final mockNotifications = [
        NotificationModel(
          id: '1',
          title: 'Test Notification 1',
          message: 'This is a test notification',
          type: 'info',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: '2',
          title: 'Test Notification 2',
          message: 'This is another test notification',
          type: 'warning',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => mockNotifications),
          ],
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Test Notification 1'), findsOneWidget);
      expect(find.text('Test Notification 2'), findsOneWidget);
      expect(find.text('This is a test notification'), findsOneWidget);
      expect(find.text('This is another test notification'), findsOneWidget);
    });

    testWidgets('NotificationScreen shows empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => []),
          ],
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('You\'ll see important updates here'), findsOneWidget);
    });

    testWidgets('NotificationScreen handles mark as read', (WidgetTester tester) async {
      final mockNotifications = [
        NotificationModel(
          id: '1',
          title: 'Test Notification',
          message: 'This is a test notification',
          type: 'info',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => mockNotifications),
          ],
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find and tap the mark as read button
      final markAsReadButton = find.byIcon(Icons.mark_email_read);
      expect(markAsReadButton, findsOneWidget);
      
      await tester.tap(markAsReadButton);
      await tester.pump();

      // Verify the button is no longer visible (notification is marked as read)
      expect(find.byIcon(Icons.mark_email_read), findsNothing);
    });

    testWidgets('NotificationScreen handles refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find and pull down to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 500), 1000);
      await tester.pump();

      // Verify refresh indicator is shown
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('NotificationScreen filters by type', (WidgetTester tester) async {
      final mockNotifications = [
        NotificationModel(
          id: '1',
          title: 'Info Notification',
          message: 'This is an info notification',
          type: 'info',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: '2',
          title: 'Warning Notification',
          message: 'This is a warning notification',
          type: 'warning',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: '3',
          title: 'Error Notification',
          message: 'This is an error notification',
          type: 'error',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => mockNotifications),
          ],
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Test filtering by info type
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);
      
      await tester.tap(filterButton);
      await tester.pump();

      // Select info filter
      final infoFilter = find.text('Info');
      expect(infoFilter, findsOneWidget);
      
      await tester.tap(infoFilter);
      await tester.pump();

      // Verify only info notifications are shown
      expect(find.text('Info Notification'), findsOneWidget);
      expect(find.text('Warning Notification'), findsNothing);
      expect(find.text('Error Notification'), findsNothing);
    });
  });
}
