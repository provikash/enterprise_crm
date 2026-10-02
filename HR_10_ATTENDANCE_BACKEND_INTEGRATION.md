# HR-10.6 — Attendance Backend Integration Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Attendance Backend Integration  
**Status:** `IMPLEMENTED — LIVE UAT PENDING`

---

## 1. Purpose and Scope

This document details the backend communication contracts, data transfer models, domain mappings, date/timezone normalization invariants, security policies, and controlled cutover mechanism established for **HR-10.6: Attendance Backend Integration** in the Enterprise CRM Flutter application.

Building upon the backend foundation established in HR-10.1 through HR-10.5, HR-10.6 connects the Attendance Management feature (HR-4) to the instructor backend:
1. **`AttendanceRecordDto`** (`lib/features/hr/data/dto/attendance_record_dto.dart`): Strict serialization and validation boundary parsing backend JSON structures, validating mandatory keys (`id`, `employee_id`, `date`, `status`), and normalizing calendar dates to UTC midnight.
2. **`BackendAttendanceRepository`** (`lib/features/hr/data/repositories/backend_attendance_repository.dart`): Production-compatible implementation of `AttendanceRepository` connecting listing, filtering, date range queries, employee queries, single record inspection, and attendance recording to the backend API (`/hr/attendance`).
3. **Controlled Mock / Backend Cutover**: Introduction of `AttendanceRepositoryFactory` (`lib/features/hr/data/repositories/attendance_repository_factory.dart`) ensuring explicit mode selection without silent fallback to mock data on backend failure.
4. **Data Integrity & Payroll Isolation**: Preserves the critical invariant that missing attendance records are never fabricated as 'Absent', and strictly excludes all payroll calculations, overtime formulas, and salary deductions from the attendance layer.
5. **Cubit & Screen Wiring**: Direct compatibility with `AttendanceListCubit`, `AttendanceListScreen`, `AttendanceDetailsDialog`, and `AttendanceReportCubit`.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.6):** `6ac4bd6f127426ec8b20eb209f53fc14ef473931` (`feat(hr): integrate employee documents backend (HR-10.5)`)
- **HR-10.1 Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`
- **HR-10.3 Commit:** `326adc3ea6dca1375d86290ea8111e5ae5d78627`
- **HR-10.4 Commit:** `90f80a1334c9c277bf8238612711dc10d8a55dbb`
- **HR-10.5 Commit:** `6ac4bd6f127426ec8b20eb209f53fc14ef473931`

---

## 3. HR-10.5 Dependency Status

| Checkpoint | Status | Delivery |
| :--- | :--- | :--- |
| HR-10.1 Audit | `VERIFIED` | Document & commit `54edb65` |
| HR-10.2 Connection | `VERIFIED` | `ApiClient`, `BackendConfig`, `NetworkException`, commit `55288ab` |
| HR-10.3 Adapter | `VERIFIED` | `BackendEmployeeRepository` base, commit `326adc3` |
| HR-10.4 Employee | `VERIFIED` | Full Employee CRUD & controlled cutover, commit `90f80a1` |
| HR-10.5 Documents | `VERIFIED` | Document listing, details, upload, download, commit `6ac4bd6` |

---

## 4. Existing Attendance Architecture

| Screen / Component | Role | Interface Method | Integration State |
| :--- | :--- | :--- | :--- |
| `AttendanceListScreen` | Main Attendance view (List & Calendar) | `getAttendanceRecords()` | Backend-backed via `BackendAttendanceRepository` |
| `AttendanceListCubit` | Query and filter state management | `getAttendanceRecords()` | Backend-backed via `BackendAttendanceRepository` |
| `AttendanceDetailsDialog` | Single record inspection | `getAttendanceById()` | Backend-backed via `BackendAttendanceRepository` |
| `AttendanceReportScreen` | Attendance reports and aggregations | `getAttendanceRecords()` | Reuses domain repository |

---

## 5. Verified Backend API Contracts

Derived from `CRM_Backend_Schema.md` §10 and `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §14:
- **`GET /api/v1/hr/attendance`**: Returns JSON array or envelope of attendance records matching query parameters (`employee_id`, `start_date`, `end_date`, `status`, `page`, `page_size`).
- **`GET /api/v1/hr/attendance/{id}`**: Returns single attendance record JSON object or `{ "data": { ... } }`.
- **`POST /api/v1/hr/attendance`**: Creates or updates an attendance record (`id`, `employee_id`, `date`, `status`, `check_in`, `check_out`, `remarks`).

