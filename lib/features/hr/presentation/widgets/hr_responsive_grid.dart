import 'package:flutter/material.dart';

/// Responsive grid layout component for HR dashboards, feature cards, and metrics.
///
/// Automatically determines the number of columns based on available width:
/// - Small mobile (<500px): 1 column (or 2 if [allowMobileTwoColumn] is true and width >= 380)
/// - Tablet / medium (500-849px): 2 columns
/// - Desktop (850-1199px): 3 columns
/// - Large desktop (>=1200px): 4 columns
class HrResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;
  final bool allowMobileTwoColumn;

  const HrResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 14.0,
    this.runSpacing = 14.0,
    this.forceColumns,
    this.allowMobileTwoColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = forceColumns ?? _calculateColumns(width);

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        final double totalSpacing = spacing * (columns - 1);
        final double itemWidth = (width - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth.clamp(1.0, double.infinity),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width >= 1200) {
      return 4;
    } else if (width >= 850) {
      return 3;
    } else if (width >= 500) {
      return 2;
    } else if (allowMobileTwoColumn && width >= 380) {
      return 2;
    } else {
      return 1;
    }
  }
}
