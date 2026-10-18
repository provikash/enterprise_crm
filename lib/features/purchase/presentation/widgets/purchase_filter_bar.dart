import 'package:flutter/material.dart';
import '../../domain/entities/purchase_order_status.dart';

/// Control bar for purchase order search, status filtering, and data refreshing.
class PurchaseFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final PurchaseOrderStatus? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<PurchaseOrderStatus?> onStatusChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onClearFilters;

  const PurchaseFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onStatusChanged,
    required this.onRefresh,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          final searchField = TextField(
            key: const Key('purchase_search_input'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: constraints.maxWidth < 450
                  ? 'Search POs...'
                  : 'Search PO #, vendor, SKU, or contact...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('purchase_search_clear_button'),
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onSearchCleared,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          final statusDropdown = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PurchaseOrderStatus?>(
                key: const Key('purchase_status_filter_dropdown'),
                value: selectedStatus,
                isDense: true,
                isExpanded: true,
                hint: const Text('All Statuses'),
                items: [
                  const DropdownMenuItem<PurchaseOrderStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...PurchaseOrderStatus.values.map(
                    (status) => DropdownMenuItem<PurchaseOrderStatus?>(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          );

          final refreshButton = IconButton.outlined(
            key: const Key('purchase_refresh_button'),
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
          );

          final hasActiveFilters =
              searchController.text.isNotEmpty || selectedStatus != null;

          final clearButton = hasActiveFilters && onClearFilters != null
              ? TextButton.icon(
                  key: const Key('purchase_clear_filters_button'),
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colorScheme.error,
                  ),
                )
              : const SizedBox.shrink();

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: statusDropdown),
                    const SizedBox(width: 8),
                    refreshButton,
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 4),
                      clearButton,
                    ],
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 12),
              SizedBox(width: 200, child: statusDropdown),
              const SizedBox(width: 8),
              refreshButton,
              if (hasActiveFilters) ...[
                const SizedBox(width: 4),
                clearButton,
              ],
            ],
          );
        },
      ),
    );
  }
}
