import 'package:flutter/material.dart';
import '../../domain/entities/approval_step.dart';
import '../../domain/entities/approval_step_status.dart';

/// Visual multi-tier progress indicator for an approval request's sequential review stages.
class ApprovalStepStepper extends StatelessWidget {
  final List<ApprovalStep> steps;
  final int currentStepIndex;

  const ApprovalStepStepper({
    super.key,
    required this.steps,
    this.currentStepIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: colorScheme.outline),
            const SizedBox(width: 8),
            Text(
              'Single-stage approval workflow (no multi-tier steps).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('approval_step_stepper'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepTile(context, step: steps[i], index: i, isLast: i == steps.length - 1),
        ],
      ],
    );
  }

  Widget _buildStepTile(
    BuildContext context, {
    required ApprovalStep step,
    required int index,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = index == currentStepIndex && step.status == ApprovalStepStatus.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step circle indicator + connecting line
          Column(
            children: [
              _buildStepIndicator(context, step: step, isActive: isActive),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: _lineColor(step.status, colorScheme),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Step details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step ${step.stepOrder}: ${step.title}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                      _buildStepStatusChip(step.status),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Assignment
                  if (step.assignedUserName != null || step.assignedRole != null)
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 13, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (step.assignedUserName != null) step.assignedUserName,
                              if (step.assignedRole != null) '(${step.assignedRole})',
                            ].join(' '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Decided info & comments
                  if (step.decidedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Decided on: ${_formatDateTime(step.decidedAt!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],

                  if (step.comments != null && step.comments!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '"${step.comments!}"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context, {
    required ApprovalStep step,
    required bool isActive,
  }) {
    IconData icon;
    Color bg;
    Color fg;

    switch (step.status) {
      case ApprovalStepStatus.approved:
        icon = Icons.check;
        bg = Colors.green;
        fg = Colors.white;
      case ApprovalStepStatus.rejected:
        icon = Icons.close;
        bg = Colors.red;
        fg = Colors.white;
      case ApprovalStepStatus.skipped:
        icon = Icons.redo;
        bg = Colors.grey.shade400;
        fg = Colors.white;
      case ApprovalStepStatus.pending:
        icon = isActive ? Icons.hourglass_top : Icons.circle;
        bg = isActive ? Colors.amber.shade700 : Colors.grey.shade300;
        fg = Colors.white;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }

  Color _lineColor(ApprovalStepStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ApprovalStepStatus.approved:
        return Colors.green.shade400;
      case ApprovalStepStatus.rejected:
        return Colors.red.shade400;
      default:
        return colorScheme.outlineVariant;
    }
  }

  Widget _buildStepStatusChip(ApprovalStepStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case ApprovalStepStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case ApprovalStepStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case ApprovalStepStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case ApprovalStepStatus.skipped:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
