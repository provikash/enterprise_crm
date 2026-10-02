# HR-10.7 — KPI / Performance Backend Integration Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — KPI & Performance Backend Integration  
**Status:** `IMPLEMENTED — LIVE UAT PENDING`

---

## 1. Purpose and Scope

This document details the backend communication contracts, data transfer models, domain mappings, stored score authority invariants, security policies, and controlled cutover mechanism established for **HR-10.7: KPI / Performance Backend Integration** in the Enterprise CRM Flutter application.

Building on the foundation established in HR-10.1 through HR-10.6, HR-10.7 connects the KPI / Performance feature (HR-5) to the instructor backend:
1. **`EmployeeKpiDto`** (`lib/features/hr/data/dto/employee_kpi_dto.dart`): Strict serialization and validation boundary parsing backend JSON structures, validating mandatory keys (`id`, `employee_id`, `metric_name`, `period_start`, `period_end`, `target_value`, `actual_value`), and normalizing calendar dates to UTC midnight.
2. **`BackendEmployeeKpiRepository`** (`lib/features/hr/data/repositories/backend_employee_kpi_repository.dart`): Production-compatible implementation of `EmployeeKpiRepository` connecting listing, filtering, date range queries, employee queries, single record inspection, and create/update mutations to the backend API (`/hr/kpis`).
3. **Controlled Mock / Backend Cutover**: Introduction of `EmployeeKpiRepositoryFactory` (`lib/features/hr/data/repositories/employee_kpi_repository_factory.dart`) ensuring explicit mode selection without silent fallback to mock data on backend failure.
4. **Stored Score Authority & Zero Client Calculations**: Upholds the critical invariant that stored scores from the backend are preserved verbatim; client-side grading formulas, normalized score recalculations, or performance rankings are strictly prohibited.
5. **Cubit & Screen Wiring**: Direct compatibility with `EmployeeKpiListCubit`, `EmployeeKpiDetailsCubit`, `EmployeeKpiFormCubit`, `EmployeeKpiSummaryCubit`, and `KpiReportCubit`.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.7):** `f1766e14b6723cca6f4a421f5af1dc8d07859cbf` (`feat(hr): integrate attendance backend (HR-10.6)`)
- **HR-10.1 Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`
- **HR-10.3 Commit:** `326adc3ea6dca1375d86290ea8111e5ae5d78627`
- **HR-10.4 Commit:** `90f80a1334c9c277bf8238612711dc10d8a55dbb`
- **HR-10.5 Commit:** `6ac4bd6f127426ec8b20eb209f53fc14ef473931`
- **HR-10.6 Commit:** `f1766e14b6723cca6f4a421f5af1dc8d07859cbf`

---

## 3. HR-10.1 Through HR-10.6 Dependencies

| Checkpoint | Status | Delivery |
| :--- | :--- | :--- |
| HR-10.1 Audit | `VERIFIED` | Document & commit `54edb65` |
| HR-10.2 Connection | `VERIFIED` | `ApiClient`, `BackendConfig`, `NetworkException`, commit `55288ab` |
| HR-10.3 Adapter | `VERIFIED` | `BackendEmployeeRepository` base, commit `326adc3` |
| HR-10.4 Employee | `VERIFIED` | Full Employee CRUD & controlled cutover, commit `90f80a1` |
| HR-10.5 Documents | `VERIFIED` | Document listing, details, upload, download, commit `6ac4bd6` |
| HR-10.6 Attendance | `VERIFIED` | Attendance listing, filtering, recording, commit `f1766e1` |

---

## 4. Existing HR-5 Architecture

| Screen / Component | Role | Interface Method | Integration State |
| :--- | :--- | :--- | :--- |
| `EmployeeKpiListScreen` | Main KPI directory and search | `getKpis()` | Backend-backed via `BackendEmployeeKpiRepository` |
| `EmployeeKpiListCubit` | Query and filter state management | `getKpis()` | Backend-backed via `BackendEmployeeKpiRepository` |
| `EmployeeKpiDetailsScreen` | Single KPI record inspection | `getKpiById()` | Backend-backed via `BackendEmployeeKpiRepository` |
| `AddEmployeeKpiScreen` | Evaluator KPI creation | `createKpi()` | Backend-backed via `BackendEmployeeKpiRepository` |
| `EditEmployeeKpiScreen` | Assessor record revision | `updateKpi()` | Backend-backed via `BackendEmployeeKpiRepository` |
| `KpiReportScreen` | KPI reports and aggregations | `getKpis()` | Reuses domain repository |

---

## 5. Verified Backend API Contracts

Derived from `CRM_Backend_Schema.md` §10 and `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §15:
- **`GET /api/v1/hr/kpis`**: Returns JSON array or paginated envelope of KPI records. Supports query parameters `employee_id`, `start_date`, and `end_date`.
- **`GET /api/v1/hr/kpis/{id}`**: Returns a single KPI record object by stable ID.
- **`POST /api/v1/hr/kpis`**: Creates a new KPI evaluation record with validated target, actual, score, and remarks.
- **`PUT /api/v1/hr/kpis/{id}`**: Updates an existing KPI record by stable ID.

