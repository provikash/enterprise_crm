# HR-8.1 — HR / Payroll Reports Requirements Audit & Freeze

## 1. Purpose and Scope
This document defines the comprehensive requirements, data availability audit, aggregation contracts, export scopes, and authorization boundaries for **HR-8: HR / Payroll Reports & Export** in the Enterprise CRM application.
It acts as the authoritative contract before technical implementation begins in HR-8.2+.

---

## 2. Starting Git State
- **Branch:** `feature/hr-8-reports-export`
- **Starting HEAD:** `2935058` (`test(hr): prepare payroll calculation final UAT (HR-7.10)`)
- **Working Tree:** Clean (unrelated working files preserved unstaged).

---

## 3. Previous HR Dependency Status
- **HR-1 Core Architecture:** VERIFIED & FROZEN (`CrmModule.hrPayroll`, `HrAccessPolicy`).
- **HR-2 Employee Management:** VERIFIED & FROZEN (`Employee`, `EmployeeRepository`, `MockEmployeeStore`).
- **HR-3 Employee Documents:** VERIFIED & FROZEN (`EmployeeDocument`, `EmployeeDocumentRepository`).
- **HR-4 Attendance:** VERIFIED & FROZEN (`AttendanceRecord`, `AttendanceRepository`).
- **HR-5 KPI / Performance:** VERIFIED & FROZEN (`EmployeeKpi`, `KpiRepository`).
- **HR-6 Payroll Foundation:** VERIFIED & FROZEN (`PayrollRecord`, `PayrollPeriod`, `PayrollRepository`).
- **HR-7 Payroll Calculation:** IMPLEMENTED & FROZEN (`PayrollCalculationEngine`, `Money`, `PayrollComponent`, `PayrollCalculationPreviewScreen`).

---

## 4. Source Documents Reviewed
- `MASTER_DEVELOPMENT_RULES.md`
- `CRM_PRD.md`
- `CRM_TRD.md`
- `CRM_Backend_Schema.md`
- `HR_PAYROLL_REQUIREMENTS.md`
- `HR_6_FINAL_UAT_AND_FREEZE.md`
- `HR_7_CALCULATION_REQUIREMENTS.md`
- `HR_7_PAYROLL_INPUT_AND_POLICY_CONTRACT.md`
- `HR_7_CALCULATION_INTEGRITY_AUDIT.md`
- `HR_7_SECURITY_AND_CALCULATION_AUDIT.md`
- `HR_7_FINAL_UAT_AND_FREEZE.md`

---

## 5. Existing HR Data Inventory

| Domain Entity | Repository | Available Fields | Stable Key | Aggregation Feasibility | Export Feasibility |
|---|---|---|---|---|---|
| `Employee` | `EmployeeRepository` | `id`, `employeeCode`, `fullName`, `email`, `phone`, `department`, `designation`, `employmentStatus`, `joiningDate`, `userId` | `id` | Count by Dept, Status, Total Headcount | High (non-sensitive fields) |
| `EmployeeDocument` | `EmployeeDocumentRepository`| `id`, `employeeId`, `documentType`, `fileName`, `fileSizeBytes`, `uploadedAt`, `mimeType` | `id` | Count per employee / type | Metadata only; no binary blobs |
| `AttendanceRecord` | `AttendanceRepository` | `id`, `employeeId`, `date`, `attendanceStatus`, `checkInTime`, `checkOutTime`, `remarks` | `id` | Status counts per date / employee | High (status summaries) |
| `EmployeeKpi` | `KpiRepository` | `id`, `employeeId`, `metricTitle`, `targetValue`, `actualValue`, `unit`, `periodStartDate`, `periodEndDate` | `id` | Count, Target vs Actual where units match | High |
| `PayrollRecord` | `PayrollRepository` | `id`, `employeeId`, `payrollPeriodId`, `grossSalary`, `netSalary`, `totalAllowances`, `totalDeductions`, `currency`, `paymentStatus` | `id` | Stored currency totals by period | Strictly Gated (`payrollView` only) |
| `PayrollCalculationResult` | Domain (`PayrollCalculationEngine`) | `calculationId`, `employeeId`, `payrollPeriodId`, `grossEarnings`, `totalDeductions`, `netPayable`, `components` | `calculationId` | Non-final previews; not official reporting records | Preview only; not official report |

---

