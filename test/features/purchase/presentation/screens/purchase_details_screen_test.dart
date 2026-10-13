import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/presentation/screens/purchase_details_screen.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_lifecycle_stepper.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

Widget _buildTestApp({
  required String purchaseOrderId,
  required MockPurchaseRepository repository,
  CurrentUser? user,
  Size surfaceSize = const Size(1200, 900),
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: PurchaseDetailsScreen(
        purchaseOrderId: purchaseOrderId,
        user: user ?? MockAuthTestFixtures.admin,
        repository: repository,
      ),
    ),
  );
}

void main() {
  group('PurchaseDetailsScreen Widget Tests', () {
    late MockPurchaseRepository repository;

    setUp(() {
      repository = MockPurchaseRepository();
    });

    testWidgets('unauthorized user gets AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_001',
          repository: repository,
          user: MockAuthTestFixtures.standardUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.text('PO-2026-001'), findsNothing);
    });

    testWidgets('authorized admin sees PO details, stepper, line items, and totals', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_001',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PO-2026-001'), findsOneWidget);
      expect(find.byType(PurchaseLifecycleStepper), findsOneWidget);
      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsOneWidget);
      expect(find.text('27-inch 4K UHD Monitors'), findsOneWidget);
      expect(find.byKey(const Key('purchase_details_total_amount')), findsOneWidget);
      expect(find.text('₹240720.00'), findsOneWidget);
    });

    testWidgets('draft PO displays Submit for Approval button and advances status', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // po_004 is draft
      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_004',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('purchase_submit_approval_button'));
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final updated = await repository.getPurchaseOrderById('po_004');
      expect(updated!.status, PurchaseOrderStatus.pendingApproval);
      expect(find.text('Pending Approval'), findsWidgets);
    });

    testWidgets('pendingApproval PO displays Approve button for admin and advances status', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // po_003 is pending approval
      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_003',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('purchase_approve_button'));
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      final updated = await repository.getPurchaseOrderById('po_003');
      expect(updated!.status, PurchaseOrderStatus.approved);
      expect(updated.approvedBy, 'Administrator');
      expect(find.text('Approved'), findsWidgets);
    });

    testWidgets('approved PO displays Place Order button and transitions to ordered', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // po_002 is approved
      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_002',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final placeOrderBtn = find.byKey(const Key('purchase_place_order_button'));
      expect(placeOrderBtn, findsOneWidget);

      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();

      final updated = await repository.getPurchaseOrderById('po_002');
      expect(updated!.status, PurchaseOrderStatus.ordered);
      expect(find.text('Ordered'), findsWidgets);
    });

    testWidgets('ordered PO displays Receive Stock button and dialog confirms receipt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // po_001 is ordered
      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_001',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final receiveBtn = find.byKey(const Key('purchase_receive_stock_button'));
      expect(receiveBtn, findsOneWidget);

      await tester.tap(receiveBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receive_stock_dialog')), findsOneWidget);
      expect(find.byKey(const Key('confirm_receive_stock_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_receive_stock_button')));
      await tester.pumpAndSettle();

      final updated = await repository.getPurchaseOrderById('po_001');
      expect(updated!.status, PurchaseOrderStatus.received);
      expect(find.text('Received'), findsWidgets);
    });

    testWidgets('cancel option in popup menu confirms and cancels order', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          purchaseOrderId: 'po_004',
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel PO'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Purchase Order'), findsOneWidget);
      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();

      final updated = await repository.getPurchaseOrderById('po_004');
      expect(updated!.status, PurchaseOrderStatus.cancelled);
      expect(find.text('Purchase Order Cancelled'), findsOneWidget);
    });
  });
}
