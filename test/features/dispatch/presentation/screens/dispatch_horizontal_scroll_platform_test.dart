import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_data_table.dart';
import 'package:enterprise_crm/features/dispatch/presentation/widgets/dispatch_mobile_card.dart';

void main() {
  group('DispatchWorkspaceScreen - Platform Horizontal Scroll & Responsiveness Tests', () {
    final adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: {CrmModule.dispatch},
      permissions: const {},
    );

    testWidgets('shows bottom horizontal scroll bar and navigation controls on desktop/web', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repository = MockDispatchRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: DispatchWorkspaceScreen(user: adminUser, repository: repository),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DispatchDataTable), findsOneWidget);
        expect(find.byKey(const Key('dispatch_records_table')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_horizontal_scroll_bar')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_scroll_start_button')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_scroll_left_button')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_horizontal_scroll_slider')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_scroll_right_button')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_scroll_end_button')), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('omits bottom horizontal scroll buttons on native Android APK in favor of touch gestures', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repository = MockDispatchRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: DispatchWorkspaceScreen(user: adminUser, repository: repository),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DispatchDataTable), findsOneWidget);
        expect(find.byKey(const Key('dispatch_records_table')), findsOneWidget);
        expect(find.byKey(const Key('dispatch_horizontal_scroll_bar')), findsNothing);
        expect(find.byKey(const Key('dispatch_scroll_start_button')), findsNothing);
        expect(find.byKey(const Key('dispatch_scroll_left_button')), findsNothing);
        expect(find.byKey(const Key('dispatch_horizontal_scroll_slider')), findsNothing);
        expect(find.byKey(const Key('dispatch_scroll_right_button')), findsNothing);
        expect(find.byKey(const Key('dispatch_scroll_end_button')), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('compact mobile screen (<768) uses vertical DispatchMobileCard with no horizontal table', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = MockDispatchRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(user: adminUser, repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DispatchMobileCard), findsWidgets);
      expect(find.byType(DispatchDataTable), findsNothing);
      expect(find.byKey(const Key('dispatch_horizontal_scroll_bar')), findsNothing);
    });
  });
}
