import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_source.dart';
import '../../domain/entities/lead_status.dart';

/// Formats a lead name, falling back to 'Unnamed Lead' if null or empty.
String formatLeadName(String? name) =>
    (name != null && name.trim().isNotEmpty) ? name.trim() : 'Unnamed Lead';

/// Formats a phone number, falling back to '—' if null or empty.
String formatLeadPhone(String? phone) =>
    (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '—';

/// Formats an email address, falling back to '—' if null or empty.
String formatLeadEmail(String? email) =>
    (email != null && email.trim().isNotEmpty) ? email.trim() : '—';

/// Formats a lead status value, falling back to '—' if null or empty.
String formatLeadStatus(LeadStatus? status) =>
    (status != null && status.value.trim().isNotEmpty)
    ? status.value.trim()
    : '—';

/// Formats the lead assignee display string:
/// 1. assigned user display name if available
/// 2. 'Assigned' if assigned without a display name
/// 3. 'Unassigned' if not assigned
String formatLeadAssignee(Lead lead) {
  if (lead.assignedUserName != null &&
      lead.assignedUserName!.trim().isNotEmpty) {
    return lead.assignedUserName!.trim();
  }
  return lead.isAssigned ? 'Assigned' : 'Unassigned';
}

/// Formats a lead source into a clean, human-readable label.
String formatLeadSource(LeadSource source) {
  switch (source) {
    case LeadSource.manual:
      return 'Manual';
    case LeadSource.excel:
      return 'Excel';
    case LeadSource.csv:
      return 'CSV';
    case LeadSource.portal:
      return 'Web Portal';
    case LeadSource.metaCampaign:
      return 'Meta Campaign';
  }
}

/// Formats a DateTime into a consistent YYYY-MM-DD string, or '—' if null.
String formatLeadDate(DateTime? dt) {
  if (dt == null) return '—';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Formats a DateTime into a consistent YYYY-MM-DD, hh:mm AM/PM string, or '—' if null.
String formatLeadDateTime(DateTime? dt) {
  if (dt == null) return '—';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hour24 = dt.hour;
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  final h = hour12.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = hour24 >= 12 ? 'PM' : 'AM';
  return '$y-$m-$d, $h:$min $ampm';
}
