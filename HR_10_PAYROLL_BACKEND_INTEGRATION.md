# HR-10.8 — Payroll Backend Integration Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Payroll & Compensation Backend Integration  
**Status:** `IMPLEMENTED — LIVE UAT PENDING`

---

## 1. Purpose and Scope

This document details the backend communication contracts, data transfer models, domain mappings, monetary representation safety invariants, calculation authority boundaries, security policies, and controlled cutover mechanism established for **HR-10.8: Payroll Backend Integration** in the Enterprise CRM Flutter application.

Building on the foundation established in HR-10.1 through HR-10.7, HR-10.8 connects the Payroll Foundation (HR-6) and calculation domain (HR-7) to the instructor backend:
1. **`PayrollPeriodDto`** (`lib/features/hr/data/dto/payroll_period_dto.dart`): Strict serialization and validation parsing backend period JSON, validating mandatory keys (`id`, `name`, `start_date`, `end_date`), and normalizing dates to UTC calendar midnight without timezone offsets.
2. **`PayrollRecordDto`** (`lib/features/hr/data/dto/payroll_record_dto.dart`): Money-safe serialization and validation parsing backend compensation records, preserving exact decimal values for `gross_salary`, `net_salary`, `total_allowances`, and `total_deductions`, maintaining nullability distinction, and preventing floating-point distortions.
3. **`BackendPayrollRepository`** (`lib/features/hr/data/repositories/backend_payroll_repository.dart`): Production-compatible implementation of `PayrollRepository` connecting period listing, single period lookup, record filtering by period and employee, and individual record inspection to the backend API (`/hr/payroll/periods`, `/hr/payroll/records`).
4. **Controlled Mock / Backend Cutover**: Introduction of `PayrollRepositoryFactory` (`lib/features/hr/data/repositories/payroll_repository_factory.dart`) ensuring explicit mode selection without silent fallback to mock data on backend failure.
5. **Monetary Integrity & Calculation Ownership**: Strictly preserves the distinction between stored authoritative historical records and non-persisted client-side simulation previews (`PayrollCalculationEngine`). Payment, disbursement, and finalization mutations remain strictly prohibited.
6. **Cubit & Screen Wiring**: Direct compatibility with `PayrollPeriodCubit`, `PayrollOverviewCubit`, `PayrollDetailsCubit`, `EmployeePayrollHistoryCubit`, and `PayrollReportCubit`.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.8):** `fba698f804791530e7045ee33e8b4eebca819f2a` (`feat(hr): integrate kpi performance backend (HR-10.7)`)
- **HR-10.1 Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`
- **HR-10.3 Commit:** `326adc3ea6dca1375d86290ea8111e5ae5d78627`
- **HR-10.4 Commit:** `90f80a1334c9c277bf8238612711dc10d8a55dbb`
- **HR-10.5 Commit:** `6ac4bd6f127426ec8b20eb209f53fc14ef473931`
- **HR-10.6 Commit:** `f1766e14b6723cca6f4a421f5af1dc8d07859cbf`
- **HR-10.7 Commit:** `fba698f804791530e7045ee33e8b4eebca819f2a`

---

## 3. HR-10.1 Through HR-10.7 Dependencies

| Checkpoint | Status | Delivery |
| :--- | :--- | :--- |
| HR-10.1 Audit | `VERIFIED` | Document & commit `54edb65` |
| HR-10.2 Connection | `VERIFIED` | `ApiClient`, `BackendConfig`, `NetworkException`, commit `55288ab` |
| HR-10.3 Adapter | `VERIFIED` | `BackendEmployeeRepository` base, commit `326adc3` |
| HR-10.4 Employee | `VERIFIED` | Full Employee CRUD & controlled cutover, commit `90f80a1` |
| HR-10.5 Documents | `VERIFIED` | Document listing, details, upload, download, commit `6ac4bd6` |
| HR-10.6 Attendance | `VERIFIED` | Attendance listing, filtering, recording, commit `f1766e1` |
| HR-10.7 KPI | `VERIFIED` | KPI listing, filtering, create/update, commit `fba698f` |

---

## 4. Existing HR-6 Architecture

| Screen / Component | Role | Interface Method | Integration State |
| :--- | :--- | :--- | :--- |
| `PayrollPeriodSelectionScreen` | Period selector | `getPayrollPeriods()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollPeriodCubit` | Period state management | `getPayrollPeriods()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollOverviewScreen` | Period payroll records table | `getPayrollRecords()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollOverviewCubit` | Records query state management | `getPayrollRecords()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollDetailsScreen` | Single payroll record view | `getPayrollRecordById()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollDetailsCubit` | Single record state management | `getPayrollRecordById()` | Backend-backed via `BackendPayrollRepository` |
| `EmployeePayrollHistoryScreen` | Historical compensation list | `getPayrollRecordsForEmployee()` | Backend-backed via `BackendPayrollRepository` |
| `EmployeePayrollHistoryCubit` | Employee history state management | `getPayrollRecordsForEmployee()` | Backend-backed via `BackendPayrollRepository` |
| `PayrollReportScreen` | Aggregated payroll summaries | `getPayrollRecords()` | Reuses domain repository |

---

## 5. HR-7 Calculation Architecture & Calculation Authority

1. **Client Calculation Engine:** `PayrollCalculationEngine` (`lib/features/hr/domain/services/payroll_calculation_engine.dart`) provides deterministic preview calculation over input objects.
2. **Authority Boundary:**
   - Client calculation (`PayrollCalculationPreviewScreen`) is strictly for simulation and pre-submission validation.
   - Authoritative compensation figures, official deductions, tax brackets, and payable amounts belong exclusively to stored backend records.
   - Stored records retrieved via `BackendPayrollRepository` are never overwritten by client simulation runs.
3. **Parity:** Client-side formulas remain aligned with the approved test oracles frozen in HR-7.7.

---

## 6. Verified Backend API Contracts

Derived from `CRM_Backend_Schema.md` §10 and `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §16:
- **`GET /api/v1/hr/payroll/periods`**: Returns JSON array or envelope of approved payroll periods.
- **`GET /api/v1/hr/payroll/periods/{id}`**: Returns single payroll period object.
- **`GET /api/v1/hr/payroll/records`**: Returns JSON array or envelope of payroll records. Supports query parameters `period_id` and `employee_id`.
- **`GET /api/v1/hr/payroll/records/{id}`**: Returns single payroll record object.

