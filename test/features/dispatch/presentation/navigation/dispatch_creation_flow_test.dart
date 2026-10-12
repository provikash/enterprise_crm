import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/create_dispatch_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('Dispatch Creation End-to-End Flow Tests', () {
    testWidgets('create dispatch button launches CreateDispatchScreen and refreshes workspace on success', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = MockDispatchRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.byKey(const Key('create_dispatch_button')), findsOneWidget);

      // Tap "New Dispatch"
      await tester.tap(find.byKey(const Key('create_dispatch_button')));
      await tester.pumpAndSettle();

      // Verified: on CreateDispatchScreen
      expect(find.byType(CreateDispatchScreen), findsOneWidget);
      expect(find.text('New Dispatch Order'), findsOneWidget);

      // Fill form
      await tester.enterText(
        find.byKey(const Key('dispatch_form_customer_name')),
        'Wipro Technologies',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_customer_phone')),
        '+91 99887 76655',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_delivery_address')),
        'Sarjapur Road, Bangalore - 560035',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_invoice_number')),
        'INV-2026-7777',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_invoice_amount')),
        '190000.0',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_transporter_name')),
        'TCI Freight',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_vehicle_number')),
        'KA-53-Z-1001',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_driver_name')),
        'Devendra Yadav',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_driver_phone')),
        '+91 98222 33445',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_builty_number')),
        'BL-TCI-99881',
      );

      // Line item
      await tester.enterText(
        find.byKey(const Key('item_name_0')),
        'Enterprise Rack Servers 2U',
      );
      await tester.enterText(find.byKey(const Key('item_sku_0')), 'SRV-RACK-02');
      await tester.enterText(find.byKey(const Key('item_quantity_0')), '2');
      await tester.enterText(find.byKey(const Key('item_price_0')), '95000');

      // Submit
      await tester.tap(find.byKey(const Key('dispatch_save_button')));
      await tester.pumpAndSettle();

      // Back on DispatchWorkspaceScreen
      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.byType(CreateDispatchScreen), findsNothing);

      // Newly created dispatch appears in the table
      expect(find.text('Wipro Technologies'), findsOneWidget);
      expect(find.text('INV-2026-7777'), findsOneWidget);
    });
  });
}
