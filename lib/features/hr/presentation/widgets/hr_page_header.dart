import 'package:flutter/material.dart';

/// Standardized responsive page header for HR & Payroll modules and overview pages.
class HrPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? tag;
  final Widget? primaryAction;
  final List<Widget>? secondaryActions;

  const HrPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.primaryAction,
    this.secondaryActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 10),
                  tag!,
                ],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...?secondaryActions,
            if (secondaryActions != null && primaryAction != null)
              const SizedBox(width: 8),
            ?primaryAction,
          ],
        );

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                actions,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (primaryAction != null ||
                  (secondaryActions != null && secondaryActions!.isNotEmpty)) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            ],
          ),
        );
      },
    );
  }
}
