import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_status.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_summary.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_filter_bar.dart';
import 'package:enterprise_crm/features/purchase/presentation/widgets/purchase_summary_cards.dart';

void main() {
  group('PurchaseSummaryCards Widget Tests', () {
    const summary = PurchaseSummary(
      totalOrders: 30,
      draftCount: 5,
      pendingApprovalCount: 6,
      approvedCount: 7,
      orderedCount: 4,
      receivedCount: 8,
      totalSpendAmount: 450000.0,
    );

    testWidgets('renders all 6 KPI cards with correct metrics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurchaseSummaryCards(summary: summary),
          ),
        ),
      );

      expect(find.byKey(const Key('purchase_summary_total')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_pending_approval')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_approved')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_ordered')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_received')), findsOneWidget);
      expect(find.byKey(const Key('purchase_summary_spend')), findsOneWidget);

      expect(find.text('30'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('₹4.5L'), findsOneWidget);
    });

    testWidgets('tapping pending approval card calls onStatusSelected with pendingApproval', (tester) async {
      PurchaseOrderStatus? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseSummaryCards(
              summary: summary,
              onStatusSelected: (status) => selected = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('purchase_summary_pending_approval')));
      await tester.pump();

      expect(selected, equals(PurchaseOrderStatus.pendingApproval));
    });

    testWidgets('tapping approved card calls onStatusSelected with approved', (tester) async {
      PurchaseOrderStatus? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseSummaryCards(
              summary: summary,
              onStatusSelected: (status) => selected = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('purchase_summary_approved')));
      await tester.pump();

      expect(selected, equals(PurchaseOrderStatus.approved));
    });

    testWidgets('tapping already selected card toggles it off back to null', (tester) async {
      PurchaseOrderStatus? selected = PurchaseOrderStatus.ordered;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseSummaryCards(
              summary: summary,
              selectedStatus: PurchaseOrderStatus.ordered,
              onStatusSelected: (status) => selected = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('purchase_summary_ordered')));
      await tester.pump();

      expect(selected, isNull);
    });

    testWidgets('tapping Total POs card sets filter to null', (tester) async {
      PurchaseOrderStatus? selected = PurchaseOrderStatus.received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseSummaryCards(
              summary: summary,
              selectedStatus: PurchaseOrderStatus.received,
              onStatusSelected: (status) => selected = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('purchase_summary_total')));
      await tester.pump();

      expect(selected, isNull);
    });
  });

  group('PurchaseFilterBar Widget Tests', () {
    testWidgets('typing in search bar triggers onSearchChanged', (tester) async {
      String? changed;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseFilterBar(
              searchController: controller,
              selectedStatus: null,
              onSearchChanged: (val) => changed = val,
              onSearchCleared: () {},
              onStatusChanged: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('purchase_search_input')), 'Apex');
      await tester.pump();

      expect(changed, equals('Apex'));
    });

    testWidgets('search clear button triggers onSearchCleared callback', (tester) async {
      var cleared = false;
      final controller = TextEditingController(text: 'Monitors');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseFilterBar(
              searchController: controller,
              selectedStatus: null,
              onSearchChanged: (_) {},
              onSearchCleared: () => cleared = true,
              onStatusChanged: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      final clearIconFinder = find.byKey(const Key('purchase_search_clear_button'));
      expect(clearIconFinder, findsOneWidget);

      await tester.tap(clearIconFinder);
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('refresh button calls onRefresh callback', (tester) async {
      var refreshed = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseFilterBar(
              searchController: controller,
              selectedStatus: null,
              onSearchChanged: (_) {},
              onSearchCleared: () {},
              onStatusChanged: (_) {},
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('purchase_refresh_button')));
      await tester.pump();

      expect(refreshed, isTrue);
    });

    testWidgets('clear filters button appears and calls onClearFilters when filters active', (tester) async {
      var clearedAll = false;
      final controller = TextEditingController(text: 'PO-2026');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurchaseFilterBar(
              searchController: controller,
              selectedStatus: PurchaseOrderStatus.ordered,
              onSearchChanged: (_) {},
              onSearchCleared: () {},
              onStatusChanged: (_) {},
              onRefresh: () {},
              onClearFilters: () => clearedAll = true,
            ),
          ),
        ),
      );

      final clearButtonFinder = find.byKey(const Key('purchase_clear_filters_button'));
      expect(clearButtonFinder, findsOneWidget);

      await tester.tap(clearButtonFinder);
      await tester.pump();

      expect(clearedAll, isTrue);
    });
  });
}
