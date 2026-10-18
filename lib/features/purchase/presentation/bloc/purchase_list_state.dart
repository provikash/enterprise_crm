import 'package:flutter/foundation.dart';
import '../../domain/entities/purchase_filter_query.dart';
import '../../domain/entities/purchase_order_record.dart';
import '../../domain/entities/purchase_summary.dart';

/// Base state for the Purchase list view.
@immutable
sealed class PurchaseListState {
  final PurchaseFilterQuery query;
  final PurchaseSummary summary;

  const PurchaseListState({
    required this.query,
    this.summary = const PurchaseSummary.empty(),
  });
}

/// Initial state prior to fetching purchase orders.
final class PurchaseListInitial extends PurchaseListState {
  const PurchaseListInitial({
    super.query = const PurchaseFilterQuery(),
    super.summary,
  });
}

/// State emitted while purchase orders or summary metrics are loading.
final class PurchaseListLoading extends PurchaseListState {
  const PurchaseListLoading({
    required super.query,
    super.summary,
  });
}

/// State emitted when purchase orders have been loaded successfully.
final class PurchaseListLoaded extends PurchaseListState {
  final List<PurchaseOrderRecord> orders;
  final int totalCount;

  const PurchaseListLoaded({
    required super.query,
    required super.summary,
    required this.orders,
    required this.totalCount,
  });

  int get totalPages => (totalCount / query.pageSize).ceil().clamp(1, 9999);

  bool get isEmpty => orders.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseListLoaded &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          summary == other.summary &&
          listEquals(orders, other.orders) &&
          totalCount == other.totalCount;

  @override
  int get hashCode =>
      Object.hash(query, summary, Object.hashAll(orders), totalCount);
}

/// State emitted when fetching purchase orders encounters an error.
final class PurchaseListFailure extends PurchaseListState {
  final String message;

  const PurchaseListFailure({
    required super.query,
    super.summary,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseListFailure &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          summary == other.summary &&
          message == other.message;

  @override
  int get hashCode => Object.hash(query, summary, message);
}
