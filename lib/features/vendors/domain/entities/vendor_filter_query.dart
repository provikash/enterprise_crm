import 'package:flutter/foundation.dart';
import 'vendor_record.dart';
import 'vendor_status.dart';

/// Encapsulates filtering, searching, and sorting parameters for vendors.
@immutable
class VendorFilterQuery {
  final String search;
  final VendorStatus? status;
  final String? category;
  final String sortField;
  final bool sortAscending;

  const VendorFilterQuery({
    this.search = '',
    this.status,
    this.category,
    this.sortField = 'name',
    this.sortAscending = true,
  });

  bool get isEmpty => search.trim().isEmpty && status == null && (category == null || category == 'All');

  bool matches(VendorRecord vendor) {
    if (status != null && vendor.status != status) {
      return false;
    }

    if (category != null && category != 'All' && vendor.category.toLowerCase() != category!.toLowerCase()) {
      return false;
    }

    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matchesName = vendor.companyName.toLowerCase().contains(query);
      final matchesCode = vendor.vendorCode.toLowerCase().contains(query);
      final matchesContact = vendor.contactPerson.toLowerCase().contains(query);
      final matchesGst = vendor.gstin.toLowerCase().contains(query);
      final matchesPhone = vendor.phone.contains(query);
      final matchesEmail = vendor.email.toLowerCase().contains(query);
      if (!matchesName && !matchesCode && !matchesContact && !matchesGst && !matchesPhone && !matchesEmail) {
        return false;
      }
    }

    return true;
  }

  VendorFilterQuery copyWith({
    String? search,
    VendorStatus? status,
    bool clearStatus = false,
    String? category,
    bool clearCategory = false,
    String? sortField,
    bool? sortAscending,
  }) {
    return VendorFilterQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
