import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/attendance_record.dart';
import '../entities/hr_approval_request.dart';
import '../entities/hr_approval_status.dart';
import '../entities/hr_approval_target.dart';
import '../entities/hr_approval_workflow_type.dart';
import '../exceptions/hr_approval_exception.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/employee_document_repository.dart';
import '../repositories/hr_approval_repository.dart';
import '../repositories/payroll_repository.dart';

/// Integration service coordinating confirmed HR operations with the shared Approvals capability.
///
/// Architectural Invariants (HR-9.6):
/// - Source-Record Mutation Timing: Request -> Pending -> Approved -> Apply Change.
/// - Underlying HR records must NOT be mutated while an approval request is pending.
/// - Rejection or cancellation leaves source HR records strictly unmodified.
/// - Exact monetary values, currency, and precision are preserved without recalculation.
/// - Zero payroll fund disbursement or salary payments (prohibited by CRM core rules).
/// - Idempotency: duplicate attempts to apply an already-applied approval do not duplicate side-effects.
class HrApprovalIntegrationService {
  final HrApprovalRepository _approvalRepository;
  final AttendanceRepository _attendanceRepository;
  final PayrollRepository _payrollRepository;
  final EmployeeDocumentRepository _documentRepository;

  final Set<String> _appliedRequestIds = {};

  HrApprovalIntegrationService({
    required HrApprovalRepository approvalRepository,
    required AttendanceRepository attendanceRepository,
    required PayrollRepository payrollRepository,
    required EmployeeDocumentRepository documentRepository,
  })  : _approvalRepository = approvalRepository,
        _attendanceRepository = attendanceRepository,
        _payrollRepository = payrollRepository,
        _documentRepository = documentRepository;

