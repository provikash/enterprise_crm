import 'package:flutter/foundation.dart';

/// Aggregated metric summary displayed in KPI cards across the Purchase workspace.
@immutable
class PurchaseSummary {
  final int totalOrders;
  final int draftCount;
  final int pendingApprovalCount;
  final int approvedCount;
  final int orderedCount;
  final int receivedCount;
  final double totalSpendAmount;

  const PurchaseSummary({
    this.totalOrders = 0,
    this.draftCount = 0,
    this.pendingApprovalCount = 0,
    this.approvedCount = 0,
    this.orderedCount = 0,
    this.receivedCount = 0,
    this.totalSpendAmount = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseSummary &&
          runtimeType == other.runtimeType &&
          totalOrders == other.totalOrders &&
          draftCount == other.draftCount &&
          pendingApprovalCount == other.pendingApprovalCount &&
          approvedCount == other.approvedCount &&
          orderedCount == other.orderedCount &&
          receivedCount == other.receivedCount &&
          totalSpendAmount == other.totalSpendAmount;

  @override
  int get hashCode => Object.hash(
        totalOrders,
        draftCount,
        pendingApprovalCount,
        approvedCount,
        orderedCount,
        receivedCount,
        totalSpendAmount,
      );
}
