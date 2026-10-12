import 'package:flutter/foundation.dart';
import 'purchase_order_status.dart';

/// Query parameters for searching, filtering, and paginating purchase orders.
@immutable
class PurchaseFilterQuery {
  final String? searchText;
  final PurchaseOrderStatus? status;
  final String? vendorName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const PurchaseFilterQuery({
    this.searchText,
    this.status,
    this.vendorName,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 5,
  })  : assert(page >= 1, 'Page must be 1 or greater'),
        assert(pageSize >= 1, 'PageSize must be 1 or greater');

  PurchaseFilterQuery copyWith({
    String? searchText,
    PurchaseOrderStatus? status,
    String? vendorName,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
    bool clearStatus = false,
  }) {
    return PurchaseFilterQuery(
      searchText: searchText ?? this.searchText,
      status: clearStatus ? null : (status ?? this.status),
      vendorName: vendorName ?? this.vendorName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseFilterQuery &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          status == other.status &&
          vendorName == other.vendorName &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(
        searchText,
        status,
        vendorName,
        startDate,
        endDate,
        page,
        pageSize,
      );
}
