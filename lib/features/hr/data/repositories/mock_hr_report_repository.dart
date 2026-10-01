import '../../domain/entities/attendance_report_query.dart';
import '../../domain/entities/attendance_report_row.dart';
import '../../domain/entities/attendance_report_summary.dart';
import '../../domain/entities/employee_report_query.dart';
import '../../domain/entities/employee_report_row.dart';
import '../../domain/entities/kpi_report_query.dart';
import '../../domain/entities/kpi_report_row.dart';
import '../../domain/entities/kpi_report_summary.dart';
import '../../domain/entities/payroll_report_query.dart';
import '../../domain/entities/payroll_report_row.dart';
import '../../domain/entities/payroll_report_summary.dart';
import '../../domain/entities/report_result.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'mock_attendance_repository.dart';
import 'mock_employee_kpi_repository.dart';
import 'mock_employee_repository.dart';
import 'mock_payroll_repository.dart';

/// In-memory mock implementation of [HrReportRepository].
///
/// Follows HR-8.2, HR-8.4, HR-8.5, and HR-8.6 architectural principles:
/// - Reuses existing [EmployeeRepository], [AttendanceRepository], [EmployeeKpiRepository], and [PayrollRepository].
/// - Purely functional filtering, searching, and sorting over authoritative entity records.
/// - Zero data mutation on underlying repositories.
class MockHrReportRepository implements HrReportRepository {
  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final EmployeeKpiRepository _kpiRepository;
  final PayrollRepository _payrollRepository;

  MockHrReportRepository({
    EmployeeRepository? employeeRepository,
    AttendanceRepository? attendanceRepository,
    EmployeeKpiRepository? kpiRepository,
    PayrollRepository? payrollRepository,
  })  : _employeeRepository = employeeRepository ?? MockEmployeeRepository(),
        _attendanceRepository =
            attendanceRepository ?? MockAttendanceRepository(),
        _kpiRepository = kpiRepository ?? MockEmployeeKpiRepository(),
        _payrollRepository = payrollRepository ?? MockPayrollRepository();

  @override
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(
    EmployeeReportQuery query,
  ) async {
    final employees = await _employeeRepository.getEmployees();

    // 1. Transform authoritative entities to report rows
    var rows = employees.map(EmployeeReportRow.fromEmployee).toList();

    // 2. Apply department filter
    if (query.department != null && query.department!.trim().isNotEmpty) {
      final deptFilter = query.department!.trim().toLowerCase();
      rows = rows
          .where((r) => r.department?.trim().toLowerCase() == deptFilter)
          .toList();
    }

    // 3. Apply employment status filter
    if (query.employmentStatus != null) {
      rows = rows
          .where((r) => r.employmentStatus == query.employmentStatus)
          .toList();
    }

    // 4. Apply joining date range filter
    if (query.joiningDateRange != null) {
      final range = query.joiningDateRange!;
      rows = rows
          .where((r) => r.joiningDate != null && range.contains(r.joiningDate!))
          .toList();
    }

    // 5. Apply search term filter (fullName or employeeCode)
    if (query.searchTerm != null && query.searchTerm!.trim().isNotEmpty) {
      final term = query.searchTerm!.trim().toLowerCase();
      rows = rows.where((r) {
        final nameMatch = r.fullName.toLowerCase().contains(term);
        final codeMatch =
            r.employeeCode?.toLowerCase().contains(term) ?? false;
        return nameMatch || codeMatch;
      }).toList();
    }

    // 6. Apply sorting
    final sort = query.sort ?? const ReportSort(field: 'fullName');
    rows.sort((a, b) {
      int comparison;
      switch (sort.field) {
        case 'employeeCode':
          final aCode = a.employeeCode ?? '';
          final bCode = b.employeeCode ?? '';
          comparison = aCode.compareTo(bCode);
          break;
        case 'department':
          final aDept = (a.department ?? '').toLowerCase();
          final bDept = (b.department ?? '').toLowerCase();
          comparison = aDept.compareTo(bDept);
          break;
        case 'designation':
          final aDesig = (a.designation ?? '').toLowerCase();
          final bDesig = (b.designation ?? '').toLowerCase();
          comparison = aDesig.compareTo(bDesig);
          break;
        case 'joiningDate':
          final aDate = a.joiningDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.joiningDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aDate.compareTo(bDate);
          break;
        case 'fullName':
        default:
          comparison = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          break;
      }

      return sort.direction.isDescending ? -comparison : comparison;
    });

    return ReportResult<EmployeeReportRow>(
      rows: rows,
      totalCount: rows.length,
      metadata: {
        'filteredCount': rows.length,
        'hasFilters': query.hasFilters,
      },
    );
  }

