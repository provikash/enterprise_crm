import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/presentation/screens/create_purchase_order_screen.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

Widget _buildTestApp({
  required MockPurchaseRepository repository,
  dynamic user,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: CreatePurchaseOrderScreen(
      user: user ?? MockAuthTestFixtures.admin,
      repository: repository,
    ),
  );
}

void main() {
  group('CreatePurchaseOrderScreen Widget Tests', () {
    late MockPurchaseRepository repository;

    setUp(() {
      repository = MockPurchaseRepository();
    });

    testWidgets('unauthorized user gets AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.standardUser,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.text('New Purchase Order'), findsNothing);
    });

    testWidgets('authorized admin sees form fields, line items, and financial summary', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('New Purchase Order'), findsOneWidget);
      expect(find.byKey(const Key('purchase_save_po_button')), findsOneWidget);

      // Section 1
      expect(find.byKey(const Key('purchase_form_vendor_name')), findsOneWidget);
      expect(find.byKey(const Key('purchase_form_vendor_gst')), findsOneWidget);
      expect(find.byKey(const Key('purchase_form_vendor_contact')), findsOneWidget);

      // Section 2
      expect(find.byKey(const Key('purchase_form_payment_terms')), findsOneWidget);
      expect(find.byKey(const Key('purchase_form_shipping_address')), findsOneWidget);

      // Section 3: Line item
      expect(find.byKey(const Key('purchase_add_item_button')), findsOneWidget);
      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_sku_0')), findsOneWidget);
      expect(find.byKey(const Key('item_quantity_0')), findsOneWidget);
      expect(find.byKey(const Key('item_price_0')), findsOneWidget);

      // Section 4: Financial Summary Card
      expect(find.byKey(const Key('purchase_financial_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_subtotal')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_tax')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_total_amount')), findsOneWidget);

      // Section 5: Notes
      expect(find.byKey(const Key('purchase_form_notes')), findsOneWidget);
    });

    testWidgets('tapping Create PO with empty vendor name triggers form validation error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('purchase_save_po_button')));
      await tester.pumpAndSettle();

      expect(find.text('Vendor name required'), findsOneWidget);
    });

    testWidgets('entering line item details updates live financial calculation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(repository: repository));
      await tester.pumpAndSettle();

      // Enter Qty = 10, Price = 500
      await tester.enterText(find.byKey(const Key('item_quantity_0')), '10');
      await tester.enterText(find.byKey(const Key('item_price_0')), '500');
      await tester.pumpAndSettle();

      // Subtotal = 5000, Tax = 900 (18%), Total = 5900
      expect(find.text('₹5000.00'), findsWidgets);
      expect(find.text('₹900.00'), findsOneWidget);
      expect(find.text('₹5900.00'), findsOneWidget);
    });

    testWidgets('adding and removing items dynamically adjusts line items and totals', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_name_1')), findsNothing);

      // Tap Add Item
      await tester.tap(find.byKey(const Key('purchase_add_item_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_name_0')), findsOneWidget);
      expect(find.byKey(const Key('item_name_1')), findsOneWidget);
      expect(find.byKey(const Key('item_remove_1')), findsOneWidget);

      // Remove item 1
      await tester.tap(find.byKey(const Key('item_remove_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item_name_1')), findsNothing);
    });

    testWidgets('submitting valid purchase order calls repository and creates order', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(repository: repository));
      await tester.pumpAndSettle();

      // Fill in vendor info
      await tester.enterText(
        find.byKey(const Key('purchase_form_vendor_name')),
        'Zenith Components India Ltd',
      );
      await tester.enterText(
        find.byKey(const Key('purchase_form_vendor_gst')),
        '07ZZZZZ9999Z1Z1',
      );
      await tester.enterText(
        find.byKey(const Key('purchase_form_vendor_contact')),
        '+91 99112 33445',
      );

      // Fill in line item
      await tester.enterText(
        find.byKey(const Key('item_name_0')),
        '4K IPS Displays 32 inch',
      );
      await tester.enterText(
        find.byKey(const Key('item_sku_0')),
        'INV-MON-32',
      );
      await tester.enterText(
        find.byKey(const Key('item_quantity_0')),
        '5',
      );
      await tester.enterText(
        find.byKey(const Key('item_price_0')),
        '12000',
      );
      await tester.pumpAndSettle();

      // Tap Create PO
      await tester.tap(find.byKey(const Key('purchase_save_po_button')));
      await tester.pumpAndSettle();

      // Verify order is created in repository
      final orders = await repository.getPurchaseOrders();
      final created = orders.firstWhere(
        (po) => po.vendorName == 'Zenith Components India Ltd',
      );
      expect(created, isNotNull);
      expect(created.items.first.itemName, '4K IPS Displays 32 inch');
      expect(created.items.first.orderedQuantity, 5);
      expect(created.subtotalAmount, 60000.0);
      expect(created.taxAmount, 10800.0);
      expect(created.totalAmount, 70800.0);
    });
  });
}
