import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_filter_query.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';

void main() {
  group('VendorFilterQuery Domain Tests', () {
    final sampleVendor = VendorRecord(
      id: 'vnd_1',
      vendorCode: 'VND-001',
      companyName: 'Apex Industrial Supplies',
      contactPerson: 'Vikram Malhotra',
      email: 'vikram@apex.com',
      phone: '+91 98111 22334',
      gstin: '07AAAAA0000A1Z5',
      category: 'Electronics',
      status: VendorStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    test('default query matches all vendors', () {
      const query = VendorFilterQuery();
      expect(query.isEmpty, isTrue);
      expect(query.matches(sampleVendor), isTrue);
    });

    test('matches by substring in companyName, code, contact, GSTIN, phone, and email', () {
      expect(const VendorFilterQuery(search: 'apex').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: 'VND-001').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: 'Vikram').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: '07AAAAA').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: '98111').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: 'vikram@apex').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(search: 'nonexistent').matches(sampleVendor), isFalse);
    });

    test('matches status filter', () {
      expect(const VendorFilterQuery(status: VendorStatus.active).matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(status: VendorStatus.blacklisted).matches(sampleVendor), isFalse);
    });

    test('matches category filter', () {
      expect(const VendorFilterQuery(category: 'Electronics').matches(sampleVendor), isTrue);
      expect(const VendorFilterQuery(category: 'Furniture').matches(sampleVendor), isFalse);
      expect(const VendorFilterQuery(category: 'All').matches(sampleVendor), isTrue);
    });

    test('copyWith updates and clears filters cleanly', () {
      const query = VendorFilterQuery(
        search: 'test',
        status: VendorStatus.underReview,
        category: 'Hardware',
      );

      final cleared = query.copyWith(clearStatus: true, clearCategory: true);
      expect(cleared.status, isNull);
      expect(cleared.category, isNull);
      expect(cleared.search, 'test');
    });
  });
}
