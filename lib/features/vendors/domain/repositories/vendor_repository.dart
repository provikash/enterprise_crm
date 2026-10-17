import '../entities/vendor_filter_query.dart';
import '../entities/vendor_record.dart';
import '../entities/vendor_summary.dart';

/// Abstract repository defining data contract for Vendor master management.
abstract class VendorRepository {
  /// Fetches a list of vendors matching the provided [query].
  Future<List<VendorRecord>> getVendors({
    VendorFilterQuery query = const VendorFilterQuery(),
  });

  /// Computes summary analytics across all vendors.
  Future<VendorSummary> getVendorSummary();

  /// Retrieves a single vendor by [id], or `null` if not found.
  Future<VendorRecord?> getVendorById(String id);

  /// Creates and persists a new [vendor].
  Future<VendorRecord> createVendor(VendorRecord vendor);

  /// Updates an existing [vendor].
  Future<VendorRecord> updateVendor(VendorRecord vendor);

  /// Deletes or deactivates a vendor by [id].
  Future<bool> deleteVendor(String id);
}
