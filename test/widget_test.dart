import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_connected_app/widgets/error_view.dart';
import 'package:flutter_connected_app/widgets/loading_indicator.dart';

void main() {
  testWidgets('LoadingIndicator displays message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(message: 'Fetching products...'),
        ),
      ),
    );

    expect(find.text('Fetching products...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView displays message and retry button', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Custom network error message',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Custom network error message'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
  });
}
