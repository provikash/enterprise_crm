import '../../domain/entities/vendor_filter_query.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_summary.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../mock/mock_vendors.dart';

/// In-memory mock implementation of [VendorRepository].
class MockVendorRepository implements VendorRepository {
  final List<VendorRecord> _vendors;

  MockVendorRepository({List<VendorRecord>? initialVendors})
      : _vendors = initialVendors ?? MockVendorDataSource.generateSeedVendors();

  @override
  Future<List<VendorRecord>> getVendors({
    VendorFilterQuery query = const VendorFilterQuery(),
  }) async {
    final filtered = _vendors.where((v) => query.matches(v)).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (query.sortField) {
        case 'code':
          cmp = a.vendorCode.compareTo(b.vendorCode);
          break;
        case 'rating':
          cmp = a.rating.compareTo(b.rating);
          break;
        case 'created':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'name':
        default:
          cmp = a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase());
          break;
      }
      return query.sortAscending ? cmp : -cmp;
    });

    return List.unmodifiable(filtered);
  }

  @override
  Future<VendorSummary> getVendorSummary() async {
    return VendorSummary.fromRecords(_vendors);
  }

  @override
  Future<VendorRecord?> getVendorById(String id) async {
    final index = _vendors.indexWhere((v) => v.id == id);
    if (index == -1) return null;
    return _vendors[index];
  }

  @override
  Future<VendorRecord> createVendor(VendorRecord vendor) async {
    final id = vendor.id.isEmpty ? 'vnd_${DateTime.now().millisecondsSinceEpoch}' : vendor.id;
    final code = vendor.vendorCode.isEmpty ? 'VND-${(_vendors.length + 1).toString().padLeft(3, '0')}' : vendor.vendorCode;

    final newVendor = vendor.copyWith(
      id: id,
      vendorCode: code,
      createdAt: DateTime.now(),
    );

    _vendors.insert(0, newVendor);
    return newVendor;
  }

  @override
  Future<VendorRecord> updateVendor(VendorRecord vendor) async {
    final index = _vendors.indexWhere((v) => v.id == vendor.id);
    if (index == -1) {
      throw ArgumentError('Vendor with ID ${vendor.id} not found.');
    }

    final updated = vendor.copyWith(updatedAt: DateTime.now());
    _vendors[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteVendor(String id) async {
    final index = _vendors.indexWhere((v) => v.id == id);
    if (index == -1) return false;
    _vendors.removeAt(index);
    return true;
  }
}