---

## 6. Implemented Operations

1. `getAttendanceRecords({employeeId, startDate, endDate, status})`: Queries records with optional server-side filters.
2. `getAttendanceById(String id)`: Fetches record metadata or returns `null` on HTTP 404 Not Found.
3. `getAttendanceForEmployee(String employeeId, {startDate, endDate})`: Scoped employee query.
4. `getAttendanceForDate(DateTime date)`: Scoped single calendar date query with normalized UTC date string.
5. `recordAttendance(AttendanceRecord record)`: Submits attendance record to backend via POST.

---

## 7. Attendance DTO Mapping

`AttendanceRecordDto` maps:
- `id` -> `AttendanceRecord.id` (mandatory)
- `employee_id` -> `AttendanceRecord.employeeId` (mandatory)
- `date` -> `AttendanceRecord.date` (normalized to UTC midnight `DateTime.utc(year, month, day)`)
- `status` -> `AttendanceRecord.attendanceStatus` (mandatory string value object)
- `check_in` -> `AttendanceRecord.checkIn` (parsed from ISO-8601 UTC string)
- `check_out` -> `AttendanceRecord.checkOut` (parsed from ISO-8601 UTC string)
- `remarks` -> `AttendanceRecord.remarks`
- `recorded_by` -> `AttendanceRecord.recordedBy`

---

## 8. Employee / Attendance Identity

- **`employeeId`**: Foreign key pointing to internal workforce record (`Employee.id`).
- **`id` / `attendanceId`**: Stable primary key of the attendance record.
- **Invariant**: Attendance records are never identified solely by employee name or list index.

---

## 9. Status Mapping

- Values supported: `'Present'`, `'Half-day'`, `'Absent'`, `'On Leave'`.
- Status mapping preserves string value-object conventions without hardcoded closed enum restrictions.

---

## 10. Date and Timezone Semantics

- **Normalized Calendar Date**: Every attendance record's `date` property is normalized to midnight UTC (`DateTime.utc(date.year, date.month, date.day)`).
- **Timezone Invariance**: Eliminates off-by-one day boundary errors across device local timezones (e.g. IST vs UTC).
- **Check-in / Check-out**: Full ISO-8601 UTC timestamps preserved without loss of precision.

---

## 11. Attendance Listing & Filtering

- `AttendanceListCubit.loadAttendance()` calls `repository.getAttendanceRecords()`.
- Supports filtering by `employeeId`, `startDate`, `endDate`, and `status`.
- Local filtering in `AttendanceListCubit` provides instant UI reaction while backend parameters reduce network payload size.

---

## 12. Pagination

- Unpacks direct JSON lists (`[...]`) and paginated envelopes (`{"items": [...], "total": ...}`).

---

## 13. Creation and Update

- `recordAttendance` submits the attendance entry to `POST /hr/attendance`.
- Translates HTTP 409 Conflict to `AttendanceException('Conflict detected: attendance record already exists for this date.')`.

---

## 14. HR-9 Approval Integration

- Attendance corrections requiring managerial review continue to route through `HrApprovalRepository` (`workflowType: 'attendance_correction'`).
- Direct mutations to finalized attendance records do not bypass required approval gates.

---

## 15. Missing vs. Absent Semantics

- **Critical Invariant**: Missing attendance entries are NEVER fabricated as 'Absent'.
- An empty query result indicates that no record has been created for that date, not that the employee was absent.

---

## 16. Payroll Boundary

- Zero payroll calculations, salary deductions, payable day computations, or overtime pay formulas are executed in the Attendance layer.
- Payroll reconciliation remains strictly isolated in HR-6 and HR-7.

---

## 17. HR-8 Reports Compatibility

