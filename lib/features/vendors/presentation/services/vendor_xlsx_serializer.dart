import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../../domain/entities/vendor_record.dart';

/// Pure-Dart serializer for generating Vendor XLSX workbooks.
class VendorXlsxSerializer {
  const VendorXlsxSerializer();

  static const String sheetName = 'Vendors';

  static const List<String> headers = [
    'Vendor Code',
    'Company Name',
    'Category',
    'Status',
    'Contact Person',
    'Phone',
    'Alternate Phone',
    'Email Address',
    'GSTIN',
    'PAN',
    'Rating',
    'Payment Terms',
    'Credit Limit (INR)',
    'Bank Name',
    'Account Number',
    'IFSC Code',
    'Branch Name',
    'Address',
    'City',
    'State',
    'Pincode',
    'Created At',
  ];

  Uint8List convertToBytes(List<VendorRecord> vendors) {
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

    // Write Header Row
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Write Data Rows
    for (final v in vendors) {
      sheet.appendRow([
        TextCellValue(v.vendorCode),
        TextCellValue(v.companyName),
        TextCellValue(v.category),
        TextCellValue(v.status.displayName),
        TextCellValue(v.contactPerson),
        TextCellValue(v.phone),
        TextCellValue(v.alternatePhone),
        TextCellValue(v.email),
        TextCellValue(v.gstin),
        TextCellValue(v.pan),
        DoubleCellValue(v.rating),
        TextCellValue(v.paymentTerms),
        DoubleCellValue(v.creditLimitInr),
        TextCellValue(v.bankName),
        TextCellValue(v.accountNumber),
        TextCellValue(v.ifscCode),
        TextCellValue(v.branchName),
        TextCellValue(v.address),
        TextCellValue(v.city),
        TextCellValue(v.state),
        TextCellValue(v.pincode),
        TextCellValue(v.createdAt.toIso8601String()),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook for vendors.');
    }
    return Uint8List.fromList(bytes);
  }
}
