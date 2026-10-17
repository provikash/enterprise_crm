import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_summary.dart';

void main() {
  group('VendorSummary Aggregation Tests', () {
    test('computes counts and average rating accurately from vendor records', () {
      final now = DateTime(2026, 1, 1);
      final vendors = [
        VendorRecord(id: '1', vendorCode: 'VND-1', companyName: 'A', status: VendorStatus.active, rating: 5.0, createdAt: now),
        VendorRecord(id: '2', vendorCode: 'VND-2', companyName: 'B', status: VendorStatus.active, rating: 4.0, createdAt: now),
        VendorRecord(id: '3', vendorCode: 'VND-3', companyName: 'C', status: VendorStatus.underReview, rating: 3.0, createdAt: now),
        VendorRecord(id: '4', vendorCode: 'VND-4', companyName: 'D', status: VendorStatus.blacklisted, rating: 1.0, createdAt: now),
        VendorRecord(id: '5', vendorCode: 'VND-5', companyName: 'E', status: VendorStatus.inactive, rating: 2.0, createdAt: now),
      ];

      final summary = VendorSummary.fromRecords(vendors);

      expect(summary.totalVendors, 5);
      expect(summary.activeVendors, 2);
      expect(summary.underReviewVendors, 1);
      expect(summary.blacklistedVendors, 1);
      expect(summary.inactiveVendors, 1);
      expect(summary.averageRating, 3.0);
    });

    test('handles empty list cleanly', () {
      final summary = VendorSummary.fromRecords([]);
      expect(summary.totalVendors, 0);
      expect(summary.activeVendors, 0);
      expect(summary.averageRating, 0.0);
    });
  });
}
