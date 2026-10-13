import 'package:flutter/material.dart';

/// Clean pagination controls widget for the Dispatch workspace.
class DispatchPaginationControls extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const DispatchPaginationControls({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalPages = (totalItems + pageSize - 1) ~/ pageSize;
    final start = ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize) > totalItems
        ? totalItems
        : (currentPage * pageSize);
    final canGoPrevious = currentPage > 1 && onPrevious != null;
    final canGoNext = currentPage < totalPages && onNext != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          final rangeText = Text(
            '$start–$end of $totalItems dispatches',
            key: const Key('dispatch_pagination_range_text'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          );

          final pageText = Text(
            'Page $currentPage of $totalPages',
            key: const Key('dispatch_pagination_page_text'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          );

          final prevButton = OutlinedButton.icon(
            key: const Key('dispatch_pagination_prev_button'),
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: canGoPrevious ? onPrevious : null,
          );

          final nextButton = OutlinedButton.icon(
            key: const Key('dispatch_pagination_next_button'),
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: canGoNext ? onNext : null,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [rangeText, pageText],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: prevButton),
                    const SizedBox(width: 8),
                    Expanded(child: nextButton),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              rangeText,
              const Spacer(),
              pageText,
              const SizedBox(width: 16),
              prevButton,
              const SizedBox(width: 8),
              nextButton,
            ],
          );
        },
      ),
    );
  }
}
