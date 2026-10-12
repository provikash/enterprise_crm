import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../../domain/entities/dispatch_record.dart';

/// Serializes dispatch records to an Excel (.xlsx) workbook.
class DispatchXlsxSerializer {
  static const String sheetName = 'Dispatches';

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

  Uint8List convertToBytes(List<DispatchRecord> records) {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    if (defaultSheet != null &&
        defaultSheet != sheetName &&
        excel.tables.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    // Write header cells
    final headerCells = headers
        .map<CellValue>((h) => TextCellValue(h))
        .toList();
    sheet.appendRow(headerCells);

    // Style header row
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Write data rows
    for (final record in records) {
      final rowCells = <CellValue>[
        TextCellValue(record.dispatchCode),
        TextCellValue(record.orderNumber),
        TextCellValue(record.invoiceNumber),
        TextCellValue(record.invoiceDate != null ? _formatDate(record.invoiceDate!) : ''),
        DoubleCellValue(record.invoiceAmount),
        TextCellValue(record.status.displayName),
        TextCellValue(record.customerName),
        TextCellValue(record.customerPhone),
        TextCellValue(record.deliveryAddress),
        TextCellValue(record.transporterName),
        TextCellValue(record.vehicleNumber),
        TextCellValue(record.vehicleType),
        TextCellValue(record.driverName),
        TextCellValue(record.driverPhone),
        TextCellValue(record.builtyNumber),
        TextCellValue(record.builtyDate != null ? _formatDate(record.builtyDate!) : ''),
        IntCellValue(record.items.length),
        DoubleCellValue(record.totalItemsQuantity),
        TextCellValue(_formatDate(record.createdAt)),
        TextCellValue(record.dispatchedAt != null ? _formatDate(record.dispatchedAt!) : ''),
        TextCellValue(record.deliveredAt != null ? _formatDate(record.deliveredAt!) : ''),
        TextCellValue(record.notes),
      ];

      sheet.appendRow(rowCells);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook for Dispatches.');
    }
    return Uint8List.fromList(bytes);
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
