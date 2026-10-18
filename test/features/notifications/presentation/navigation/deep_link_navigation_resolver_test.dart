import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approval_detail_screen.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/presentation/navigation/deep_link_navigation_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('DeepLinkNavigationResolver Tests', () {
    testWidgets('returns false when referenceEntityId is null or empty', (
      tester,
    ) async {
      final notification = CrmNotification(
        id: 'n-1',
        recipientUserId: 'usr_admin',
        title: 'System Alert',
        body: 'Alert without target',
        category: NotificationCategory.systemAlert,
        priority: NotificationPriority.info,
        referenceEntityId: null,
        createdAt: DateTime(2026, 10, 1),
      );

      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    result = DeepLinkNavigationResolver.resolve(
                      context,
                      notification: notification,
                      user: MockAuthTestFixtures.admin,
                    );
                  },
                  child: const Text('Resolve Empty Target'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resolve Empty Target'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('resolves approval_request entity and pushes ApprovalDetailScreen', (
      tester,
    ) async {
      final store = MockApprovalStore();
      final repository = MockApprovalRepository(store);
      final notification = CrmNotification(
        id: 'n-2',
        recipientUserId: 'usr_admin',
        title: 'PO Approval',
        body: 'Please approve PO-9821',
        category: NotificationCategory.approvalRequest,
        priority: NotificationPriority.critical,
        referenceModule: CrmModule.purchase,
        referenceEntityType: 'approval_request',
        referenceEntityId: 'appr-001',
        createdAt: DateTime(2026, 10, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    DeepLinkNavigationResolver.resolve(
                      context,
                      notification: notification,
                      user: MockAuthTestFixtures.admin,
                      approvalRepository: repository,
                    );
                  },
                  child: const Text('Resolve Approval Target'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resolve Approval Target'));
      await tester.pumpAndSettle();

      expect(find.byType(ApprovalDetailScreen), findsOneWidget);
      expect(find.text('REQ-2026-0001'), findsOneWidget);
    });

    testWidgets('resolves non-approval target and displays informative feedback', (
      tester,
    ) async {
      final notification = CrmNotification(
        id: 'n-3',
        recipientUserId: 'usr_admin',
        title: 'Employee Check-in',
        body: 'Employee #104 has checked in',
        category: NotificationCategory.announcement,
        priority: NotificationPriority.info,
        referenceModule: CrmModule.hrPayroll,
        referenceEntityType: 'employee',
        referenceEntityId: 'emp-104',
        createdAt: DateTime(2026, 10, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    DeepLinkNavigationResolver.resolve(
                      context,
                      notification: notification,
                      user: MockAuthTestFixtures.admin,
                    );
                  },
                  child: const Text('Resolve Non-Approval'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Resolve Non-Approval'));
      await tester.pumpAndSettle();

      expect(find.text('Target reference: hrPayroll (emp-104)'), findsOneWidget);
    });
  });
}
