import 'package:flutter/material.dart';
import '../../domain/entities/hr_approval_status.dart';

/// Reusable badge widget for displaying the status of an HR approval request.
///
/// Communicates state via both color and explicit icon + text label to ensure
/// accessibility compliance.
class HrApprovalStatusBadge extends StatelessWidget {
  final HrApprovalStatus status;

  const HrApprovalStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (Color bg, Color fg, IconData icon) = _styleForStatus(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _styleForStatus(bool isDark) {
    switch (status) {
      case HrApprovalStatus.pending:
        return (
          isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100,
          isDark ? Colors.amber.shade300 : Colors.amber.shade900,
          Icons.hourglass_empty_rounded,
        );
      case HrApprovalStatus.approved:
        return (
          isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade100,
          isDark ? Colors.green.shade300 : Colors.green.shade900,
          Icons.check_circle_outline_rounded,
        );
      case HrApprovalStatus.rejected:
        return (
          isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade100,
          isDark ? Colors.red.shade300 : Colors.red.shade900,
          Icons.highlight_off_rounded,
        );
      case HrApprovalStatus.cancelled:
        return (
          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          Icons.cancel_outlined,
        );
    }
  }
}