---

## 6. Supported vs Deferred Operations

| Operation | Method | Route | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| List KPIs | `GET` | `/api/v1/hr/kpis` | `SUPPORTED` | Filters by employee and date range |
| KPI Details | `GET` | `/api/v1/hr/kpis/{id}` | `SUPPORTED` | Returns null on 404 |
| Employee KPIs | `GET` | `/api/v1/hr/kpis?employee_id={id}` | `SUPPORTED` | Scoped by employee ID |
| Create KPI | `POST` | `/api/v1/hr/kpis` | `SUPPORTED` | Handles 409 Conflict |
| Update KPI | `PUT` | `/api/v1/hr/kpis/{id}` | `SUPPORTED` | Handles 404 Not Found & 409 Conflict |
| Delete KPI | `DELETE`| `/api/v1/hr/kpis/{id}` | `DEFERRED` | Audit policy requires historical evaluation preservation |
| Auto-Bonus Engine | `POST` | `/api/v1/hr/kpis/bonus` | `EXCLUDED` | Strict scope exclusion |

---

## 7. DTO Structure and Domain Mapping

- **DTO Model:** `EmployeeKpiDto` in `lib/features/hr/data/dto/employee_kpi_dto.dart`.
- **JSON Fields Mapped:**
  - `id`: String (mandatory)
  - `employee_id`: String (mandatory)
  - `metric_name`: String (mandatory)
  - `period_start`: String (ISO-8601 date, mandatory)
  - `period_end`: String (ISO-8601 date, mandatory)
  - `target_value`: num (mandatory, converted to double)
  - `actual_value`: num (mandatory, converted to double)
  - `score`: num? (optional, converted to double?)
  - `remarks`: String? (optional)
  - `created_at`: String? (optional, parsed to UTC DateTime)
  - `updated_at`: String? (optional, parsed to UTC DateTime)
- **Domain Entity:** `EmployeeKpi` in `lib/features/hr/domain/entities/employee_kpi.dart`.

---

## 8. Stored Score Authority Invariants

1. **Zero Client Scoring:** The frontend displays only stored scores returned from the backend. No grading algorithms (e.g. `(actual / target) * 100`) are computed on the client.
2. **Preservation of Nullability:** Missing scores are never fabricated as 0.0. A null score indicates an unassessed metric.
3. **No Dual Calculations:** The DTO mapper and backend repository strictly avoid recomputing or normalizing score values.

---

## 9. KPI Period and Date Normalization

1. **UTC Calendar Midnight:** `periodStart` and `periodEnd` are normalized to UTC midnight (`DateTime.utc(year, month, day)`).
2. **Invariant:** `periodEnd.isBefore(periodStart)` is rejected at the DTO and repository boundaries.
3. **Query Serialization:** Date filters are serialized to standard `YYYY-MM-DD` query parameters (`start_date`, `end_date`).

---

## 10. Repository and Factory Implementation

- **`BackendEmployeeKpiRepository`** (`lib/features/hr/data/repositories/backend_employee_kpi_repository.dart`):
  - Extends `BackendAdapter`, implements `EmployeeKpiRepository`.
  - Translates `NetworkException` to domain `EmployeeKpiException` with safe messages.
  - Transparently handles flat arrays and `{ "data": [...] }` response envelopes.
  - Provides idempotent reads and transactional create/update operations.
- **`EmployeeKpiRepositoryFactory`** (`lib/features/hr/data/repositories/employee_kpi_repository_factory.dart`):
  - Injects `BackendEmployeeKpiRepository` when `config.mode.isBackend`.
  - Injects `MockEmployeeKpiRepository` when `config.mode.isMock`.
  - Strictly prohibits silent fallback to mock data on backend failure.

