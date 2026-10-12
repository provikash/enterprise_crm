import 'package:flutter/foundation.dart';
import '../../domain/entities/dispatch_filter_query.dart';
import '../../domain/entities/dispatch_record.dart';
import '../../domain/entities/dispatch_summary.dart';

/// Base state for the Dispatch list view.
@immutable
sealed class DispatchListState {
  final DispatchFilterQuery query;
  final DispatchSummary summary;

  const DispatchListState({
    required this.query,
    this.summary = const DispatchSummary.empty(),
  });
}

/// Initial state prior to fetching dispatches.
final class DispatchListInitial extends DispatchListState {
  const DispatchListInitial({
    super.query = const DispatchFilterQuery(),
    super.summary,
  });
}

/// State emitted while dispatches or metrics are loading.
final class DispatchListLoading extends DispatchListState {
  const DispatchListLoading({
    required super.query,
    super.summary,
  });
}

/// State emitted when dispatch records have been loaded.
final class DispatchListLoaded extends DispatchListState {
  final List<DispatchRecord> dispatches;
  final int totalCount;

  const DispatchListLoaded({
    required super.query,
    required super.summary,
    required this.dispatches,
    required this.totalCount,
  });

  int get totalPages => (totalCount / query.pageSize).ceil().clamp(1, 9999);

  bool get isEmpty => dispatches.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispatchListLoaded &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          summary == other.summary &&
          listEquals(dispatches, other.dispatches) &&
          totalCount == other.totalCount;

  @override
  int get hashCode =>
      Object.hash(query, summary, Object.hashAll(dispatches), totalCount);
}

/// State emitted when fetching dispatches encounters an error.
final class DispatchListFailure extends DispatchListState {
  final String message;

  const DispatchListFailure({
    required super.query,
    super.summary,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispatchListFailure &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          summary == other.summary &&
          message == other.message;

  @override
  int get hashCode => Object.hash(query, summary, message);
}
