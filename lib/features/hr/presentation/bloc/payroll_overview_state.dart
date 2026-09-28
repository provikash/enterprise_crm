import 'package:flutter/foundation.dart';

import '../../domain/entities/payroll_record.dart';

/// Status lifecycle for the Payroll Overview state.
enum PayrollOverviewStatus {
  initial,
  loading,
  loaded,
  failure,
}

/// Immutable state for the Payroll Overview Cubit.
///
/// Follows HR-6.5 architectural constraints:
/// - Stably tracks [selectedPeriodId].
/// - Stores immutable repository-backed [records] without client-side salary calculations.
/// - Resolves employee names via [employeeNames] map.
/// - Supports real-time search filtering via [searchQuery].
/// - Prevents leaking raw exceptions via safe [errorMessage].
class PayrollOverviewState {
  final PayrollOverviewStatus status;
  final String? selectedPeriodId;
  final List<PayrollRecord> records;
  final String searchQuery;
  final Map<String, String> employeeNames;
  final String? errorMessage;

  const PayrollOverviewState({
    this.status = PayrollOverviewStatus.initial,
    this.selectedPeriodId,
    this.records = const [],
    this.searchQuery = '',
    this.employeeNames = const {},
    this.errorMessage,
  });

  /// Filtered records based on [searchQuery].
  ///
  /// Matches case-insensitively against:
  /// - Resolved employee full name
  /// - Associated [PayrollRecord.employeeId]
  /// - Stored [PayrollRecord.id]
  List<PayrollRecord> get filteredRecords {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return records;

    return records.where((record) {
      final empName = employeeNames[record.employeeId]?.toLowerCase() ?? '';
      final empId = record.employeeId.toLowerCase();
      final recordId = record.id.toLowerCase();

      return empName.contains(query) ||
          empId.contains(query) ||
          recordId.contains(query);
    }).toList(growable: false);
  }

  /// Whether the period query returned 0 records from the repository.
  bool get isEmpty =>
      status == PayrollOverviewStatus.loaded && records.isEmpty;

  /// Whether the search query returned 0 records while the period itself has records.
  bool get isSearchEmpty =>
      status == PayrollOverviewStatus.loaded &&
      records.isNotEmpty &&
      filteredRecords.isEmpty;

  /// Total record count for the selected period.
  int get recordCount => records.length;

  /// Filtered record count matching the current search query.
  int get filteredCount => filteredRecords.length;

  PayrollOverviewState copyWith({
    PayrollOverviewStatus? status,
    String? selectedPeriodId,
    bool clearSelectedPeriodId = false,
    List<PayrollRecord>? records,
    String? searchQuery,
    Map<String, String>? employeeNames,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollOverviewState(
      status: status ?? this.status,
      selectedPeriodId: clearSelectedPeriodId
          ? null
          : (selectedPeriodId ?? this.selectedPeriodId),
      records: records ?? this.records,
      searchQuery: searchQuery ?? this.searchQuery,
      employeeNames: employeeNames ?? this.employeeNames,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollOverviewState &&
        other.status == status &&
        other.selectedPeriodId == selectedPeriodId &&
        listEquals(other.records, records) &&
        other.searchQuery == searchQuery &&
        mapEquals(other.employeeNames, employeeNames) &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        selectedPeriodId,
        Object.hashAll(records),
        searchQuery,
        Object.hashAll(
          employeeNames.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        errorMessage,
      );

  @override
  String toString() =>
      'PayrollOverviewState(status: $status, period: $selectedPeriodId, count: ${records.length}, filtered: ${filteredRecords.length})';
}
