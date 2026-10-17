import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';

void main() {
  group('VendorRecord Domain Entity Tests', () {
    test('instantiates with required fields and defaults', () {
      final now = DateTime(2026, 1, 1);
      final vendor = VendorRecord(
        id: 'vnd_1',
        vendorCode: 'VND-001',
        companyName: 'Acme Supplies',
        createdAt: now,
      );

      expect(vendor.id, 'vnd_1');
      expect(vendor.vendorCode, 'VND-001');
      expect(vendor.companyName, 'Acme Supplies');
      expect(vendor.status, VendorStatus.active);
      expect(vendor.category, 'General');
      expect(vendor.paymentTerms, 'Net 30');
      expect(vendor.creditLimitInr, 0.0);
      expect(vendor.rating, 4.0);
      expect(vendor.createdAt, now);
      expect(vendor.updatedAt, isNull);
    });

    test('copyWith updates specified fields correctly', () {
      final now = DateTime(2026, 1, 1);
      final vendor = VendorRecord(
        id: 'vnd_1',
        vendorCode: 'VND-001',
        companyName: 'Acme Supplies',
        createdAt: now,
      );

      final updated = vendor.copyWith(
        companyName: 'Acme Global Supplies',
        status: VendorStatus.underReview,
        rating: 4.8,
        creditLimitInr: 500000.0,
      );

      expect(updated.id, 'vnd_1');
      expect(updated.companyName, 'Acme Global Supplies');
      expect(updated.status, VendorStatus.underReview);
      expect(updated.rating, 4.8);
      expect(updated.creditLimitInr, 500000.0);
    });

    test('equality and hashCode match based on id, code, companyName and status', () {
      final now = DateTime(2026, 1, 1);
      final v1 = VendorRecord(
        id: 'vnd_1',
        vendorCode: 'VND-001',
        companyName: 'Acme',
        status: VendorStatus.active,
        createdAt: now,
      );

      final v2 = VendorRecord(
        id: 'vnd_1',
        vendorCode: 'VND-001',
        companyName: 'Acme',
        status: VendorStatus.active,
        createdAt: now.add(const Duration(days: 1)),
      );

      final v3 = VendorRecord(
        id: 'vnd_2',
        vendorCode: 'VND-002',
        companyName: 'Beta',
        createdAt: now,
      );

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1 == v3, isFalse);
    });
  });
}