## 6. Report Requirements Classification
Requirements are classified strictly into:
1. **CONFIRMED:** Explicitly supported by approved requirements and available data models.
2. **PROPOSED:** Reasonable future directions, pending business sign-off.
3. **UNCONFIRMED:** Mentioned in roadmap but lacking detailed specifications.
4. **BACKEND-DEPENDENT:** Requires backend aggregation/database endpoints (HR-10).
5. **APPROVED DEFERRED:** Explicitly excluded from HR-8 scope.
6. **CONFLICTING:** Competing business interpretations.

---

## 7. Employee Reports Contract (CONFIRMED)
- **Approved Report:** Employee Directory Report (`employee_directory`).
- **Business Purpose:** Operational visibility into workforce distribution across departments, designations, and employment statuses.
- **Reported Fields:**
  - `id` (Stable Opaque ID)
  - `employeeCode` (Display code e.g. `EMP-001`)
  - `fullName` (Employee Name)
  - `department` (e.g. `Human Resources`, `Engineering`)
  - `designation` (e.g. `HR Manager`)
  - `employmentStatus` (Enum: `active`, `inactive`, `onLeave`, `terminated`)
  - `joiningDate` (UTC Date)
- **Sensitive Fields Excluded from Default Directory:** Personal phone, email, credentials, linked user IDs, salary data.
- **Approved Filters:**
  - `department`: Single/Multi match against known departments.
  - `employmentStatus`: Filter by `active`, `inactive`, `onLeave`, `terminated`.
  - `joiningDateRange`: Inclusive start and end date range.
  - `search`: Case-insensitive prefix/contains search on `fullName` and `employeeCode`.
- **Approved Sorting:** `fullName`, `employeeCode`, `department`, `joiningDate` (Ascending / Descending).
- **Approved Summaries:** Total Headcount (integer count of matching records).

---

## 8. Employee Document Reporting Contract (PROPOSED / DEFERRED)
- Document metadata reporting is classified as **APPROVED DEFERRED** for initial HR-8 checkpoints. No document files or binary URLs will be exported.

---

## 9. Attendance Reports Contract (CONFIRMED for HR-8.4)
- **Approved Scope:** Attendance Daily & Period Summary Report (`attendance_summary`).
- **Reported Fields:** `date`, `employeeId`, `employeeName`, `attendanceStatus` (`Present`, `Absent`, `HalfDay`, `Leave`), `checkInTime`, `checkOutTime`.
- **Aggregation Rules:** Count of days Present, Absent, HalfDay, Leave within period.
- **Rule Boundary:** Zero invented "attendance percentage" without an approved denominator contract. Missing attendance records will NOT be inferred as absent.

---

## 10. KPI / Performance Reports Contract (CONFIRMED for HR-8.5)
- **Approved Scope:** KPI Metric Status Report (`kpi_status`).
- **Reported Fields:** `employeeId`, `employeeName`, `metricTitle`, `targetValue`, `actualValue`, `unit`, `periodStartDate`, `periodEndDate`.
- **Aggregation Rules:** Only identical metrics with matching units may be summed or compared. Zero cross-metric averaging or leaderboard ranking.

---

## 11. Payroll Reports Contract (CONFIRMED for HR-8.6)
- **Approved Scope:** Payroll Summary by Period (`payroll_period_summary`).
- **Reported Fields:** `payrollPeriodId`, `employeeId`, `employeeName`, `grossSalary`, `totalAllowances`, `totalDeductions`, `netSalary`, `currency`, `paymentStatus`.
- **Aggregation Rules:** Sum of Gross, Deductions, and Net strictly grouped by ISO `currency`. Cross-currency summation is strictly prohibited.
- **Access Boundary:** Requires explicit `CrmPermissions.payrollView`.

---

## 12. Stored vs Calculated Data Rules
- Official Payroll Reports must consume stored, approved `PayrollRecord` data from `PayrollRepository`.
- `PayrollCalculationResult` from HR-7 is an interactive, non-final preview and cannot be reported as official financial records.
- Stored values are authoritative; the reporting layer performs zero client-side salary recomputations.

---

## 13. Aggregation Contract
- **Count:** Supported across all entity queries.
- **Sum:** Supported on monetary amounts within identical ISO currency codes and numeric metrics with identical units.
- **Average:** Prohibited for categorical IDs or mixed-unit KPI metrics.
- **Percentage:** Prohibited unless both numerator and denominator definitions are explicitly frozen.

---

## 14. Date and Period Contract
- All date boundaries are evaluated in UTC normalized midnight (`00:00:00.000Z` to `23:59:59.999Z`).
- Date ranges are inclusive: `startDate <= record.date <= endDate`.
- Payroll queries must reference valid `PayrollPeriod.id` records.

