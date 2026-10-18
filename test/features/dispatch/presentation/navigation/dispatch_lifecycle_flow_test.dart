import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_status.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_details_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('Dispatch Lifecycle & Details Integration Flow', () {
    testWidgets('view dispatch from workspace, advance status to delivered, and verify workspace refresh', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2400, 1200));
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

      // On workspace, dsp_001 view button is available
      final viewButton = find.byKey(const Key('dispatch_view_button_dsp_001'));
      expect(viewButton, findsOneWidget);

      // Tap view button
      await tester.ensureVisible(viewButton);
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      // Verified: on DispatchDetailsScreen
      expect(find.byType(DispatchDetailsScreen), findsOneWidget);
      expect(find.text('DSP-2026-001'), findsOneWidget);

      // Tap Update Status
      await tester.tap(find.byKey(const Key('open_update_status_dialog_button')));
      await tester.pumpAndSettle();

      // Change status to Delivered
      await tester.tap(find.byKey(const Key('dispatch_status_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(DispatchStatus.delivered.displayName).last);
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.byKey(const Key('confirm_status_update_button')));
      await tester.pumpAndSettle();

      // Status is updated on details screen
      expect(find.text(DispatchStatus.delivered.displayName), findsWidgets);

      // Pop back to workspace
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verified back on DispatchWorkspaceScreen
      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.byType(DispatchDetailsScreen), findsNothing);

      // Verify that status in repository was updated
      final record = await repository.getDispatchById('dsp_001');
      expect(record?.status, equals(DispatchStatus.delivered));
    });
  });
}
