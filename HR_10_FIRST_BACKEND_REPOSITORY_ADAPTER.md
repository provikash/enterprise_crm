# HR-10.3 — First Approved HR Repository Backend Adapter Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — First Backend Repository Adapter (`BackendEmployeeRepository`)  
**Status:** `IMPLEMENTED — LIVE BACKEND VERIFICATION PENDING`

---

## 1. Purpose and Scope

This document defines the architectural specifications, DTO serialization contracts, domain mapping invariants, error translations, and automated test verifications established for **HR-10.3: First Approved HR Repository Backend Adapter** in the Enterprise CRM Flutter application.

As identified in the HR-10.1 readiness audit and prioritized in the HR-10 roadmap, the primary focus of HR-10.3 is establishing the first production-compatible repository adapter connecting the existing `EmployeeRepository` domain contract to the instructor backend via the shared `ApiClient` network foundation built in HR-10.2.

Key deliverables completed in HR-10.3:
1. **`EmployeeDto`** (`lib/features/hr/data/dto/employee_dto.dart`): Strict data transfer object parsing backend JSON formats, validating mandatory keys (`id`, `full_name`), normalizing date formats, mapping status strings to `EmploymentStatus`, and preventing sensitive payroll or credential leakage.
2. **`BackendEmployeeRepository`** (`lib/features/hr/data/repositories/backend_employee_repository.dart`): Concrete repository adapter implementing `EmployeeRepository` and extending `BackendAdapter`, connecting domain operations (`getEmployees()`, `getEmployeeById()`) to the backend API (`/hr/employees`).
3. **Strongly Typed Error Translation**: Transparent translation of `NetworkException` (`UnauthorizedException`, `ForbiddenException`, `NetworkTimeoutException`, `ConnectionException`, `ServerException`) to domain `EmployeeException` with user-safe messaging.
4. **Mock vs. Backend Separation**: Strict adherence to the rule that backend mode executes real requests and never silently falls back to mock fixtures on network errors.
5. **Comprehensive Automated Tests** (22 tests): 8 tests covering DTO parsing, validation, serialization, and domain conversions; 14 tests covering repository routes, query filters, envelope unpacking, HTTP status mapping, and deferred write handling.

---

## 2. Git Baseline

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.3):** `55288ab2193e60c64cbb8a7bedb8dd409425a410` (`feat(hr): establish backend api connection foundation (HR-10.2)`)
- **HR-10.1 Audit Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Connection Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`

---

## 3. HR-10.1 & HR-10.2 Dependency Verification

| Pre-requisite | Status | Evidence |
| :--- | :--- | :--- |
| HR-10.1 Requirements Audit | `VERIFIED` | `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` (Commit `54edb65`) |
| HR-10.2 Connection Foundation | `VERIFIED` | `HR_10_BACKEND_CONNECTION_CONTRACT.md` (Commit `55288ab`) |
| Shared Transport Available | `VERIFIED` | `ApiTransport`, `MockApiTransport`, `ApiClient` |
| Validated Configuration | `VERIFIED` | `BackendConfig` enforcing HTTPS and URL normalization |
| Session Token Attachment | `VERIFIED` | `AuthTokenProvider` dynamic resolution per request |
| Mock Repositories Intact | `VERIFIED` | `MockEmployeeRepository` 100% operational |

---

## 4. Selected First Backend Operation

Following the approved HR-10 roadmap from HR-10.1 §8, the lowest-risk and highest-impact initial operations selected are **Employee Management Read Operations**:
1. **List Employees (`getEmployees`)**:
   - Route: `GET /api/v1/hr/employees`
   - Purpose: Retrieve all authorized workforce records with optional query parameters (`search`, `department`, `status`, `page`, `page_size`).
2. **Get Employee by ID (`getEmployeeById`)**:
   - Route: `GET /api/v1/hr/employees/{id}`
   - Purpose: Retrieve single employee profile details by stable workforce identifier.

*Note:* Mutating operations (`createEmployee`, `updateEmployee`) are explicitly deferred to HR-10.4.

---

## 5. API Contract Evidence

Derived from `context/CRM_Backend_Schema.md` §10 and normalized in `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §12:
- **Protocol:** HTTP/1.1 & HTTP/2 over TLS (HTTPS).
- **Endpoint Structure:**
  - `GET /api/v1/hr/employees`: Accepts optional query parameters; returns JSON array or envelope `{ "items": [...], "total": ... }`.
  - `GET /api/v1/hr/employees/{id}`: Returns JSON object or envelope `{ "data": { ... } }`.
