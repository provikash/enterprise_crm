import 'package:flutter/material.dart';
import '../../domain/entities/vendor_status.dart';
import '../../domain/entities/vendor_summary.dart';

/// Top KPI summary cards displaying vendor counts by status.
class VendorSummaryCards extends StatelessWidget {
  final VendorSummary summary;
  final VendorStatus? selectedStatus;
  final ValueChanged<VendorStatus?>? onStatusSelected;

  const VendorSummaryCards({
    super.key,
    required this.summary,
    this.selectedStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final items = [
          _SummaryCardItem(
            key: const Key('vendor_summary_total'),
            title: 'Total Vendors',
            value: '${summary.totalVendors}',
            icon: Icons.storefront_outlined,
            color: const Color(0xFF2563EB),
            status: null,
            isSelected: selectedStatus == null,
          ),
          _SummaryCardItem(
            key: const Key('vendor_summary_active'),
            title: 'Active',
            value: '${summary.activeVendors}',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF059669),
            status: VendorStatus.active,
            isSelected: selectedStatus == VendorStatus.active,
          ),
          _SummaryCardItem(
            key: const Key('vendor_summary_under_review'),
            title: 'Under Review',
            value: '${summary.underReviewVendors}',
            icon: Icons.hourglass_top_outlined,
            color: const Color(0xFFD97706),
            status: VendorStatus.underReview,
            isSelected: selectedStatus == VendorStatus.underReview,
          ),
          _SummaryCardItem(
            key: const Key('vendor_summary_blacklisted'),
            title: 'Blacklisted',
            value: '${summary.blacklistedVendors}',
            icon: Icons.block_outlined,
            color: const Color(0xFFDC2626),
            status: VendorStatus.blacklisted,
            isSelected: selectedStatus == VendorStatus.blacklisted,
          ),
          _SummaryCardItem(
            key: const Key('vendor_summary_inactive'),
            title: 'Inactive',
            value: '${summary.inactiveVendors}',
            icon: Icons.pause_circle_outline,
            color: const Color(0xFF64748B),
            status: VendorStatus.inactive,
            isSelected: selectedStatus == VendorStatus.inactive,
          ),
        ];

        if (isNarrow) {
          return SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 140,
                  child: _buildCard(items[index], context),
                );
              },
            ),
          );
        }

        return Row(
          children: items.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildCard(item, context),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard(_SummaryCardItem item, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      key: item.key,
      onTap: () {
        if (item.isSelected && item.status != null) {
          onStatusSelected?.call(null);
        } else {
          onStatusSelected?.call(item.status);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.isSelected
              ? item.color.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.isSelected
                ? item.color
                : colorScheme.outlineVariant,
            width: item.isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 16, color: item.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.isSelected ? item.color : colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: item.isSelected ? item.color : colorScheme.onSurface,
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
  final String value;
  final IconData icon;
  final Color color;
  final VendorStatus? status;
  final bool isSelected;

  const _SummaryCardItem({
    required this.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.status,
    required this.isSelected,
  });
}
