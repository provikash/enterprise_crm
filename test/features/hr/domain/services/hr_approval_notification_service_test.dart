import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_approval_store.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_notification_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_notification_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification_type.dart';
import 'package:enterprise_crm/features/hr/domain/services/hr_approval_notification_service.dart';

void main() {
  group('HrApprovalNotificationService Tests (HR-9.8)', () {
    late MockHrNotificationStore notificationStore;
    late MockHrNotificationRepository notificationRepository;
    late HrApprovalNotificationService notificationService;
    late MockHrApprovalStore approvalStore;
    late MockHrApprovalRepository approvalRepository;

    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
      permissions: {},
    );

    const hrUser = CurrentUser(
      id: 'usr_hr',
      displayName: 'HR Specialist',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
      permissions: {},
    );

    setUp(() {
      notificationStore = MockHrNotificationStore(seedInitialData: false);
      notificationRepository = MockHrNotificationRepository(store: notificationStore);
      notificationService = HrApprovalNotificationService(
        notificationRepository: notificationRepository,
        adminRecipientUserId: 'usr_admin',
      );
      approvalStore = MockHrApprovalStore(seedInitialData: true);
      approvalRepository = MockHrApprovalRepository(
        store: approvalStore,
        notificationService: notificationService,
      );
    });

    test('submitRequest emits NOTIF-01 to administrator', () async {
      final req = await approvalRepository.submitRequest(
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        requesterId: hrUser.id,
        target: HrApprovalTarget.attendanceRecord('att_101'),
        remarks: 'Biometric device punch correction',
      );

      final adminNotifs = await notificationRepository.getNotificationsForUser(adminUser.id);
      expect(adminNotifs.length, equals(1));

      final notif = adminNotifs.first;
      expect(notif.type, equals(HrNotificationType.approvalRequestSubmitted));
      expect(notif.recipientUserId, equals('usr_admin'));
      expect(notif.requestId, equals(req.id));
      expect(notif.title, equals('New Approval Request'));
      expect(notif.body, contains('att_101'));
      expect(notif.body, contains(hrUser.id));

      // Privacy: no salary or sensitive PII
      expect(notif.body, isNot(contains('\$')));
      expect(notif.body, isNot(contains('salary')));
    });

    test('submitDecision with approve emits NOTIF-02 to original requester', () async {
      // appr_req_1 was requested by usr_hr
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.utc(2026, 2, 6, 10, 0),
        reason: 'Verified punch logs',
      );

      final updated = await approvalRepository.submitDecision(
        requestId: 'appr_req_1',
        decision: decision,
        actor: adminUser,
      );

      expect(updated.status, equals(HrApprovalStatus.approved));

      final hrNotifs = await notificationRepository.getNotificationsForUser(hrUser.id);
      expect(hrNotifs.length, equals(1));

      final notif = hrNotifs.first;
      expect(notif.type, equals(HrNotificationType.approvalDecisionRecorded));
      expect(notif.recipientUserId, equals(hrUser.id));
      expect(notif.title, equals('Approval Decision Recorded'));
      expect(notif.body, contains('approved by usr_admin'));
    });

    test('submitDecision with reject emits NOTIF-03 to original requester with reason', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.reject,
        decisionTime: DateTime.utc(2026, 2, 6, 11, 0),
        reason: 'Proof inadequate',
      );

      final updated = await approvalRepository.submitDecision(
        requestId: 'appr_req_1',
        decision: decision,
        actor: adminUser,
      );

      expect(updated.status, equals(HrApprovalStatus.rejected));

      final hrNotifs = await notificationRepository.getNotificationsForUser(hrUser.id);
      expect(hrNotifs.length, equals(1));

      final notif = hrNotifs.first;
      expect(notif.type, equals(HrNotificationType.approvalDecisionRecorded));
      expect(notif.recipientUserId, equals(hrUser.id));
      expect(notif.title, equals('Approval Request Rejected'));
      expect(notif.body, contains('rejected by usr_admin'));
      expect(notif.body, contains('Reason: Proof inadequate'));
    });

    test('cancelRequest emits NOTIF-04 to administrator', () async {
      final cancelled = await approvalRepository.cancelRequest(
        requestId: 'appr_req_1',
        actor: hrUser,
        reason: 'Mistake in submission',
      );

      expect(cancelled.status, equals(HrApprovalStatus.cancelled));

      final adminNotifs = await notificationRepository.getNotificationsForUser(adminUser.id);
      expect(adminNotifs.length, equals(1));

      final notif = adminNotifs.first;
      expect(notif.type, equals(HrNotificationType.approvalRequestCancelled));
      expect(notif.recipientUserId, equals(adminUser.id));
      expect(notif.title, equals('Approval Request Cancelled'));
      expect(notif.body, contains('appr_req_1'));
    });

    test('notification delivery failure does not corrupt approval decision state', () async {
      // Inject failure into notification store
      notificationStore.simulateFailure = true;

      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.utc(2026, 2, 6, 12, 0),
      );

      // Decision succeeds even when notification delivery fails
      final updated = await approvalRepository.submitDecision(
        requestId: 'appr_req_1',
        decision: decision,
        actor: adminUser,
      );

      expect(updated.status, equals(HrApprovalStatus.approved));
      final history = await approvalRepository.getHistoryForRequest('appr_req_1');
      expect(history.last.action, equals('approved'));
    });

    test('duplicate event processing is idempotent and ignores repeated dispatch', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.utc(2026, 2, 6, 13, 0),
      );

      final req = await approvalRepository.getRequestById('appr_req_1');
      final first = await notificationService.handleDecisionRecorded(req!, decision);
      expect(first, isNotNull);

      // Second identical event call returns null without generating duplicate notification
      final duplicate = await notificationService.handleDecisionRecorded(req, decision);
      expect(duplicate, isNull);

      final hrNotifs = await notificationRepository.getNotificationsForUser(hrUser.id);
      expect(hrNotifs.length, equals(1));
    });

    test('reset clears event keys for session isolation', () async {
      final decision = HrApprovalDecision(
        requestId: 'appr_req_1',
        actorId: adminUser.id,
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: DateTime.utc(2026, 2, 6, 14, 0),
      );

      final req = await approvalRepository.getRequestById('appr_req_1');
      await notificationService.handleDecisionRecorded(req!, decision);
      expect(notificationService.isEventDispatched('decision_appr_req_1_approve'), isTrue);

      notificationService.reset();
      expect(notificationService.isEventDispatched('decision_appr_req_1_approve'), isFalse);
    });

    test('content privacy invariant: excludes sensitive payroll figures', () async {
      final req = await approvalRepository.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: hrUser.id,
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        remarks: 'Salary amount: \$50,000 for period',
      );

      final adminNotifs = await notificationRepository.getNotificationsForUser(adminUser.id);
      final notif = adminNotifs.first;
      expect(notif.requestId, equals(req.id));

      // Sensitive financial figure from remarks is excluded from notification body
      expect(notif.body, isNot(contains('\$50,000')));
      expect(notif.body, isNot(contains('salary')));
      expect(notif.body, equals('A new request for payroll_period period_2026_01 was submitted by usr_hr.'));
    });
  });
}