---

## 11. Security, Authorization, and Session Isolation

1. **Authentication:** Bearer token evaluated dynamically per request via `ApiClient.tokenProvider`.
2. **Authorization:** Server-side HR access policies enforced; HTTP 403 Forbidden is translated to user-safe messages without session invalidation.
3. **Session Purge:** Logout invalidates dynamic token providers and clears all active Cubit states.
4. **Zero PII/Score Logging:** Performance scores and assessor notes are excluded from client loggers.

---

## 12. HR-8 KPI Reports Compatibility

`KpiReportScreen` and `KpiReportCubit` consume `EmployeeKpiRepository` directly:
- Aggregations and summaries operate over authoritative backend-returned datasets.
- Query filters (`startDate`, `endDate`, `employeeId`) are passed faithfully.
- No page-level data is misrepresented as full enterprise metrics.

---

## 13. Platform Verification

1. **Android:** Pure-Dart byte handling and HTTP transport; verified configuration with zero platform-incompatible dependencies.
2. **Web:** Clean compilation (`flutter build web`); zero `dart:io` leakage.
3. **Responsive UI:** Verified across mobile (<600px width cards) and desktop (>=600px DataTable) layouts.

---

## 14. Automated Tests

- **`employee_kpi_dto_test.dart`:** 7 / 7 PASS.
- **`backend_employee_kpi_repository_test.dart`:** 16 / 16 PASS.
- **`employee_kpi_backend_integration_test.dart`:** 2 / 2 PASS.
- **Total New HR-10.7 Tests:** 25 / 25 PASS.
- **Static Analysis:** `flutter analyze` clean (0 issues).

---

## 15. Manual UAT Status

| Checkpoint / Feature | Test Type | Status | Evidence |
| :--- | :--- | :--- | :--- |
| KPI List View | Automated / Mock Transport | `PASS` | `employee_kpi_backend_integration_test.dart` |
| KPI Search & Filter | Automated / Mock Transport | `PASS` | `employee_kpi_backend_integration_test.dart` |
| Create KPI (POST) | Automated / Mock Transport | `PASS` | `backend_employee_kpi_repository_test.dart` |
| Update KPI (PUT) | Automated / Mock Transport | `PASS` | `backend_employee_kpi_repository_test.dart` |
| Failure & Retry Handling | Automated / Mock Transport | `PASS` | `employee_kpi_backend_integration_test.dart` |
| Controlled Cutover Factory | Automated / Unit | `PASS` | `backend_employee_kpi_repository_test.dart` |
| Live Physical Server UAT | Live Hardware / Server | `NOT TESTED` | Live instructor server pending deployment |

Overall Manual UAT Status: `IMPLEMENTED — LIVE UAT PENDING`

---

## 16. Exit Criteria Checklist

- [x] Approved KPI API contract verified.
- [x] Existing HR-5 domain preserved (`EmployeeKpi`).
- [x] Existing `EmployeeKpiRepository` interface reused.
- [x] Approved DTO mapping implemented (`EmployeeKpiDto`).
- [x] Employee, KPI, and Metric IDs preserved.
- [x] KPI periods correctly mapped and normalized.
- [x] Target/actual values preserved.
- [x] Stored score authority preserved (zero client scoring).
- [x] Missing values not converted to zero.
- [x] Approved read operations integrated (`getKpis`, `getKpiById`).
- [x] Approved write operations integrated (`createKpi`, `updateKpi`).
- [x] HR-9 approval rules respected.
- [x] Cubits integrated (`EmployeeKpiListCubit`).
- [x] HR-8 KPI Reports regression verified.
- [x] Authorization maintained.
- [x] Session isolation verified.
- [x] Mock mode preserved.
- [x] No production mock fallback.
- [x] Controlled cutover factory implemented (`EmployeeKpiRepositoryFactory`).
- [x] Automated tests pass (25 / 25 HR-10.7 tests).
- [x] Static analyzer clean (0 issues).
- [x] Deliverable document created (`HR_10_KPI_BACKEND_INTEGRATION.md`).

---

## 17. Git Commit Reference

- **Commit Message:** `feat(hr): integrate kpi performance backend (HR-10.7)`