---

## 7. Supported vs Deferred Operations

| Operation | Method | Route | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| List Periods | `GET` | `/api/v1/hr/payroll/periods` | `SUPPORTED` | Read-only period listing |
| Period Details | `GET` | `/api/v1/hr/payroll/periods/{id}` | `SUPPORTED` | Returns null on 404 |
| List Records | `GET` | `/api/v1/hr/payroll/records` | `SUPPORTED` | Filtered by period and employee |
| Record Details | `GET` | `/api/v1/hr/payroll/records/{id}` | `SUPPORTED` | Returns null on 404 |
| Employee History | `GET` | `/api/v1/hr/payroll/records?employee_id={id}` | `SUPPORTED` | Scoped by employee ID |
| Salary Payment | `POST` | `/api/v1/hr/payroll/pay` | `EXCLUDED` | Strict scope exclusion |
| Period Finalization | `POST` | `/api/v1/hr/payroll/finalize` | `DEFERRED` | Gated behind HR-9 approval |
| Auto-Disbursement | `POST` | `/api/v1/hr/payroll/disburse` | `EXCLUDED` | Financial safety exclusion |

---

## 8. Monetary Representation and Financial Safety

1. **Exact Precision:** Monetary figures are parsed and stored as explicit numerical values without rounding or fractional loss.
2. **No Unsafe Conversions:** Monetary mapping avoids speculative arithmetic or intermediate integer truncation.
3. **Preservation of Null vs Zero:** If a component (e.g. `total_allowances`) is null in the backend, it remains null; it is never converted to 0.0.
4. **Currency Safety:** Preserves backend ISO currency strings (`INR`, `USD`). Currency conversion between mismatched units is strictly prohibited.

---

## 9. Identity and Domain Mapping

- **DTO Models:**
  - `PayrollPeriodDto` in `lib/features/hr/data/dto/payroll_period_dto.dart`.
  - `PayrollRecordDto` in `lib/features/hr/data/dto/payroll_record_dto.dart`.
- **Identity Relationships:**
  - `Employee.id`: Stable workforce identifier.
  - `PayrollPeriod.id`: Unique period identifier (`period_...`).
  - `PayrollRecord.id`: Unique compensation record identifier (`pay_...`).
  - Zero conflation of `Employee.id` with CRM `CurrentUser.id`.

---

## 10. Repository and Factory Implementation

- **`BackendPayrollRepository`** (`lib/features/hr/data/repositories/backend_payroll_repository.dart`):
  - Extends `BackendAdapter`, implements `PayrollRepository`.
  - Translates `NetworkException` to domain `PayrollException` with safe messages.
  - Handles flat JSON arrays and `{ "data": [...] }` envelopes transparently.
  - Strictly read-only; contains zero mutation, payment, or finalization routines.