- `AttendanceReportScreen` and `AttendanceReportCubit` query `AttendanceRepository`.
- Because `BackendAttendanceRepository` implements `AttendanceRepository` with identical return types, report summaries remain completely operational.

---

## 18. Authorization & Session Isolation

- Inherits `ApiClient` Bearer token injection.
- HTTP 403 Forbidden is translated to `AttendanceException('Access denied: You do not have permission...')`.
- Zero mutable static caching prevents cross-session leakage.

---

## 19. Mock / Backend Controlled Cutover

Implemented via `AttendanceRepositoryFactory`:
```dart
class AttendanceRepositoryFactory {
  static AttendanceRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockAttendanceStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendAttendanceRepository(apiClient: apiClient);
    }
    return MockAttendanceRepository(store: mockStore);
  }
}
```
Invariants:
- When `BackendMode.backend`, `BackendAttendanceRepository` is used.
- When `BackendMode.mock`, `MockAttendanceRepository` is used.
- ZERO silent fallback to mock data on backend network failure.

---

## 20. Platform Verification (Android & Web)

- `flutter build apk --config-only` PASSED cleanly.
- `flutter build web` PASSED cleanly.
- Pure Dart network transport with zero platform-incompatible dependencies.

---

## 21. Automated Tests

- **`attendance_record_dto_test.dart`:** 6 / 6 PASS.
- **`backend_attendance_repository_test.dart`:** 15 / 15 PASS.
- **`attendance_backend_integration_test.dart`:** 4 / 4 PASS.
- **Total New HR-10.6 Tests:** 25 / 25 PASS.
- **Full CRM Regression Suite:** 2,127 / 2,127 PASS.

---

## 22. Manual UAT Status

| Checkpoint / Feature | Test Type | Status | Evidence |
| :--- | :--- | :--- | :--- |
| Attendance List View | Automated / Mock Transport | `PASS` | `attendance_backend_integration_test.dart` |
| Attendance Calendar View | Automated / Mock Transport | `PASS` | `attendance_backend_integration_test.dart` |
| Status Filtering | Automated / Mock Transport | `PASS` | `attendance_backend_integration_test.dart` |
| Record Attendance (POST) | Automated / Mock Transport | `PASS` | `backend_attendance_repository_test.dart` |
| Failure & Retry Handling | Automated / Mock Transport | `PASS` | `attendance_backend_integration_test.dart` |
| Controlled Cutover Factory | Automated / Unit | `PASS` | `backend_attendance_repository_test.dart` |
| Live Physical Server UAT | Live Hardware / Server | `NOT TESTED` | Live instructor server pending deployment |

Overall Manual UAT Status: `IMPLEMENTED — LIVE UAT PENDING`

---

## 23. Exit Criteria Checklist

- [x] HR-10.5 verified and committed.
- [x] Attendance API contract verified.
- [x] Existing HR-4 domain preserved.
- [x] Existing `AttendanceRepository` interface reused.
- [x] Approved DTO mapping implemented (`AttendanceRecordDto`).
- [x] Employee/Attendance IDs preserved.
- [x] Approved read operations integrated.
- [x] Approved filters integrated.
- [x] Date/timezone semantics verified (UTC midnight normalization).
- [x] Missing records not fabricated as Absent.
- [x] Approved writes integrated (`recordAttendance`).
- [x] HR-9 approval rules respected.
- [x] No Attendance-to-Payroll calculations added.
- [x] Existing Attendance Reports regression verified.
- [x] Authorization maintained.
- [x] Session isolation verified.
- [x] Mock mode preserved.
- [x] No backend-mode mock fallback.
- [x] Controlled cutover factory implemented (`AttendanceRepositoryFactory`).
- [x] Automated tests pass (25 / 25 HR-10.6 tests).
- [x] Full regression passes (2,127 / 2,127 tests).
- [x] Android config passes.
- [x] Web build passes.
- [x] Deliverable document created (`HR_10_ATTENDANCE_BACKEND_INTEGRATION.md`).

---

## 24. Git Commit Reference

- **Commit Message:** `feat(hr): integrate attendance backend (HR-10.6)`
