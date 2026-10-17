import 'package:flutter/foundation.dart';
import '../../domain/entities/vendor_filter_query.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_summary.dart';

@immutable
sealed class VendorListState {
  const VendorListState();
}

class VendorListInitial extends VendorListState {
  const VendorListInitial();
}

class VendorListLoading extends VendorListState {
  const VendorListLoading();
}

class VendorListLoaded extends VendorListState {
  final List<VendorRecord> vendors;
  final VendorSummary summary;
  final VendorFilterQuery query;
  final bool isExporting;

  const VendorListLoaded({
    required this.vendors,
    required this.summary,
    required this.query,
    this.isExporting = false,
  });

  VendorListLoaded copyWith({
    List<VendorRecord>? vendors,
    VendorSummary? summary,
    VendorFilterQuery? query,
    bool? isExporting,
  }) {
    return VendorListLoaded(
      vendors: vendors ?? this.vendors,
      summary: summary ?? this.summary,
      query: query ?? this.query,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class VendorListError extends VendorListState {
  final String message;
  const VendorListError(this.message);
}