---

## 15. Search / Filter / Sort Requirements
- Search is local to loaded datasets and executes on public identifier fields (`fullName`, `employeeCode`).
- Filtering order:
  `Source Records` -> `Authorization Scope` -> `Filters (Dept, Status, Date)` -> `Search Query` -> `Sort Order`.
- Multi-filter combinations are applied conjunctively (`AND` logic).

---

## 16. Report Summary Requirements
- Only single-dimensional, unit-consistent summary metrics:
  - Employee Report: `Total Matching Employees` (Count).
  - Attendance Report: `Total Records`, `Total Present`, `Total Absent` (Counts).
  - Payroll Report: `Total Net Payout`, `Total Gross Payout` (Grouped by Currency).

---

## 17. Visualization Requirements
- Visual charts are classified as **PROPOSED / DEFERRED**. No third-party charting libraries will be introduced in HR-8.

---

## 18. Export Format Requirements
- **CSV:** Confirmed for tabular data export in HR-8.8.
- **Excel (XLSX):** Proposed / Deferred pending dependency evaluation in HR-8.8.
- **PDF:** Deferred to future scope. Zero official payslip generation in HR-8.

---

## 19. Export Field Contract
- Exports must contain only approved report columns.
- Personal phone numbers, home addresses, sensitive credentials, and internal passwords must never appear in exported files.

---

## 20. Authorization Matrix

| Report Capability | Required Permission | UI Enforcement | Repository Guard | Status |
|---|---|---|---|---|
| View Employee Directory Report | `CrmPermissions.hrView` | Gated route | Gated query | CONFIRMED |
| View Attendance Report | `CrmPermissions.hrView` | Gated route | Gated query | CONFIRMED |
| View KPI Report | `CrmPermissions.hrView` | Gated route | Gated query | CONFIRMED |
| View Payroll Summary Report | `CrmPermissions.payrollView` | Gated route | Gated query | CONFIRMED |
| Export Employee Report | `CrmPermissions.hrView` | Deferred to HR-8.9 | Deferred to HR-8.9 | DEFERRED |
| Export Payroll Report | `CrmPermissions.payrollView` | Deferred to HR-8.9 | Deferred to HR-8.9 | DEFERRED |

---

## 21. Sensitive Data Classification
- **Public / Operational:** Employee name, code, department, designation, employment status, joining date.
- **Sensitive Personal:** Email, phone, address, national IDs (excluded from standard directory reports).
- **Sensitive Financial:** Gross salary, net salary, allowances, deductions, bank accounts (restricted strictly to `payrollView`).

---

## 22. Frontend vs Backend Responsibilities
- **Frontend (Flutter):** Interactive filter controls, local list sorting, responsive presentation, error/empty states.
- **Backend (Future HR-10):** Scalable pagination over massive datasets (>10,000 records), multi-tenant data isolation, server-side PDF/Excel generation.

---

## 23. Performance and Pagination Requirements
- For datasets within memory (<1,000 records), in-memory filtering and sorting provide sub-millisecond responsiveness.
- Future backend query pagination (`page`, `pageSize`) contract defined in domain query structures.

---

## 24. Known-Answer Reporting Fixtures
Using `MockEmployeeStore`:
- Total seeded employees = 5.
- Sales & Marketing department = 2 (Charlie Davis [active], Evan Wright [inactive]).
- Active status filter = 3 (Alice Johnson, Bob Miller, Charlie Davis).
- Sales & Marketing + Active filter = 1 (Charlie Davis).

---

## 25. Open Questions and Conflicts
- None for Employee reporting.
- Currency conversion policies for multi-currency payroll remain unresolved; solved by strict currency grouping.

---

## 26. Explicitly Deferred Features
- PDF Payslip export (deferred to future HR payroll expansion).
- Performance leaderboard / employee ranking (deferred to business review).
- Dynamic SQL / custom report builder (out of scope).

---

## 27. HR-8.2–8.10 Dependency Map

