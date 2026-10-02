# HR-10.4 — Employee Management Backend Integration & Controlled Cutover Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Employee Management Backend Integration  
**Status:** `IMPLEMENTED — LIVE UAT PENDING`

---

## 1. Purpose and Scope

This document details the architecture, request/response models, mutation workflows, state management wiring, security policies, and controlled cutover mechanism established for **HR-10.4: Employee Management Backend Integration & Controlled Cutover** in the Enterprise CRM Flutter application.

Building directly upon the first repository adapter established in HR-10.3, HR-10.4 completes the backend integration for the entire Employee Management domain (HR-2):
1. **Full CRUD & Search/Filter Operations**: Full implementation of `getEmployees()`, `getEmployeeById()`, `createEmployee()`, and `updateEmployee()` in `BackendEmployeeRepository`.
2. **Cubit & Screen Wiring**: Direct compatibility with existing `EmployeeDirectoryCubit`, `EmployeeDetailsCubit`, `EmployeeDirectoryScreen`, `EmployeeDetailsScreen`, `AddEmployeeScreen`, and `EditEmployeeScreen` without altering existing UI design or business rules.
3. **Controlled Mock / Backend Cutover**: Introduction of `EmployeeRepositoryFactory` (`lib/features/hr/data/repositories/employee_repository_factory.dart`) governing explicit runtime selection based on `BackendConfig.mode` (`BackendMode.mock` vs `BackendMode.backend`), with a strict zero-silent-fallback policy.
4. **Defensive Validation & Conflict Handling**: Mapping HTTP 409 Conflict to `EmployeeException('Conflict detected...')`, local input validation guarding against empty employee names/IDs, and user-safe error translation.
5. **Responsive & Platform Verification**: Clean verification across mobile (360x640) and desktop (1200x800) viewports, Android APK config check, and Flutter Web build.

---

## 2. Starting Git Baseline

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.4):** `326adc3ea6dca1375d86290ea8111e5ae5d78627` (`feat(hr): implement first backend repository adapter (HR-10.3)`)
- **HR-10.1 Audit Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Connection Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`
- **HR-10.3 Adapter Commit:** `326adc3ea6dca1375d86290ea8111e5ae5d78627`

---

## 3. HR-10.3 Dependency Verification

| Pre-requisite | Status | Evidence |
| :--- | :--- | :--- |
| `EmployeeDto` Model | `VERIFIED` | `lib/features/hr/data/dto/employee_dto.dart` |
| `BackendEmployeeRepository` Base | `VERIFIED` | `lib/features/hr/data/repositories/backend_employee_repository.dart` |
| Read Operations (`getEmployees`, `getEmployeeById`) | `VERIFIED` | Tested & passing in `backend_employee_repository_test.dart` |
| Mock Repository Intact | `VERIFIED` | `MockEmployeeRepository` 100% operational |
| Unit Tests Passing | `VERIFIED` | 22 / 22 HR-10.3 tests PASS |

---

## 4. Backend Contract Sources

Derived from:
- `CRM_PRD.md` §5 & `CRM_TRD.md` §4 (Workforce directory specification).
- `context/CRM_Backend_Schema.md` §10 (REST endpoints and data contracts).
- `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §8 & §12.
- `HR_10_FIRST_BACKEND_REPOSITORY_ADAPTER.md` (Read adapter contracts).

---

## 5. Existing Employee Feature Audit

| Screen / Component | Cubit / State | Repository Method Called | Status in HR-10.4 |
| :--- | :--- | :--- | :--- |
| `EmployeeDirectoryScreen` | `EmployeeDirectoryCubit` | `getEmployees()` | Backend-backed via `BackendEmployeeRepository` |
| `EmployeeDetailsScreen` | `EmployeeDetailsCubit` | `getEmployeeById(id)` | Backend-backed via `BackendEmployeeRepository` |
| `AddEmployeeScreen` | Form State | `createEmployee(input)` | Backend-backed via `BackendEmployeeRepository` |
| `EditEmployeeScreen` | Form State | `updateEmployee(input)` | Backend-backed via `BackendEmployeeRepository` |

---

## 6. Implemented API Operations

1. **`GET /api/v1/hr/employees`**:
   - Query Parameters: `search`, `department`, `status`, `page`, `page_size`.
   - Returns: JSON array or `{ "items": [...], "total": ... }`.
2. **`GET /api/v1/hr/employees/{id}`**:
   - Returns: JSON object or `{ "data": { ... } }`.
3. **`POST /api/v1/hr/employees`**:
   - Body: JSON payload (`full_name`, `employee_code`, `email`, `phone`, `department`, `designation`, `status`, `joining_date`, `user_id`).
   - Returns: 201 Created with authoritative created `EmployeeDto`.
4. **`PUT /api/v1/hr/employees/{id}`**:
   - Body: JSON payload (`id`, `full_name`, `employee_code`, `email`, `phone`, `department`, `designation`, `status`, `joining_date`, `user_id`).
   - Returns: 200 OK with authoritative updated `EmployeeDto`.

---

