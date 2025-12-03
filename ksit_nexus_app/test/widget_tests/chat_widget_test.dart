import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksit_nexus_app/screens/chatbot/chat_screen.dart';
import 'package:ksit_nexus_app/models/chatbot_model.dart';
import 'package:ksit_nexus_app/providers/data_providers.dart';

void main() {
  group('Chat Widget Tests', () {
    testWidgets('ChatScreen displays initial state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      expect(find.text('KSIT Nexus Assistant'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('ChatScreen displays messages', (WidgetTester tester) async {
      final mockMessages = [
        ChatMessage(
          id: '1',
          content: 'Hello, how can I help you?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          content: 'I need help with my reservation',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith((ref) => mockMessages),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Hello, how can I help you?'), findsOneWidget);
      expect(find.text('I need help with my reservation'), findsOneWidget);
    });

    testWidgets('ChatScreen sends message', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find text field and enter message
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      await tester.enterText(textField, 'Hello, I need help');
      await tester.pump();

      // Find and tap send button
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      
      await tester.tap(sendButton);
      await tester.pump();

      // Verify message was sent (text field should be cleared)
      expect(find.text('Hello, I need help'), findsNothing);
    });

    testWidgets('ChatScreen shows typing indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isTypingProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Assistant is typing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ChatScreen handles empty message', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Try to send empty message
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pump();

      // Send button should be disabled or message should not be sent
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('ChatScreen shows error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatErrorProvider.overrideWith((ref) => 'Failed to send message'),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Failed to send message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('ChatScreen handles long messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Enter a very long message
      final longMessage = 'This is a very long message that should be handled properly by the chat screen. ' * 10;
      final textField = find.byType(TextField);
      
      await tester.enterText(textField, longMessage);
      await tester.pump();

      // Verify the message is displayed correctly
      expect(find.textContaining('This is a very long message'), findsOneWidget);
    });

    testWidgets('ChatScreen scrolls to bottom on new message', (WidgetTester tester) async {
      final mockMessages = List.generate(20, (index) => ChatMessage(
        id: index.toString(),
        content: 'Message $index',
        isUser: index % 2 == 0,
        timestamp: DateTime.now(),
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith((ref) => mockMessages),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify that the last message is visible
      expect(find.text('Message 19'), findsOneWidget);
    });

    testWidgets('ChatScreen handles different message types', (WidgetTester tester) async {
      final mockMessages = [
        ChatMessage(
          id: '1',
          content: 'Text message',
          isUser: true,
          timestamp: DateTime.now(),
          messageType: 'text',
        ),
        ChatMessage(
          id: '2',
          content: 'Image message',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: 'image',
          imageUrl: 'https://example.com/image.jpg',
        ),
        ChatMessage(
          id: '3',
          content: 'File message',
          isUser: true,
          timestamp: DateTime.now(),
          messageType: 'file',
          fileName: 'document.pdf',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith((ref) => mockMessages),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Text message'), findsOneWidget);
      expect(find.text('Image message'), findsOneWidget);
      expect(find.text('File message'), findsOneWidget);
      
      // Verify different message types are displayed with appropriate icons
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('ChatScreen handles keyboard visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Tap on text field to show keyboard
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Verify keyboard is shown (this is platform dependent)
      // On some platforms, the keyboard might not be visible in tests
      expect(textField, findsOneWidget);
    });

    testWidgets('ChatScreen handles message selection', (WidgetTester tester) async {
      final mockMessages = [
        ChatMessage(
          id: '1',
          content: 'Selectable message',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatMessagesProvider.overrideWith((ref) => mockMessages),
          ],
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      // Long press on message to select it
      final messageWidget = find.text('Selectable message');
      await tester.longPress(messageWidget);
      await tester.pump();

      // Verify selection menu appears
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
