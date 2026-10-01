# HR-8.7 Report Filters, Periods & Summaries Audit

## 1. Purpose
This audit document captures the standardized verification of report querying, filtering, date/period handling, and summary metrics across all implemented HR reports in the Enterprise CRM Flutter application:
- Employee Directory Report (HR-8.3)
- Attendance Summary Report (HR-8.4)
- KPI Performance Report (HR-8.5)
- Payroll Summary Report (HR-8.6)

The objective of HR-8.7 is to unify shared query mechanisms, prevent stale asynchronous updates, preserve domain-specific period models without inappropriate collapsing, verify multi-currency/unit calculation safety, and enforce consistent filter clearing/reset behavior across all reporting surfaces.

---

## 2. Starting Git Baseline
- **Branch:** `feature/hr-8-reports-export`
- **HR-8.5 Commit:** `7684d59` (`feat(hr): implement kpi reports (HR-8.5)`)
- **HR-8.6 Commit:** `548517a` (`feat(hr): implement payroll reports (HR-8.6)`)
- **Starting HEAD for HR-8.7:** `548517a`

---

## 3. Reports Reviewed
1. **Employee Directory Report**:
   - Query: `EmployeeReportQuery`
   - Row: `EmployeeReportRow`
   - State/Cubit: `EmployeeReportCubit` / `EmployeeReportState`
   - Screen: `EmployeeReportScreen`
2. **Attendance Summary Report**:
   - Query: `AttendanceReportQuery`
   - Row: `AttendanceReportRow`
   - Summary: `AttendanceReportSummary`
   - State/Cubit: `AttendanceReportCubit` / `AttendanceReportState`
   - Screen: `AttendanceReportScreen`
3. **KPI Performance Report**:
   - Query: `KpiReportQuery`
   - Row: `KpiReportRow`
   - Summary: `KpiReportSummary`
   - State/Cubit: `KpiReportCubit` / `KpiReportState`
   - Screen: `KpiReportScreen`
4. **Payroll Summary Report**:
   - Query: `PayrollReportQuery`
   - Row: `PayrollReportRow`
   - Summary: `PayrollReportSummary` / `PayrollCurrencySummary`
   - State/Cubit: `PayrollReportCubit` / `PayrollReportState`
   - Screen: `PayrollReportScreen`

---

## 4. Filter Matrix

| Filter Capability | Employee Directory | Attendance Summary | KPI Performance | Payroll Summary | Standardization Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Search** | Name, Code, Email | Employee Name, Code | Employee Name, Code | Employee Name, Code, Record ID | `VERIFIED` |
| **Employee ID** | N/A (Directory is employee list) | `employeeId` | `employeeId` | `employeeId` | `VERIFIED` |
| **Department** | `department` | N/A | N/A | N/A | `VERIFIED` |
| **Status / Category** | `employmentStatus` | `status` (Present/Absent/etc.) | `metricName` | `paymentStatus` | `VERIFIED` |
| **Date Range / Period** | `joiningDateRange` (`ReportDateRange`) | `dateRange` (`ReportDateRange`) | `dateRange` (`ReportDateRange`) | `payrollPeriodId` (`PayrollPeriod`) | `VERIFIED` |
| **Currency** | N/A | N/A | N/A | `currency` | `VERIFIED` |
| **Sorting** | `ReportSort` | `ReportSort` | `ReportSort` | `ReportSort` | `VERIFIED` |
| **State Inspection** | `hasFilters` / `hasActiveFilters` | `hasFilters` / `hasActiveFilters` | `hasFilters` / `hasActiveFilters` | `hasFilters` / `hasActiveFilters` | `FIXED AND RETESTED` |
| **Reset / Clear** | `clearFilters()` / `resetFilters()` | `clearFilters()` / `resetFilters()` | `clearFilters()` / `resetFilters()` | `clearFilters()` / `resetFilters()` | `FIXED AND RETESTED` |

---

## 5. Search Behavior
- **Implementation**: Text input triggers query update with trimmed search string; empty/whitespace queries clear the active search filter.
- **Searchable Attributes**: Limited strictly to non-sensitive identifiers (Employee Name, Code, and Record ID). Sensitive financial or performance values are never searchable.
- **Intersection**: Search combines with other active filters using boolean AND conjunction.
- **Status**: `VERIFIED`