## 7. Deferred & Unsupported Operations

- **Employee Hard Delete (`DELETE /api/v1/hr/employees/{id}`)**: Strictly excluded to preserve audit trails, attendance integrity, and historical payroll relationships.
- **Direct Database Migrations**: Server-side responsibility.
- **Offline Sync Engine**: Deferred; real-time online architecture maintained.

---

## 8. Employee DTO Mapping

`EmployeeDto` maps all fields to immutable domain `Employee`:
- `id` -> `Employee.id` (mandatory)
- `full_name` -> `Employee.fullName` (mandatory)
- `status` -> `EmploymentStatus.fromString(status)`
- `joining_date` -> `YYYY-MM-DD` <-> `DateTime?`
- Sensitive payroll components and credentials are never included.

---

## 9. Identity Mapping

- `Employee.id`: Stable internal workforce ID (e.g. `emp_001`).
- `Employee.userId`: Optional link to CRM authentication user (`CurrentUser.id`).
- Strict separation: Updating employee profile never mutates the authenticated CRM user account.

---

## 10. Employee List Integration

- `EmployeeDirectoryCubit.loadEmployees()` calls `repository.getEmployees()`.
- On success: updates `state.employees` and applies active search/department/status filters.
- On failure: catches `EmployeeException` and emits `EmployeeDirectoryStatus.failure` with user-safe message and retry capability.

---

## 11. Employee Details Integration

- `EmployeeDetailsCubit.loadEmployee(id)` calls `repository.getEmployeeById(id)`.
- If server returns 404: emits `EmployeeDetailsStatus.notFound`.
- If server returns valid payload: emits `EmployeeDetailsStatus.loaded`.
- If network fails: emits `EmployeeDetailsStatus.failure` with retry capability.

---

## 12. Search and Filtering

- Client-side filtering in `EmployeeDirectoryCubit` continues to provide instantaneous search feedback over loaded records.
- `BackendEmployeeRepository.getEmployees` supports server-side query parameter forwarding (`search`, `department`, `status`, `page`, `page_size`).

---

## 13. Pagination

- `BackendEmployeeRepository` unpacks both direct JSON arrays (`[...]`) and paginated envelopes (`{"items": [...], "page": 1, "page_size": 20}`).
- Preserves pagination metadata for future infinite-scroll / pagination UI extensions.

---

## 14. Creation (Add Employee)

- Restricted to Administrators only (`widget.user.isAdmin`).
- Local validation prevents blank full names before firing network calls.
- Encodes JSON payload and calls `POST /hr/employees`.
- Translates HTTP 409 Conflict to `EmployeeException('Conflict detected while creating employee: employee code or record already exists.')`.

---

## 15. Updates (Edit Employee)

- Restricted to Administrators only.
- Encodes JSON payload and calls `PUT /hr/employees/{id}`.
- Translates HTTP 404 to `EmployeeException('Employee record not found while updating employee.')`.
- Translates HTTP 409 Conflict to conflict exception.

---

## 16. Status Changes

- Employment status updates are executed through `updateEmployee` with validated `EmploymentStatus.value`.
- Supported status values: `'Active'`, `'Probation'`, `'Inactive'`, `'On Leave'`.

---

## 17. Deletion Policy

- Deletion is disabled in the UI and repository interface.
- Employees can be deactivated by setting status to `'Inactive'`.

---

## 18. Authentication Integration

- Inherits `ApiClient` Bearer token injection.
- Re-evaluates token dynamically for every request via `AuthTokenProvider`.
- Session expiration (HTTP 401) immediately maps to `EmployeeException` informing user of expired session.

---

## 19. Authorization

- Enforces CRM Access Policy:
  - `HrAccessPolicy.canAccessModule(user)` guards entry to directory.
  - `HrAccessPolicy.canViewHrRecords(user)` guards viewing records.
  - `user.isAdmin` guards `createEmployee` and `updateEmployee`.

---

## 20. HR-9 Approval Interactions

- Approvals workflows (HR-9) continue to operate via `HrApprovalRepository`.
- Attendance correction and payroll finalization approvals reference stable `Employee.id` values.
- Direct mutations to employee records do not bypass required approval gates.

---

## 21. Cubit Integration

- `EmployeeDirectoryCubit` and `EmployeeDetailsCubit` seamlessly integrate with `BackendEmployeeRepository`.
- In-flight operations handle state transitions: `loading` -> `loaded` / `failure`.

---

## 22. Error & Validation Behavior

- Validation errors from server (HTTP 400 / 422) map to user-facing `EmployeeException`.
- Network timeouts, server outages (500), and offline states are translated without raw stack trace exposure.

---

## 23. Session Isolation

- `BackendEmployeeRepository` has zero mutable static state.
- Switching authenticated users immediately directs subsequent requests to the new user's session token.

---

## 24. Stale-Response Protection

- Sequential request tokens in `EmployeeDetailsCubit` discard out-of-order network responses.

---

## 25. Cache Behavior

- No unapproved client-side disk caching of sensitive workforce PII.
- Repository always queries the authoritative backend or mock store.

