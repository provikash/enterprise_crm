import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/presentation/services/vendor_xlsx_serializer.dart';

void main() {
  group('VendorXlsxSerializer Tests', () {
    const serializer = VendorXlsxSerializer();

    test('serializes vendor list to valid non-empty XLSX byte array', () {
      final vendors = [
        VendorRecord(
          id: '1',
          vendorCode: 'VND-001',
          companyName: 'Apex Tech Supplies',
          contactPerson: 'Vikram Malhotra',
          email: 'sales@apex.com',
          phone: '+91 98111 22334',
          gstin: '07AAAAA0000A1Z5',
          category: 'Electronics',
          status: VendorStatus.active,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final bytes = serializer.convertToBytes(vendors);
      expect(bytes, isNotEmpty);
      // PK Zip archive signature
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });
}