- **Status Codes:**
  - `200 OK`: Valid payload returned.
  - `401 Unauthorized`: Session token expired or missing.
  - `403 Forbidden`: User lacks `hrView` / `hrPayroll` permissions.
  - `404 Not Found`: Employee does not exist (maps to `null` in `getEmployeeById`).
  - `500 Internal Server Error`: Backend error.

---

## 6. Existing Repository Interface

Located at: `lib/features/hr/domain/repositories/employee_repository.dart`
```dart
abstract interface class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<Employee> createEmployee(CreateEmployeeInput input);
  Future<Employee> updateEmployee(UpdateEmployeeInput input);
}
```
*Zero interface changes* were required. The domain interface remains 100% stable and compatible.

---

## 7. Backend Adapter Architecture

```text
EmployeeDirectoryCubit / EmployeeDetailsCubit
                 |
                 v
         EmployeeRepository (Interface)
                 |
        +--------+--------+
        |                 |
        v                 v
MockEmployeeRepository  BackendEmployeeRepository (HR-10.3)
        |                 |
MockEmployeeStore         +---> ApiClient (HR-10.2)
                                   |
                                   +---> ApiTransport
                                            |
                                            v
                                     Instructor API
```

---

## 8. DTO Contract (`EmployeeDto`)

Located at: `lib/features/hr/data/dto/employee_dto.dart`

