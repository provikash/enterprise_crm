import 'package:enterprise_crm/features/leads/presentation/widgets/hybrid_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required TextEditingController controller,
    required List<String> options,
    String labelText = 'Test Label',
    String? hintText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: HybridDropdownField(
            controller: controller,
            options: options,
            labelText: labelText,
            hintText: hintText,
            onChanged: onChanged,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('HybridDropdownField Widget Tests', () {
    testWidgets('renders initial value and label correctly', (tester) async {
      final controller = TextEditingController(text: 'Initial');
      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          options: ['Option A', 'Option B'],
          labelText: 'Select Option',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Option'), findsOneWidget);
      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('tapping dropdown icon shows full list of options', (tester) async {
      final controller = TextEditingController(text: 'Option A');
      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          options: ['Option A', 'Option B', 'Option C'],
        ),
      );
      await tester.pumpAndSettle();

      // Tap suffix icon to open dropdown
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);

      // Tap Option B
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Option B');
    });

    testWidgets('allows arbitrary manual text entry when option not in list', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? changedVal;

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          options: ['Mumbai', 'Delhi', 'Bengaluru'],
          onChanged: (val) => changedVal = val,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Label'),
        'Custom City 123',
      );
      await tester.pumpAndSettle();

      expect(controller.text, 'Custom City 123');
      expect(changedVal, 'Custom City 123');
    });

    testWidgets('filters suggestions dynamically as user types', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          options: ['Pune', 'Punjab', 'Patna', 'Mumbai'],
        ),
      );
      await tester.pumpAndSettle();

      // Enter 'Pu'
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Test Label'),
        'Pu',
      );
      await tester.pumpAndSettle();

      expect(find.text('Pune'), findsOneWidget);
      expect(find.text('Punjab'), findsOneWidget);
      expect(find.text('Mumbai'), findsNothing);
    });

    testWidgets('disabled field ignores taps and suffix icon presses', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          options: ['Option 1', 'Option 2'],
          enabled: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_drop_down), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Option 1'), findsNothing);
    });
  });
}
