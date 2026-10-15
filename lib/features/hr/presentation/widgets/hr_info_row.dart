import 'package:flutter/material.dart';

/// Reusable key-value row for displaying record properties consistently.
///
/// Responsive: adapts between stacked and horizontal alignment depending on width.
class HrInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  final IconData? icon;
  final bool isEmphasized;
  final double labelWidth;

  const HrInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
    this.icon,
    this.isEmphasized = false,
    this.labelWidth = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 440;

          final displayedValue = valueWidget ??
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isEmphasized ? FontWeight.bold : FontWeight.w600,
                  color: isEmphasized
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                displayedValue,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: displayedValue),
            ],
          );
        },
      ),
    );
  }
}
