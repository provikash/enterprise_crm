import 'package:flutter/foundation.dart';
import 'vendor_record.dart';
import 'vendor_status.dart';

/// Aggregated metrics across all vendors in the CRM.
@immutable
class VendorSummary {
  final int totalVendors;
  final int activeVendors;
  final int underReviewVendors;
  final int blacklistedVendors;
  final int inactiveVendors;
  final double averageRating;

  const VendorSummary({
    this.totalVendors = 0,
    this.activeVendors = 0,
    this.underReviewVendors = 0,
    this.blacklistedVendors = 0,
    this.inactiveVendors = 0,
    this.averageRating = 0.0,
  });

  factory VendorSummary.fromRecords(List<VendorRecord> records) {
    if (records.isEmpty) {
      return const VendorSummary();
    }

    int active = 0;
    int underReview = 0;
    int blacklisted = 0;
    int inactive = 0;
    double ratingSum = 0.0;

    for (final v in records) {
      switch (v.status) {
        case VendorStatus.active:
          active++;
          break;
        case VendorStatus.underReview:
          underReview++;
          break;
        case VendorStatus.blacklisted:
          blacklisted++;
          break;
        case VendorStatus.inactive:
          inactive++;
          break;
      }
      ratingSum += v.rating;
    }

    return VendorSummary(
      totalVendors: records.length,
      activeVendors: active,
      underReviewVendors: underReview,
      blacklistedVendors: blacklisted,
      inactiveVendors: inactive,
      averageRating: records.isEmpty ? 0.0 : ratingSum / records.length,
    );
  }
}
