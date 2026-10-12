import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/dispatch_record.dart';
import '../../domain/policies/dispatch_access_policy.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../bloc/dispatch_details_cubit.dart';
import '../bloc/dispatch_details_state.dart';
import '../widgets/dispatch_lifecycle_stepper.dart';
import '../widgets/dispatch_status_badge.dart';
import '../widgets/update_dispatch_status_dialog.dart';

/// Screen presenting comprehensive dispatch order details, line items, and lifecycle tracking.
class DispatchDetailsScreen extends StatelessWidget {
  final String dispatchId;
  final CurrentUser user;
  final DispatchRepository repository;

  const DispatchDetailsScreen({
    super.key,
    required this.dispatchId,
    required this.user,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!DispatchAccessPolicy.canView(user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<DispatchDetailsCubit>(
      create: (_) => DispatchDetailsCubit(repository)..loadDispatch(dispatchId),
      child: _DispatchDetailsView(
        dispatchId: dispatchId,
        user: user,
      ),
    );
  }
}

class _DispatchDetailsView extends StatelessWidget {
  final String dispatchId;
  final CurrentUser user;

  const _DispatchDetailsView({
    required this.dispatchId,
    required this.user,
  });

  void _openUpdateStatusDialog(BuildContext context, DispatchRecord record) {
    showDialog(
      context: context,
      builder: (_) => UpdateDispatchStatusDialog(
        currentStatus: record.status,
        onUpdate: (result) {
          context.read<DispatchDetailsCubit>().updateStatus(
                result.newStatus,
                remarks: result.remarks,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<DispatchDetailsCubit, DispatchDetailsState>(
      listener: (context, state) {
        if (state is DispatchDetailsLoaded && state.updateError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.updateError!),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dispatch Details'),
            actions: [
              if (state is DispatchDetailsLoaded) ...[
                if (DispatchAccessPolicy.canUpdateStatus(user) &&
                    !state.record.status.isTerminal)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FilledButton.tonalIcon(
                      key: const Key('open_update_status_dialog_button'),
                      icon: const Icon(Icons.edit_road_outlined, size: 18),
                      label: const Text('Update Status'),
                      onPressed: state.isUpdating
                          ? null
                          : () => _openUpdateStatusDialog(context, state.record),
                    ),
                  ),
              ],
            ],
          ),
          body: switch (state) {
            DispatchDetailsInitial() || DispatchDetailsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DispatchDetailsFailure(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(message, style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ),
            DispatchDetailsLoaded(:final record, :final isUpdating) =>
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isUpdating)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: LinearProgressIndicator(),
                          ),

                        // Lifecycle Progression Stepper
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          color: colorScheme.surfaceContainerLowest,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Shipment Progress',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DispatchStatusBadge(status: record.status),
                                  ],
                                ),
                                const Divider(height: 20),
                                DispatchLifecycleStepper(currentStatus: record.status),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Overview Card
                        _buildSectionCard(
                          context,
                          title: 'Shipment Overview',
                          icon: Icons.local_shipping_outlined,
                          children: [
                            _buildInfoRow(
                              'Dispatch Code',
                              record.dispatchCode,
                              valueKey: const Key('details_dispatch_code'),
                              isBold: true,
                            ),
                            _buildInfoRow('Order Number', record.orderNumber),
                            _buildInfoRow('Created Date', _formatDate(record.createdAt)),
                            if (record.dispatchedAt != null)
                              _buildInfoRow('Dispatched Date', _formatDate(record.dispatchedAt!)),
                            if (record.deliveredAt != null)
                              _buildInfoRow('Delivered Date', _formatDate(record.deliveredAt!)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Consignee Details Card
                        _buildSectionCard(
                          context,
                          title: 'Customer & Consignee Destination',
                          icon: Icons.person_pin_circle_outlined,
                          children: [
                            _buildInfoRow(
                              'Customer / Firm',
                              record.customerName,
                              valueKey: const Key('details_customer_name'),
                              isBold: true,
                            ),
                            _buildInfoRow(
                              'Contact Phone',
                              record.customerPhone,
                              valueKey: const Key('details_customer_phone'),
                            ),
                            _buildInfoRow(
                              'Delivery Address',
                              record.deliveryAddress,
                              valueKey: const Key('details_delivery_address'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Commercial & Invoice Card
                        _buildSectionCard(
                          context,
                          title: 'Commercial & Invoice Details',
                          icon: Icons.receipt_long_outlined,
                          children: [
                            _buildInfoRow(
                              'Invoice Number',
                              record.invoiceNumber,
                              valueKey: const Key('details_invoice_number'),
                              isBold: true,
                            ),
                            _buildInfoRow(
                              'Invoice Amount',
                              '₹${record.invoiceAmount.toStringAsFixed(2)}',
                              valueKey: const Key('details_invoice_amount'),
                              isBold: true,
                              valueColor: colorScheme.primary,
                            ),
                            _buildInfoRow(
                              'Total Items Qty',
                              '${record.totalItemsQuantity}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Transport & Carrier Logistics Card
                        _buildSectionCard(
                          context,
                          title: 'Carrier & Logistics Details',
                          icon: Icons.directions_boat_filled_outlined,
                          children: [
                            _buildInfoRow(
                              'Transporter Name',
                              record.transporterName,
                              valueKey: const Key('details_transporter_name'),
                            ),
                            _buildInfoRow(
                              'Vehicle',
                              '${record.vehicleNumber} (${record.vehicleType})',
                              valueKey: const Key('details_vehicle_number'),
                            ),
                            _buildInfoRow(
                              'Driver',
                              '${record.driverName} • ${record.driverPhone}',
                              valueKey: const Key('details_driver_name'),
                            ),
                            _buildInfoRow(
                              'Builty / LR #',
                              record.builtyNumber.isEmpty ? '—' : record.builtyNumber,
                              valueKey: const Key('details_builty_number'),
                              isMonospace: true,
                              isBold: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Line Items Breakdown
                        _buildSectionCard(
                          context,
                          title: 'Shipment Items (${record.items.length})',
                          icon: Icons.inventory_2_outlined,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                key: const Key('details_items_table'),
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Unit Price (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: record.items.map((item) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text(item.sku)),
                                      DataCell(Text('${item.quantity}')),
                                      DataCell(Text(item.unit)),
                                      DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                                      DataCell(
                                        Text(
                                          '₹${item.totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Document Proofs & Receipts
                        _buildSectionCard(
                          context,
                          title: 'Document Proofs & Receipts',
                          icon: Icons.attachment_outlined,
                          children: [
                            _buildDocumentItem(
                              context,
                              'Builty / Consignment Note (LR)',
                              record.builtyDocumentName,
                              icon: Icons.picture_as_pdf_outlined,
                            ),
                            const Divider(height: 16),
                            _buildDocumentItem(
                              context,
                              'Final Tax Invoice',
                              record.finalInvoiceDocumentName,
                              icon: Icons.description_outlined,
                            ),
                            const Divider(height: 16),
                            _buildDocumentItem(
                              context,
                              'Proof of Delivery (POD Slip)',
                              record.deliveryProofDocumentName,
                              icon: Icons.verified_outlined,
                            ),
                          ],
                        ),

                        if (record.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            context,
                            title: 'Instructions & Notes',
                            icon: Icons.note_outlined,
                            children: [
                              Text(
                                record.notes,
                                key: const Key('details_notes'),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
          },
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Key? valueKey,
    bool isBold = false,
    bool isMonospace = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontFamily: isMonospace ? 'monospace' : null,
                color: valueColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    String label,
    String? documentName, {
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDocument = documentName != null && documentName.isNotEmpty;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: hasDocument ? colorScheme.primary : colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hasDocument ? documentName : 'Not uploaded / pending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasDocument
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        if (hasDocument)
          Chip(
            visualDensity: VisualDensity.compact,
            label: const Text('Attached', style: TextStyle(fontSize: 11)),
            avatar: const Icon(Icons.check, size: 14, color: Colors.green),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
