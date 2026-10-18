import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approval_history_export_screen.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approvals_workspace_screen.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockApprovalStore store;
  late MockApprovalRepository repository;

  final adminUser = CurrentUser(
    id: 'usr-admin',
    accountType: AccountType.admin,
    displayName: 'System Administrator',
    modules: CrmModule.values.toSet(),
    permissions: const {
      CrmPermissions.approvalsView,
      CrmPermissions.approvalsAction,
      CrmPermissions.approvalsExport,
    },
  );

  final userWithoutExport = CurrentUser(
    id: 'usr-standard',
    accountType: AccountType.user,
    displayName: 'Standard User',
    modules: const {CrmModule.approvalsNotifications},
    permissions: const {CrmPermissions.approvalsView},
  );

  final userWithExport = CurrentUser(
    id: 'usr-analyst',
    accountType: AccountType.user,
    displayName: 'BI Analyst',
    modules: const {CrmModule.approvalsNotifications},
    permissions: const {
      CrmPermissions.approvalsView,
      CrmPermissions.approvalsExport,
    },
  );

  setUp(() {
    store = MockApprovalStore();
    repository = MockApprovalRepository(store);
  });

  Widget buildTestApp({
    required CurrentUser user,
    MockApprovalRepository? repo,
  }) {
    return MaterialApp(
      home: ApprovalHistoryExportScreen(
        user: user,
        repository: repo ?? repository,
      ),
    );
  }

  group('ApprovalHistoryExportScreen Widget Tests', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(buildTestApp(user: userWithoutExport));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(ApprovalHistoryExportScreen), findsOneWidget);
      expect(find.byKey(const Key('export_search_field')), findsNothing);
    });

    testWidgets('authorized user sees search, filter controls, and seeded records', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(user: adminUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export_search_field')), findsOneWidget);
      expect(find.byKey(const Key('export_csv_button')), findsOneWidget);
      expect(find.byKey(const Key('export_module_filter')), findsOneWidget);
      expect(find.byKey(const Key('export_status_filter')), findsOneWidget);
      expect(find.byKey(const Key('export_priority_filter')), findsOneWidget);
      expect(find.byKey(const Key('export_date_range_button')), findsOneWidget);

      expect(find.textContaining('Showing 6 of 6 records'), findsOneWidget);
    });

    testWidgets('search query filters approval records correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(user: userWithExport));
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 6 of 6 records'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('export_search_field')),
        'Titanium',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 1 of 6 records'), findsOneWidget);
      expect(find.textContaining('Titanium Rods'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 6 of 6 records'), findsOneWidget);
    });

    testWidgets('Export CSV button opens preview dialog and triggers clipboard copy', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(user: adminUser));
      await tester.pumpAndSettle();

      final exportButton = find.byKey(const Key('export_csv_button'));
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Export Preview (6 records)'), findsOneWidget);
      expect(find.textContaining('RFC-4180 Compliant CSV'), findsOneWidget);

      final copyButton = find.byKey(const Key('copy_csv_clipboard_button'));
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Copied 6 records to clipboard as CSV.'),
        findsOneWidget,
      );
    });

    testWidgets('ApprovalsWorkspaceScreen links to export screen for permitted user', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApprovalsWorkspaceScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportHistoryButton = find.byKey(
        const Key('workspace_export_history_button'),
      );
      expect(exportHistoryButton, findsOneWidget);

      await tester.tap(exportHistoryButton);
      await tester.pumpAndSettle();

      expect(find.byType(ApprovalHistoryExportScreen), findsOneWidget);
      expect(find.text('Approval History & Export'), findsOneWidget);
    });

    testWidgets('ApprovalsWorkspaceScreen hides export button for unpermitted user', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApprovalsWorkspaceScreen(
            user: userWithoutExport,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('workspace_export_history_button')),
        findsNothing,
      );
    });

    testWidgets('responsive layout renders cleanly across multiple viewports', (
      tester,
    ) async {
      const viewports = [
        Size(320, 568),
        Size(360, 640),
        Size(768, 1024),
        Size(1200, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildTestApp(user: adminUser));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('export_search_field')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
