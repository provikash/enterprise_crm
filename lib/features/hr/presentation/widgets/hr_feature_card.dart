import 'package:flutter/material.dart';

/// Interactive feature card used in the HR & Payroll grid navigation.
///
/// Follows the CRM design system:
/// - Reuses [ColorScheme.surfaceContainerLowest], [ColorScheme.primaryContainer],
///   and [ColorScheme.outlineVariant].
/// - Subtle hover transition on Web / Desktop.
/// - Clear typography hierarchy and navigation affordance.
class HrFeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final String? metric;
  final Color? accentColor;
  final bool isActive;

  const HrFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
    this.metric,
    this.accentColor,
    this.isActive = false,
  });

  @override
  State<HrFeatureCard> createState() => _HrFeatureCardState();
}

class _HrFeatureCardState extends State<HrFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBorderColor = widget.isActive
        ? colorScheme.primary
        : _isHovered
            ? colorScheme.primary.withValues(alpha: 0.6)
            : colorScheme.outlineVariant;

    final effectiveCardColor = widget.isActive
        ? colorScheme.primaryContainer.withValues(alpha: 0.15)
        : _isHovered
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest;

    return Card(
      elevation: _isHovered ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: effectiveBorderColor,
          width: widget.isActive ? 1.5 : 1.0,
        ),
      ),
      color: effectiveCardColor,
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor?.withValues(alpha: 0.15) ??
                            colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: widget.accentColor ?? colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (widget.badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: _isHovered
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.metric != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.metric!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
