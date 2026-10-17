import 'package:flutter/material.dart';
import '../../domain/entities/vendor_filter_query.dart';
import '../../domain/entities/vendor_status.dart';

/// Filter bar providing search, status filtering, category filtering, and reset.
class VendorFilterBar extends StatelessWidget {
  final VendorFilterQuery query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VendorStatus?> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onClearFilters;

  static const List<String> availableCategories = [
    'All',
    'Electronics',
    'Furniture',
    'Manufacturing',
    'Hardware',
    'Logistics',
    'Chemicals',
  ];

  const VendorFilterBar({
    super.key,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        final searchField = TextField(
          key: const Key('vendor_search_field'),
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search vendor name, code, contact, GSTIN...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    key: const Key('vendor_search_clear_button'),
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        );

        final statusDropdown = DropdownButtonFormField<VendorStatus?>(
          key: ValueKey('vendor_status_${query.status}'),
          initialValue: query.status,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<VendorStatus?>(
              value: null,
              child: Text('All Statuses'),
            ),
            ...VendorStatus.values.map(
              (status) => DropdownMenuItem<VendorStatus?>(
                value: status,
                child: Text(status.displayName),
              ),
            ),
          ],
          onChanged: onStatusChanged,
        );

        final categoryDropdown = DropdownButtonFormField<String?>(
          key: ValueKey('vendor_category_${query.category}'),
          initialValue: query.category ?? 'All',
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: availableCategories.map(
            (category) => DropdownMenuItem<String?>(
              value: category,
              child: Text(category),
            ),
          ).toList(),
          onChanged: onCategoryChanged,
        );

        final clearButton = TextButton.icon(
          key: const Key('vendor_clear_filters_button'),
          icon: const Icon(Icons.filter_alt_off, size: 16),
          label: const Text('Reset'),
          onPressed: onClearFilters,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
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
                  Expanded(child: categoryDropdown),
                ],
              ),
              if (!query.isEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: clearButton,
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 12),
            SizedBox(width: 160, child: statusDropdown),
            const SizedBox(width: 12),
            SizedBox(width: 160, child: categoryDropdown),
            if (!query.isEmpty) ...[
              const SizedBox(width: 8),
              clearButton,
            ],
          ],
        );
      },
    );
  }
}
