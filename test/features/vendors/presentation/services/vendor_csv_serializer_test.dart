import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/services/vendor_csv_serializer.dart';

void main() {
  group('VendorCsvSerializer Tests', () {
    const serializer = VendorCsvSerializer();

    test('serializes vendor list to standard CSV string with proper escaping', () {
      final vendors = [
        VendorRecord(
          id: '1',
          vendorCode: 'VND-001',
          companyName: 'Apex "Prime", Inc.',
          contactPerson: 'Vikram, Jr.',
          email: 'sales@apex.com',
          phone: '+91 98111 22334',
          gstin: '07AAAAA0000A1Z5',
          category: 'Electronics',
          status: VendorStatus.active,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final csv = serializer.convertToString(vendors);

      expect(csv, contains('Vendor Code,Company Name,Contact Person'));
      expect(csv, contains('VND-001'));
      // Escaped quotes and commas
      expect(csv, contains('"Apex ""Prime"", Inc."'));
      expect(csv, contains('"Vikram, Jr."'));
    });

    test('convertToBytes returns UTF-8 encoded bytes', () {
      final vendors = [
        VendorRecord(
          id: '1',
          vendorCode: 'VND-001',
          companyName: 'Apex',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final bytes = serializer.convertToBytes(vendors);
      final decoded = utf8.decode(bytes);

      expect(decoded, contains('VND-001'));
    });
  });
}