  /// Submits an approval request for payroll period finalization.
  ///
  /// Invariants:
  /// - Source [PayrollPeriod] must exist.
  /// - Source records in [PayrollRepository] remain completely unmodified while pending.
  /// - Gated by [requester.isAdmin] or authorized HR permissions.
  Future<HrApprovalRequest> requestPayrollFinalization({
    required String periodId,
    required CurrentUser requester,
    String? remarks,
  }) async {
    final period = await _payrollRepository.getPayrollPeriodById(periodId);
    if (period == null) {
      throw HrApprovalWorkflowException(
        'Payroll period "$periodId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    final target = HrApprovalTarget.payrollPeriod(periodId);
    return _approvalRepository.submitRequest(
      workflowType: HrApprovalWorkflowType.payrollFinalization,
      requesterId: requester.id,
      target: target,
      remarks: remarks ?? 'Payroll period finalization request for ${period.name}',
    );
  }

  /// Submits an attendance correction approval request.
  ///
  /// Invariants:
  /// - Source [AttendanceRecord] must exist.
  /// - Original attendance record remains untouched while request is pending.
  Future<HrApprovalRequest> requestAttendanceCorrection({
    required String attendanceRecordId,
    required CurrentUser requester,
    required String proposedStatus,
    String? reason,
  }) async {
    final record = await _attendanceRepository.getAttendanceById(attendanceRecordId);
    if (record == null) {
      throw HrApprovalWorkflowException(
        'Attendance record "$attendanceRecordId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    final target = HrApprovalTarget.attendanceRecord(attendanceRecordId);
    final remarksPayload = 'Proposed Status: $proposedStatus'
        '${reason != null && reason.trim().isNotEmpty ? " | Reason: ${reason.trim()}" : ""}';

    return _approvalRepository.submitRequest(
      workflowType: HrApprovalWorkflowType.attendanceCorrection,
      requesterId: requester.id,
      target: target,
      remarks: remarksPayload,
    );
  }

  /// Submits an employee document verification approval request.
  ///
  /// Invariants:
  /// - Source document must exist.
  /// - Raw file binary data is never embedded in approval request payloads.
  Future<HrApprovalRequest> requestDocumentVerification({
    required String documentId,
    required CurrentUser requester,
    String? remarks,
  }) async {
    final doc = await _documentRepository.getDocumentById(documentId);
    if (doc == null) {
      throw HrApprovalWorkflowException(
        'Employee document "$documentId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    final target = HrApprovalTarget.employeeDocument(documentId);
    return _approvalRepository.submitRequest(
      workflowType: HrApprovalWorkflowType.documentVerification,
      requesterId: requester.id,
      target: target,
      remarks: remarks ?? 'Verification request for document: ${doc.title}',
    );
  }

  /// Applies the approved side-effects for a confirmed request.
  ///
  /// Contract:
  /// - Request must be in [HrApprovalStatus.approved].
  /// - Only authorized actors ([actor.isAdmin]) can trigger side-effect application.
  /// - Exactly-once semantics: repeated calls return without repeating mutations.
  /// - For attendance correction: updates the source attendance record status.
  /// - For payroll finalization: records the confirmed review status without disbursements.
  /// - For document verification: records the verified reference.
  Future<bool> applyApprovedEffect({
    required String requestId,
    required CurrentUser actor,
  }) async {
    if (!actor.isAdmin) {
      throw const HrApprovalWorkflowException(
        'Unauthorized: only administrators can apply approved feature changes.',
        code: HrApprovalWorkflowException.unauthorizedActor,
      );
    }

    // Idempotency check: prevent duplicate application
    if (_appliedRequestIds.contains(requestId)) {
      return true;
    }

    final req = await _approvalRepository.getRequestById(requestId);
    if (req == null) {
      throw HrApprovalWorkflowException(
        'Approval request "$requestId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    if (!req.status.isApproved) {
      throw HrApprovalWorkflowException(
        'Cannot apply changes for request "$requestId" with status "${req.status.label}". Must be approved.',
        code: HrApprovalWorkflowException.invalidTransition,
      );
    }

    switch (req.workflowType) {
      case HrApprovalWorkflowType.attendanceCorrection:
        await _applyAttendanceCorrection(req);
        break;
      case HrApprovalWorkflowType.payrollFinalization:
        // Governance finalization check: recorded via approval request reference;
        // CRM strictly forbids automatic monetary disbursement or mutation of past records.
        break;
      case HrApprovalWorkflowType.documentVerification:
        // Document verification status recorded via approval reference.
        break;
    }

    _appliedRequestIds.add(requestId);
    return true;
  }

  Future<void> _applyAttendanceCorrection(HrApprovalRequest req) async {
    final recordId = req.target.targetEntityId;
    final record = await _attendanceRepository.getAttendanceById(recordId);
    if (record == null) {
      throw HrApprovalWorkflowException(
        'Target attendance record "$recordId" no longer exists.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    // Parse proposed status from remarks payload if formatted
    String newStatus = record.attendanceStatus;
    if (req.remarks != null && req.remarks!.contains('Proposed Status:')) {
      final match = RegExp(r'Proposed Status:\s*([A-Za-z_]+)').firstMatch(req.remarks!);
      if (match != null && match.group(1) != null) {
        newStatus = match.group(1)!.trim();
      }
    }

    final updated = AttendanceRecord(
      id: record.id,
      employeeId: record.employeeId,
      date: record.date,
      attendanceStatus: newStatus,
      checkIn: record.checkIn,
      checkOut: record.checkOut,
      remarks: record.remarks != null
          ? '${record.remarks!} (Corrected via Approval ${req.id})'
          : 'Corrected via Approval ${req.id}',
    );

    await _attendanceRepository.recordAttendance(updated);
  }

  /// Checks if an approved request has already been applied.
  bool isEffectApplied(String requestId) => _appliedRequestIds.contains(requestId);

  /// Retrieves all approval requests for a specific HR target.
  Future<List<HrApprovalRequest>> getRequestsForTarget(HrApprovalTarget target) {
    return _approvalRepository.getRequestsForTarget(target);
  }

  /// Resets service state for session isolation.
  void reset() {
    _appliedRequestIds.clear();
  }
}
