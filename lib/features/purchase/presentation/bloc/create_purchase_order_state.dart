import 'package:flutter/foundation.dart';
import '../../domain/entities/purchase_order_record.dart';

/// States for the purchase order creation flow.
@immutable
sealed class CreatePurchaseOrderState {
  const CreatePurchaseOrderState();
}

/// Initial form state ready for user input.
final class CreatePurchaseOrderInitial extends CreatePurchaseOrderState {
  const CreatePurchaseOrderInitial();
}

/// State emitted while creation request is being processed.
final class CreatePurchaseOrderSubmitting extends CreatePurchaseOrderState {
  const CreatePurchaseOrderSubmitting();
}

/// State emitted when a purchase order is successfully created.
final class CreatePurchaseOrderSuccess extends CreatePurchaseOrderState {
  final PurchaseOrderRecord record;

  const CreatePurchaseOrderSuccess(this.record);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePurchaseOrderSuccess &&
          runtimeType == other.runtimeType &&
          record == other.record;

  @override
  int get hashCode => record.hashCode;
}

/// State emitted when purchase order creation fails validation or submission.
final class CreatePurchaseOrderFailure extends CreatePurchaseOrderState {
  final String message;

  const CreatePurchaseOrderFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePurchaseOrderFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
