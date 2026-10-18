import 'package:flutter/foundation.dart';
import 'purchase_order_item.dart';
import 'purchase_order_status.dart';

/// Represents a complete Purchase Order record in the Enterprise CRM.
@immutable
class PurchaseOrderRecord {
  final String id;
  final String poNumber;
  final String vendorName;
  final String vendorGst;
  final String vendorContact;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final PurchaseOrderStatus status;
  final List<PurchaseOrderItem> items;
  final double subtotalAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentTerms;
  final String shippingAddress;
  final String notes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? receivedAt;
  final DateTime createdAt;

  const PurchaseOrderRecord({
    required this.id,
    required this.poNumber,
    required this.vendorName,
    this.vendorGst = '',
    this.vendorContact = '',
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.status,
    this.items = const [],
    required this.subtotalAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.paymentTerms = 'Net 30 Days',
    this.shippingAddress = 'Main Warehouse, Sector 18, Gurugram',
    this.notes = '',
    this.approvedBy,
    this.approvedAt,
    this.receivedAt,
    required this.createdAt,
  });

  /// Total units across all items ordered in this PO.
  int get totalOrderedQuantity =>
      items.fold(0, (sum, item) => sum + item.orderedQuantity);

  /// Total units received so far.
  int get totalReceivedQuantity =>
      items.fold(0, (sum, item) => sum + item.receivedQuantity);

  /// Percentage of receipt completion (0.0 to 100.0).
  double get receiptProgressPercentage {
    if (totalOrderedQuantity == 0) return 0.0;
    return (totalReceivedQuantity / totalOrderedQuantity * 100.0).clamp(0.0, 100.0);
  }

  PurchaseOrderRecord copyWith({
    String? id,
    String? poNumber,
    String? vendorName,
    String? vendorGst,
    String? vendorContact,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    PurchaseOrderStatus? status,
    List<PurchaseOrderItem>? items,
    double? subtotalAmount,
    double? taxAmount,
    double? totalAmount,
    String? paymentTerms,
    String? shippingAddress,
    String? notes,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? receivedAt,
    DateTime? createdAt,
  }) {
    return PurchaseOrderRecord(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      vendorName: vendorName ?? this.vendorName,
      vendorGst: vendorGst ?? this.vendorGst,
      vendorContact: vendorContact ?? this.vendorContact,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          poNumber == other.poNumber &&
          vendorName == other.vendorName &&
          status == other.status &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode => Object.hash(id, poNumber, vendorName, status, totalAmount);
}
