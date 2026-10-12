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

  const DispatchFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onStatusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;

          final searchField = TextField(
            key: const Key('dispatch_search_input'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search dispatch #, invoice, vehicle, customer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('dispatch_search_clear_button'),
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onSearchCleared,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          final statusDropdown = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DispatchStatus?>(
                key: const Key('dispatch_status_filter_dropdown'),
                value: selectedStatus,
                isDense: true,
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
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: onRefresh,
          );

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
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              statusDropdown,
              const SizedBox(width: 8),
              refreshButton,
            ],
          );
        },
      ),
    );
  }
}
