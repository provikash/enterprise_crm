import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../approvals/domain/entities/approval_request.dart';
import '../../../approvals/domain/repositories/approval_repository.dart';
import '../../../approvals/domain/services/approval_bridge.dart';
import '../../../approvals/presentation/screens/approval_detail_screen.dart';
import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../../notifications/domain/entities/notification_priority.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
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
  final ApprovalBridge? approvalBridge;
  final NotificationDispatcher? notificationDispatcher;
  final ApprovalRepository? approvalRepository;

  const PurchaseDetailsScreen({
    super.key,
    required this.purchaseOrderId,
    required this.user,
    required this.repository,
    this.fileSaver,
    this.approvalBridge,
    this.notificationDispatcher,
    this.approvalRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (!PurchaseAccessPolicy.canView(user)) {
      return const AccessRestrictedScreen();
    }

    ApprovalBridge? bridge = approvalBridge;
    if (bridge == null) {
      try {
        bridge = context.read<ApprovalBridge>();
      } catch (_) {}
    }

    NotificationDispatcher? dispatcher = notificationDispatcher;
    if (dispatcher == null) {
      try {
        dispatcher = context.read<NotificationDispatcher>();
      } catch (_) {}
    }

    ApprovalRepository? approvalRepo = approvalRepository;
    if (approvalRepo == null) {
      try {
        approvalRepo = context.read<ApprovalRepository>();
      } catch (_) {}
    }

    return BlocProvider<PurchaseDetailsCubit>(
      create: (_) =>
          PurchaseDetailsCubit(repository)..loadPurchaseOrder(purchaseOrderId),
      child: _PurchaseDetailsView(
        purchaseOrderId: purchaseOrderId,
        user: user,
        fileSaver: fileSaver,
        approvalBridge: bridge,
        notificationDispatcher: dispatcher,
        approvalRepository: approvalRepo,
      ),
    );
  }
}

class _PurchaseDetailsView extends StatefulWidget {
  final String purchaseOrderId;
  final CurrentUser user;
  final PurchaseFileSaver? fileSaver;
  final ApprovalBridge? approvalBridge;
  final NotificationDispatcher? notificationDispatcher;
  final ApprovalRepository? approvalRepository;

  const _PurchaseDetailsView({
    required this.purchaseOrderId,
    required this.user,
    this.fileSaver,
    this.approvalBridge,
    this.notificationDispatcher,
    this.approvalRepository,
  });

  @override
  State<_PurchaseDetailsView> createState() => _PurchaseDetailsViewState();
}

class _PurchaseDetailsViewState extends State<_PurchaseDetailsView> {
  ApprovalRequest? _approvalRequest;
  bool _isLoadingApproval = false;
  String? _loadedForPoId;

  Future<void> _loadApprovalRequest(PurchaseOrderRecord record) async {
    if (widget.approvalBridge == null) return;
    _isLoadingApproval = true;
    try {
      var req = await widget.approvalBridge!.getApprovalForEntity(
        entityType: 'purchase_order',
        entityId: record.id,
      );
      if (req == null && record.poNumber.isNotEmpty) {
        req = await widget.approvalBridge!.getApprovalForEntity(
          entityType: 'purchase_order',
          entityId: record.poNumber,
        );
      }
      if (mounted) {
        setState(() {
          _approvalRequest = req;
          _loadedForPoId = record.id;
          _isLoadingApproval = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingApproval = false;
        });
      }
    }
  }

