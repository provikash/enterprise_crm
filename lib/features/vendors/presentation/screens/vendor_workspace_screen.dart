import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../../purchase/domain/repositories/purchase_repository.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/policies/vendor_access_policy.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../bloc/vendor_list_cubit.dart';
import '../bloc/vendor_list_state.dart';
import '../services/vendor_file_saver.dart';
import '../widgets/vendor_data_table.dart';
import '../widgets/vendor_export_dialog.dart';
import '../widgets/vendor_filter_bar.dart';
import '../widgets/vendor_mobile_card.dart';
import '../widgets/vendor_summary_cards.dart';
import 'create_edit_vendor_screen.dart';
import 'vendor_details_screen.dart';

/// Main workspace screen for Vendor Management.
///
/// Guarded by [VendorAccessPolicy.canView(user)].
class VendorWorkspaceScreen extends StatelessWidget {
  final CurrentUser user;
  final VendorRepository repository;
  final PurchaseRepository? purchaseRepository;
  final VendorFileSaver? fileSaver;

  const VendorWorkspaceScreen({
    super.key,
    required this.user,
    required this.repository,
    this.purchaseRepository,
    this.fileSaver,
  });

  @override
  Widget build(BuildContext context) {
    if (!VendorAccessPolicy.canView(user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<VendorListCubit>(
      create: (_) => VendorListCubit(repository)..loadVendors(),
      child: _VendorWorkspaceView(
        user: user,
        repository: repository,
        purchaseRepository: purchaseRepository,
        fileSaver: fileSaver,
      ),
    );
  }
}

class _VendorWorkspaceView extends StatefulWidget {
  final CurrentUser user;
  final VendorRepository repository;
  final PurchaseRepository? purchaseRepository;
  final VendorFileSaver? fileSaver;

  const _VendorWorkspaceView({
    required this.user,
    required this.repository,
    this.purchaseRepository,
    this.fileSaver,
  });

  @override
  State<_VendorWorkspaceView> createState() => _VendorWorkspaceViewState();
}

class _VendorWorkspaceViewState extends State<_VendorWorkspaceView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _openAddVendor(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEditVendorScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (created == true && context.mounted) {
      context.read<VendorListCubit>().refresh();
    }
  }

  void _openVendorDetails(BuildContext context, VendorRecord vendor) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorDetailsScreen(
          initialVendor: vendor,
          repository: widget.repository,
          purchaseRepository: widget.purchaseRepository,
          fileSaver: widget.fileSaver,
        ),
      ),
    );

    if (didChange == true && context.mounted) {
      context.read<VendorListCubit>().refresh();
    }
  }

  void _openEditVendor(BuildContext context, VendorRecord vendor) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEditVendorScreen(
          repository: widget.repository,
          vendor: vendor,
        ),
      ),
    );

    if (didUpdate == true && context.mounted) {
      context.read<VendorListCubit>().refresh();
    }
  }

  void _handleDelete(BuildContext context, VendorRecord vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor?'),
        content: Text('Are you sure you want to remove ${vendor.companyName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<VendorListCubit>().deleteVendor(vendor.id);
    }
  }

  void _handleExport(BuildContext context, List<VendorRecord> vendors) async {
    final result = await showVendorExportDialog(
      context: context,
      vendors: vendors,
      fileSaver: widget.fileSaver ?? const DefaultVendorFileSaver(),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor directory exported successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = VendorAccessPolicy.canCreate(widget.user);
    final canEdit = VendorAccessPolicy.canEdit(widget.user);
    final canDelete = VendorAccessPolicy.canDelete(widget.user);
    final canExport = VendorAccessPolicy.canExport(widget.user);

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        actions: [
          if (canExport)
            BlocBuilder<VendorListCubit, VendorListState>(
              builder: (context, state) {
                final vendors = state is VendorListLoaded ? state.vendors : <VendorRecord>[];
                if (isCompact) {
                  return IconButton(
                    key: const Key('vendor_export_button'),
                    icon: const Icon(Icons.download, size: 20),
                    tooltip: 'Export',
                    onPressed: vendors.isEmpty ? null : () => _handleExport(context, vendors),
                  );
                }
                return TextButton.icon(
                  key: const Key('vendor_export_button'),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                  onPressed: vendors.isEmpty ? null : () => _handleExport(context, vendors),
                );
              },
            ),
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isCompact
                  ? IconButton(
                      key: const Key('vendor_add_button'),
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Add Vendor',
                      onPressed: () => _openAddVendor(context),
                    )
                  : ElevatedButton.icon(
                      key: const Key('vendor_add_button'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Vendor'),
                      onPressed: () => _openAddVendor(context),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<VendorListCubit, VendorListState>(
          builder: (context, state) {
            if (state is VendorListLoading && state is! VendorListLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is VendorListError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(state.message, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<VendorListCubit>().refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is VendorListLoaded) {
              final width = MediaQuery.of(context).size.width;
              final isDesktop = width >= 800;

              return RefreshIndicator(
                onRefresh: () => context.read<VendorListCubit>().refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 400 ? 12.0 : 20.0,
                    vertical: 16.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // KPI Summary Cards
                          VendorSummaryCards(
                            summary: state.summary,
                            selectedStatus: state.query.status,
                            onStatusSelected: (status) =>
                                context.read<VendorListCubit>().filterByStatus(status),
                          ),
                          const SizedBox(height: 16),

                          // Search & Filter Bar
                          VendorFilterBar(
                            query: state.query,
                            searchController: _searchController,
                            onSearchChanged: (text) =>
                                context.read<VendorListCubit>().search(text),
                            onStatusChanged: (status) =>
                                context.read<VendorListCubit>().filterByStatus(status),
                            onCategoryChanged: (category) =>
                                context.read<VendorListCubit>().filterByCategory(category),
                            onClearFilters: () {
                              _searchController.clear();
                              context.read<VendorListCubit>().clearFilters();
                            },
                          ),
                          const SizedBox(height: 16),

                          // Data View
                          if (isDesktop)
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: VendorDataTable(
                                vendors: state.vendors,
                                horizontalController: _horizontalScrollController,
                                onView: (v) => _openVendorDetails(context, v),
                                onEdit: canEdit ? (v) => _openEditVendor(context, v) : null,
                                onDelete: canDelete ? (v) => _handleDelete(context, v) : null,
                              ),
                            )
                          else
                            state.vendors.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    alignment: Alignment.center,
                                    child: const Text('No vendors found matching criteria.'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.vendors.length,
                                    itemBuilder: (context, index) {
                                      final v = state.vendors[index];
                                      return VendorMobileCard(
                                        vendor: v,
                                        onTap: () => _openVendorDetails(context, v),
                                        onEdit: canEdit ? () => _openEditVendor(context, v) : null,
                                        onDelete: canDelete ? () => _handleDelete(context, v) : null,
                                      );
                                    },
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
