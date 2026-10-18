import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../approvals/domain/entities/approval_priority.dart';
import '../../../approvals/domain/services/approval_bridge.dart';
import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../notifications/domain/entities/notification_priority.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../domain/inputs/create_purchase_order_input.dart';
import '../../domain/repositories/purchase_repository.dart';
import 'create_purchase_order_state.dart';

/// Cubit managing creation and validation of new purchase orders.
class CreatePurchaseOrderCubit extends Cubit<CreatePurchaseOrderState> {
  final PurchaseRepository repository;
  final ApprovalBridge? approvalBridge;
  final NotificationDispatcher? notificationDispatcher;
  final CurrentUser? currentUser;

  CreatePurchaseOrderCubit(
    this.repository, {
    this.approvalBridge,
    this.notificationDispatcher,
    this.currentUser,
  }) : super(const CreatePurchaseOrderInitial());

  Future<void> submit(CreatePurchaseOrderInput input) async {
    if (state is CreatePurchaseOrderSubmitting) return;

    final error = input.validate();
    if (error != null) {
      emit(CreatePurchaseOrderFailure(error));
      return;
    }

    emit(const CreatePurchaseOrderSubmitting());

    try {
      final record = await repository.createPurchaseOrder(input);

      // Auto-submit high-value orders for managerial approval
      if (approvalBridge != null && currentUser != null && record.totalAmount >= 5000) {
        try {
          await approvalBridge!.submitForApproval(
            module: CrmModule.purchase,
            entityType: 'purchase_order',
            entityId: record.id,
            entityTitle: 'Purchase Order ${record.poNumber} (${record.vendorName})',
            requester: currentUser!,
            amount: record.totalAmount,
            currencyCode: 'USD',
            priority: record.totalAmount >= 20000
                ? ApprovalPriority.urgent
                : ApprovalPriority.high,
            metadata: {
              'poNumber': record.poNumber,
              'vendorName': record.vendorName,
              'totalAmount': record.totalAmount,
            },
          );
        } catch (_) {
          // Non-blocking bridge execution
        }
      }

      // Operational notification
      if (notificationDispatcher != null && currentUser != null) {
        try {
          await notificationDispatcher!.notifySystemAlert(
            recipientUserId: currentUser!.id,
            title: 'PO Created: ${record.poNumber}',
            message: 'Purchase order ${record.poNumber} for \$${record.totalAmount.toStringAsFixed(2)} was successfully recorded.',
            priority: NotificationPriority.info,
            module: CrmModule.purchase,
          );
        } catch (_) {
          // Non-blocking notification dispatch
        }
      }

      emit(CreatePurchaseOrderSuccess(record));
    } catch (e) {
      final message = e is ArgumentError ? e.message.toString() : e.toString();
      emit(CreatePurchaseOrderFailure(message));
    }
  }
}
