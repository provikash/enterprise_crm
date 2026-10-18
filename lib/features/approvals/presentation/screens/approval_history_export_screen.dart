import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/presentation/screens/access_restricted_screen.dart';
import '../../../dashboard/presentation/mappers/crm_module_presentation.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/policies/approvals_access_policy.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../domain/services/approval_export_service.dart';
import '../widgets/approval_card.dart';
import '../widgets/approval_data_table.dart';
import 'approval_detail_screen.dart';

/// Screen providing full-text multi-criteria query, timeline auditing, and RFC-4180 CSV export.
class ApprovalHistoryExportScreen extends StatefulWidget {
  final CurrentUser user;
  final ApprovalRepository repository;

  const ApprovalHistoryExportScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  State<ApprovalHistoryExportScreen> createState() =>
      _ApprovalHistoryExportScreenState();
}

class _ApprovalHistoryExportScreenState
    extends State<ApprovalHistoryExportScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ApprovalRequest> _allRequests = const [];

  // Filter states
  String _searchQuery = '';
  CrmModule? _selectedModule;
  ApprovalStatus? _selectedStatus;
  ApprovalPriority? _selectedPriority;
  DateTimeRange? _selectedDateRange;

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.getApprovals();
      if (!mounted) return;
      setState(() {
        _allRequests = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ApprovalRequest> get _filteredRequests {
    return _allRequests.where((req) {
      if (_selectedModule != null && req.module != _selectedModule) {
        return false;
      }
      if (_selectedStatus != null && req.status != _selectedStatus) {
        return false;
      }
      if (_selectedPriority != null && req.priority != _selectedPriority) {
        return false;
      }
      if (_selectedDateRange != null) {
        if (req.submittedAt.isBefore(_selectedDateRange!.start) ||
            req.submittedAt.isAfter(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNumber = req.requestNumber.toLowerCase().contains(q);
        final matchesTitle = req.entityTitle.toLowerCase().contains(q);
        final matchesRequester = req.requesterName.toLowerCase().contains(q);
        if (!matchesNumber && !matchesTitle && !matchesRequester) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedModule = null;
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedDateRange = null;
    });
  }

  void _showExportPreview(BuildContext context, List<ApprovalRequest> records) {
    final csvContent = ApprovalExportService.exportApprovalsToCsv(records);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_view_outlined, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Export Preview (${records.length} records)'),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RFC-4180 Compliant CSV snapshot generated:',
                style: Theme.of(dialogCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(dialogCtx)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(dialogCtx).colorScheme.outlineVariant,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            key: const Key('copy_csv_clipboard_button'),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              try {
                Clipboard.setData(ClipboardData(text: csvContent));
              } catch (_) {}
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Copied ${records.length} records to clipboard as CSV.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ApprovalsAccessPolicy.canExport(widget.user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final records = _filteredRequests;

    return Scaffold(
      key: const Key('approval_history_export_scaffold'),
      appBar: AppBar(
        title: const Text('Approval History & Export'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls & Filter section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search and Export Button row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('export_search_field'),
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search by request #, entity title, or requester...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          key: const Key('export_csv_button'),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(
                            isDesktop ? 'Export CSV' : 'Export',
                          ),
                          onPressed: records.isEmpty
                              ? null
                              : () => _showExportPreview(context, records),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontally scrollable dropdown filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Module filter
                          DropdownButton<CrmModule?>(
                            key: const Key('export_module_filter'),
                            value: _selectedModule,
                            isDense: true,
                            hint: const Text('All Modules'),
                            items: [
                              const DropdownMenuItem<CrmModule?>(
                                value: null,
                                child: Text('All Modules'),
                              ),
                              ...CrmModule.values.map(
                                (mod) => DropdownMenuItem<CrmModule?>(
                                  value: mod,
                                  child: Text(mod.displayName),
                                ),
                              ),
                            ],
                            onChanged: (mod) {
                              setState(() {
                                _selectedModule = mod;
                              });
                            },
                          ),
                          const SizedBox(width: 12),

                          // Status filter
                          DropdownButton<ApprovalStatus?>(
                            key: const Key('export_status_filter'),
                            value: _selectedStatus,
                            isDense: true,
                            hint: const Text('All Statuses'),
                            items: [
                              const DropdownMenuItem<ApprovalStatus?>(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              ...ApprovalStatus.values.map(
                                (st) => DropdownMenuItem<ApprovalStatus?>(
                                  value: st,
                                  child: Text(st.displayName),
                                ),
                              ),
                            ],
                            onChanged: (st) {
                              setState(() {
                                _selectedStatus = st;
                              });
                            },
                          ),
                          const SizedBox(width: 12),

                          // Priority filter
                          DropdownButton<ApprovalPriority?>(
                            key: const Key('export_priority_filter'),
                            value: _selectedPriority,
                            isDense: true,
                            hint: const Text('All Priorities'),
                            items: [
                              const DropdownMenuItem<ApprovalPriority?>(
                                value: null,
                                child: Text('All Priorities'),
                              ),
                              ...ApprovalPriority.values.map(
                                (p) => DropdownMenuItem<ApprovalPriority?>(
                                  value: p,
                                  child: Text(p.displayName),
                                ),
                              ),
                            ],
                            onChanged: (p) {
                              setState(() {
                                _selectedPriority = p;
                              });
                            },
                          ),
                          const SizedBox(width: 12),

                          // Date Range Button
                          OutlinedButton.icon(
                            key: const Key('export_date_range_button'),
                            icon: const Icon(Icons.date_range, size: 16),
                            label: Text(
                              _selectedDateRange == null
                                  ? 'Date Range'
                                  : '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} - ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}',
                            ),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDateRange: _selectedDateRange,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDateRange = picked;
                                });
                              }
                            },
                          ),

                          // Clear filters
                          if (_selectedModule != null ||
                              _selectedStatus != null ||
                              _selectedPriority != null ||
                              _selectedDateRange != null ||
                              _searchQuery.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              key: const Key('export_clear_filters_button'),
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Reset'),
                              onPressed: _clearFilters,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results count banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Showing ${records.length} of ${_allRequests.length} records',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        key: Key('export_loading_indicator'),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text('Failed to load approval records.'),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _loadRequests,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list_off,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No approval records match your criteria.',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isDesktop
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ApprovalDataTable(
                                    requests: records,
                                    onSelectRequest: (req) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ApprovalDetailScreen(
                                            user: widget.user,
                                            repository: widget.repository,
                                            requestId: req.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: records.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final req = records[idx];
                                    return ApprovalCard(
                                      request: req,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ApprovalDetailScreen(
                                              user: widget.user,
                                              repository: widget.repository,
                                              requestId: req.id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }
}