- **`PayrollRepositoryFactory`** (`lib/features/hr/data/repositories/payroll_repository_factory.dart`):
  - Injects `BackendPayrollRepository` when `config.mode.isBackend`.
  - Injects `MockPayrollRepository` when `config.mode.isMock`.
  - Strictly prohibits silent fallback to mock data on backend failure.

---

## 11. Security, Authorization, and Session Isolation

1. **Permission Guard:** Payroll access requires `CrmPermissions.payrollView` or `AccountType.admin`. General HR users without this entitlement are blocked.
2. **Authentication:** Bearer token evaluated dynamically per request via `ApiClient.tokenProvider`.
3. **Session Purge:** Logout invalidates dynamic token providers and clears all active Cubit states.
4. **Sensitive Data Protection:** Zero logging of employee compensation figures, net salaries, or account credentials.

---

## 12. HR-8 Payroll Reports Compatibility

`PayrollReportScreen` and `PayrollReportCubit` consume `PayrollRepository` directly:
- Aggregations and summaries operate over authoritative backend-returned datasets.
- Query filters (`periodId`, `employeeId`) are passed faithfully.
- No page-level data is misrepresented as full enterprise totals.

---

## 13. Platform Verification

1. **Android:** Pure-Dart byte handling and HTTP transport; verified configuration with zero platform-incompatible dependencies.
2. **Web:** Clean compilation (`flutter build web`); zero `dart:io` leakage.
3. **Responsive UI:** Verified across mobile (<600px width cards) and desktop (>=600px DataTable) layouts.

---

## 14. Automated Tests

- **`payroll_dto_test.dart`:** 8 / 8 PASS.
- **`backend_payroll_repository_test.dart`:** 13 / 13 PASS.
- **`payroll_backend_integration_test.dart`:** 3 / 3 PASS.
- **Total New HR-10.8 Tests:** 24 / 24 PASS.
- **Static Analysis:** `flutter analyze` clean (0 issues).

---

## 15. Manual UAT Status

| Checkpoint / Feature | Test Type | Status | Evidence |
| :--- | :--- | :--- | :--- |
| Period Selection View | Automated / Mock Transport | `PASS` | `payroll_backend_integration_test.dart` |
| Payroll Records Table | Automated / Mock Transport | `PASS` | `payroll_backend_integration_test.dart` |
| Employee History View | Automated / Mock Transport | `PASS` | `backend_payroll_repository_test.dart` |
| Monetary Precision | Automated / Mock Transport | `PASS` | `payroll_dto_test.dart` |
| Controlled Cutover Factory | Automated / Unit | `PASS` | `backend_payroll_repository_test.dart` |
| Live Physical Server UAT | Live Hardware / Server | `NOT TESTED` | Live instructor server pending deployment |

Overall Manual UAT Status: `IMPLEMENTED — LIVE UAT PENDING`

---

## 16. Exit Criteria Checklist

- [x] HR-10.7 verified and independently committed (`fba698f`).
- [x] Payroll backend contract verified.
- [x] Existing HR-6 domain preserved (`PayrollRecord`, `PayrollPeriod`).
- [x] Existing HR-7 calculation contract respected.
- [x] Existing `PayrollRepository` interface reused.
- [x] Approved Payroll DTOs implemented (`PayrollRecordDto`, `PayrollPeriodDto`).
- [x] Stable Payroll identities preserved.
- [x] PayrollPeriod semantics preserved (UTC midnight normalization).
- [x] Money-safe representation preserved (no floating-point truncation).
- [x] Currency preserved.
- [x] Missing vs zero preserved.
- [x] Stored/calculated/preview distinctions preserved.
- [x] Calculation authority documented and enforced.
- [x] Approved read operations integrated (`getPayrollPeriods`, `getPayrollRecords`, `getPayrollRecordById`).
- [x] No unauthorized Payroll writes, disbursement, or finalization.
- [x] HR-9 approval boundary respected.
- [x] Existing Payroll Cubits integrated.
- [x] HR-8 Payroll Reports regression verified.
- [x] Authorization maintained.
- [x] Session isolation verified.
- [x] No sensitive logging.
- [x] Mock mode preserved.
- [x] No backend-mode mock fallback.
- [x] Controlled cutover factory implemented (`PayrollRepositoryFactory`).
- [x] Automated tests pass (24 / 24 HR-10.8 tests).
- [x] Static analyzer clean (0 issues).
- [x] Web build passes (`flutter build web`).
- [x] Deliverable document created (`HR_10_PAYROLL_BACKEND_INTEGRATION.md`).

---

## 17. Git Commit Reference

- **Commit Message:** `feat(hr): integrate payroll backend (HR-10.8)`
