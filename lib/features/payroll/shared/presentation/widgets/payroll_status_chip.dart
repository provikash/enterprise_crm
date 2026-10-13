import 'package:flutter/material.dart';

import '../../domain/payroll_status.dart';

class PayrollStatusChip extends StatelessWidget {
  final PayrollStatus status;

  const PayrollStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _style(status, scheme);
    return Semantics(
      label: 'Status: ${status.label}',
      child: Chip(
        avatar: Icon(style.icon, size: 16, color: style.foreground),
        label: Text(status.label),
        backgroundColor: style.background,
        labelStyle: TextStyle(
          color: style.foreground,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: style.foreground.withValues(alpha: 0.35)),
      ),
    );
  }

  _StatusStyle _style(PayrollStatus status, ColorScheme scheme) {
    return switch (status) {
      PayrollStatus.draft => _StatusStyle(
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        Icons.edit_outlined,
      ),
      PayrollStatus.calculated => _StatusStyle(
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.calculate_outlined,
      ),
      PayrollStatus.underReview || PayrollStatus.pending => _StatusStyle(
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.schedule_outlined,
      ),
      PayrollStatus.approved || PayrollStatus.verified => _StatusStyle(
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      PayrollStatus.locked => _StatusStyle(
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.lock_outline,
      ),
      PayrollStatus.paid || PayrollStatus.closed => _StatusStyle(
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.task_alt,
      ),
      PayrollStatus.rejected || PayrollStatus.failed => _StatusStyle(
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      PayrollStatus.held => _StatusStyle(
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.pause_circle_outline,
      ),
    };
  }
}

class _StatusStyle {
  final Color background;
  final Color foreground;
  final IconData icon;
  const _StatusStyle(this.background, this.foreground, this.icon);
}
