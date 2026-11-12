import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/accessibility/crm_semantics.dart';

void main() {
  group('CrmSemantics WCAG 2.1 AA Accessibility Tests', () {
    testWidgets('button enforces minimum 48x48 touch target dimension', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      const buttonKey = Key('accessible_save_btn');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CrmSemantics.button(
                label: 'Save Changes',
                hint: 'Double tap to save',
                onTap: () {},
                child: const Icon(Icons.save, key: buttonKey, size: 20),
              ),
            ),
          ),
        ),
      );

      final boxFinder = find.ancestor(
        of: find.byKey(buttonKey),
        matching: find.byType(ConstrainedBox),
      ).first;

      final renderBox = tester.renderObject<RenderBox>(boxFinder);
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));

      final semantics = tester.getSemantics(boxFinder);
      expect(semantics.label, 'Save Changes');
      expect(semantics.hint, 'Double tap to save');
      expect(semantics.flagsCollection.isButton, isTrue);

      semanticsHandle.dispose();
    });

    testWidgets('metricCard assigns container semantics and composite label', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      const cardContentKey = Key('card_content');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CrmSemantics.metricCard(
                label: 'Total Leads',
                value: '1,420',
                child: const Text('1,420', key: cardContentKey),
              ),
            ),
          ),
        ),
      );

      final cardFinder = find.ancestor(
        of: find.byKey(cardContentKey),
        matching: find.byType(Semantics),
      ).first;

      final semantics = tester.getSemantics(cardFinder);
      expect(semantics.label, 'Total Leads: 1,420');

      semanticsHandle.dispose();
    });

    testWidgets('announce invokes accessibility dispatch cleanly without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await CrmSemantics.announce(context, 'Lead successfully created.');
                  },
                  child: const Text('Announce'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Announce'));
      await tester.pumpAndSettle();
      // Verified: no unhandled exception thrown during announcement
    });
  });
}