---

## 6. Sorting Behavior
- **Implementation**: Structured `ReportSort(field, direction)` abstraction from HR-8.2 used uniformly across all four reports.
- **Null Safety**: Null values sort safely without unhandled exceptions.
- **Financial/Performance Sorting**: Directional sorting on salaries or scores does NOT generate qualitative ranking labels (e.g., no "best employee" or "worst salary" classifications).
- **Status**: `VERIFIED`

---

## 7. Date-Range Contract
- **Model**: `ReportDateRange` with non-null `start` and `end` `DateTime` boundaries.
- **Inclusivity**: Comparisons evaluate `date >= start && date <= end` (inclusive).
- **Time Normalization**: Date components normalized to UTC or start-of-day/end-of-day bounds to prevent fractional millisecond omissions.
- **Status**: `VERIFIED`

---

## 8. KPI Period Behavior
- **Domain Independence**: KPI evaluation ranges use `ReportDateRange` indicating evaluation start and end dates.
- **Separation**: KPI periods are not collapsed into Payroll periods, acknowledging distinct organizational cadence (quarterly/biannual vs. monthly payroll).
- **Status**: `VERIFIED`

---

## 9. PayrollPeriod Behavior
- **Model**: Distinct `PayrollPeriod` entity with stable string `id`, `name`, `startDate`, `endDate`, and optional `paymentDate`.
- **Authoritative Selection**: Filtering operates on stable `payrollPeriodId` values, never on formatted UI strings or client-synthesized month dates.
- **Status**: `VERIFIED`

---

## 10. Reset / Default Query Behavior
- **Implementation**: Every Cubit exposes both `clearFilters()` and `resetFilters()`.
- **Contract**: Calling reset returns the query to its respective `defaultQuery` (or empty default), immediately dispatches a fresh single evaluation, and cleanses stale state.
- **State Inspection**: Both `hasFilters` and `hasActiveFilters` return `false` on default query state across all 4 report queries.
- **Status**: `FIXED AND RETESTED`

---

## 11. Stale-Request Protection
- **Mechanism**: Monotonically increasing `_activeRequestId` tracking in every report Cubit.
- **Protection**: If request $A$ finishes after subsequent request $B$, request $A$'s response is silently dropped to prevent race conditions during rapid filter adjustments.
- **Integration Test**: Verified under rapid consecutive filter selections (`test/features/hr/presentation/integration/report_filters_and_summaries_test.dart`).
- **Status**: `VERIFIED`

---

## 12. Employee Report Summaries
- **Metrics**: Total matching employee count (`totalCount`).
- **Safety**: No unapproved workforce metrics (attrition, retention rate, tenure averages) fabricated.
- **Status**: `VERIFIED`

---

## 13. Attendance Summaries
- **Metrics**: `totalRecords`, `presentCount`, `absentCount`, `halfDayCount`, `onLeaveCount`.
- **Integrity**: Missing days are NOT treated as absences. No speculative "attendance percentage" calculated.
- **Status**: `VERIFIED`

---

## 14. KPI Summaries
- **Metrics**: `totalRecords` (evaluated KPI entries).
- **Safety**: Incompatible metrics with different target units (e.g., currency vs. percentage vs. hours) are NOT averaged into an invalid composite score.
- **Status**: `VERIFIED`

---

## 15. Payroll Summaries
- **Metrics**: `totalRecords` and currency-segregated breakdown (`currencySummaries` mapping ISO currency codes to `PayrollCurrencySummary`).
- **Authoritative Source**: Stored `PayrollRecord` entity aggregates; calculation preview results are never aggregated as authoritative historical payroll.
- **Status**: `VERIFIED`

---

## 16. Missing vs. Zero Handling
- **Preservation**: Optional financial figures (`grossSalary`, `netSalary`, `totalAllowances`, `totalDeductions`) remain `null` when not populated.
- **No Fabrication**: Missing payroll records or unrecorded attendance are not synthesized as `0.0` or absences.
- **Status**: `VERIFIED`

---

## 17. Currency Aggregation Safety
- **Strict Rule**: No cross-currency addition. Monetary totals are partitioned strictly by `currency` (e.g., USD distinct from INR).
- **Summary**: `PayrollReportSummary.currencySummaries` produces discrete `PayrollCurrencySummary` records for each unique currency present in the matching row subset.
- **Status**: `VERIFIED`

