import 'package:apidash/widgets/editor_json.dart';
import 'package:apidash/widgets/json_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert'; // Add this import for JSON handling

void main() {
  Widget createApp({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('JsonEditor basic functionality test', (tester) async {
    String? changedValue;
    const initialJson = '{"test": "value"}';
    
    await tester.pumpWidget(
      createApp(
        child: JsonTextFieldEditor(
          fieldKey: 'test-editor',
          onChanged: (value) => changedValue = value,
          initialValue: initialJson,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widget exists
    expect(find.byType(JsonTextFieldEditor), findsOneWidget);
    expect(find.byKey(const Key('test-editor')), findsOneWidget);
    
    // Verify initial value is set - compare JSON objects instead of strings
    final state = tester.state<JsonTextFieldEditorState>(
      find.byType(JsonTextFieldEditor)
    );
    
    // Parse both JSONs and compare their content instead of their string representation
    final expectedJson = jsonDecode(initialJson);
    final actualJson = jsonDecode(state.controller.text);
    expect(actualJson, expectedJson);
  });

  testWidgets('JsonEditor handles validation errors', (tester) async {
    await tester.pumpWidget(
      createApp(
        child: JsonTextFieldEditor(
          fieldKey: 'error-editor',
          initialValue: '{invalid json}',
        ),
      ),
    );

    // Wait for validator
    await tester.pump(const Duration(milliseconds: 600));

    // Verify error widget appears
    expect(find.byType(JsonErrorWidget), findsOneWidget);
  });
}