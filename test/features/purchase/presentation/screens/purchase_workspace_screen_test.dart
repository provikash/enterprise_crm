import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_record.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/presentation/screens/purchase_workspace_screen.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_data_table.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_mobile_card.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

Widget _buildTestApp({
  required CurrentUser user,
  required MockPurchaseRepository repository,
  VoidCallback? onCreatePurchaseOrder,
  ValueChanged<PurchaseOrderRecord>? onViewPurchaseOrder,
  Size surfaceSize = const Size(1200, 800),
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: PurchaseWorkspaceScreen(
        user: user,
        repository: repository,
        onCreatePurchaseOrder: onCreatePurchaseOrder,
        onViewPurchaseOrder: onViewPurchaseOrder,
      ),
    ),
  );
}

void main() {
  group('PurchaseWorkspaceScreen Widget Tests', () {
    late MockPurchaseRepository repository;

    setUp(() {
      repository = MockPurchaseRepository();
    });

    testWidgets('unauthorized user without purchase module gets AccessRestrictedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.standardUser,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(PurchaseWorkspaceScreen), findsOneWidget);
      expect(find.text('Purchase Management'), findsNothing);
    });

    testWidgets('authorized admin sees header, summary cards, and desktop data table', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Purchase Management'), findsOneWidget);
      expect(find.byKey(const Key('create_purchase_order_button')), findsOneWidget);

      // KPI Summary Cards
      expect(find.byKey(const Key('purchase_summary_total')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_pending_approval')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_approved')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_ordered')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_received')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_spend')), findsOneWidget);

      // Filter Bar
      expect(find.byKey(const Key('purchase_search_input')), findsOneWidget);
      expect(
        find.byKey(const Key('purchase_status_filter_dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('purchase_refresh_button')), findsOneWidget);

      // Desktop DataTable with native scrollbar
      expect(find.byType(PurchaseDataTable), findsOneWidget);
      expect(find.byKey(const Key('purchase_horizontal_scroll_bar')), findsOneWidget);
      expect(find.byKey(const Key('purchase_orders_table')), findsOneWidget);
      expect(find.text('PO-2026-004'), findsOneWidget);
    });

    testWidgets('mobile screen width renders PurchaseMobileCard list', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
          surfaceSize: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PurchaseDataTable), findsNothing);
      expect(find.byType(PurchaseMobileCard), findsWidgets);
      expect(find.text('PO-2026-004'), findsOneWidget);
    });

    testWidgets('typing in search input filters records in table', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsNWidgets(2));

      await tester.enterText(
        find.byKey(const Key('purchase_search_input')),
        'Global Office',
      );
      await tester.pumpAndSettle();

      expect(find.text('Global Office Furnishings'), findsOneWidget);
      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsNothing);

      // Clear search
      await tester.tap(find.byKey(const Key('purchase_search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Apex Tech Supplies Pvt Ltd'), findsNWidgets(2));
    });

    testWidgets('filtering by status updates shown items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('purchase_status_filter_dropdown')));
      await tester.pumpAndSettle();

      // Select Ordered
      await tester.tap(find.text(PurchaseOrderStatus.ordered.displayName).last);
      await tester.pumpAndSettle();

      // Only ordered records are present
      expect(find.text('PO-2026-001'), findsOneWidget);
      expect(find.text('PO-2026-004'), findsNothing); // draft
    });

    testWidgets('create purchase order button triggers callback', (tester) async {
      bool created = false;

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
          onCreatePurchaseOrder: () {
            created = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_purchase_order_button')));
      await tester.pumpAndSettle();

      expect(created, isTrue);
    });

    testWidgets('tapping summary card filters records and clear filters resets view', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Approved summary card
      await tester.tap(find.byKey(const Key('purchase_summary_approved')));
      await tester.pumpAndSettle();

      // Only approved records shown
      expect(find.text('PO-2026-002'), findsOneWidget);
      expect(find.text('PO-2026-001'), findsNothing);

      // Tap clear filters button
      final clearButtonFinder = find.byKey(const Key('purchase_clear_filters_button'));
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // All records shown again
      expect(find.text('PO-2026-004'), findsOneWidget);
    });

    testWidgets('tapping view button triggers onViewPurchaseOrder callback', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      PurchaseOrderRecord? selected;

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
          onViewPurchaseOrder: (po) {
            selected = po;
          },
        ),
      );
      await tester.pumpAndSettle();

      final firstViewButton = find.byKey(const Key('purchase_view_button_po_004'));
      expect(firstViewButton, findsOneWidget);

      await tester.ensureVisible(firstViewButton);
      await tester.pumpAndSettle();

      await tester.tap(firstViewButton);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, equals('po_004'));
    });
  });
}