  @override
  Future<ReportResult<AttendanceReportRow>> getAttendanceReport(
    AttendanceReportQuery query,
  ) async {
    // 1. Retrieve records from AttendanceRepository
    final records = await _attendanceRepository.getAttendanceRecords(
      employeeId: query.employeeId,
      startDate: query.dateRange?.startDate,
      endDate: query.dateRange?.endDate,
      status: (query.status != null && query.status != 'All')
          ? query.status
          : null,
    );

    // 2. Fetch employee records to resolve names and codes
    final employees = await _employeeRepository.getEmployees();
    final employeeMap = {for (final e in employees) e.id: e};

    // 3. Map to AttendanceReportRow (Strict missing record integrity: no absent fabrication)
    var rows = records.map((record) {
      final emp = employeeMap[record.employeeId];
      return AttendanceReportRow.fromAttendanceRecord(
        record,
        employeeCode: emp?.employeeCode,
        employeeName: emp?.fullName ?? 'Unknown (${record.employeeId})',
      );
    }).toList();

    // 4. Apply search term filter on employeeName or employeeCode
    if (query.searchTerm != null && query.searchTerm!.trim().isNotEmpty) {
      final term = query.searchTerm!.trim().toLowerCase();
      rows = rows.where((r) {
        final nameMatch = r.employeeName.toLowerCase().contains(term);
        final codeMatch =
            r.employeeCode?.toLowerCase().contains(term) ?? false;
        return nameMatch || codeMatch;
      }).toList();
    }

    // 5. Apply status filter (ensuring case-insensitive match)
    if (query.status != null &&
        query.status!.trim().isNotEmpty &&
        query.status != 'All') {
      final targetStatus = query.status!.trim().toLowerCase();
      rows = rows
          .where((r) => r.attendanceStatus.trim().toLowerCase() == targetStatus)
          .toList();
    }

    // 6. Apply sorting
    final sort = query.sort ??
        const ReportSort(
          field: 'date',
          direction: ReportSortDirection.descending,
        );

    rows.sort((a, b) {
      int comparison;
      switch (sort.field) {
        case 'employeeName':
          comparison =
              a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
          break;
        case 'employeeCode':
          final aCode = a.employeeCode ?? '';
          final bCode = b.employeeCode ?? '';
          comparison = aCode.compareTo(bCode);
          break;
        case 'status':
          comparison = a.attendanceStatus
              .toLowerCase()
              .compareTo(b.attendanceStatus.toLowerCase());
          break;
        case 'date':
        default:
          comparison = a.attendanceDate.compareTo(b.attendanceDate);
          break;
      }
      return sort.direction.isDescending ? -comparison : comparison;
    });

    final summary = AttendanceReportSummary.fromRows(rows);

    return ReportResult<AttendanceReportRow>(
      rows: rows,
      totalCount: rows.length,
      metadata: {
        'summary': summary,
        'hasFilters': query.hasActiveFilters,
      },
    );
  }

  @override
  Future<ReportResult<KpiReportRow>> getKpiReport(
    KpiReportQuery query,
  ) async {
    // 1. Retrieve records from EmployeeKpiRepository
    final kpis = await _kpiRepository.getKpis(
      employeeId: query.employeeId,
      startDate: query.dateRange?.startDate,
      endDate: query.dateRange?.endDate,
    );

    // 2. Resolve employee records
    final employees = await _employeeRepository.getEmployees();
    final employeeMap = {for (final e in employees) e.id: e};

    // 3. Map to KpiReportRow (Strict score integrity: no recalculation)
    var rows = kpis.map((kpi) {
      final emp = employeeMap[kpi.employeeId];
      return KpiReportRow.fromEmployeeKpi(
        kpi,
        employeeCode: emp?.employeeCode,
        employeeName: emp?.fullName ?? 'Unknown (${kpi.employeeId})',
      );
    }).toList();

    // 4. Apply metricName filter
    if (query.metricName != null &&
        query.metricName!.trim().isNotEmpty &&
        query.metricName != 'All') {
      final targetMetric = query.metricName!.trim().toLowerCase();
      rows = rows
          .where((r) => r.metricName.trim().toLowerCase() == targetMetric)
          .toList();
    }

    // 5. Apply search term filter on employeeName, employeeCode, or metricName
    if (query.searchTerm != null && query.searchTerm!.trim().isNotEmpty) {
      final term = query.searchTerm!.trim().toLowerCase();
      rows = rows.where((r) {
        final nameMatch = r.employeeName.toLowerCase().contains(term);
        final codeMatch =
            r.employeeCode?.toLowerCase().contains(term) ?? false;
        final metricMatch = r.metricName.toLowerCase().contains(term);
        return nameMatch || codeMatch || metricMatch;
      }).toList();
    }

    // 6. Apply sorting
    final sort = query.sort ??
        const ReportSort(
          field: 'period',
          direction: ReportSortDirection.descending,
        );

    rows.sort((a, b) {
      int comparison;
      switch (sort.field) {
        case 'employeeName':
          comparison =
              a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
          break;
        case 'metricName':
          comparison =
              a.metricName.toLowerCase().compareTo(b.metricName.toLowerCase());
          break;
        case 'target':
          comparison = a.targetValue.compareTo(b.targetValue);
          break;
        case 'actual':
          comparison = a.actualValue.compareTo(b.actualValue);
          break;
        case 'score':
          final aScore = a.score ?? -1.0;
          final bScore = b.score ?? -1.0;
          comparison = aScore.compareTo(bScore);
          break;
        case 'period':
        default:
          comparison = a.periodStart.compareTo(b.periodStart);
          break;
      }
      return sort.direction.isDescending ? -comparison : comparison;
    });

    final summary = KpiReportSummary.fromRows(rows);

    return ReportResult<KpiReportRow>(
      rows: rows,
      totalCount: rows.length,
      metadata: {
        'summary': summary,
        'hasFilters': query.hasActiveFilters,
      },
    );
  }

