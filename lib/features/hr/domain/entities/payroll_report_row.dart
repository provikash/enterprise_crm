import 'package:flutter/foundation.dart';

import 'payroll_record.dart';

/// Immutable domain row representing a single record in the Payroll Summary Report.
///
/// Follows HR-8.6 contract requirements:
/// - Stably identified by the underlying [PayrollRecord.id].
/// - Retains stable associations: [employeeId] and [payrollPeriodId].
/// - Enforces exact monetary values from authoritative stored records (no client-side calculation).
/// - Preserves distinction between missing/null values and explicit zeroes.
/// - Clear data source tagging: [source] explicitly identifies 'stored'.
@immutable
class PayrollReportRow {
  final String id;
  final String payrollPeriodId;
  final String periodName;
  final String employeeId;
  final String? employeeCode;
  final String employeeName;
  final double? grossSalary;
  final double? totalAllowances;
  final double? totalDeductions;
  final double? netSalary;
  final String currency;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String source;

  const PayrollReportRow({
    required this.id,
    required this.payrollPeriodId,
    required this.periodName,
    required this.employeeId,
    this.employeeCode,
    required this.employeeName,
    this.grossSalary,
    this.totalAllowances,
    this.totalDeductions,
    this.netSalary,
    required this.currency,
    required this.paymentStatus,
    this.paymentDate,
    this.source = 'stored',
  });

  /// Factory creating a [PayrollReportRow] from an authoritative [PayrollRecord].
  factory PayrollReportRow.fromPayrollRecord(
    PayrollRecord record, {
    String? employeeCode,
    required String employeeName,
    required String periodName,
  }) {
    return PayrollReportRow(
      id: record.id,
      payrollPeriodId: record.payrollPeriodId,
      periodName: periodName,
      employeeId: record.employeeId,
      employeeCode: employeeCode,
      employeeName: employeeName,
      grossSalary: record.grossSalary,
      totalAllowances: record.totalAllowances,
      totalDeductions: record.totalDeductions,
      netSalary: record.netSalary,
      currency: record.currency?.trim().isNotEmpty == true
          ? record.currency!.trim().toUpperCase()
          : 'USD',
      paymentStatus: record.paymentStatus ?? 'Pending',
      paymentDate: record.paymentDate,
      source: 'stored',
    );
  }

  /// Formatted payment date in 'YYYY-MM-DD' format, or '-' if absent.
  String get formattedPaymentDate {
    if (paymentDate == null) return '-';
    final y = paymentDate!.year.toString().padLeft(4, '0');
    final m = paymentDate!.month.toString().padLeft(2, '0');
    final d = paymentDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formatted gross salary with currency code, or '-' if null.
  String get formattedGrossSalary {
    if (grossSalary == null) return '-';
    return '$currency ${grossSalary!.toStringAsFixed(2)}';
  }

  /// Formatted net salary with currency code, or '-' if null.
  String get formattedNetSalary {
    if (netSalary == null) return '-';
    return '$currency ${netSalary!.toStringAsFixed(2)}';
  }

  /// Formatted total allowances with currency code, or '-' if null.
  String get formattedAllowances {
    if (totalAllowances == null) return '-';
    return '$currency ${totalAllowances!.toStringAsFixed(2)}';
  }

  /// Formatted total deductions with currency code, or '-' if null.
  String get formattedDeductions {
    if (totalDeductions == null) return '-';
    return '$currency ${totalDeductions!.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollReportRow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          payrollPeriodId == other.payrollPeriodId &&
          periodName == other.periodName &&
          employeeId == other.employeeId &&
          employeeCode == other.employeeCode &&
          employeeName == other.employeeName &&
          grossSalary == other.grossSalary &&
          totalAllowances == other.totalAllowances &&
          totalDeductions == other.totalDeductions &&
          netSalary == other.netSalary &&
          currency == other.currency &&
          paymentStatus == other.paymentStatus &&
          paymentDate == other.paymentDate &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
        id,
        payrollPeriodId,
        periodName,
        employeeId,
        employeeCode,
        employeeName,
        grossSalary,
        totalAllowances,
        totalDeductions,
        netSalary,
        currency,
        paymentStatus,
        paymentDate,
        source,
      );
}
