import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_lifecycle_stepper.dart';

void main() {
  group('PurchaseLifecycleStepper Widget Tests', () {
    testWidgets('renders cancelled banner when status is cancelled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurchaseLifecycleStepper(
              currentStatus: PurchaseOrderStatus.cancelled,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('purchase_stepper_cancelled')), findsOneWidget);
      expect(find.text('Purchase Order Cancelled'), findsOneWidget);
    });

    testWidgets('renders horizontal stepper on wide viewports (>= 640px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurchaseLifecycleStepper(
              currentStatus: PurchaseOrderStatus.ordered,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('purchase_lifecycle_stepper_horizontal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('purchase_lifecycle_stepper_vertical')),
        findsNothing,
      );

      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Ordered'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets('renders vertical stepper on narrow viewports (< 640px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurchaseLifecycleStepper(
              currentStatus: PurchaseOrderStatus.draft,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('purchase_lifecycle_stepper_vertical')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('purchase_lifecycle_stepper_horizontal')),
        findsNothing,
      );
    });
  });
}
