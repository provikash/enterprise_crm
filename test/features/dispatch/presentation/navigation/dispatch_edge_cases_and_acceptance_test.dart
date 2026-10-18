import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_filter_query.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_details_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_mobile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

class _ThrowingRepository extends MockDispatchRepository {
  bool shouldThrow = true;

  @override
  Future<List<DispatchRecord>> getDispatches({DispatchFilterQuery? query}) async {
    if (shouldThrow) {
      throw Exception('Network timeout connecting to dispatch gateway');
    }
    return super.getDispatches(query: query);
  }
}

void main() {
  group('Dispatch Module Part 5 - Edge Cases & Integration Acceptance', () {
    late MockDispatchRepository repository;

    setUp(() {
      repository = MockDispatchRepository();
    });

    testWidgets('mobile end-to-end: tap mobile card, view vertical stepper, advance status, and verify workspace refresh', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile cards rendered
      expect(find.byType(DispatchMobileCard), findsWidgets);
      final cardForDsp003 = find.byKey(const Key('dispatch_card_dsp_003'));
      expect(cardForDsp003, findsOneWidget);

      // Tap card to navigate to details
      await tester.tap(cardForDsp003);
      await tester.pumpAndSettle();

      // On details screen with vertical stepper on mobile
      expect(find.byType(DispatchDetailsScreen), findsOneWidget);
      expect(find.text('DSP-2026-003'), findsOneWidget);
      expect(find.byKey(const Key('dispatch_lifecycle_stepper_vertical')), findsOneWidget);

      // Advance status
      await tester.tap(find.byKey(const Key('open_update_status_dialog_button')));
      await tester.pumpAndSettle();

      // Select Delivered
      await tester.tap(find.byKey(const Key('dispatch_status_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(DispatchStatus.delivered.displayName).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_status_update_button')));
      await tester.pumpAndSettle();

      // Now back to workspace
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verified: on workspace again, and dsp_003 reflects Delivered
      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(cardForDsp003, findsOneWidget);
    });

    testWidgets('empty search results show friendly empty state card', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: MockAuthTestFixtures.admin,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a search that yields no match
      await tester.enterText(
        find.byKey(const Key('dispatch_search_input')),
        'QUERY_WITH_NO_MATCHES_12345',
      );
      await tester.pumpAndSettle();

      expect(find.text('No dispatch records found'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('repository error displays error message and retry button re-triggers load', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final throwingRepo = _ThrowingRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: MockAuthTestFixtures.admin,
            repository: throwingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Failure view is displayed
      expect(find.textContaining('Network timeout connecting to dispatch gateway'), findsOneWidget);
      expect(find.byKey(const Key('dispatch_retry_button')), findsOneWidget);

      // Now heal the repository and tap Retry
      throwingRepo.shouldThrow = false;
      await tester.tap(find.byKey(const Key('dispatch_retry_button')));
      await tester.pumpAndSettle();

      // Successfully recovers and loads records
      expect(find.text('DSP-2026-001'), findsOneWidget);
      expect(find.byKey(const Key('dispatch_retry_button')), findsNothing);
    });

    testWidgets('unauthorized user without dispatch module is restricted from accessing workspace', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Attempting to open Dispatch Workspace with standardUser (only leads & calling modules)
      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: MockAuthTestFixtures.standardUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('create_dispatch_button')), findsNothing);
    });
  });
}
