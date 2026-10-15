import 'package:flutter/material.dart';

class PayrollPaginationControls extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PayrollPaginationControls({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final pages = totalItems == 0 ? 0 : (totalItems + pageSize - 1) ~/ pageSize;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(totalItems == 0 ? 'No results' : 'Page $page of $pages'),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < pages ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