  @override
  Future<ReportResult<PayrollReportRow>> getPayrollReport(
    PayrollReportQuery query,
  ) async {
    // 1. Retrieve records from PayrollRepository
    final periodFilter = (query.payrollPeriodId != null &&
            query.payrollPeriodId!.isNotEmpty &&
            query.payrollPeriodId != 'All')
        ? query.payrollPeriodId
        : null;

    final records = await _payrollRepository.getPayrollRecords(
      payrollPeriodId: periodFilter,
      employeeId: query.employeeId,
    );

    // 2. Resolve employee records and payroll periods
    final employees = await _employeeRepository.getEmployees();
    final employeeMap = {for (final e in employees) e.id: e};

    final periods = await _payrollRepository.getPayrollPeriods();
    final periodMap = {for (final p in periods) p.id: p};

    // 3. Map to PayrollReportRow (authoritative stored records only; zero client calculations)
    var rows = records.map((rec) {
      final emp = employeeMap[rec.employeeId];
      final period = periodMap[rec.payrollPeriodId];
      return PayrollReportRow.fromPayrollRecord(
        rec,
        employeeCode: emp?.employeeCode,
        employeeName: emp?.fullName ?? 'Unknown (${rec.employeeId})',
        periodName: period?.name ?? 'Period ${rec.payrollPeriodId}',
      );
    }).toList();

    // 4. Apply paymentStatus filter
    if (query.paymentStatus != null &&
        query.paymentStatus!.trim().isNotEmpty &&
        query.paymentStatus != 'All') {
      final targetStatus = query.paymentStatus!.trim().toLowerCase();
      rows = rows
          .where((r) => r.paymentStatus.trim().toLowerCase() == targetStatus)
          .toList();
    }

    // 5. Apply currency filter
    if (query.currency != null &&
        query.currency!.trim().isNotEmpty &&
        query.currency != 'All') {
      final targetCurrency = query.currency!.trim().toUpperCase();
      rows = rows
          .where((r) => r.currency.trim().toUpperCase() == targetCurrency)
          .toList();
    }

    // 6. Apply search term filter on employeeName, employeeCode, or record ID
    if (query.searchTerm != null && query.searchTerm!.trim().isNotEmpty) {
      final term = query.searchTerm!.trim().toLowerCase();
      rows = rows.where((r) {
        final nameMatch = r.employeeName.toLowerCase().contains(term);
        final codeMatch =
            r.employeeCode?.toLowerCase().contains(term) ?? false;
        final idMatch = r.id.toLowerCase().contains(term);
        return nameMatch || codeMatch || idMatch;
      }).toList();
    }

    // 7. Apply sorting
    final sort = query.sort ??
        const ReportSort(
          field: 'period',
          direction: ReportSortDirection.descending,
        );

    rows.sort((a, b) {
      int comparison;
      switch (sort.field) {
        case 'employee':
        case 'employeeName':
          comparison = a.employeeName
              .toLowerCase()
              .compareTo(b.employeeName.toLowerCase());
          break;
        case 'grossSalary':
          final aVal = a.grossSalary ?? -1.0;
          final bVal = b.grossSalary ?? -1.0;
          comparison = aVal.compareTo(bVal);
          break;
        case 'netSalary':
          final aVal = a.netSalary ?? -1.0;
          final bVal = b.netSalary ?? -1.0;
          comparison = aVal.compareTo(bVal);
          break;
        case 'paymentDate':
          final aDate =
              a.paymentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.paymentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aDate.compareTo(bDate);
          break;
        case 'period':
        default:
          final aPeriod = periodMap[a.payrollPeriodId];
          final bPeriod = periodMap[b.payrollPeriodId];
          if (aPeriod != null && bPeriod != null) {
            comparison = aPeriod.startDate.compareTo(bPeriod.startDate);
          } else {
            comparison = a.payrollPeriodId.compareTo(b.payrollPeriodId);
          }
          break;
      }
      return sort.direction.isDescending ? -comparison : comparison;
    });

    final summary = PayrollReportSummary.fromRows(rows);

    return ReportResult<PayrollReportRow>(
      rows: rows,
      totalCount: rows.length,
      metadata: {
        'summary': summary,
        'hasFilters': query.hasActiveFilters,
      },
    );
  }
}
