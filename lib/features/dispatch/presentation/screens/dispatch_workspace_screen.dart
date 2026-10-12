import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/dispatch_record.dart';
import '../../domain/policies/dispatch_access_policy.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../bloc/dispatch_list_cubit.dart';
import '../bloc/dispatch_list_state.dart';
import '../widgets/dispatch_export_dialog.dart';
import '../widgets/dispatch_data_table.dart';
import '../widgets/dispatch_filter_bar.dart';
import '../widgets/dispatch_mobile_card.dart';
import '../widgets/dispatch_pagination_controls.dart';
import '../widgets/dispatch_summary_cards.dart';
import '../services/dispatch_file_saver.dart';
import 'create_dispatch_screen.dart';
import 'dispatch_details_screen.dart';

/// Main workspace screen for Dispatch logistics and shipment tracking.
///
/// Guarded by [AccessPolicy.canAccessModule(user, CrmModule.dispatch)].
class DispatchWorkspaceScreen extends StatelessWidget {
  final CurrentUser user;
  final DispatchRepository repository;
  final VoidCallback? onCreateDispatch;
  final ValueChanged<DispatchRecord>? onViewDispatch;
  final DispatchFileSaver? fileSaver;

  const DispatchWorkspaceScreen({
    super.key,
    required this.user,
    required this.repository,
    this.onCreateDispatch,
    this.onViewDispatch,
    this.fileSaver,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthorized = AccessPolicy.canAccessModule(user, CrmModule.dispatch);

    if (!isAuthorized) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<DispatchListCubit>(
      create: (_) => DispatchListCubit(repository)..loadDispatches(),
      child: _DispatchWorkspaceView(
        user: user,
        repository: repository,
        onCreateDispatch: onCreateDispatch,
        onViewDispatch: onViewDispatch,
        fileSaver: fileSaver,
      ),
    );
  }
}

class _DispatchWorkspaceView extends StatefulWidget {
  final CurrentUser user;
  final DispatchRepository repository;
  final VoidCallback? onCreateDispatch;
  final ValueChanged<DispatchRecord>? onViewDispatch;
  final DispatchFileSaver? fileSaver;

  const _DispatchWorkspaceView({
    required this.user,
    required this.repository,
    this.onCreateDispatch,
    this.onViewDispatch,
    this.fileSaver,
  });

  @override
  State<_DispatchWorkspaceView> createState() => _DispatchWorkspaceViewState();
}

class _DispatchWorkspaceViewState extends State<_DispatchWorkspaceView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _handleCreateDispatch(BuildContext context) async {
    if (widget.onCreateDispatch != null) {
      widget.onCreateDispatch!();
    } else {
      final cubit = context.read<DispatchListCubit>();
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateDispatchScreen(
            user: widget.user,
            repository: widget.repository,
          ),
        ),
      );
      if (created == true && mounted) {
        cubit.refresh();
      }
    }
  }

  void _handleViewDispatch(BuildContext context, DispatchRecord record) async {
    if (widget.onViewDispatch != null) {
      widget.onViewDispatch!(record);
    } else {
      final cubit = context.read<DispatchListCubit>();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DispatchDetailsScreen(
            dispatchId: record.id,
            user: widget.user,
            repository: widget.repository,
          ),
        ),
      );
      if (mounted) {
        cubit.refresh();
      }
    }
  }

  void _handleExportDispatches(BuildContext context) {
    final cubit = context.read<DispatchListCubit>();
    final state = cubit.state;
    showDispatchExportDialog(
      context: context,
      repository: widget.repository,
      currentQuery: state.query,
      currentFilteredRecords:
          state is DispatchListLoaded ? state.dispatches : null,
      fileSaver: widget.fileSaver,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Management'),
        actions: [
          IconButton(
            key: const Key('dispatch_export_button'),
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Dispatches',
            onPressed: () => _handleExportDispatches(context),
          ),
          const SizedBox(width: 8),
          if (DispatchAccessPolicy.canCreate(widget.user))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                key: const Key('create_dispatch_button'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Dispatch'),
                onPressed: () => _handleCreateDispatch(context),
              ),
            ),
        ],
      ),
      body: BlocBuilder<DispatchListCubit, DispatchListState>(
        builder: (context, state) {
          final cubit = context.read<DispatchListCubit>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DispatchSummaryCards(
                summary: state.summary,
                selectedStatus: state.query.status,
                onStatusSelected: (status) => cubit.updateStatusFilter(status),
              ),
              DispatchFilterBar(
                searchController: _searchController,
                selectedStatus: state.query.status,
                onSearchChanged: (val) => cubit.updateSearch(val),
                onSearchCleared: () {
                  _searchController.clear();
                  cubit.updateSearch('');
                },
                onStatusChanged: (status) => cubit.updateStatusFilter(status),
                onClearFilters: () {
                  _searchController.clear();
                  cubit.clearFilters();
                },
                onRefresh: () => cubit.refresh(),
              ),
              const Divider(height: 1),
              Expanded(
                child: switch (state) {
                  DispatchListInitial() || DispatchListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  DispatchListFailure(:final message) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              key: const Key('dispatch_retry_button'),
                              onPressed: () => cubit.refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  DispatchListLoaded(:final dispatches) =>
                    dispatches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No dispatch records found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 768;

                              if (isMobile) {
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  itemCount: dispatches.length,
                                  itemBuilder: (context, index) {
                                    final record = dispatches[index];
                                    return DispatchMobileCard(
                                      record: record,
                                      onViewRecord: (r) =>
                                          _handleViewDispatch(context, r),
                                    );
                                  },
                                );
                              }

                              return DispatchDataTable(
                                dispatches: dispatches,
                                horizontalScrollController:
                                    _horizontalScrollController,
                                verticalScrollController:
                                    _verticalScrollController,
                                onViewRecord: (r) =>
                                    _handleViewDispatch(context, r),
                              );
                            },
                          ),
                },
              ),
              if (state is DispatchListLoaded && state.totalCount > 0)
                DispatchPaginationControls(
                  currentPage: state.query.page,
                  pageSize: state.query.pageSize,
                  totalItems: state.totalCount,
                  onPrevious: () => cubit.updatePage(state.query.page - 1),
                  onNext: () => cubit.updatePage(state.query.page + 1),
                ),
            ],
          );
        },
      ),
    );
  }
}