```dart
class EmployeeDto {
  final String id;
  final String? employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? department;
  final String? designation;
  final String status;
  final DateTime? joiningDate;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

Validation Rules:
- `id`: Non-empty string required. Throws `FormatException` if missing.
- `fullName`: Non-empty string required (supports `full_name`, `name`, `fullName`). Throws `FormatException` if missing.
- `status`: String mapped to `EmploymentStatus` (default `'active'`).
- `joiningDate`: ISO 8601 or `YYYY-MM-DD` date string parsed to `DateTime?`.

---

## 9. DTO-to-Domain Mapping

The mapping boundary ensures domain purity:
- Translates `status` string to value object `EmploymentStatus.fromString(status)`.
- Reconstructs immutable `Employee` entity with exact timestamps and identifiers.
- Reversible: `EmployeeDto.fromDomain(employee)` and `dto.toJson()` allow round-trip serialization.

---

## 10. Stable ID Mapping

- **Workforce Identity:** `Employee.id` represents internal directory record (e.g. `emp_001`).
- **Account Identity:** `Employee.userId` optionally links to a CRM login user account (`CurrentUser.id`).
- **Strict Distinction:** The backend adapter never confuses or overwrites `Employee.id` with `CurrentUser.id`.

---

## 11. Dates, Enums, and Nullability

- **Dates:** Stored as UTC `DateTime`. Serialized in `toJson()` to normalized `YYYY-MM-DD` string.
- **Enums:** Handled via `EmploymentStatus` value object without hardcoded closed enum limitations.
- **Null Safety:** Missing optional fields (`phone`, `department`, `designation`, `userId`, `joiningDate`) produce safe `null` values without fabricated mock defaults.

---

## 12. Search, Filtering & Pagination

`BackendEmployeeRepository.getEmployees` supports optional query parameters:
- `search`: Appended as `?search=<term>` for server-side filtering.
- `department`: Appended as `?department=<dept>`.
- `status`: Appended as `?status=<status>`.
- `page`: Appended as `?page=<int>`.
- `pageSize`: Appended as `?page_size=<int>`.

Responses can be direct lists `[...]` or paginated envelopes `{"items": [...]}` / `{"results": [...]}` / `{"data": [...]}`.

---

## 13. Authentication Integration

- Utilizes the `ApiClient` from HR-10.2.
- Injects dynamic `Authorization: Bearer <token>` header resolved at request execution time via `AuthTokenProvider`.
- Stale or expired credentials receive HTTP 401 and throw `EmployeeException('Unauthorized...')`.

---

## 14. Authorization

- Read operations respect server-enforced permissions (`hrView`, `hrPayroll`).
- HTTP 403 Forbidden is translated cleanly to `EmployeeException('Access denied: You do not have permission...')`.

---

## 15. Error Handling & Translation

| Network Exception | Translated Domain Exception | User-Safe Message |
| :--- | :--- | :--- |
| `UnauthorizedException` | `EmployeeException` | `"Unauthorized: Session has expired or is invalid. Please log in again."` |
| `ForbiddenException` | `EmployeeException` | `"Access denied: You do not have permission to view employee records."` |
| `NetworkTimeoutException` | `EmployeeException` | `"Network timeout while loading employee directory. Please try again."` |
| `ConnectionException` | `EmployeeException` | `"Connection failure while loading employee directory. Check your internet connection."` |
| `ServerException` (500) | `EmployeeException` | `"Backend server error (500) while loading employee directory. Please try again later."` |
| `InvalidResponseException` | `EmployeeException` | `"Received invalid response format from backend server."` |

---

## 16. Session Isolation

- `BackendEmployeeRepository` retains zero stateful in-memory employee caches.
- Logout or user switching completely prevents data leaks across sessions because queries always flow through `ApiClient`.

---

## 17. Mock vs. Backend Separation

- `BackendEmployeeRepository.isBackendMode` is `true`.
- Zero hidden fallback to `MockEmployeeStore` or `MockEmployeeRepository` on network failure.
- When the network fails, `BackendEmployeeRepository` throws `EmployeeException` explicitly.

---

## 18. Dependency Composition

- `BackendEmployeeRepository` is instantiated with `apiClient: ApiClient(...)`.
- Can be passed directly to `CrmApp(employeeRepository: ...)` or screen constructors without altering existing Cubit implementations.

---

## 19. Unit Test Results

Executed via `flutter test`:
- **`employee_dto_test.dart`:** 8 / 8 PASS
  - Full valid JSON parsing with snake_case keys.
  - CamelCase fallback keys parsing.
  - Minimal required fields validation.
  - Missing `id` throws `FormatException`.
  - Missing `full_name` throws `FormatException`.
  - DTO to domain `Employee` conversion.
  - Domain to DTO and `toJson()` serialization.
  - Date serialization formatting (`YYYY-MM-DD`).
- **`backend_employee_repository_test.dart`:** 14 / 14 PASS
  - JSON array parsing.
  - Paginated envelope parsing.
  - Query parameters propagation.
  - HTTP 401 Unauthorized mapping.
  - HTTP 403 Forbidden mapping.
  - Network failure translation without mock fallback.
  - HTTP 500 Server error translation.
  - Single employee retrieval by ID.
  - Data envelope retrieval.
  - 404 Not Found returns `null`.
  - Empty ID string returns `null` immediately.
  - `createEmployee` throws HR-10.4 deferral exception.
  - `updateEmployee` throws HR-10.4 deferral exception.
  - Mode reflection from configuration.
- **Total Targeted Tests:** 22 / 22 PASS.

---

## 20. Live Connectivity Evidence

- **Status:** `LIVE CONNECTIVITY — BLOCKED / NOT TESTED`
- **Reason:** The instructor backend repository and live deployment endpoints have not yet been provided in the local workspace.
- **Test Fake Verification:** 100% verified via `MockApiTransport`.

---

## 21. Platform Compatibility

- **Web:** Verified clean compilation via `flutter build web`.
- **Android:** Verified clean configuration via `flutter build apk --config-only`.
- **Zero Platform-Specific Imports:** Pure Dart domain and network abstractions only.

---

## 22. Deferred Operations

- `createEmployee(CreateEmployeeInput input)`: Scheduled for HR-10.4.
- `updateEmployee(UpdateEmployeeInput input)`: Scheduled for HR-10.4.
- Attendance, KPI, Payroll, Reports, Approvals, Notifications adapters: Scheduled for HR-10.5 through HR-10.9.

---

## 23. Security Limitations

- Tokens are never logged in debug logs.
- Sensitive payroll figures are strictly excluded from `EmployeeDto`.
- Production configuration enforces HTTPS.

---

## 24. Backend Dependencies

- Awaiting instructor-provided staging/production server URL and backend repository source.

---

## 25. Exit Criteria Checklist

- [x] HR-10.1 verified.
- [x] HR-10.2 verified.
- [x] First backend operation selected (Employee read operations).
- [x] Existing repository interface reused (`EmployeeRepository`).
- [x] Approved backend adapter implemented (`BackendEmployeeRepository`).
- [x] DTO mapping accurate (`EmployeeDto`).
- [x] Stable IDs preserved.
- [x] Date/null/enum behavior correct.
- [x] Approved query parameters supported.
- [x] Authentication reused via `ApiClient`.
- [x] Authorization boundary preserved.
- [x] Errors mapped safely to `EmployeeException`.
- [x] Session isolation verified.
- [x] Mock repository preserved intact.
- [x] No production mock fallback on network failure.
- [x] Deterministic tests pass (22 / 22 PASS).
- [x] Deliverable document created (`HR_10_FIRST_BACKEND_REPOSITORY_ADAPTER.md`).

---

## 26. Git Commit Reference

- **Commit Message:** `feat(hr): implement first backend repository adapter (HR-10.3)`
