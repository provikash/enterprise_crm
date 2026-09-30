import 'package:flutter/foundation.dart';

/// Immutable domain result model representing evaluated report output.
///
/// Encapsulates unmodifiable typed [rows], authoritative [totalCount],
/// generation timestamp, and optional context metadata.
@immutable
class ReportResult<T> {
  final List<T> rows;
  final int totalCount;
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;

  ReportResult({
    required List<T> rows,
    int? totalCount,
    DateTime? generatedAt,
    this.metadata,
  })  : rows = List.unmodifiable(rows),
        totalCount = totalCount ?? rows.length,
        generatedAt = (generatedAt ?? DateTime.now()).toUtc();

  /// Whether this report returned zero matching rows.
  bool get isEmpty => rows.isEmpty;

  /// Whether this report contains one or more matching rows.
  bool get isNotEmpty => rows.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportResult<T> &&
          runtimeType == other.runtimeType &&
          listEquals(rows, other.rows) &&
          totalCount == other.totalCount &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(rows),
        totalCount,
        generatedAt,
      );

  @override
  String toString() =>
      'ReportResult<$T>(totalCount: $totalCount, generatedAt: ${generatedAt.toIso8601String()})';
}
