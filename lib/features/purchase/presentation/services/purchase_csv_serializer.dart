import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/purchase_order_record.dart';

/// Pure-Dart serializer generating standard RFC-4180 CSV representations of purchase orders.
class PurchaseCsvSerializer {
  const PurchaseCsvSerializer();

  String convertToString(List<PurchaseOrderRecord> orders) {
    final buffer = StringBuffer();

    // CSV Header row
    buffer.writeln(
      'PO Number,Vendor Name,Vendor GST,Contact,Order Date,Expected Delivery,Status,Items Count,Subtotal (INR),Tax (INR),Total Amount (INR),Payment Terms,Shipping Address,Approved By,Notes',
    );

    for (final po in orders) {
      final fields = [
        po.poNumber,
        po.vendorName,
        po.vendorGst,
        po.vendorContact,
        _formatDate(po.orderDate),
        po.expectedDeliveryDate != null ? _formatDate(po.expectedDeliveryDate!) : '',
        po.status.displayName,
        po.items.length.toString(),
        po.subtotalAmount.toStringAsFixed(2),
        po.taxAmount.toStringAsFixed(2),
        po.totalAmount.toStringAsFixed(2),
        po.paymentTerms,
        po.shippingAddress,
        po.approvedBy ?? '',
        po.notes,
      ];

      buffer.writeln(fields.map(_escapeCsvField).join(','));
    }

    return buffer.toString();
  }

  Uint8List convertToBytes(List<PurchaseOrderRecord> orders) {
    return Uint8List.fromList(utf8.encode(convertToString(orders)));
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
