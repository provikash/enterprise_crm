import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_summary.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_filter_bar.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_summary_cards.dart';

void main() {
  group('DispatchSummaryCards Filtering Widget Tests', () {
    const summary = DispatchSummary(
      totalDispatches: 25,
      pendingCount: 5,
      inTransitCount: 8,
      outForDeliveryCount: 4,
      deliveredCount: 8,
      todayDispatchesCount: 4,
    );

    testWidgets('renders all 5 KPI cards with correct counts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DispatchSummaryCards(summary: summary),
          ),
        ),
      );

      expect(find.byKey(const Key('dispatch_summary_total')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_pending')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_in_transit')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_out_for_delivery')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_delivered')), findsOneWidget);

      expect(find.text('25'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('8'), findsNWidgets(2)); // in transit and delivered both 8
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('tapping pending card calls onStatusSelected with pending', (tester) async {
      DispatchStatus? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchSummaryCards(
              summary: summary,
              onStatusSelected: (status) => selectedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('dispatch_summary_pending')));
      await tester.pump();

      expect(selectedStatus, equals(DispatchStatus.pending));
    });

    testWidgets('tapping out for delivery card calls onStatusSelected with outForDelivery', (tester) async {
      DispatchStatus? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchSummaryCards(
              summary: summary,
              onStatusSelected: (status) => selectedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('dispatch_summary_out_for_delivery')));
      await tester.pump();

      expect(selectedStatus, equals(DispatchStatus.outForDelivery));
    });

    testWidgets('tapping already selected card toggles it off back to null', (tester) async {
      DispatchStatus? selectedStatus = DispatchStatus.inTransit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchSummaryCards(
              summary: summary,
              selectedStatus: DispatchStatus.inTransit,
              onStatusSelected: (status) => selectedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('dispatch_summary_in_transit')));
      await tester.pump();

      expect(selectedStatus, isNull);
    });

    testWidgets('tapping Total card sets filter to null', (tester) async {
      DispatchStatus? selectedStatus = DispatchStatus.delivered;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchSummaryCards(
              summary: summary,
              selectedStatus: DispatchStatus.delivered,
              onStatusSelected: (status) => selectedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('dispatch_summary_total')));
      await tester.pump();

      expect(selectedStatus, isNull);
    });
  });

  group('DispatchFilterBar Clear Filter Widget Tests', () {
    testWidgets('clear filter button calls onClearFilters callback', (tester) async {
      var cleared = false;
      final controller = TextEditingController(text: 'Acme');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DispatchFilterBar(
              searchController: controller,
              selectedStatus: DispatchStatus.pending,
              onSearchChanged: (_) {},
              onSearchCleared: () {},
              onStatusChanged: (_) {},
              onRefresh: () {},
              onClearFilters: () => cleared = true,
            ),
          ),
        ),
      );

      final clearButtonFinder = find.byKey(const Key('dispatch_clear_filters_button'));
      expect(clearButtonFinder, findsOneWidget);

      await tester.tap(clearButtonFinder);
      await tester.pump();

      expect(cleared, isTrue);
    });
  });
}
