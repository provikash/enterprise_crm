import '../entities/approval_activity.dart';
import '../entities/approval_request.dart';

/// RFC-4180 compliant CSV export generator for approval history and audit logs.
class ApprovalExportService {
  const ApprovalExportService();

  /// Escapes a CSV cell value according to RFC-4180 rules.
  ///
  /// Cells containing commas, double quotes, or line breaks are enclosed in quotes,
  /// and inner quotes are doubled.
  static String escapeCsvCell(String? value) {
    if (value == null) return '';
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Exports a collection of approval requests into an RFC-4180 CSV string.
  static String exportApprovalsToCsv(List<ApprovalRequest> requests) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Request ID,Request Number,Module,Entity Type,Entity ID,Entity Title,Requester ID,Requester Name,Department,Status,Priority,Amount,Currency,Current Step,Submitted At,Decided At,Decided By,Decision Notes',
    );

    for (final req in requests) {
      final currentStepName = req.currentStep?.title ?? '';
      final row = [
        escapeCsvCell(req.id),
        escapeCsvCell(req.requestNumber),
        escapeCsvCell(req.module.name),
        escapeCsvCell(req.entityType),
        escapeCsvCell(req.entityId),
        escapeCsvCell(req.entityTitle),
        escapeCsvCell(req.requesterId),
        escapeCsvCell(req.requesterName),
        escapeCsvCell(req.departmentName ?? req.departmentId ?? ''),
        escapeCsvCell(req.status.name),
        escapeCsvCell(req.priority.name),
        escapeCsvCell(req.amount != null ? req.amount!.toStringAsFixed(2) : ''),
        escapeCsvCell(req.currencyCode ?? ''),
        escapeCsvCell(currentStepName),
        escapeCsvCell(req.submittedAt.toIso8601String()),
        escapeCsvCell(req.decidedAt?.toIso8601String() ?? ''),
        escapeCsvCell(req.decidedByUserName ?? req.decidedByUserId ?? ''),
        escapeCsvCell(req.decisionNotes ?? ''),
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  /// Exports an approval request's chronological audit trail to CSV format.
  static String exportAuditTrailToCsv(
    ApprovalRequest request,
    List<ApprovalActivity> auditTrail,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Activity ID,Request Number,Action,Actor User ID,Actor User Name,Comment,Timestamp',
    );

    for (final act in auditTrail) {
      final row = [
        escapeCsvCell(act.id),
        escapeCsvCell(request.requestNumber),
        escapeCsvCell(act.action.name),
        escapeCsvCell(act.actorUserId),
        escapeCsvCell(act.actorUserName),
        escapeCsvCell(act.comment ?? ''),
        escapeCsvCell(act.timestamp.toIso8601String()),
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }
}
