import 'package:flutter/foundation.dart';

/// Represents a single line item within a Purchase Order.
@immutable
class PurchaseOrderItem {
  final String id;
  final String itemName;
  final String sku;
  final String category;
  final int orderedQuantity;
  final int receivedQuantity;
  final String unit;
  final double unitPriceInr;

  const PurchaseOrderItem({
    required this.id,
    required this.itemName,
    required this.sku,
    this.category = 'General',
    required this.orderedQuantity,
    this.receivedQuantity = 0,
    this.unit = 'Pcs',
    required this.unitPriceInr,
  });

  /// Total line price before taxes.
  double get totalPriceInr => orderedQuantity * unitPriceInr;

  /// Quantity still pending receipt from vendor.
  int get pendingQuantity => (orderedQuantity - receivedQuantity).clamp(0, orderedQuantity);

  /// Whether this line item is fully received.
  bool get isFullyReceived => receivedQuantity >= orderedQuantity;

  PurchaseOrderItem copyWith({
    String? id,
    String? itemName,
    String? sku,
    String? category,
    int? orderedQuantity,
    int? receivedQuantity,
    String? unit,
    double? unitPriceInr,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unit: unit ?? this.unit,
      unitPriceInr: unitPriceInr ?? this.unitPriceInr,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemName == other.itemName &&
          sku == other.sku &&
          category == other.category &&
          orderedQuantity == other.orderedQuantity &&
          receivedQuantity == other.receivedQuantity &&
          unit == other.unit &&
          unitPriceInr == other.unitPriceInr;

  @override
  int get hashCode => Object.hash(
        id,
        itemName,
        sku,
        category,
        orderedQuantity,
        receivedQuantity,
        unit,
        unitPriceInr,
      );
}
