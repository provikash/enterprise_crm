import 'package:flutter/material.dart';
import '../../domain/entities/dispatch_status.dart';

/// Control bar for dispatch search, status filtering, and data refreshing.
class DispatchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final DispatchStatus? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<DispatchStatus?> onStatusChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onClearFilters;

  const DispatchFilterBar({
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
            key: const Key('dispatch_search_input'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: constraints.maxWidth < 450
                  ? 'Search dispatches...'
                  : 'Search dispatch #, invoice, vehicle, customer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('dispatch_search_clear_button'),
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
              child: DropdownButton<DispatchStatus?>(
                key: const Key('dispatch_status_filter_dropdown'),
                value: selectedStatus,
                isDense: true,
                isExpanded: true,
                hint: const Text('All Statuses'),
                items: [
                  const DropdownMenuItem<DispatchStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  ...DispatchStatus.values.map(
                    (status) => DropdownMenuItem<DispatchStatus?>(
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
            key: const Key('dispatch_refresh_button'),
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
          );

          final hasActiveFilters =
              selectedStatus != null || searchController.text.isNotEmpty;

          final clearFiltersButton = OutlinedButton.icon(
            key: const Key('dispatch_clear_filters_button'),
            icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
            label: Text(constraints.maxWidth < 420 ? 'Clear' : 'Clear Filters'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed:
                hasActiveFilters && onClearFilters != null ? onClearFilters : null,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 6),
                    refreshButton,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: statusDropdown),
                    if (onClearFilters != null) ...[
                      const SizedBox(width: 6),
                      clearFiltersButton,
                    ],
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 10),
              SizedBox(width: 170, child: statusDropdown),
              if (onClearFilters != null) ...[
                const SizedBox(width: 8),
                clearFiltersButton,
              ],
              const SizedBox(width: 8),
              refreshButton,
            ],
          );
        },
      ),
    );
  }
}
