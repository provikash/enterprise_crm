import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_status.dart';
import '../../domain/entities/dispatch_summary.dart';

/// Top KPI summary cards displaying high-level dispatch volume and states.
///
/// Tapping any card filters the dispatch list by that status.
/// Tapping Total Dispatches or the active status card clears the filter.
class DispatchSummaryCards extends StatelessWidget {
  final DispatchSummary summary;
  final DispatchStatus? selectedStatus;
  final ValueChanged<DispatchStatus?>? onStatusSelected;

  const DispatchSummaryCards({
    super.key,
    required this.summary,
    this.selectedStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 768;

        final items = [
          _SummaryCardItem(
            key: const Key('dispatch_summary_total'),
            title: 'Total Dispatches',
            count: summary.totalDispatches,
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF2563EB),
            status: null,
            isSelected: selectedStatus == null,
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_pending'),
            title: 'Pending',
            count: summary.pendingCount,
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFFD97706),
            status: DispatchStatus.pending,
            isSelected: selectedStatus == DispatchStatus.pending ||
                selectedStatus == DispatchStatus.packed,
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_in_transit'),
            title: 'In Transit',
            count: summary.inTransitCount,
            icon: Icons.route_outlined,
            color: const Color(0xFF4F46E5),
            status: DispatchStatus.inTransit,
            isSelected: selectedStatus == DispatchStatus.inTransit,
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_out_for_delivery'),
            title: 'Out for Delivery',
            count: summary.outForDeliveryCount,
            icon: Icons.delivery_dining_outlined,
            color: const Color(0xFF8B5CF6),
            status: DispatchStatus.outForDelivery,
            isSelected: selectedStatus == DispatchStatus.outForDelivery,
          ),
          _SummaryCardItem(
            key: const Key('dispatch_summary_delivered'),
            title: 'Delivered',
            count: summary.deliveredCount,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF16A34A),
            status: DispatchStatus.delivered,
            isSelected: selectedStatus == DispatchStatus.delivered,
          ),
        ];

        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final cardWidth = (constraints.maxWidth - 40) / 2;
                return SizedBox(
                  width: cardWidth.clamp(140.0, 240.0),
                  child: _buildCard(context, item),
                );
              }).toList(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
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
    final isSelected = item.isSelected;

    return Card(
      key: item.key,
      elevation: isSelected ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? item.color
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected
          ? item.color.withValues(alpha: 0.08)
          : colorScheme.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (onStatusSelected == null) return;
          if (item.status == null) {
            onStatusSelected!(null);
          } else if (selectedStatus == item.status) {
            onStatusSelected!(null); // Toggle off back to all
          } else {
            onStatusSelected!(item.status);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 10),
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
                        color: isSelected
                            ? item.color
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.count}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? item.color : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  final DispatchStatus? status;
  final bool isSelected;

  const _SummaryCardItem({
    required this.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.status,
    required this.isSelected,
  });
}
