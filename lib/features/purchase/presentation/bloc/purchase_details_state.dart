import 'package:flutter/foundation.dart';
import '../../domain/entities/purchase_order_record.dart';

/// States for the purchase order details inspection and lifecycle progression.
@immutable
sealed class PurchaseDetailsState {
  const PurchaseDetailsState();
}

/// Initial state before purchase order record is loaded.
final class PurchaseDetailsInitial extends PurchaseDetailsState {
  const PurchaseDetailsInitial();
}

/// State emitted while loading record details.
final class PurchaseDetailsLoading extends PurchaseDetailsState {
  const PurchaseDetailsLoading();
}

/// State emitted when purchase order record is successfully loaded.
final class PurchaseDetailsLoaded extends PurchaseDetailsState {
  final PurchaseOrderRecord record;
  final bool isUpdating;
  final String? updateError;

  const PurchaseDetailsLoaded(
    this.record, {
    this.isUpdating = false,
    this.updateError,
  });

  PurchaseDetailsLoaded copyWith({
    PurchaseOrderRecord? record,
    bool? isUpdating,
    String? updateError,
  }) {
    return PurchaseDetailsLoaded(
      record ?? this.record,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseDetailsLoaded &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          isUpdating == other.isUpdating &&
          updateError == other.updateError;

  @override
  int get hashCode => Object.hash(record, isUpdating, updateError);
}

/// State emitted when loading purchase order record encounters an error.
final class PurchaseDetailsFailure extends PurchaseDetailsState {
  final String message;

  const PurchaseDetailsFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseDetailsFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
