import 'package:flutter/material.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_summary.dart';

/// Top KPI summary cards displaying high-level purchase volume and states.
///
/// Tapping any card filters the purchase orders list by that status.
/// Tapping Total Orders or the active status card clears the filter.
class PurchaseSummaryCards extends StatelessWidget {
  final PurchaseSummary summary;
  final PurchaseOrderStatus? selectedStatus;
  final ValueChanged<PurchaseOrderStatus?>? onStatusSelected;

  const PurchaseSummaryCards({
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
            key: const Key('purchase_summary_total'),
            title: 'Total POs',
            value: '${summary.totalOrders}',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF2563EB),
            status: null,
            isSelected: selectedStatus == null,
          ),
          _SummaryCardItem(
            key: const Key('purchase_summary_pending_approval'),
            title: 'Pending',
            value: '${summary.pendingApprovalCount}',
            icon: Icons.hourglass_top_outlined,
            color: const Color(0xFFD97706),
            status: PurchaseOrderStatus.pendingApproval,
            isSelected: selectedStatus == PurchaseOrderStatus.pendingApproval,
          ),
          _SummaryCardItem(
            key: const Key('purchase_summary_approved'),
            title: 'Approved',
            value: '${summary.approvedCount}',
            icon: Icons.verified_outlined,
            color: const Color(0xFF0284C7),
            status: PurchaseOrderStatus.approved,
            isSelected: selectedStatus == PurchaseOrderStatus.approved,
          ),
          _SummaryCardItem(
            key: const Key('purchase_summary_ordered'),
            title: 'Ordered',
            value: '${summary.orderedCount}',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF7C3AED),
            status: PurchaseOrderStatus.ordered,
            isSelected: selectedStatus == PurchaseOrderStatus.ordered,
          ),
          _SummaryCardItem(
            key: const Key('purchase_summary_received'),
            title: 'Received',
            value: '${summary.receivedCount}',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF16A34A),
            status: PurchaseOrderStatus.received,
            isSelected: selectedStatus == PurchaseOrderStatus.received,
          ),
          _SummaryCardItem(
            key: const Key('purchase_summary_spend'),
            title: 'Total Spend',
            value: _formatCurrency(summary.totalSpendAmount),
            icon: Icons.payments_outlined,
            color: const Color(0xFF059669),
            status: null,
            isSelected: false,
          ),
        ];

        if (isNarrow) {
          return SizedBox(
            height: 66,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 145,
                  child: _buildCard(context, items[index]),
                );
              },
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: item.key,
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (item.status == null) {
            onStatusSelected?.call(null);
          } else if (selectedStatus == item.status) {
            onStatusSelected?.call(null);
          } else {
            onStatusSelected?.call(item.status);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? item.color
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 16,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? item.color : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  static String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

class _SummaryCardItem {
  final Key key;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final PurchaseOrderStatus? status;
  final bool isSelected;

  const _SummaryCardItem({
    required this.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.status,
    required this.isSelected,
  });
}
