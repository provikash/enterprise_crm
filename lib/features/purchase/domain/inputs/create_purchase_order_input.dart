import 'package:flutter/foundation.dart';
import '../entities/purchase_order_item.dart';

/// Input data required to create a new Purchase Order.
@immutable
class CreatePurchaseOrderInput {
  final String vendorName;
  final String vendorGst;
  final String vendorContact;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final String paymentTerms;
  final String shippingAddress;
  final String notes;
  final List<PurchaseOrderItem> items;

  const CreatePurchaseOrderInput({
    required this.vendorName,
    this.vendorGst = '',
    this.vendorContact = '',
    this.orderDate,
    this.expectedDeliveryDate,
    this.paymentTerms = 'Net 30 Days',
    this.shippingAddress = 'Main Warehouse, Sector 18, Gurugram',
    this.notes = '',
    required this.items,
  });

  /// Subtotal before tax.
  double get subtotalAmount =>
      items.fold(0.0, (sum, item) => sum + item.totalPriceInr);

  /// 18% standard GST tax amount.
  double get taxAmount => subtotalAmount * 0.18;

  /// Total amount including taxes.
  double get totalAmount => subtotalAmount + taxAmount;

  /// Validates input fields and returns error message or `null` if valid.
  String? validate() {
    if (vendorName.trim().isEmpty) {
      return 'Vendor name is required.';
    }
    if (items.isEmpty) {
      return 'At least one purchase line item is required.';
    }
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.itemName.trim().isEmpty) {
        return 'Item #${i + 1} name is required.';
      }
      if (item.orderedQuantity <= 0) {
        return 'Item #${i + 1} ordered quantity must be greater than zero.';
      }
      if (item.unitPriceInr < 0) {
        return 'Item #${i + 1} unit price cannot be negative.';
      }
    }
    return null;
  }
}
