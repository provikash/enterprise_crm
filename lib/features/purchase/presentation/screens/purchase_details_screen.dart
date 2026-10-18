import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/entities/purchase_order_status.dart';
import '../../domain/policies/purchase_access_policy.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../bloc/purchase_details_cubit.dart';
import '../bloc/purchase_details_state.dart';
import '../services/purchase_file_saver.dart';
import '../services/purchase_pdf_serializer.dart';
import '../widgets/purchase_lifecycle_stepper.dart';
import '../widgets/purchase_status_badge.dart';
import '../widgets/receive_stock_dialog.dart';

/// Screen presenting comprehensive purchase order details, itemized goods receipt,
/// and approval / lifecycle status progression.
class PurchaseDetailsScreen extends StatelessWidget {
  final String purchaseOrderId;
  final CurrentUser user;
  final PurchaseRepository repository;
  final PurchaseFileSaver? fileSaver;

  const PurchaseDetailsScreen({
    super.key,
    required this.purchaseOrderId,
    required this.user,
    required this.repository,
    this.fileSaver,
  });

  @override
  Widget build(BuildContext context) {
    if (!PurchaseAccessPolicy.canView(user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider<PurchaseDetailsCubit>(
      create: (_) => PurchaseDetailsCubit(repository)
        ..loadPurchaseOrder(purchaseOrderId),
      child: _PurchaseDetailsView(
        purchaseOrderId: purchaseOrderId,
        user: user,
        fileSaver: fileSaver,
      ),
    );
  }
}

class _PurchaseDetailsView extends StatelessWidget {
  final String purchaseOrderId;
  final CurrentUser user;
  final PurchaseFileSaver? fileSaver;

  const _PurchaseDetailsView({
    required this.purchaseOrderId,
    required this.user,
    this.fileSaver,
  });

  void _openReceiveStockDialog(BuildContext context, PurchaseOrderRecord record) {
    showDialog(
      context: context,
      builder: (_) => ReceiveStockDialog(
        record: record,
        onReceiveConfirmed: (receivedMap) {
          context.read<PurchaseDetailsCubit>().receiveItems(receivedMap);
        },
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, PurchaseOrderRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Purchase Order'),
        content: Text(
          'Are you sure you want to cancel ${record.poNumber}? This action cannot be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep PO'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<PurchaseDetailsCubit>().updateStatus(
                    PurchaseOrderStatus.cancelled,
                    notes: 'Cancelled by user ${user.displayName}',
                  );
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBill(BuildContext context, PurchaseOrderRecord record) async {
    try {
      final saver = fileSaver ?? const DefaultPurchaseFileSaver();
      final bytes = const PurchasePdfSerializer().generatePurchaseOrderBillPdf(record);
      final fileName = 'Purchase_Order_${record.poNumber}.pdf';
      final uri = await saver.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        extension: 'pdf',
        dialogTitle: 'Save Purchase Order (${record.poNumber})',
      );
      if (context.mounted && uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved $fileName'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PO bill: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<PurchaseDetailsCubit, PurchaseDetailsState>(
      listener: (context, state) {
        if (state is PurchaseDetailsLoaded && state.updateError != null) {
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
            title: Text(
              state is PurchaseDetailsLoaded
                  ? state.record.poNumber
                  : 'Purchase Order Details',
            ),
            actions: [
              if (state is PurchaseDetailsLoaded) ...[
                if (MediaQuery.sizeOf(context).width >= 420)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PurchaseStatusBadge(status: state.record.status),
                  ),
                _buildActionButtons(context, state.record, state.isUpdating),
              ],
            ],
          ),
          body: switch (state) {
            PurchaseDetailsInitial() || PurchaseDetailsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            PurchaseDetailsFailure(:final message) => Center(
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
                        onPressed: () => context
                            .read<PurchaseDetailsCubit>()
                            .loadPurchaseOrder(purchaseOrderId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            PurchaseDetailsLoaded(:final record) => SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Lifecycle Progress Stepper
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.timeline,
                                            size: 20,
                                            color: colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Order Lifecycle Progression',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    PurchaseLifecycleStepper(
                                      currentStatus: record.status,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Vendor Information Card
                            _buildSectionCard(
                              context,
                              title: 'Vendor Information',
                              icon: Icons.storefront_outlined,
                              children: [
                                _buildDetailRow(
                                  context,
                                  'Vendor Name',
                                  record.vendorName,
                                  isBold: true,
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  context,
                                  'GSTIN',
                                  record.vendorGst.isEmpty
                                      ? 'Not provided'
                                      : record.vendorGst,
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  context,
                                  'Contact Details',
                                  record.vendorContact.isEmpty
                                      ? 'Not provided'
                                      : record.vendorContact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 3. Logistics, Delivery & Terms
                            _buildSectionCard(
                              context,
                              title: 'Logistics & Commercial Terms',
                              icon: Icons.local_shipping_outlined,
                              action: PurchaseAccessPolicy.canDownloadBill(user)
                                  ? OutlinedButton.icon(
                                      key: const Key('purchase_download_bill_button'),
                                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                      label: const Text('Download Bill (PDF)'),
                                      onPressed: () => _downloadBill(context, record),
                                    )
                                  : null,
                              children: [
                                _buildDetailRow(
                                  context,
                                  'Order Date',
                                  _formatDate(record.orderDate),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  context,
                                  'Expected Delivery',
                                  record.expectedDeliveryDate != null
                                      ? _formatDate(record.expectedDeliveryDate!)
                                      : 'Not scheduled',
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  context,
                                  'Payment Terms',
                                  record.paymentTerms,
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  context,
                                  'Shipping Address',
                                  record.shippingAddress,
                                ),
                                if (record.approvedBy != null) ...[
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    context,
                                    'Approved By',
                                    '${record.approvedBy} (${record.approvedAt != null ? _formatDate(record.approvedAt!) : ""})',
                                  ),
                                ],
                                if (record.receivedAt != null) ...[
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    context,
                                    'Received At',
                                    _formatDate(record.receivedAt!),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 4. Line Items Breakdown
                            _buildSectionCard(
                              context,
                              title: 'Purchased Items & Receipt Progress',
                              icon: Icons.inventory_2_outlined,
                              children: [
                                ...record.items.asMap().entries.map((entry) {
                                  final item = entry.value;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.itemName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '₹${item.totalPriceInr.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'SKU: ${item.sku} • Category: ${item.category} • Rate: ₹${item.unitPriceInr.toStringAsFixed(2)} / ${item.unit}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child:
                                                    LinearProgressIndicator(
                                                  value: item.orderedQuantity > 0
                                                      ? item.receivedQuantity /
                                                          item.orderedQuantity
                                                      : 0.0,
                                                  minHeight: 6,
                                                  backgroundColor: colorScheme
                                                      .outlineVariant
                                                      .withValues(alpha: 0.4),
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    item.isFullyReceived
                                                        ? Colors.green
                                                        : colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${item.receivedQuantity}/${item.orderedQuantity} ${item.unit} received',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: item.isFullyReceived
                                                    ? Colors.green.shade700
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 5. Financial Summary Card
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('Subtotal Amount:',
                                              style: theme.textTheme.bodyMedium),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${record.subtotalAmount.toStringAsFixed(2)}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('GST (18% Standard):',
                                              style: theme.textTheme.bodyMedium),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${record.taxAmount.toStringAsFixed(2)}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Total PO Amount:',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${record.totalAmount.toStringAsFixed(2)}',
                                          key: const Key(
                                              'purchase_details_total_amount'),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 6. Notes & Instructions
                            if (record.notes.isNotEmpty) ...[
                              _buildSectionCard(
                                context,
                                title: 'Notes & Remarks',
                                icon: Icons.notes_outlined,
                                children: [
                                  Text(
                                    record.notes,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
          },
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PurchaseOrderRecord record,
    bool isUpdating,
  ) {
    if (record.status.isTerminal) return const SizedBox.shrink();

    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final cubit = context.read<PurchaseDetailsCubit>();

    Widget buildButton({
      required Key key,
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      if (isNarrow) {
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton.filled(
            key: key,
            icon: Icon(icon, size: 18),
            tooltip: label,
            onPressed: isUpdating ? null : onPressed,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: FilledButton.icon(
          key: key,
          icon: Icon(icon, size: 16),
          label: Text(label),
          onPressed: isUpdating ? null : onPressed,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (record.status == PurchaseOrderStatus.draft)
          buildButton(
            key: const Key('purchase_submit_approval_button'),
            icon: Icons.send_outlined,
            label: 'Submit for Approval',
            onPressed: () =>
                cubit.updateStatus(PurchaseOrderStatus.pendingApproval),
          ),
        if (record.status == PurchaseOrderStatus.pendingApproval &&
            PurchaseAccessPolicy.canApprove(user))
          buildButton(
            key: const Key('purchase_approve_button'),
            icon: Icons.verified_outlined,
            label: 'Approve PO',
            onPressed: () => cubit.updateStatus(
              PurchaseOrderStatus.approved,
              approvedBy: user.displayName,
            ),
          ),
        if (record.status == PurchaseOrderStatus.approved)
          buildButton(
            key: const Key('purchase_place_order_button'),
            icon: Icons.local_shipping_outlined,
            label: 'Place Order',
            onPressed: () => cubit.updateStatus(PurchaseOrderStatus.ordered),
          ),
        if (record.status == PurchaseOrderStatus.ordered &&
            PurchaseAccessPolicy.canReceive(user))
          buildButton(
            key: const Key('purchase_receive_stock_button'),
            icon: Icons.inventory_2_outlined,
            label: 'Receive Stock',
            onPressed: () => _openReceiveStockDialog(context, record),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            if (val == 'cancel') {
              _confirmCancelOrder(context, record);
            } else if (val == 'download_bill') {
              _downloadBill(context, record);
            }
          },
          itemBuilder: (ctx) => [
            if (PurchaseAccessPolicy.canDownloadBill(user))
              const PopupMenuItem(
                key: Key('purchase_menu_download_bill'),
                value: 'download_bill',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Download Bill (PDF)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancel PO',
                      style: TextStyle(color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? action,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                if (isNarrow && action != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 8),
                      action,
                    ],
                  );
                }
                return Row(
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
                    ?action,
                  ],
                );
              },
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
