import 'package:flutter/material.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../dashboard/presentation/mappers/crm_module_presentation.dart';
import '../../domain/entities/approval_priority.dart';

/// Filter, module selector, and search bar for the Approval Inbox.
class ApprovalFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final CrmModule? selectedModule;
  final ValueChanged<CrmModule?> onModuleChanged;
  final ApprovalPriority? selectedPriority;
  final ValueChanged<ApprovalPriority?> onPriorityChanged;
  final VoidCallback onClearFilters;

  const ApprovalFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedModule,
    required this.onModuleChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.onClearFilters,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      selectedModule != null ||
      selectedPriority != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search row + Module dropdown + Clear button
          if (isCompact) ...[
            _buildSearchField(context),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildModuleDropdown(context)),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  _buildClearButton(context),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField(context)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildModuleDropdown(context)),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 12),
                  _buildClearButton(context),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Priority chips row (horizontally scrollable on small screens)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority: ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                _buildPriorityChip(context, label: 'All', priority: null),
                const SizedBox(width: 6),
                _buildPriorityChip(
                  context,
                  label: 'Urgent',
                  priority: ApprovalPriority.urgent,
                ),
                const SizedBox(width: 6),
                _buildPriorityChip(
                  context,
                  label: 'High',
                  priority: ApprovalPriority.high,
                ),
                const SizedBox(width: 6),
                _buildPriorityChip(
                  context,
                  label: 'Normal',
                  priority: ApprovalPriority.normal,
                ),
                const SizedBox(width: 6),
                _buildPriorityChip(
                  context,
                  label: 'Low',
                  priority: ApprovalPriority.low,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextFormField(
      key: const Key('approval_search_field'),
      initialValue: searchQuery,
      decoration: InputDecoration(
        hintText: 'Search by title, number, requester...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                key: const Key('approval_clear_search_btn'),
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onSearchChanged(''),
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onSearchChanged,
    );
  }

  Widget _buildModuleDropdown(BuildContext context) {
    const modules = [
      CrmModule.purchase,
      CrmModule.hrPayroll,
      CrmModule.vendorManagement,
      CrmModule.inventory,
      CrmModule.dispatch,
    ];

    return DropdownButtonFormField<CrmModule?>(
      key: const Key('approval_module_dropdown'),
      initialValue: selectedModule,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        const DropdownMenuItem<CrmModule?>(
          value: null,
          child: Text('All Modules'),
        ),
        ...modules.map(
          (m) => DropdownMenuItem<CrmModule?>(
            value: m,
            child: Text(m.displayName),
          ),
        ),
      ],
      onChanged: onModuleChanged,
    );
  }

  Widget _buildPriorityChip(
    BuildContext context, {
    required String label,
    required ApprovalPriority? priority,
  }) {
    final isSelected = selectedPriority == priority;
    return ChoiceChip(
      key: Key('approval_priority_chip_${label.toLowerCase()}'),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPriorityChanged(priority),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return TextButton.icon(
      key: const Key('approval_clear_filters_btn'),
      onPressed: onClearFilters,
      icon: const Icon(Icons.filter_alt_off, size: 16),
      label: const Text('Clear', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