---

## 18. Authorization Boundary
- **Policy Enforcement**: `HrAccessPolicy` controls entry at both navigation points and screen builds (`HrAccessPolicy.canViewPayroll`, `HrAccessPolicy.canViewKpi`, `HrAccessPolicy.canViewAttendance`, `HrAccessPolicy.canViewEmployees`).
- **Data Filtering**: Unauthorized users receive forbidden state or are blocked from executing privileged report queries.
- **Status**: `VERIFIED`

---

## 19. Responsive Verification
- **Mobile (<600px)**: Compact stacked cards with flexible wraps; no RenderFlex overflow on 320x568 or 360x640 viewports.
- **Desktop (>=600px)**: Multi-column `DataTable` with horizontal scroll wrappers and clearly aligned headers.
- **Theme Support**: Verified under Light and Dark theme palettes.
- **Status**: `VERIFIED`

---

## 20. Defects Found
1. **Divergent State Inspection Getters**: `EmployeeReportQuery` exposed `hasFilters`, while `AttendanceReportQuery`, `KpiReportQuery`, and `PayrollReportQuery` exposed `hasActiveFilters`.
2. **Inconsistent Reset Methods**: `EmployeeReportCubit`, `AttendanceReportCubit`, and `KpiReportCubit` exposed `clearFilters()`, whereas `PayrollReportCubit` exposed `resetFilters()`.
3. **Cubit Constructor Dependency Naming**: `EmployeeReportCubit`, `AttendanceReportCubit`, and `KpiReportCubit` accepted `repository:`, while `PayrollReportCubit` accepted `reportRepository:`.
4. **Mobile Layout Overflow in Payroll Screen**: Long formatted monetary rows caused RenderFlex overflows on 320px screens.

---

## 21. Fixes Applied
1. Added unified `hasActiveFilters` / `hasFilters` aliases across all 4 report queries.
2. Added `resetFilters()` and `clearFilters()` aliases across all 4 report cubits.
3. Updated `PayrollReportCubit` constructor to support `repository:` alongside `reportRepository:`.
4. Refactored mobile cards in `PayrollReportScreen` to use responsive `Wrap` and `FittedBox` components.
5. Added comprehensive cross-report integration test suite `test/features/hr/presentation/integration/report_filters_and_summaries_test.dart`.

---

## 22. Remaining Blockers
- None. All requirements for HR-8.7 are satisfied.

---

## 23. Backend Dependencies
- Reporting currently operates over deterministic mock repositories (`MockHrReportRepository`, `MockPayrollRepository`, etc.). Future instructor backend integration will map `HrReportRepository` directly to backend query endpoints.

---

## 24. HR-8.7 Exit Criteria
- [x] HR-8.6 verified and committed (`548517a`).
- [x] Shared filter behavior audited across all 4 reports.
- [x] Stable IDs used for entity filtering.
- [x] Date-range semantics consistent and inclusive.
- [x] KPI period remains domain-specific (`ReportDateRange`).
- [x] PayrollPeriod remains domain-specific (`PayrollPeriod.id`).
- [x] Search behavior verified (non-sensitive fields only).
- [x] Sorting behavior verified.
- [x] Clear/reset behavior verified uniformly.
- [x] Combined filters intersection verified (AND conjunction).
- [x] Stale request protection verified via requestId tracking.
- [x] Employee summaries verified (`totalCount`).
- [x] Attendance summaries verified (counts only, no invented percentages).
- [x] KPI aggregation safety verified (no cross-unit composite averages).
- [x] Payroll currency safety verified (isolated currency breakdowns).
- [x] Missing vs zero semantics preserved.
- [x] Authorization remains enforced (`HrAccessPolicy`).
- [x] Responsive filter layout verified.
- [x] Cross-report regression passes.
- [x] Audit document created (`HR_8_REPORT_FILTERS_AND_SUMMARIES_AUDIT.md`).
- [ ] Separate HR-8.7 commit created.

---

## 25. Commit Reference
- **HR-8.6 Commit:** `548517a` (`feat(hr): implement payroll reports (HR-8.6)`)
- **HR-8.7 Commit:** *Pending completion of verification step*
