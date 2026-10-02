import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_approval_exception.dart';
import 'package:enterprise_crm/features/hr/domain/services/hr_approval_integration_service.dart';

void main() {
  group('HrApprovalIntegrationService Tests (HR-9.6)', () {
    late MockHrApprovalRepository approvalRepository;
    late MockAttendanceRepository attendanceRepository;
    late MockPayrollRepository payrollRepository;
    late MockEmployeeDocumentRepository documentRepository;
    late HrApprovalIntegrationService integrationService;

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
      permissions: {},
    );

    setUp(() {
      approvalRepository = MockHrApprovalRepository();
      attendanceRepository = MockAttendanceRepository();
      payrollRepository = MockPayrollRepository();
      documentRepository = MockEmployeeDocumentRepository();

      integrationService = HrApprovalIntegrationService(
        approvalRepository: approvalRepository,
        attendanceRepository: attendanceRepository,
        payrollRepository: payrollRepository,
        documentRepository: documentRepository,
      );
    });

    group('Payroll Period Finalization Integration', () {
      test('submitting request creates pending approval without mutating payroll records', () async {
        final initialRecords = await payrollRepository.getPayrollRecordsForPeriod('period_2026_01');
        final initialPeriod = await payrollRepository.getPayrollPeriodById('period_2026_01');

        final req = await integrationService.requestPayrollFinalization(
          periodId: 'period_2026_01',
          requester: hrUser,
          remarks: 'Lock payroll period January 2026',
        );

        expect(req.workflowType, equals(HrApprovalWorkflowType.payrollFinalization));
        expect(req.status, equals(HrApprovalStatus.pending));
        expect(req.target, equals(HrApprovalTarget.payrollPeriod('period_2026_01')));

        // Invariant: underlying payroll period and records remain strictly untouched while pending
        final currentPeriod = await payrollRepository.getPayrollPeriodById('period_2026_01');
        final currentRecords = await payrollRepository.getPayrollRecordsForPeriod('period_2026_01');
        expect(currentPeriod, equals(initialPeriod));
        expect(currentRecords, equals(initialRecords));
      });

      test('throws requestNotFound if payroll period does not exist', () async {
        expect(
          () => integrationService.requestPayrollFinalization(
            periodId: 'period_non_existent',
            requester: hrUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.requestNotFound),
            ),
          ),
        );
      });

      test('approved payroll finalization governance check applies without fund disbursement', () async {
        final req = await integrationService.requestPayrollFinalization(
          periodId: 'period_2026_01',
          requester: hrUser,
        );

        // Administrator approves
        await approvalRepository.submitDecision(
          requestId: req.id,
          decision: HrApprovalDecision(
            requestId: req.id,
            actorId: adminUser.id,
            decisionType: HrApprovalDecisionType.approve,
            decisionTime: DateTime.utc(2026, 2, 6, 10, 0),
          ),
          actor: adminUser,
        );

        final applied = await integrationService.applyApprovedEffect(
          requestId: req.id,
          actor: adminUser,
        );

        expect(applied, isTrue);
        expect(integrationService.isEffectApplied(req.id), isTrue);

        // Calling again is idempotent
        final reapplied = await integrationService.applyApprovedEffect(
          requestId: req.id,
          actor: adminUser,
        );
        expect(reapplied, isTrue);
      });
    });

    group('Attendance Correction Integration', () {
      test('submitting correction request leaves original attendance record untouched', () async {
        final initialRecord = await attendanceRepository.getAttendanceById('att_101');
        expect(initialRecord, isNotNull);

        final req = await integrationService.requestAttendanceCorrection(
          attendanceRecordId: 'att_101',
          requester: hrUser,
          proposedStatus: 'present',
          reason: 'Biometric device offline during morning check-in',
        );

        expect(req.workflowType, equals(HrApprovalWorkflowType.attendanceCorrection));
        expect(req.status, equals(HrApprovalStatus.pending));

        // Original record status remains unchanged while pending
        final currentRecord = await attendanceRepository.getAttendanceById('att_101');
        expect(currentRecord!.attendanceStatus, equals(initialRecord!.attendanceStatus));
      });

      test('approved attendance correction updates source record status upon application', () async {
        final req = await integrationService.requestAttendanceCorrection(
          attendanceRecordId: 'att_101',
          requester: hrUser,
          proposedStatus: 'present',
          reason: 'Corrected punch',
        );

        // Approve request
        await approvalRepository.submitDecision(
          requestId: req.id,
          decision: HrApprovalDecision(
            requestId: req.id,
            actorId: adminUser.id,
            decisionType: HrApprovalDecisionType.approve,
            decisionTime: DateTime.utc(2026, 2, 6, 11, 0),
          ),
          actor: adminUser,
        );

        await integrationService.applyApprovedEffect(
          requestId: req.id,
          actor: adminUser,
        );

        final updatedRecord = await attendanceRepository.getAttendanceById('att_101');
        expect(updatedRecord!.attendanceStatus, equals('present'));
        expect(updatedRecord.remarks, contains('Corrected via Approval ${req.id}'));
      });

      test('rejected attendance correction leaves source record strictly untouched', () async {
        final initialRecord = await attendanceRepository.getAttendanceById('att_101');

        final req = await integrationService.requestAttendanceCorrection(
          attendanceRecordId: 'att_101',
          requester: hrUser,
          proposedStatus: 'present',
        );

        // Reject request
        await approvalRepository.submitDecision(
          requestId: req.id,
          decision: HrApprovalDecision(
            requestId: req.id,
            actorId: adminUser.id,
            decisionType: HrApprovalDecisionType.reject,
            decisionTime: DateTime.utc(2026, 2, 6, 12, 0),
            reason: 'Insufficient proof',
          ),
          actor: adminUser,
        );

        // Attempting to apply non-approved effect throws invalidTransition
        expect(
          () => integrationService.applyApprovedEffect(
            requestId: req.id,
            actor: adminUser,
          ),
          throwsA(isA<HrApprovalWorkflowException>()),
        );

        final finalRecord = await attendanceRepository.getAttendanceById('att_101');
        expect(finalRecord!.attendanceStatus, equals(initialRecord!.attendanceStatus));
      });
    });

    group('Employee Document Verification Integration', () {
      test('submitting verification request creates pending request', () async {
        final req = await integrationService.requestDocumentVerification(
          documentId: 'doc_1',
          requester: hrUser,
        );

        expect(req.workflowType, equals(HrApprovalWorkflowType.documentVerification));
        expect(req.status, equals(HrApprovalStatus.pending));
      });

      test('throws requestNotFound if document does not exist', () async {
        expect(
          () => integrationService.requestDocumentVerification(
            documentId: 'doc_non_existent',
            requester: hrUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.requestNotFound),
            ),
          ),
        );
      });
    });

    group('Authorization and Security Invariants', () {
      test('non-admin user cannot apply approved effect, throws unauthorizedActor', () async {
        expect(
          () => integrationService.applyApprovedEffect(
            requestId: 'appr_req_3', // approved seed
            actor: hrUser, // standard user
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.unauthorizedActor),
            ),
          ),
        );
      });

      test('reset clears applied requests set for clean session isolation', () async {
        await integrationService.applyApprovedEffect(
          requestId: 'appr_req_3',
          actor: adminUser,
        );
        expect(integrationService.isEffectApplied('appr_req_3'), isTrue);

        integrationService.reset();
        expect(integrationService.isEffectApplied('appr_req_3'), isFalse);
      });
    });
  });
}
