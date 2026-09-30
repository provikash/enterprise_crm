import '../../domain/entities/employee_report_query.dart';
import '../../domain/entities/employee_report_row.dart';
import '../../domain/entities/report_result.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import 'mock_employee_repository.dart';

/// In-memory mock implementation of [HrReportRepository].
///
/// Follows HR-8.2 architectural principles:
/// - Reuses existing [EmployeeRepository] to prevent data duplication.
/// - Purely functional filtering, searching, and sorting over authoritative entity records.
/// - Zero data mutation on underlying repositories.
class MockHrReportRepository implements HrReportRepository {
  final EmployeeRepository _employeeRepository;

  MockHrReportRepository({
    EmployeeRepository? employeeRepository,
  }) : _employeeRepository = employeeRepository ?? MockEmployeeRepository();

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
}
