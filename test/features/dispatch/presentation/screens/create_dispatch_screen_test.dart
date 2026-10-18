import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/create_dispatch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('CreateDispatchScreen Widget Tests', () {
    late MockDispatchRepository repository;

    setUp(() {
      repository = MockDispatchRepository();
    });

    testWidgets('unauthorized user gets AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateDispatchScreen(
            user: MockAuthTestFixtures.standardUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.text('New Dispatch Order'), findsNothing);
    });

    testWidgets('renders all structured form sections and buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateDispatchScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Dispatch Order'), findsOneWidget);
      expect(find.byKey(const Key('dispatch_save_button')), findsOneWidget);

      // Section titles
      expect(find.text('Customer & Delivery Destination'), findsOneWidget);
      expect(find.text('Invoice & Commercial Details'), findsOneWidget);
      expect(find.text('Transport & Logistics Information'), findsOneWidget);
      expect(find.text('Shipment Line Items'), findsOneWidget);
      expect(find.text('Handling & Delivery Notes'), findsOneWidget);

      // Form inputs
      expect(find.byKey(const Key('dispatch_form_customer_name')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_customer_phone')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_delivery_address')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_invoice_number')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_vehicle_number')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_driver_name')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_driver_phone')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_form_builty_number')), findsOneWidget);

      // Initial line item row
      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_add_item_button')), findsOneWidget);
    });

    testWidgets('dynamic line items: adding and removing item rows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateDispatchScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts with 1 item row
      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_name_1')), findsNothing);

      // Add second item
      await tester.tap(find.byKey(const Key('dispatch_add_item_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_name_1')), findsOneWidget);
      expect(find.byKey(const Key('item_remove_1')), findsOneWidget);

      // Remove second item
      await tester.tap(find.byKey(const Key('item_remove_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_name_1')), findsNothing);
    });

    testWidgets('validation error when required fields are blank', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: CreateDispatchScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit without entering data
      await tester.tap(find.byKey(const Key('dispatch_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Customer name required'), findsOneWidget);
      expect(find.text('Customer phone required'), findsOneWidget);
      expect(find.text('Delivery address required'), findsOneWidget);
    });

    testWidgets('successful submission creates dispatch order and navigates back', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('open_create_screen'),
                onPressed: () async {
                  popResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CreateDispatchScreen(
                        user: MockAuthTestFixtures.admin,
                        repository: repository,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_create_screen')));
      await tester.pumpAndSettle();

      // Fill in required fields
      await tester.enterText(
        find.byKey(const Key('dispatch_form_customer_name')),
        'Tech Mahindra Ltd',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_customer_phone')),
        '+91 98765 12345',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_delivery_address')),
        'Electronic City Phase 1, Bangalore',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_invoice_number')),
        'INV-2026-9999',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_invoice_amount')),
        '75000.0',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_transporter_name')),
        'SafeXpress',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_vehicle_number')),
        'KA-01-EE-4567',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_driver_name')),
        'Sunil Verma',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_driver_phone')),
        '+91 97111 22334',
      );
      await tester.enterText(
        find.byKey(const Key('dispatch_form_builty_number')),
        'BL-SAFE-88712',
      );

      // Line item
      await tester.enterText(
        find.byKey(const Key('item_name_0')),
        'High-Speed Managed Switches',
      );
      await tester.enterText(find.byKey(const Key('item_sku_0')), 'NET-SW-01');
      await tester.enterText(find.byKey(const Key('item_quantity_0')), '5');
      await tester.enterText(find.byKey(const Key('item_price_0')), '15000');

      // Submit
      await tester.tap(find.byKey(const Key('dispatch_save_button')));
      await tester.pumpAndSettle();

      // Verify popped with true
      expect(popResult, isTrue);

      // Verify repository contains the new dispatch
      final dispatches = await repository.getDispatches();
      expect(
        dispatches.any((d) => d.customerName == 'Tech Mahindra Ltd'),
        isTrue,
      );
    });
  });
}
