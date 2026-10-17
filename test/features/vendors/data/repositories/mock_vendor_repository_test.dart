import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/vendors/data/repositories/mock_vendor_repository.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_filter_query.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_record.dart';
import 'package:enterprise_crm/features/vendors/domain/entities/vendor_status.dart';

void main() {
  group('MockVendorRepository Tests', () {
    late MockVendorRepository repository;

    setUp(() {
      repository = MockVendorRepository();
    });

    test('initializes with seed vendors', () async {
      final vendors = await repository.getVendors();
      expect(vendors, isNotEmpty);
      expect(vendors.any((v) => v.companyName.contains('Apex')), isTrue);
    });

    test('filters vendors by search substring', () async {
      final filtered = await repository.getVendors(
        query: const VendorFilterQuery(search: 'Apex'),
      );
      expect(filtered.length, 1);
      expect(filtered.first.companyName, 'Apex Tech Supplies Pvt Ltd');
    });

    test('filters vendors by status', () async {
      final blacklisted = await repository.getVendors(
        query: const VendorFilterQuery(status: VendorStatus.blacklisted),
      );
      expect(blacklisted.every((v) => v.status == VendorStatus.blacklisted), isTrue);
    });

    test('sorts vendors ascending and descending', () async {
      final sortedAsc = await repository.getVendors(
        query: const VendorFilterQuery(sortField: 'rating', sortAscending: true),
      );
      expect(sortedAsc.first.rating <= sortedAsc.last.rating, isTrue);

      final sortedDesc = await repository.getVendors(
        query: const VendorFilterQuery(sortField: 'rating', sortAscending: false),
      );
      expect(sortedDesc.first.rating >= sortedDesc.last.rating, isTrue);
    });

    test('createVendor adds new vendor with generated ID and code', () async {
      final newVendor = await repository.createVendor(
        VendorRecord(
          id: '',
          vendorCode: '',
          companyName: 'New Horizon Components',
          createdAt: DateTime.now(),
        ),
      );

      expect(newVendor.id, isNotEmpty);
      expect(newVendor.vendorCode, isNotEmpty);

      final fetched = await repository.getVendorById(newVendor.id);
      expect(fetched, isNotNull);
      expect(fetched!.companyName, 'New Horizon Components');
    });

    test('updateVendor updates existing record and sets updatedAt', () async {
      final vendors = await repository.getVendors();
      final target = vendors.first;

      final updated = await repository.updateVendor(
        target.copyWith(companyName: 'Updated Company Name'),
      );

      expect(updated.companyName, 'Updated Company Name');
      expect(updated.updatedAt, isNotNull);

      final fetched = await repository.getVendorById(target.id);
      expect(fetched!.companyName, 'Updated Company Name');
    });

    test('deleteVendor removes vendor by ID', () async {
      final vendors = await repository.getVendors();
      final target = vendors.first;

      final result = await repository.deleteVendor(target.id);
      expect(result, isTrue);

      final fetched = await repository.getVendorById(target.id);
      expect(fetched, isNull);
    });

    test('getVendorSummary returns accurate aggregated totals', () async {
      final summary = await repository.getVendorSummary();
      expect(summary.totalVendors, greaterThan(0));
      expect(summary.activeVendors, greaterThan(0));
    });
  });
}