---

## 26. Mock / Backend Controlled Cutover

Implemented via `EmployeeRepositoryFactory`:
```dart
class EmployeeRepositoryFactory {
  static EmployeeRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockEmployeeStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendEmployeeRepository(apiClient: apiClient);
    }
    return MockEmployeeRepository(store: mockStore);
  }
}
```
Invariants:
- When `BackendMode.backend`, `BackendEmployeeRepository` is returned.
- When `BackendMode.mock`, `MockEmployeeRepository` is returned.
- ZERO silent fallback to mock data on backend failure.

---

## 27. Android Verification

- `flutter build apk --config-only` PASSED cleanly.
- `android.permission.INTERNET` declared.
- Cleartext HTTP forbidden in production mode.

---

## 28. Web Verification

- `flutter build web` PASSED cleanly.
- Pure Dart network transport with zero browser incompatibilities.

---

## 29. Automated Tests

- **`backend_employee_repository_test.dart`:** 19 / 19 PASS (Read + Write + Factory).
- **`employee_backend_integration_test.dart`:** 5 / 5 PASS (Cubit, Screen, Retry, Responsive).
- **`employee_dto_test.dart`:** 8 / 8 PASS.
- **Total New HR-10 Tests:** 32 / 32 PASS.
- **CRM Regression Suite:** 2,102 / 2,102 PASS.

---

## 30. Manual UAT Status

| Checkpoint / Feature | Test Type | Status | Evidence |
| :--- | :--- | :--- | :--- |
| Employee Directory Screen | Automated / Mock Transport | `PASS` | `employee_backend_integration_test.dart` |
| Employee Details Screen | Automated / Mock Transport | `PASS` | `employee_backend_integration_test.dart` |
| Employee Search & Filter | Automated / Mock Transport | `PASS` | `employee_backend_integration_test.dart` |
| Employee Creation (POST) | Automated / Mock Transport | `PASS` | `backend_employee_repository_test.dart` |
| Employee Update (PUT) | Automated / Mock Transport | `PASS` | `backend_employee_repository_test.dart` |
| Failure & Retry Handling | Automated / Mock Transport | `PASS` | `employee_backend_integration_test.dart` |
| Controlled Cutover Factory | Automated / Unit | `PASS` | `backend_employee_repository_test.dart` |
| Live Physical Server UAT | Live Hardware / Server | `NOT TESTED` | Live instructor server pending deployment |

Overall Manual UAT Status: `IMPLEMENTED — LIVE UAT PENDING`

---

## 31. HR Regression

- HR-1 (Core): 100% PASS
- HR-2 (Employee): 100% PASS
- HR-3 (Documents): 100% PASS
- HR-4 (Attendance): 100% PASS
- HR-5 (KPI): 100% PASS
- HR-6 & HR-7 (Payroll): 100% PASS
- HR-8 (Reports): 100% PASS
- HR-9 (Approvals & Notifications): 100% PASS
- Full suite: 2,102 tests green.

---

## 32. Security Findings

- Strict role authorization on mutations (Admin only).
- Dynamic Bearer token injection.
- Zero credential logging.
- Clear separation between `Employee.id` and `CurrentUser.id`.

---

## 33. Remaining Blockers

- Instructor live backend server deployment for live smoke testing.
- Attendance, KPI, Payroll, Reports, Approvals backend adapters scheduled for HR-10.5+.

---

## 34. Backend Dependencies

- Awaiting instructor-provided staging/production server URL.

---

## 35. Cutover Readiness

- **Mock Mode:** 100% operational for offline testing, demos, and development.
- **Backend Mode:** 100% code-complete and tested with mock transport; ready for live endpoint verification upon backend availability.

---

## 36. Exit Criteria Checklist

- [x] HR-10.3 verified and committed.
- [x] Approved Employee operations integrated (`getEmployees`, `getEmployeeById`, `createEmployee`, `updateEmployee`).
- [x] Existing domain/repository contracts preserved.
- [x] DTO mapping verified (`EmployeeDto`).
- [x] Stable Employee IDs preserved.
- [x] Employee list backend-backed.
- [x] Employee details backend-backed.
- [x] Search/filter backend-backed.
- [x] Creation implemented with validation and conflict handling.
- [x] Updates implemented with validation.
- [x] Authorization and admin guards preserved.
- [x] HR-9 approval rules respected.
- [x] Session isolation verified.
- [x] Mock mode preserved.
- [x] No production mock fallback on failure.
- [x] Error/empty/retry states verified.
- [x] Controlled cutover factory implemented (`EmployeeRepositoryFactory`).
- [x] Deterministic tests pass (32 / 32 HR-10 tests).
- [x] Full regression passes (2,102 / 2,102 tests).
- [x] Android config passes.
- [x] Web build passes.
- [x] Deliverable document created (`HR_10_EMPLOYEE_BACKEND_INTEGRATION.md`).

---

## 37. Git Commit Reference

- **Commit Message:** `feat(hr): integrate employee management backend (HR-10.4)`
