import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_notification_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_approval_exception.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_notification_exception.dart';
import 'package:enterprise_crm/features/hr/domain/services/hr_approval_notification_service.dart';
import 'package:enterprise_crm/features/hr/domain/services/hr_approval_workflow_validator.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_decision_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_decision_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_request_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_request_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_notification_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_notification_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/pending_approvals_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/pending_approvals_state.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_approval_request_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/pending_approvals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHrApprovalRepository approvalRepository;
  late MockHrNotificationRepository notificationRepository;
  late HrApprovalNotificationService notificationService;

  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'System Admin',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrUser = CurrentUser(
    id: 'usr_hr',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  const standardUser = CurrentUser(
    id: 'usr_standard',
    displayName: 'Standard User',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_sales',
    displayName: 'Sales Agent',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {},
  );

  setUp(() {
    notificationRepository = MockHrNotificationRepository();
    notificationService = HrApprovalNotificationService(
      notificationRepository: notificationRepository,
      adminRecipientUserId: 'usr_admin',
    );
    approvalRepository = MockHrApprovalRepository(
      notificationService: notificationService,
    );
  });

  group('HR-9.9 — Request Submission Security & Authorization', () {
    test('authorized user submits approval request via cubit', () async {
      final cubit = HrApprovalRequestCubit(repository: approvalRepository);

      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        target: HrApprovalTarget.payrollPeriod('period_2026_03'),
        requester: hrUser,
        remarks: 'March payroll review',
      );

      expect(cubit.state, isA<HrApprovalRequestSuccess>());
      final req = (cubit.state as HrApprovalRequestSuccess).request;
      expect(req.requesterId, 'usr_hr');
      expect(req.status, HrApprovalStatus.pending);
      expect(req.target.targetEntityId, 'period_2026_03');

      await cubit.close();
    });

    test('unauthorized user cannot submit approval request', () async {
      final cubit = HrApprovalRequestCubit(repository: approvalRepository);

      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        target: HrApprovalTarget.payrollPeriod('period_2026_03'),
        requester: unauthorizedUser,
      );

      expect(cubit.state, isA<HrApprovalRequestFailure>());
      expect(
        (cubit.state as HrApprovalRequestFailure).message,
        contains('Unauthorized'),
      );

      await cubit.close();
    });

    test('empty target entity ID fails validation', () async {
      final cubit = HrApprovalRequestCubit(repository: approvalRepository);

      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        target: const HrApprovalTarget(
          targetModule: CrmModule.hrPayroll,
          targetEntityType: 'payroll_period',
          targetEntityId: '   ',
        ),
        requester: hrUser,
      );

      expect(cubit.state, isA<HrApprovalRequestFailure>());
      expect(
        (cubit.state as HrApprovalRequestFailure).message,
        contains('Target entity ID is required'),
      );

      await cubit.close();
    });

    test('empty requester ID is rejected by repository store', () async {
      expect(
        () => approvalRepository.submitRequest(
          workflowType: HrApprovalWorkflowType.attendanceCorrection,
          requesterId: '   ',
          target: HrApprovalTarget.attendanceRecord('att_1'),
        ),
        throwsA(isA<HrApprovalWorkflowException>()),
      );
    });
  });

  group('HR-9.9 — Decision Authorization & State Transition Integrity', () {
    test('non-admin user cannot submit approval or rejection decision', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: hrUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
      );

      expect(
        () => approvalRepository.submitDecision(
          requestId: 'appr_req_1',
          decision: decision,
          actor: hrUser,
        ),
        throwsA(
          isA<HrApprovalWorkflowException>().having(
            (e) => e.code,
            'code',
            HrApprovalWorkflowException.unauthorizedActor,
          ),
        ),
      );
    });

    test('decision actorId must match authenticated user ID', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: 'usr_different',
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
      );

      expect(
        () => approvalRepository.submitDecision(
          requestId: 'appr_req_1',
          decision: decision,
          actor: adminUser,
        ),
        throwsA(
          isA<HrApprovalWorkflowException>().having(
            (e) => e.code,
            'code',
            HrApprovalWorkflowException.validationError,
          ),
        ),
      );
    });

    test('admin can approve pending request and transition to approved', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
        reason: 'Monthly payroll figures verified',
      );

      final result = await approvalRepository.submitDecision(
        requestId: 'appr_req_1',
        decision: decision,
        actor: adminUser,
      );

      expect(result.status, HrApprovalStatus.approved);
      expect(result.updatedAt, isNotNull);

      // Verify audit history was appended atomically
      final history = await approvalRepository.getHistoryForRequest('appr_req_1');
      expect(history.length, 2);
      expect(history.last.action, 'approved');
      expect(history.last.actorId, adminUser.id);
      expect(history.last.newStatus, HrApprovalStatus.approved);
      expect(history.last.previousStatus, HrApprovalStatus.pending);
    });

    test('terminal request cannot be decided again (duplicate decision protection)', () async {
      // appr_req_3 is already approved in seed data
      final decision = HrApprovalDecision(
        requestId: 'appr_req_3',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.reject,
        decisionTime: DateTime.now().toUtc(),
      );

      expect(
        () => approvalRepository.submitDecision(
          requestId: 'appr_req_3',
          decision: decision,
          actor: adminUser,
        ),
        throwsA(
          isA<HrApprovalWorkflowException>().having(
            (e) => e.code,
            'code',
            HrApprovalWorkflowException.duplicateDecision,
          ),
        ),
      );
    });

    test('concurrent decision race: second decision on same request is rejected', () async {
      // Both actors attempt to decide appr_req_2
      final decision1 = HrApprovalDecision(
        requestId: 'appr_req_2',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
      );

      final decision2 = HrApprovalDecision(
        requestId: 'appr_req_2',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.reject,
        decisionTime: DateTime.now().toUtc(),
      );

      // First decision succeeds
      final firstResult = await approvalRepository.submitDecision(
        requestId: 'appr_req_2',
        decision: decision1,
        actor: adminUser,
      );
      expect(firstResult.status, HrApprovalStatus.approved);

      // Second conflicting decision fails with duplicateDecision
      expect(
        () => approvalRepository.submitDecision(
          requestId: 'appr_req_2',
          decision: decision2,
          actor: adminUser,
        ),
        throwsA(
          isA<HrApprovalWorkflowException>().having(
            (e) => e.code,
            'code',
            HrApprovalWorkflowException.duplicateDecision,
          ),
        ),
      );
    });

    test('original requester can cancel pending request', () async {
      // appr_req_2 requesterId is usr_standard
      final result = await approvalRepository.cancelRequest(
        requestId: 'appr_req_2',
        actor: standardUser,
        reason: 'Correction no longer needed',
      );

      expect(result.status, HrApprovalStatus.cancelled);

      final history = await approvalRepository.getHistoryForRequest('appr_req_2');
      expect(history.last.action, 'cancelled');
      expect(history.last.actorId, standardUser.id);
      expect(history.last.newStatus, HrApprovalStatus.cancelled);
    });

    test('unauthorized user cannot cancel another user request', () async {
      // appr_req_2 requesterId is usr_standard, hrUser is neither requester nor admin
      expect(
        () => approvalRepository.cancelRequest(
          requestId: 'appr_req_2',
          actor: hrUser,
          reason: 'Unauthorized cancel attempt',
        ),
        throwsA(
          isA<HrApprovalWorkflowException>().having(
            (e) => e.code,
            'code',
            HrApprovalWorkflowException.unauthorizedActor,
          ),
        ),
      );
    });
  });

  group('HR-9.9 — Scope & Visibility Isolation', () {
    test('standard user only sees pending requests they submitted', () async {
      final pending = await approvalRepository.getPendingRequests(user: standardUser);
      expect(pending.every((r) => r.requesterId == standardUser.id), isTrue);
    });

    test('admin user sees all pending requests regardless of requester', () async {
      final pending = await approvalRepository.getPendingRequests(user: adminUser);
      expect(pending.length, greaterThanOrEqualTo(2));
      final requesters = pending.map((r) => r.requesterId).toSet();
      expect(requesters.contains('usr_hr'), isTrue);
      expect(requesters.contains('usr_standard'), isTrue);
    });

    test('getAllRequests filters by requesterId for non-admin users', () async {
      final userRequests = await approvalRepository.getAllRequests(user: standardUser);
      expect(userRequests.every((r) => r.requesterId == standardUser.id), isTrue);

      final adminRequests = await approvalRepository.getAllRequests(user: adminUser);
      expect(adminRequests.length, greaterThan(userRequests.length));
    });
  });

  group('HR-9.9 — Notification Security, Privacy & Failure Isolation', () {
    test('notifications do NOT contain sensitive salary or financial figures', () async {
      final notifs = await notificationRepository.getNotificationsForUser('usr_admin');
      for (final n in notifs) {
        expect(n.body, isNot(contains(r'$')));
        expect(n.body, isNot(contains('salary')));
        expect(n.body, isNot(contains('gross')));
        expect(n.body, isNot(contains('net pay')));
        expect(n.body, isNot(contains('tax')));
        expect(n.body, isNot(contains('deduction')));
      }
    });

    test('notification recipient isolation: user cannot view another user notifications', () async {
      final adminNotifs = await notificationRepository.getNotificationsForUser('usr_admin');
      final hrNotifs = await notificationRepository.getNotificationsForUser('usr_hr');

      expect(adminNotifs.every((n) => n.recipientUserId == 'usr_admin'), isTrue);
      expect(hrNotifs.every((n) => n.recipientUserId == 'usr_hr'), isTrue);
    });

    test('marking another user notification as read is rejected', () async {
      // Find an admin notification
      final adminNotifs = await notificationRepository.getNotificationsForUser('usr_admin');
      expect(adminNotifs.isNotEmpty, isTrue);

      expect(
        () => notificationRepository.markAsRead(
          adminNotifs.first.id,
          recipientUserId: 'usr_hr',
        ),
        throwsA(
          isA<HrNotificationException>().having(
            (e) => e.code,
            'code',
            HrNotificationException.unauthorizedRecipient,
          ),
        ),
      );
    });

    test('duplicate event suppression: same event key is dispatched only once', () async {
      final req = await approvalRepository.getRequestById('appr_req_1');
      expect(req, isNotNull);

      // First dispatch succeeds
      final notif1 = await notificationService.handleRequestSubmitted(req!);
      expect(notif1, isNotNull);

      // Repeated dispatch returns null (suppressed)
      final notif2 = await notificationService.handleRequestSubmitted(req);
      expect(notif2, isNull);
    });

    test('notification delivery failure does not corrupt approval state (Failure Isolation)', () async {
      // Configure notification repository store to throw
      notificationRepository.store.simulateFailure = true;

      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
      );

      // Approval decision succeeds even though notification service fails internally
      final updated = await approvalRepository.submitDecision(
        requestId: 'appr_req_1',
        decision: decision,
        actor: adminUser,
      );

      expect(updated.status, HrApprovalStatus.approved);

      // Restore notification store
      notificationRepository.store.simulateFailure = false;
    });
  });

  group('HR-9.9 — Session Isolation & Direct Route Security', () {
    test('PendingApprovalsCubit clear() purges loaded requests and resets to initial', () async {
      final cubit = PendingApprovalsCubit(repository: approvalRepository);
      await cubit.loadPendingApprovals(user: adminUser);

      expect(cubit.state, isA<PendingApprovalsLoaded>());

      cubit.clear();
      expect(cubit.state, isA<PendingApprovalsInitial>());

      await cubit.close();
    });

    test('HrApprovalDecisionCubit reset() discards loaded request and resets to initial', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: approvalRepository,
        actor: adminUser,
        requestId: 'appr_req_1',
      );
      await cubit.loadDetails();

      expect(cubit.state, isA<HrApprovalDecisionReady>());
      expect(cubit.currentRequest, isNotNull);

      cubit.reset();
      expect(cubit.state, isA<HrApprovalDecisionInitial>());
      expect(cubit.currentRequest, isNull);

      await cubit.close();
    });

    test('HrNotificationCubit clear() purges notifications on logout', () async {
      final cubit = HrNotificationCubit(repository: notificationRepository);
      await cubit.loadNotifications(user: adminUser);

      expect(cubit.state, isA<HrNotificationLoaded>());

      cubit.clear();
      expect(cubit.state, isA<HrNotificationInitial>());

      await cubit.close();
    });

    testWidgets('unauthorized user navigating to PendingApprovalsScreen sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PendingApprovalsScreen(
            user: unauthorizedUser,
            repository: approvalRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsNothing);
    });

    testWidgets('unauthorized user navigating to HrApprovalRequestDetailsScreen sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HrApprovalRequestDetailsScreen(
            requestId: 'appr_req_1',
            user: unauthorizedUser,
            repository: approvalRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('hr_approval_details_scaffold')), findsNothing);
    });
  });

  group('HR-9.9 — Domain Workflow Validator Invariants', () {
    test('validateTransition throws on terminal request', () async {
      final approvedReq = (await approvalRepository.getRequestById('appr_req_3'))!;
      expect(approvedReq.status.isTerminal, isTrue);

      expect(
        () => HrApprovalWorkflowValidator.validateTransition(
          request: approvedReq,
          nextStatus: HrApprovalStatus.pending,
        ),
        throwsA(isA<HrApprovalWorkflowException>()),
      );

      expect(
        () => HrApprovalWorkflowValidator.validateTransition(
          request: approvedReq,
          nextStatus: HrApprovalStatus.rejected,
        ),
        throwsA(isA<HrApprovalWorkflowException>()),
      );
    });

    test('validateDecision throws if decision requestId does not match target request', () async {
      final req = (await approvalRepository.getRequestById('appr_req_1'))!;
      final decision = HrApprovalDecision(
        requestId: 'mismatched_id',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.now().toUtc(),
      );

      expect(
        () => HrApprovalWorkflowValidator.validateDecision(
          request: req,
          decision: decision,
          actor: adminUser,
        ),
        throwsA(isA<HrApprovalWorkflowException>()),
      );
    });
  });
}
