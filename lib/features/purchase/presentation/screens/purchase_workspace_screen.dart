import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/policies/purchase_access_policy.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../bloc/purchase_list_cubit.dart';
import '../bloc/purchase_list_state.dart';
import '../widgets/purchase_data_table.dart';
import '../widgets/purchase_filter_bar.dart';
import '../widgets/purchase_mobile_card.dart';
import '../widgets/purchase_pagination_controls.dart';
import '../widgets/purchase_summary_cards.dart';
import 'create_purchase_order_screen.dart';

/// Main workspace screen for Purchase Order procurement and supplier management.
///
/// Guarded by [PurchaseAccessPolicy.canView(user)].
class PurchaseWorkspaceScreen extends StatelessWidget {
  final CurrentUser user;
  final PurchaseRepository repository;
  final VoidCallback? onCreatePurchaseOrder;
  final ValueChanged<PurchaseOrderRecord>? onViewPurchaseOrder;

  const PurchaseWorkspaceScreen({
    super.key,
    required this.user,
    required this.repository,
    this.onCreatePurchaseOrder,
    this.onViewPurchaseOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthorized = PurchaseAccessPolicy.canView(user);

    if (!isAuthorized) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<PurchaseListCubit>(
      create: (_) => PurchaseListCubit(repository)..loadOrders(),
      child: _PurchaseWorkspaceView(
        user: user,
        repository: repository,
        onCreatePurchaseOrder: onCreatePurchaseOrder,
        onViewPurchaseOrder: onViewPurchaseOrder,
      ),
    );
  }
}

class _PurchaseWorkspaceView extends StatefulWidget {
  final CurrentUser user;
  final PurchaseRepository repository;
  final VoidCallback? onCreatePurchaseOrder;
  final ValueChanged<PurchaseOrderRecord>? onViewPurchaseOrder;

  const _PurchaseWorkspaceView({
    required this.user,
    required this.repository,
    this.onCreatePurchaseOrder,
    this.onViewPurchaseOrder,
  });

  @override
  State<_PurchaseWorkspaceView> createState() => _PurchaseWorkspaceViewState();
}

class _PurchaseWorkspaceViewState extends State<_PurchaseWorkspaceView> {
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

  void _handleCreatePurchaseOrder(BuildContext context) {
    if (widget.onCreatePurchaseOrder != null) {
      widget.onCreatePurchaseOrder!();
    } else {
      Navigator.of(context)
          .push<bool>(
        MaterialPageRoute(
          builder: (_) => CreatePurchaseOrderScreen(
            user: widget.user,
            repository: widget.repository,
          ),
        ),
      )
          .then((created) {
        if (created == true && context.mounted) {
          context.read<PurchaseListCubit>().refresh();
        }
      });
    }
  }

  void _handleViewPurchaseOrder(BuildContext context, PurchaseOrderRecord record) {
    if (widget.onViewPurchaseOrder != null) {
      widget.onViewPurchaseOrder!(record);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing ${record.poNumber} (${record.vendorName})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Purchase Management',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (PurchaseAccessPolicy.canCreate(widget.user))
            Builder(
              builder: (context) {
                final isNarrow = MediaQuery.of(context).size.width < 500;
                if (isNarrow) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton.filled(
                      key: const Key('create_purchase_order_button'),
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'New PO',
                      onPressed: () => _handleCreatePurchaseOrder(context),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FilledButton.icon(
                    key: const Key('create_purchase_order_button'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Purchase Order'),
                    onPressed: () => _handleCreatePurchaseOrder(context),
                  ),
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<PurchaseListCubit, PurchaseListState>(
        builder: (context, state) {
          final cubit = context.read<PurchaseListCubit>();

          Widget buildDataContent(bool isInsideScrollable) {
            return switch (state) {
              PurchaseListInitial() || PurchaseListLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              PurchaseListFailure(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                          key: const Key('purchase_retry_button'),
                          onPressed: () => cubit.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              PurchaseListLoaded(:final orders) => orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No purchase orders found',
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
                            shrinkWrap: isInsideScrollable,
                            physics: isInsideScrollable
                                ? const NeverScrollableScrollPhysics()
                                : null,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                            ),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final record = orders[index];
                              return PurchaseMobileCard(
                                record: record,
                                onViewRecord: (r) =>
                                    _handleViewPurchaseOrder(context, r),
                              );
                            },
                          );
                        }

                        return PurchaseDataTable(
                          orders: orders,
                          horizontalScrollController:
                              _horizontalScrollController,
                          verticalScrollController:
                              _verticalScrollController,
                          onViewRecord: (r) =>
                              _handleViewPurchaseOrder(context, r),
                        );
                      },
                    ),
            };
          }

          final summaryCards = PurchaseSummaryCards(
            summary: state.summary,
            selectedStatus: state.query.status,
            onStatusSelected: (status) => cubit.updateStatusFilter(status),
          );

          final filterBar = PurchaseFilterBar(
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
          );

          final pagination = (state is PurchaseListLoaded && state.totalCount > 0)
              ? PurchasePaginationControls(
                  currentPage: state.query.page,
                  pageSize: state.query.pageSize,
                  totalItems: state.totalCount,
                  onPrevious: () => cubit.updatePage(state.query.page - 1),
                  onNext: () => cubit.updatePage(state.query.page + 1),
                )
              : null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isHeightConstrained = constraints.maxHeight < 560;

              if (isHeightConstrained) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summaryCards,
                      filterBar,
                      const Divider(height: 1),
                      buildDataContent(true),
                      ?pagination,
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryCards,
                  filterBar,
                  const Divider(height: 1),
                  Expanded(child: buildDataContent(false)),
                  ?pagination,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
