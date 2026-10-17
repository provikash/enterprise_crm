import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/vendor_record.dart';

/// Pure-Dart serializer generating standard RFC-4180 CSV representations of vendors.
class VendorCsvSerializer {
  const VendorCsvSerializer();

  String convertToString(List<VendorRecord> vendors) {
    final buffer = StringBuffer();

    // CSV Header row
    buffer.writeln(
      'Vendor Code,Company Name,Contact Person,Email,Phone,Alternate Phone,GSTIN,PAN,Category,Payment Terms,Credit Limit (INR),Bank Name,Account Number,IFSC,City,State,Status,Rating,Notes',
    );

    for (final v in vendors) {
      final fields = [
        v.vendorCode,
        v.companyName,
        v.contactPerson,
        v.email,
        v.phone,
        v.alternatePhone,
        v.gstin,
        v.pan,
        v.category,
        v.paymentTerms,
        v.creditLimitInr.toStringAsFixed(2),
        v.bankName,
        v.accountNumber,
        v.ifscCode,
        v.city,
        v.state,
        v.status.displayName,
        v.rating.toStringAsFixed(1),
        v.notes,
      ];

      buffer.writeln(fields.map(_escapeCsvField).join(','));
    }

    return buffer.toString();
  }

  Uint8List convertToBytes(List<VendorRecord> vendors) {
    return Uint8List.fromList(utf8.encode(convertToString(vendors)));
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
}
