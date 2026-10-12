import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_summary.dart';

/// Top KPI summary cards displaying high-level dispatch volume and states.
class DispatchSummaryCards extends StatelessWidget {
  final DispatchSummary summary;

  const DispatchSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final items = [
          _SummaryCardItem(
            key: const Key('dispatch_summary_total'),
            title: 'Total Dispatches',
            count: summary.totalDispatches,
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF2563EB),
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_pending'),
            title: 'Pending / Packed',
            count: summary.pendingCount,
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFFD97706),
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_in_transit'),
            title: 'In Transit',
            count: summary.inTransitCount,
            icon: Icons.route_outlined,
            color: const Color(0xFF4F46E5),
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_delivered'),
            title: 'Delivered',
            count: summary.deliveredCount,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF16A34A),
          ),
        ];

        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: items.map((item) => _buildCard(context, item)).toList(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildCard(context, item),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, _SummaryCardItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: item.key,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.count}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardItem {
  final Key key;
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCardItem({
    required this.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
}