| Subphase | Checkpoint | Prerequisite | Deliverable |
|---|---|---|---|
| HR-8.1 | Requirements Audit & Freeze | HR-7 Freeze | `HR_8_REPORTS_REQUIREMENTS.md` |
| HR-8.2 | Report Domain & Query Contract | HR-8.1 | Report entities, queries, repository interfaces |
| HR-8.3 | Employee Reports | HR-8.2 | Employee report screen, cubit, responsive tables |
| HR-8.4 | Attendance Reports | HR-8.2 | Attendance summary reporting |
| HR-8.5 | KPI / Performance Reports | HR-8.2 | KPI target vs actual reporting |
| HR-8.6 | Payroll Reports | HR-8.2, HR-7 | Stored payroll summary by period |
| HR-8.7 | Filters, Periods & Summaries | HR-8.3-8.6 | Unified filter bar and summary widgets |
| HR-8.8 | Export Foundation (CSV) | HR-8.2 | Clean CSV serializer and file downloader |
| HR-8.9 | Security, Privacy & Export Audit | HR-8.8 | Route guards, data sanitization audit |
| HR-8.10 | Final UAT & Feature Freeze | HR-8.9 | Complete regression, responsive verification |

---

## 28. HR-8.1 Exit Criteria
- [x] Git baseline recorded.
- [x] HR-7 status verified.
- [x] Existing HR data sources audited.
- [x] Report categories classified.
- [x] Employee reporting requirements documented.
- [x] Attendance reporting requirements documented.
- [x] KPI reporting requirements documented.
- [x] Payroll reporting requirements documented.
- [x] Aggregation rules reviewed.
- [x] Date/period requirements reviewed.
- [x] Filters/search/sort classified.
- [x] Export formats classified.
- [x] Sensitive fields classified.
- [x] Authorization requirements reviewed.
- [x] Frontend/backend responsibilities documented.
- [x] Known-answer report fixtures identified.
- [x] Open questions documented.
- [x] HR-8 dependency map created.
- [x] `HR_8_REPORTS_REQUIREMENTS.md` created.
- [x] Document reviewed for unsupported assumptions.
- [ ] Separate HR-8.1 Git commit created.

---

## 29. Mandatory Report Inventory Table

| Report ID | Report Name | Data Source | Required Fields | Filters | Aggregation | Access | Export | Status |
|---|---|---|---|---|---|---|---|---|
| `emp_dir` | Employee Directory Report | `EmployeeRepository` | `id`, `code`, `name`, `dept`, `desig`, `status`, `joiningDate` | Dept, Status, Date Range, Search | Total Count | `hrView` | CSV (HR-8.8) | CONFIRMED |
| `att_sum` | Attendance Summary Report | `AttendanceRepository` | `date`, `empId`, `status`, `times` | Period, Emp, Status | Status Counts | `hrView` | CSV (HR-8.8) | CONFIRMED (HR-8.4) |
| `kpi_stat` | KPI Performance Report | `KpiRepository` | `empId`, `metric`, `target`, `actual`, `unit` | Period, Emp, Metric | Sum / Compare | `hrView` | CSV (HR-8.8) | CONFIRMED (HR-8.5) |
| `pay_sum` | Payroll Summary Report | `PayrollRepository` | `periodId`, `empId`, `gross`, `ded`, `net`, `currency` | Period, Currency | Grouped Sums | `payrollView` | CSV (HR-8.8) | CONFIRMED (HR-8.6) |

---

## 30. Mandatory Export Matrix

| Report | CSV | XLSX | PDF | Sensitive? | Permission Decision |
|---|---|---|---|---|---|
| Employee Directory | Supported (HR-8.8) | Proposed | Deferred | No (Operational) | `hrView` |
| Attendance Summary | Supported (HR-8.8) | Proposed | Deferred | No | `hrView` |
| KPI Performance | Supported (HR-8.8) | Proposed | Deferred | Internal | `hrView` |
| Payroll Summary | Supported (HR-8.8) | Proposed | Deferred | HIGH (Financial) | `payrollView` ONLY |

---

## 31. Mandatory Authorization Matrix

| Report Capability | Approved Access | UI Enforcement | Backend Enforcement | Status |
|---|---|---|---|---|
| View Employee Directory | `CrmPermissions.hrView` | Route guard | Query check | CONFIRMED |
| View Attendance Report | `CrmPermissions.hrView` | Route guard | Query check | CONFIRMED |
| View KPI Report | `CrmPermissions.hrView` | Route guard | Query check | CONFIRMED |
| View Payroll Report | `CrmPermissions.payrollView` | Route guard | Query check | CONFIRMED |
| Export Employee Report | `CrmPermissions.hrView` | Deferred HR-8.9 | Deferred HR-8.9 | CONFIRMED |
| Export Payroll Report | `CrmPermissions.payrollView` | Deferred HR-8.9 | Deferred HR-8.9 | CONFIRMED |

---

## 32. Final Requirements Freeze Status
**COMPLETE AND FROZEN** (Scope for HR-8.2 through HR-8.10 is strictly defined).
