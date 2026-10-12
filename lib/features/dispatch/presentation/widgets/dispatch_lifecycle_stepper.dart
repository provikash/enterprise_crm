import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_status.dart';

/// Visual lifecycle stepper for tracking shipment delivery progression.
class DispatchLifecycleStepper extends StatelessWidget {
  final DispatchStatus currentStatus;

  const DispatchLifecycleStepper({
    super.key,
    required this.currentStatus,
  });

  static const List<DispatchStatus> _milestones = [
    DispatchStatus.pending,
    DispatchStatus.packed,
    DispatchStatus.inTransit,
    DispatchStatus.outForDelivery,
    DispatchStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentStatus == DispatchStatus.cancelled) {
      return Container(
        key: const Key('dispatch_stepper_cancelled'),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipment Cancelled',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'This dispatch order was terminated and will not be delivered.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _milestones.indexOf(currentStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        if (isNarrow) {
          // Vertical layout for narrow screens
          return Column(
            key: const Key('dispatch_lifecycle_stepper_vertical'),
            children: _milestones.asMap().entries.map((entry) {
              final idx = entry.key;
              final status = entry.value;
              final isCompleted = currentIndex >= 0 && idx < currentIndex;
              final isCurrent = idx == currentIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _buildIndicator(context, isCompleted, isCurrent, idx + 1),
                      if (idx < _milestones.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: isCompleted
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        status.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? colorScheme.primary
                              : isCompleted
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }

        // Horizontal layout for wider viewports
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            key: const Key('dispatch_lifecycle_stepper_horizontal'),
            children: _milestones.asMap().entries.map((entry) {
              final idx = entry.key;
              final status = entry.value;
              final isCompleted = currentIndex >= 0 && idx < currentIndex;
              final isCurrent = idx == currentIndex;
              final isLast = idx == _milestones.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIndicator(context, isCompleted, isCurrent, idx + 1),
                          const SizedBox(height: 6),
                          Text(
                            status.displayName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : isCompleted
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    bool isCompleted,
    bool isCurrent,
    int stepNumber,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
