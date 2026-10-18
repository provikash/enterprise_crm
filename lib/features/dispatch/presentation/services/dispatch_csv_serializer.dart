import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../domain/entities/dispatch_record.dart';

/// Serializes dispatch records to CSV format with formula injection protection.
class DispatchCsvSerializer {
  const DispatchCsvSerializer();

  static const List<String> headers = [
    'Dispatch Code',
    'Order Number',
    'Invoice Number',
    'Invoice Date',
    'Invoice Amount',
    'Status',
    'Customer Name',
    'Customer Phone',
    'Delivery Address',
    'Transporter',
    'Vehicle Number',
    'Vehicle Type',
    'Driver Name',
    'Driver Phone',
    'Builty Number',
    'Builty Date',
    'Total Items Count',
    'Total Quantity',
    'Created Date',
    'Dispatched Date',
    'Delivered Date',
    'Notes',
  ];

  String convertToString(List<DispatchRecord> records) {
    final rows = <List<dynamic>>[headers];

    for (final record in records) {
      rows.add([
        _sanitize(record.dispatchCode),
        _sanitize(record.orderNumber),
        _sanitize(record.invoiceNumber),
        record.invoiceDate != null ? _formatDate(record.invoiceDate!) : '',
        record.invoiceAmount.toStringAsFixed(2),
        record.status.displayName,
        _sanitize(record.customerName),
        _sanitize(record.customerPhone),
        _sanitize(record.deliveryAddress),
        _sanitize(record.transporterName),
        _sanitize(record.vehicleNumber),
        _sanitize(record.vehicleType),
        _sanitize(record.driverName),
        _sanitize(record.driverPhone),
        _sanitize(record.builtyNumber),
        record.builtyDate != null ? _formatDate(record.builtyDate!) : '',
        record.items.length,
        record.totalItemsQuantity.toStringAsFixed(2),
        _formatDate(record.createdAt),
        record.dispatchedAt != null ? _formatDate(record.dispatchedAt!) : '',
        record.deliveredAt != null ? _formatDate(record.deliveredAt!) : '',
        _sanitize(record.notes),
      ]);
    }

    const encoder = CsvEncoder(
      fieldDelimiter: ',',
      lineDelimiter: '\r\n',
    );
    return encoder.convert(rows);
  }

  Uint8List convertToBytes(List<DispatchRecord> records) {
    return Uint8List.fromList(utf8.encode(convertToString(records)));
  }

  static dynamic _sanitize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final firstChar = trimmed[0];
    if (firstChar == '=' || firstChar == '+' || firstChar == '-' || firstChar == '@') {
      return "'$trimmed";
    }
    return trimmed;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