  void _openReceiveStockDialog(
    BuildContext context,
    PurchaseOrderRecord record,
  ) {
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
                notes: 'Cancelled by user ${widget.user.displayName}',
              );
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  void _promptRejectPurchaseOrder(
    BuildContext context,
    PurchaseOrderRecord record,
  ) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Purchase Order (${record.poNumber})'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason or notes for rejecting this order...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = textController.text.trim().isEmpty
                  ? 'Rejected by ${widget.user.displayName}'
                  : textController.text.trim();
              Navigator.of(ctx).pop();
              _rejectPurchaseOrder(context, record, reason);
            },
            child: const Text('Reject PO'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForApproval(
    BuildContext context,
    PurchaseOrderRecord record,
  ) async {
    final cubit = context.read<PurchaseDetailsCubit>();
    await cubit.updateStatus(PurchaseOrderStatus.pendingApproval);

    if (widget.approvalBridge != null) {
      try {
        final req = await widget.approvalBridge!.submitForApproval(
          module: CrmModule.purchase,
          entityType: 'purchase_order',
          entityId: record.id,
          entityTitle: 'Purchase Order #${record.poNumber} (${record.vendorName})',
          requester: widget.user,
          amount: record.totalAmount,
          currencyCode: 'INR',
          metadata: {
            'poNumber': record.poNumber,
            'po_number': record.poNumber,
            'vendorName': record.vendorName,
          },
        );
        if (mounted) {
          setState(() {
            _approvalRequest = req;
          });
        }
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchase Order ${record.poNumber} submitted for approval. Notification sent to approvers.',
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  Future<void> _approvePurchaseOrder(
    BuildContext context,
    PurchaseOrderRecord record,
  ) async {
    final cubit = context.read<PurchaseDetailsCubit>();
    await cubit.updateStatus(
      PurchaseOrderStatus.approved,
      approvedBy: widget.user.displayName,
    );

    if (_approvalRequest != null && widget.approvalRepository != null) {
      try {
        final updatedReq = await widget.approvalRepository!.approveRequest(
          requestId: _approvalRequest!.id,
          actor: widget.user,
          comment: 'Approved from Purchase Order view by ${widget.user.displayName}',
        );
        if (mounted) {
          setState(() {
            _approvalRequest = updatedReq;
          });
        }
        if (widget.notificationDispatcher != null) {
          await widget.notificationDispatcher!.notifyApprovalDecision(
            request: updatedReq,
            decision: 'Approved',
            notes: 'Purchase order signed off by ${widget.user.displayName}',
          );
        }
      } catch (_) {}
    } else if (widget.notificationDispatcher != null) {
      await widget.notificationDispatcher!.notifySystemAlert(
        recipientUserId: 'usr_buyer',
        title: 'PO Approved: ${record.poNumber}',
        message: 'Purchase order #${record.poNumber} has been approved by ${widget.user.displayName}.',
        priority: NotificationPriority.success,
        module: CrmModule.purchase,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase Order ${record.poNumber} approved successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _rejectPurchaseOrder(
    BuildContext context,
    PurchaseOrderRecord record,
    String reason,
  ) async {
    final cubit = context.read<PurchaseDetailsCubit>();
    await cubit.updateStatus(
      PurchaseOrderStatus.cancelled,
      notes: 'Rejected: $reason',
    );

    if (_approvalRequest != null && widget.approvalRepository != null) {
      try {
        final updatedReq = await widget.approvalRepository!.rejectRequest(
          requestId: _approvalRequest!.id,
          actor: widget.user,
          rejectionReason: reason,
        );
        if (mounted) {
          setState(() {
            _approvalRequest = updatedReq;
          });
        }
        if (widget.notificationDispatcher != null) {
          await widget.notificationDispatcher!.notifyApprovalDecision(
            request: updatedReq,
            decision: 'Rejected',
            notes: reason,
          );
        }
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase Order ${record.poNumber} was rejected.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _downloadBill(
    BuildContext context,
    PurchaseOrderRecord record,
  ) async {
    try {
      final saver = widget.fileSaver ?? const DefaultPurchaseFileSaver();
      final bytes = const PurchasePdfSerializer().generatePurchaseOrderBillPdf(
        record,
      );
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

  Widget _buildApprovalGovernanceCard(
    BuildContext context,
    PurchaseOrderRecord record,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final req = _approvalRequest;

    Color cardBorderColor;
    Color statusBadgeColor;
    String statusTitle;
    IconData statusIcon;

    if (record.status == PurchaseOrderStatus.approved ||
        record.status == PurchaseOrderStatus.ordered ||
        record.status == PurchaseOrderStatus.received ||
        req?.status.displayName.toLowerCase() == 'approved') {
      cardBorderColor = Colors.green.shade300;
      statusBadgeColor = Colors.green;
      statusTitle = 'Approved';
      statusIcon = Icons.verified;
    } else if (record.status == PurchaseOrderStatus.pendingApproval ||
        req?.status.displayName.toLowerCase().contains('pending') == true) {
      cardBorderColor = Colors.amber.shade400;
      statusBadgeColor = Colors.amber.shade700;
      statusTitle = 'Pending Approval';
      statusIcon = Icons.hourglass_top;
    } else if (record.status == PurchaseOrderStatus.cancelled ||
        req?.status.displayName.toLowerCase() == 'rejected') {
      cardBorderColor = Colors.red.shade300;
      statusBadgeColor = Colors.red;
      statusTitle = 'Rejected';
      statusIcon = Icons.cancel;
    } else {
      cardBorderColor = colorScheme.outlineVariant;
      statusBadgeColor = colorScheme.outline;
      statusTitle = 'Draft';
      statusIcon = Icons.edit_note;
    }

    return Card(
      key: const Key('purchase_approval_governance_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final badgeWidget = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusBadgeColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusBadgeColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          statusTitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Approval & Governance Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      badgeWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Icon(
                      Icons.gavel_outlined,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approval & Governance Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    badgeWidget,
                  ],
                );
              },
            ),
            const Divider(height: 20),
            if (req != null) ...[
              _buildDetailRow(
                context,
                'Approval Request',
                req.requestNumber,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Workflow Stage',
                req.currentStep?.title ?? 'Procurement Governance Review',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Assigned Approver',
                req.currentStep?.assignedUserName ??
                    req.currentStep?.assignedRole ??
                    (record.approvedBy ?? 'Finance Director'),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Priority',
                req.priority.name.toUpperCase(),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Submitted At',
                _formatDate(req.submittedAt),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('purchase_open_inbox_button'),
                    icon: const Icon(Icons.inbox_outlined, size: 16),
                    label: const Text('Open in Approvals Inbox'),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => ApprovalDetailScreen(
                                requestId: req.id,
                                user: widget.user,
                                repository: widget.approvalRepository,
                              ),
                            ),
                          )
                          .then((_) {
                            _loadApprovalRequest(record);
                          });
                    },
                  ),
                  if (record.status == PurchaseOrderStatus.pendingApproval &&
                      PurchaseAccessPolicy.canApprove(widget.user)) ...[
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reject PO',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () =>
                          _promptRejectPurchaseOrder(context, record),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve PO'),
                      onPressed: () =>
                          _approvePurchaseOrder(context, record),
                    ),
                  ],
                ],
              ),
            ] else ...[
              if (record.status == PurchaseOrderStatus.draft) ...[
                Text(
                  'This Purchase Order is currently a draft. Submit it to dispatch approval requests to department heads and notification alerts across the CRM.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const Key('purchase_submit_approval_governance_btn'),
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Submit for Approval'),
                    onPressed: () => _submitForApproval(context, record),
                  ),
                ),
              ] else if (record.status == PurchaseOrderStatus.pendingApproval) ...[
                Text(
                  'Purchase Order #${record.poNumber} is queued for managerial sign-off. Approvers have been notified.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (PurchaseAccessPolicy.canApprove(widget.user))
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Reject PO',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () =>
                            _promptRejectPurchaseOrder(context, record),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve PO'),
                        onPressed: () =>
                            _approvePurchaseOrder(context, record),
                      ),
                    ],
                  ),
              ] else if (record.status == PurchaseOrderStatus.approved) ...[
                _buildDetailRow(
                  context,
                  'Approved By',
                  record.approvedBy ?? 'Authorized Signatory',
                  isBold: true,
                ),
                if (record.approvedAt != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Approved On',
                    _formatDate(record.approvedAt!),
                  ),
                ],
              ] else ...[
                Text(
                  'Lifecycle status: ${record.status.displayName}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ],
        ),
      ),
    );
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
        if (state is PurchaseDetailsLoaded &&
            _loadedForPoId != state.record.id &&
            !_isLoadingApproval) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _loadedForPoId != state.record.id) {
              _loadApprovalRequest(state.record);
            }
          });
        }

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
            PurchaseDetailsInitial() || PurchaseDetailsLoading() =>
              const Center(child: CircularProgressIndicator()),
            PurchaseDetailsFailure(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
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
                          .loadPurchaseOrder(widget.purchaseOrderId),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timeline,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
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

                          // 2. Approval & Governance Status Card
                          _buildApprovalGovernanceCard(context, record),
                          const SizedBox(height: 16),

                          // 3. Vendor Information Card
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

                          // 4. Logistics, Delivery & Terms
                          _buildSectionCard(
                            context,
                            title: 'Logistics & Commercial Terms',
                            icon: Icons.local_shipping_outlined,
                            action: PurchaseAccessPolicy.canDownloadBill(
                              widget.user,
                            )
                                ? OutlinedButton.icon(
                                    key: const Key(
                                      'purchase_download_bill_button',
                                    ),
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Download Bill (PDF)'),
                                    onPressed: () =>
                                        _downloadBill(context, record),
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

                          // 5. Line Items Breakdown
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
                                              child: LinearProgressIndicator(
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
                                                      Color
                                                    >(
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

                          // 6. Financial Summary Card
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Subtotal Amount:',
                                          style: theme.textTheme.bodyMedium,
                                        ),
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
                                        child: Text(
                                          'GST (18% Standard):',
                                          style: theme.textTheme.bodyMedium,
                                        ),
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
                                          'purchase_details_total_amount',
                                        ),
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

                          // 7. Notes & Instructions
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
            onPressed: () => _submitForApproval(context, record),
          ),
        if (record.status == PurchaseOrderStatus.pendingApproval &&
            PurchaseAccessPolicy.canApprove(widget.user))
          buildButton(
            key: const Key('purchase_approve_button'),
            icon: Icons.verified_outlined,
            label: 'Approve PO',
            onPressed: () => _approvePurchaseOrder(context, record),
          ),
        if (record.status == PurchaseOrderStatus.approved)
          buildButton(
            key: const Key('purchase_place_order_button'),
            icon: Icons.local_shipping_outlined,
            label: 'Place Order',
            onPressed: () => cubit.updateStatus(PurchaseOrderStatus.ordered),
          ),
        if (record.status == PurchaseOrderStatus.ordered &&
            PurchaseAccessPolicy.canReceive(widget.user))
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
            } else if (val == 'reject') {
              _promptRejectPurchaseOrder(context, record);
            } else if (val == 'download_bill') {
              _downloadBill(context, record);
            }
          },
          itemBuilder: (ctx) => [
            if (record.status == PurchaseOrderStatus.pendingApproval &&
                PurchaseAccessPolicy.canApprove(widget.user))
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_down_outlined,
                      size: 18,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reject PO',
                        style: TextStyle(color: Colors.orange),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (PurchaseAccessPolicy.canDownloadBill(widget.user))
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
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
      },
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
