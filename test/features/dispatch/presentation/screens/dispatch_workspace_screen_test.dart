import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_record.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_data_table.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_mobile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

Widget _buildTestApp({
  required CurrentUser user,
  required MockDispatchRepository repository,
  VoidCallback? onCreateDispatch,
  ValueChanged<DispatchRecord>? onViewDispatch,
  Size surfaceSize = const Size(1200, 800),
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: DispatchWorkspaceScreen(
        user: user,
        repository: repository,
        onCreateDispatch: onCreateDispatch,
        onViewDispatch: onViewDispatch,
      ),
    ),
  );
}

void main() {
  group('DispatchWorkspaceScreen Widget Tests', () {
    late MockDispatchRepository repository;

    setUp(() {
      repository = MockDispatchRepository();
    });

    testWidgets('unauthorized user without dispatch module gets AccessRestrictedScreen', (
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
      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.text('Dispatch Management'), findsNothing);
    });

    testWidgets('authorized user sees header, summary cards, and desktop data table', (
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
      expect(find.text('Dispatch Management'), findsOneWidget);
      expect(find.byKey(const Key('create_dispatch_button')), findsOneWidget);

      // KPI Summary Cards
      expect(find.byKey(const Key('dispatch_summary_total')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_pending')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_in_transit')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_summary_delivered')), findsOneWidget);

      // Filter Bar
      expect(find.byKey(const Key('dispatch_search_input')), findsOneWidget);
      expect(
        find.byKey(const Key('dispatch_status_filter_dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dispatch_refresh_button')), findsOneWidget);

      // Desktop DataTable
      expect(find.byType(DispatchDataTable), findsOneWidget);
      expect(find.byKey(const Key('dispatch_records_table')), findsOneWidget);
      expect(find.text('DSP-2026-001'), findsOneWidget);
    });

    testWidgets('mobile screen width renders DispatchMobileCard cards', (
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

      expect(find.byType(DispatchDataTable), findsNothing);
      expect(find.byType(DispatchMobileCard), findsWidgets);
      // Newest dispatch DSP-2026-003 is at top of mobile list
      expect(find.text('DSP-2026-003'), findsOneWidget);
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

      expect(find.byKey(const Key('dispatch_code_dsp_001')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_code_dsp_002')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('dispatch_search_input')),
        'DSP-2026-001',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispatch_code_dsp_001')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_code_dsp_002')), findsNothing);

      // Clear search
      await tester.tap(find.byKey(const Key('dispatch_search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispatch_code_dsp_001')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_code_dsp_002')), findsOneWidget);
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

      await tester.tap(find.byKey(const Key('dispatch_status_filter_dropdown')));
      await tester.pumpAndSettle();

      // Select Delivered
      await tester.tap(find.text(DispatchStatus.delivered.displayName).last);
      await tester.pumpAndSettle();

      // Only delivered records are present
      expect(find.text('DSP-2026-006'), findsOneWidget);
      expect(find.text('DSP-2026-001'), findsNothing); // In Transit
    });

    testWidgets('create dispatch button triggers callback', (tester) async {
      bool created = false;

      await tester.pumpWidget(
        _buildTestApp(
          user: MockAuthTestFixtures.admin,
          repository: repository,
          onCreateDispatch: () {
            created = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_dispatch_button')));
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

      // Tap delivered summary card
      await tester.tap(find.byKey(const Key('dispatch_summary_delivered')));
      await tester.pumpAndSettle();

      // Only delivered records shown
      expect(find.text('DSP-2026-006'), findsOneWidget);
      expect(find.text('DSP-2026-001'), findsNothing);

      // Tap clear filters button
      final clearButtonFinder = find.byKey(const Key('dispatch_clear_filters_button'));
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // All records shown again
      expect(find.text('DSP-2026-001'), findsOneWidget);
    });

    testWidgets('tapping export button opens DispatchExportDialog', (
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

      final exportButton = find.byKey(const Key('dispatch_export_button'));
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispatch_export_dialog')), findsOneWidget);
    });

    testWidgets('User 1 (view only) cannot see create dispatch or export buttons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user1 = CurrentUser(
        id: 'usr_1',
        displayName: 'User 1',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view'},
      );

      await tester.pumpWidget(
        _buildTestApp(
          user: user1,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Management'), findsOneWidget);
      expect(find.byKey(const Key('create_dispatch_button')), findsNothing);
      expect(find.byKey(const Key('dispatch_export_button')), findsNothing);
    });

    testWidgets('User with dispatch.create sees create button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final creator = CurrentUser(
        id: 'usr_creator',
        displayName: 'Creator',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.create'},
      );

      await tester.pumpWidget(
        _buildTestApp(
          user: creator,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_dispatch_button')), findsOneWidget);
      expect(find.byKey(const Key('dispatch_export_button')), findsNothing);
    });

    testWidgets('User with dispatch.export.pdf sees export button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final exporter = CurrentUser(
        id: 'usr_exporter',
        displayName: 'Exporter',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.export.pdf'},
      );

      await tester.pumpWidget(
        _buildTestApp(
          user: exporter,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispatch_export_button')), findsOneWidget);
      expect(find.byKey(const Key('create_dispatch_button')), findsNothing);
    });
  });
}
