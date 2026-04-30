// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deadlinekeeper/main.dart';

void main() {
  testWidgets('TaskMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskMateApp());

    // Verify that the app title is displayed
    expect(find.text('TaskMate'), findsOneWidget);

    // Verify that empty state is shown
    expect(find.text('Belum ada tugas'), findsOneWidget);
  });
}
