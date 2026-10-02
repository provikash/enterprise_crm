# HR-10.1 — Backend Requirements, API Contract & Integration Readiness Audit

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Instructor Backend Integration  
**Status:** `AUDIT COMPLETE — BACKEND CONTRACT PENDING`

---

## 1. Purpose and Scope

This document represents the formal requirements, API specification, and integration readiness audit for **HR-10.1: Backend Requirements, API Contract & Integration Readiness Audit** in the Enterprise CRM Flutter application.

The primary objectives are:
1. Audit the existing Flutter CRM and HR frontend architecture, data models, and repository interfaces.
2. Discover and audit actual instructor-provided backend technology, API contracts, deployment status, and database schema specifications.
3. Compare client-side domain contracts across Employee Management, Documents, Attendance, KPI, Payroll, Reports, Approvals, and Notifications against available backend specifications.
4. Establish authentication, authorization, session management, and credential attachment boundaries.
5. Define data types, serialization rules, UTC timestamp normalization, monetary precision, and pagination/filter contracts.
6. Evaluate Android and Flutter Web networking constraints (TLS, CORS, emulator reachability, cleartext rules).
7. Identify verified vs. proposed vs. unconfirmed requirements, contract conflicts, and technical blockers.
8. Establish a dependency-driven integration sequence for subsequent HR-10 checkpoints without prematurely replacing existing working mock repositories.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration` (branched from `feature/hr-9-approvals-notifications` at commit `a3b5d80`)
- **Starting HEAD:** `a3b5d80d19ce410c5982181bc883652c799a9a3b` (`test(hr): prepare approval notification final UAT (HR-9.10)`)
- **Working Tree:** Clean (0 untracked files, 0 uncommitted changes)
- **Preceding Checkpoint Commits:**
  - `a3b5d80` test(hr): prepare approval notification final UAT (HR-9.10)
  - `aa7b1d5` test(hr): audit approval workflow security (HR-9.9)
  - `ba16e38` feat(hr): integrate approval notifications (HR-9.8)
  - `b4f21fa` feat(hr): establish notification foundation (HR-9.7)
  - `19aaf2b` feat(hr): integrate approved HR approval workflows (HR-9.6)
  - `91c06d5` feat(hr): implement approval decisions and history (HR-9.5)
  - `e865c79` feat(hr): implement approval request and pending workflows (HR-9.4)
  - `ea21e64` feat(hr): implement approval repository foundation (HR-9.3)
  - `1019252` feat(hr): establish approval workflow domain (HR-9.2)
  - `55c295a` docs(hr): audit approval notification requirements (HR-9.1)

---

## 3. Current HR Checkpoint Status

| Phase / Checkpoint | Acceptance Status | Architectural Baseline & Integration Boundary |
| :--- | :--- | :--- |
| **HR-1: Core Architecture** | `COMPLETE / FROZEN` | `HrAccessPolicy`, `CurrentUser`, `CrmModule.hrPayroll`, `AccountType`. |
| **HR-2: Employee Management** | `COMPLETE / FROZEN` | `EmployeeRepository`, `Employee` domain entity, direct Admin CRUD. |
| **HR-3: Employee Documents** | `COMPLETE / FROZEN` | `EmployeeDocumentRepository`, `EmployeeDocument` domain entity, metadata & binary download. |
| **HR-4: Attendance** | `COMPLETE / FROZEN` | `AttendanceRepository`, `AttendanceRecord` domain entity, UTC date normalization. |
| **HR-5: KPI / Performance** | `COMPLETE / FROZEN` | `EmployeeKpiRepository`, `EmployeeKpi` domain entity, target vs actual tracking. |
| **HR-6: Payroll Foundation** | `IMPLEMENTED — AWAITING MANUAL UAT` | `PayrollRepository`, `PayrollPeriod`, `PayrollRecord` read-only querying. |
| **HR-7: Payroll Calculation** | `COMPLETE / FROZEN` | `PayrollCalculationService`, itemized preview calculation engine; 0 mutation side-effects. |
| **HR-8: Reports & Export** | `PARTIAL — IMPLEMENTATION BLOCKED` | `HrReportRepository` operational for Employee, Attendance, KPI, Payroll queries; Export deferred. |
| **HR-9: Approvals & Notifications** | `IMPLEMENTED — AWAITING MANUAL UAT` | `HrApprovalRepository`, `HrNotificationRepository`, `HrApprovalNotificationService`; 62/62 tests PASS. |

---

## 4. Documents and Backend Sources Inspected

The following project documents and configuration files were audited:
1. `context/CRM_Backend_Schema.md`: Planning draft schema outlining proposed entities, access workflows, audit tables, and candidate endpoints.
   - *Crucial Finding:* §1 explicitly states: *"This is a proposed backend schema and integration contract... It is **not** the instructor's actual database schema. The final table names, database technology, authentication method, API URLs, and exact fields must be matched with the backend that the instructor provides."*
2. `context/MASTER_DEVELOPMENT_RULES.md`: Core non-negotiable rules; strict prohibition against inventing unconfirmed endpoints, schemas, database tables, or auth tokens.
3. `context/CRM_PRD.md` & `CRM_TRD.md`: CRM business requirements, 8-module scope, and high-level technical direction.
4. `context/CRM_UPDATED_PROJECT_FLOW_AND_STRUCTURE.md`: Outlines the multi-phase project flow and instructor review checkpoints.
5. `context/Enterprise_CRM_Team_Collaboration_Handoff.md`: Module ownership boundaries between Vachaspati Mishra (`leads`, `inventory`, `purchase`, `dispatch`, `hr`) and Vikash Chaurasiya (`calling`, `vendor`, `approvals`, `notifications`).
6. `pubspec.yaml`: Evaluated dependencies; confirms zero external networking libraries currently installed.

---

## 5. Instructor Backend Availability

- **Backend Source Repository:** **NOT PROVIDED / NOT INCLUDED** in the local workspace.
- **Authoritative API Documentation (Swagger / OpenAPI):** **NOT PROVIDED / NOT INCLUDED**.
- **Live Test / Staging Environment:** **NOT ACCESSIBLE / NO ENDPOINT PROVIDED**.
- **Production-Like Environment:** **UNVERIFIED / NONE CONFIGURED**.
- **Availability Classification:** `NOT PROVIDED / BACKEND MATERIALS UNAVAILABLE`.

*Implication:* The Flutter client must not invent arbitrary live URLs (`https://api.crm.example.com`) or attempt network calls to non-existent servers. Instead, HR-10.1 documents all confirmed data contracts and gaps, and HR-10.2 establishes an abstract, configurable API connection and transport foundation.

---

## 6. Backend Technology and Architecture

- **Candidate Technologies Mentioned in Drafts:** Django REST Framework, Node.js/Express, or FastAPI have been proposed in general discussions.
- **Verified Technology:** **UNCONFIRMED / PENDING INSTRUCTOR SPECIFICATION**.
- **Database Engine:** Proposed as PostgreSQL or MySQL in drafts, but unverified.
- **Architecture Style:** Expected RESTful JSON over HTTPS.
- **Client Networking Standard:** Decoupled `ApiTransport` and `ApiClient` abstraction with deterministic test fakes.

---

## 7. Existing Frontend Repository Inventory

| Feature | Interface Contract | Current Mock Implementation | Current Mock Store | Tests | Backend Adapter Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth** | `AuthRepository` | `MockAuthRepository` | In-memory users | 14 PASS | Needed for JWT/Session |
| **Employee** | `EmployeeRepository` | `MockEmployeeRepository` | `MockEmployeeStore` | 24 PASS | Target for HR-10.3 |
| **Documents**| `EmployeeDocumentRepository` | `MockEmployeeDocumentRepository` | `MockEmployeeDocumentStore`| 18 PASS | Requires multipart/storage contract |
| **Attendance**| `AttendanceRepository` | `MockAttendanceRepository` | `MockAttendanceStore` | 22 PASS | Target for HR-10.4 |
| **KPI** | `EmployeeKpiRepository` | `MockEmployeeKpiRepository` | `MockEmployeeKpiStore` | 20 PASS | Target for HR-10.5 |
| **Payroll** | `PayrollRepository` | `MockPayrollRepository` | `MockPayrollStore` | 32 PASS | Target for HR-10.6 |
| **Reports** | `HrReportRepository` | `MockHrReportRepository` | Composed stores | 28 PASS | Target for HR-10.7 |
| **Approvals**| `HrApprovalRepository` | `MockHrApprovalRepository` | `MockHrApprovalStore` | 26 PASS | Target for HR-10.8 |
| **Notifications**| `HrNotificationRepository`| `MockHrNotificationRepository` | `MockHrNotificationStore` | 28 PASS | Target for HR-10.9 |

---

## 8. API Contract Matrix

| HR Feature | Operation | Method | Candidate Route | Auth Required | Contract Status | Supporting Source |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth** | Login | `POST` | `/api/v1/auth/login` | No | `PROPOSED` | `CRM_Backend_Schema.md` §10 |
| **Auth** | Current User Profile | `GET` | `/api/v1/auth/me` | Bearer/Cookie | `PROPOSED` | `CRM_Backend_Schema.md` §10 |
| **Employee** | List Employees | `GET` | `/api/v1/hr/employees` | Bearer/Cookie | `PROPOSED` | `CRM_Backend_Schema.md` §10 |
| **Employee** | Get Employee By ID | `GET` | `/api/v1/hr/employees/{id}` | Bearer/Cookie | `PROPOSED` | `EmployeeRepository` |
| **Employee** | Create Employee | `POST` | `/api/v1/hr/employees` | Admin Bearer | `PROPOSED` | `EmployeeRepository` |
| **Employee** | Update Employee | `PUT/PATCH` | `/api/v1/hr/employees/{id}` | Admin Bearer | `PROPOSED` | `EmployeeRepository` |
| **Documents**| List Documents | `GET` | `/api/v1/hr/employees/{id}/documents` | Bearer | `PROPOSED` | `EmployeeDocumentRepository`|
| **Documents**| Upload Document | `POST` | `/api/v1/hr/employees/{id}/documents` | Bearer (Multipart) | `PROPOSED` | `EmployeeDocumentRepository`|
| **Documents**| Download File | `GET` | `/api/v1/hr/documents/{id}/download` | Bearer | `PROPOSED` | `EmployeeDocumentRepository`|
| **Attendance**| Get Records | `GET` | `/api/v1/hr/attendance` | Bearer | `PROPOSED` | `AttendanceRepository` |
| **Attendance**| Record Attendance | `POST` | `/api/v1/hr/attendance` | Bearer | `PROPOSED` | `AttendanceRepository` |
| **KPI** | List KPIs | `GET` | `/api/v1/hr/kpis` | Bearer | `PROPOSED` | `EmployeeKpiRepository` |
| **KPI** | Create / Update KPI | `POST/PUT` | `/api/v1/hr/kpis` | Admin Bearer | `PROPOSED` | `EmployeeKpiRepository` |
| **Payroll** | Get Periods | `GET` | `/api/v1/hr/payroll/periods` | Payroll View | `PROPOSED` | `PayrollRepository` |
| **Payroll** | Get Records for Period| `GET` | `/api/v1/hr/payroll/records` | Payroll View | `PROPOSED` | `PayrollRepository` |
| **Reports** | Query Report | `GET` | `/api/v1/hr/reports/{type}` | Payroll/HR View| `PROPOSED` | `HrReportRepository` |
| **Approvals** | Get Pending Requests | `GET` | `/api/v1/hr/approvals/pending` | Bearer | `PROPOSED` | `HrApprovalRepository` |
| **Approvals** | Submit Decision | `POST` | `/api/v1/hr/approvals/{id}/decision` | Admin Bearer | `PROPOSED` | `HrApprovalRepository` |
| **Notifications**| Get In-App Notifs | `GET` | `/api/v1/notifications` | Bearer | `PROPOSED` | `HrNotificationRepository`|
| **Notifications**| Mark Read | `PATCH` | `/api/v1/notifications/{id}/read` | Bearer | `PROPOSED` | `HrNotificationRepository`|

*Rule:* Zero candidate routes may be called directly in production code until confirmed by the instructor.

---

## 9. Authentication Contract

- **Client Session Identity:** `CurrentUser` entity (`id`, `displayName`, `accountType`, `modules`, `permissions`).
- **Token / Session Format:** Unconfirmed (JWT Bearer Token vs HTTP-only Session Cookie).
- **Transport Expectation:** The API client must support an injectable `AuthenticationProvider` capable of attaching an `Authorization: Bearer <token>` header or managing session cookies.
- **Session Expiration:** Standard HTTP `401 Unauthorized` signals session expiration, triggering user logout and cache purge. HTTP `403 Forbidden` indicates permission deficiency without invalidating the active session.

---

## 10. CRM User and Employee Identity Mapping

1. **`CurrentUser.id` $\ne$ `Employee.id`:**
   - `CurrentUser.id`: Represents an authenticated CRM system user (e.g. `usr_admin`, `usr_hr`).
   - `Employee.id`: Represents an internal workforce record in the HR directory (e.g. `emp_1`, `emp_2`).
2. **Cardinality:** Not all Employees possess CRM accounts; not all CRM users represent internal employees.
3. **Approval Invariant:** `requesterId` and `actorId` in approvals and notifications must reference `CurrentUser.id`, never `Employee.id`.

---

## 11. Module Permission Mapping

The backend must validate the following module and granular permissions:
- `CrmModule.hrPayroll`: Required for accessing any HR or Payroll endpoint.
- `CrmPermissions.hrView`: Grants read access to Employee Directory, Attendance, and Documents.
- `CrmPermissions.hrEdit`: Grants write access to Employee profiles and Attendance records.
- `CrmPermissions.payrollView`: Required for viewing compensation figures, payroll periods, and salary reports.
- `AccountType.admin`: Required for approval decisions, KPI creation, and payroll period locking.

---

## 12. Employee Integration Contract

- **DTO Model:** `EmployeeDto` mapping JSON fields (`id`, `name`, `department`, `designation`, `email`, `phone`, `status`, `joining_date`, `salary`).
- **Status Mapping:** String values `'active'`, `'inactive'`, `'on_leave'` map to `EmploymentStatus`.
- **Search & Pagination:** Case-insensitive search on `name`, `department`, `designation`.
- **Immutability:** Backend updates must return the complete updated employee entity.

---

## 13. Documents Integration Contract

- **Upload:** Requires `multipart/form-data` with fields `title`, `category`, `description`, and file binary.
- **Storage:** Backend manages actual object storage (S3 / local filesystem); database stores metadata and file size.
- **Download:** Backend must provide an authenticated stream or time-limited signed URL; direct public exposure is prohibited.

---

## 14. Attendance Integration Contract

- **Date Format:** Normalized ISO 8601 UTC date string (`YYYY-MM-DD`).
- **Timestamps:** Check-in and check-out timestamps in ISO 8601 UTC.
- **Status Vocabulary:** Frozen to `'present'`, `'absent'`, `'half_day'`, `'on_leave'`.
- **Missing Records:** Absence of an attendance record for a date must NOT be interpreted as `'absent'` unless explicitly recorded.

---

## 15. KPI Integration Contract

- **Metrics Representation:** Stored numeric targets and actual values (`target_value`, `actual_value`, `score`).
- **Zero Client Calculation:** The frontend displays only stored scores from the backend; client-side grading formulas or performance rankings are prohibited.

---

## 16. Payroll Integration Contract

- **Monetary Representation:** Financial amounts represented as decimal numbers with fixed 2-decimal precision.
- **Components:** Basic salary, allowances, deductions, net salary.
- **Security:** Payroll endpoints must enforce strict permission checks (`payrollView`); responses must never be leaked to general HR users.

---

## 17. Payroll Calculation Authority

- **Preview vs Stored Authority:**
  - `PayrollCalculationService` (HR-7) provides deterministic, non-persisted client-side preview.
  - Authoritative calculation, tax computation, statutory rate application, and finalization belong exclusively to the backend.
- **Parity Requirement:** When backend calculation endpoints become available, client-side preview formulas must be calibrated against backend results.

---

## 18. Reports and Export Integration

- **Query-Based Reports:** In-app reports (Employee, Attendance, KPI, Payroll) operate over domain entities.
- **Export Separation:** File generation (CSV/Excel/PDF) for large enterprise datasets should be performed server-side by the backend to prevent mobile memory exhaustion.

---

## 19. Approvals Integration

- **Workflow Types:** `'payroll_finalization'`, `'attendance_correction'`, `'document_verification'`.
- **Statuses:** `'pending'`, `'approved'`, `'rejected'`, `'cancelled'`.
- **Concurrency & Locking:** The backend must provide transactional serialization and row-level locks for concurrent decision resolution.

---

## 20. Notifications Integration

- **Channel:** In-app notification delivery (`channel: 'in_app'`).
- **Hardware Push:** Push delivery (FCM / APNS) and email dispatch (SMTP) must be managed by the backend; no mobile push SDKs will be added to Flutter without explicit approval.

---

## 21. Data Types and Serialization Rules

- **UUIDs / IDs:** Strings. No automatic parsing to numeric integers.
- **Dates & Times:** ISO 8601 strings normalized to UTC (`2026-02-01T10:00:00Z`).
- **Booleans:** Strict boolean JSON values (`true`, `false`), not integers (`1`, `0`).
- **Enums:** Snake_case string serialization matching Dart enum names.
- **Null Safety:** Missing fields vs. explicit `null` must be parsed safely using default fallbacks where appropriate.

---

## 22. Date, Time & Timezone Semantics

- All timestamps transmitted across API boundaries must be in **UTC**.
- Local device timezone display formatting is handled exclusively in the UI presentation layer.

---

## 23. Monetary Precision and Currency Semantics

- **Standard Currency:** USD (`$`) default, extensible to multi-currency.
- **Precision:** 2 decimal places. Floating-point arithmetic errors must be avoided by using integer cents or decimal string representation where necessary.

---

## 24. Pagination, Search, Filter & Sort Contract

- **Pagination Structure:**
  ```json
  {
    "items": [...],
    "page": 1,
    "page_size": 20,
    "total_count": 150,
    "total_pages": 8
  }
  ```
- **Query Parameters:** `page`, `page_size`, `search`, `sort_by`, `sort_order` (`asc`, `desc`).

---

## 25. Error and Retry Semantics

- **Error Response Schema:**
  ```json
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Target entity ID is required.",
      "details": {}
    }
  }
  ```
- **HTTP Status Codes:**
  - `400 Bad Request`: Validation failure.
  - `401 Unauthorized`: Missing or expired session token.
  - `403 Forbidden`: Insufficient module permissions.
  - `404 Not Found`: Entity does not exist.
  - `409 Conflict`: Concurrent decision or duplicate request.
  - `500 Server Error`: Backend internal error.
- **Retry Policy:** Safe only for idempotent `GET` operations. Never automatically retry non-idempotent `POST` requests.

---

## 26. Configuration and Environments

The frontend configuration must support three distinct environments:
1. `development`: Local development host (e.g. `http://10.0.2.2:8000` for Android emulator, `http://localhost:8000` for Web).
2. `staging`: Remote test server with valid TLS certificate (`https://staging-api.crm.example.com`).
3. `production`: High-availability remote server with mandatory HTTPS (`https://api.crm.example.com`).

---

## 27. Android Network Requirements

- **Permissions:** Android `INTERNET` permission in `AndroidManifest.xml`.
- **Host Resolution:** Android emulator requires `10.0.2.2` to route to host machine `localhost`. Physical devices require local LAN IP or ngrok/tunnel.
- **Cleartext Policy:** Insecure cleartext HTTP (`http://`) must be restricted to local development; production must enforce HTTPS.

---

## 28. Web / CORS Requirements

- **Cross-Origin Resource Sharing (CORS):** The backend must configure `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`, and `Access-Control-Allow-Headers` to permit Flutter Web origins.
- **Credentials:** If cookies are used, `Access-Control-Allow-Credentials: true` is mandatory.

---

## 29. Credential and Sensitive-Data Security

- Zero hardcoded passwords or API secret keys in client source code.
- Tokens stored securely in memory or session storage.
- Logging must redact `Authorization` headers, sensitive financial figures, and employee PII.

---

## 30. Backend / Frontend Ownership Matrix

| Area | Frontend Responsibility | Instructor Backend Responsibility |
| :--- | :--- | :--- |
| **Authentication** | Collect credentials, store session token, UI state | Hash passwords, issue JWT, verify signatures |
| **Authorization** | Defense-in-depth UI visibility & route guards | Authoritative RBAC on all endpoints & database RLS |
| **Data Persistence** | Deterministic mocks & API DTO mapping | Relational database storage, ACID transactions |
| **Concurrency** | Request version tokens & double-tap lock | Server-side locking & entity version checks |
| **Notifications** | In-app notification inbox & badge UI | Push token registration & FCM/APNS delivery |
| **Calculations** | Client preview calculation engine | Authoritative payroll, tax, and deduction calculations |

---

## 31. Contract Conflicts

- **Calculation Ownership:** `PayrollCalculationService` computes preview values client-side; backend calculations may introduce divergent formulas. *Resolution:* Backend must become the ultimate source of truth in HR-10.
- **Export Logic:** Draft schema proposes backend export generation; HR-8 implemented client-side query summaries. *Resolution:* Maintain client summaries, delegate file compilation to backend.

---

## 32. Unverified Requirements

- Exact authentication endpoint URLs and payload formats.
- Precise database schema table names.
- File storage upload mechanisms (direct multipart vs. presigned S3 URLs).
- Server-side export format support.

---

## 33. Backend Blockers

- **BLOCKER-01:** No live instructor backend repository or deployed API endpoint is available in the current environment.
  - *Impact:* Live network calls cannot be executed.
  - *Mitigation:* Implement a robust, configurable `ApiTransport` and `ApiClient` foundation with deterministic test fakes and verified base URL validation in HR-10.2.

---

## 34. HR-10.2 Readiness

The project is **READY** to implement the HR-10.2 configuration and API client foundation:
- Existing repository abstractions are clean and modular.
- Domain entities are completely decoupled from transport code.
- Environment configuration and base URL validation can be implemented cleanly.
- Abstract `ApiTransport` and `ApiClient` can be verified with comprehensive unit tests without breaking existing mock repositories.

---

## 35. Later HR-10 Implementation Order

1. **HR-10.1:** Requirements & Contract Audit (`AUDIT COMPLETE — BACKEND CONTRACT PENDING`).
2. **HR-10.2:** Backend Configuration & API Client Foundation (`ApiTransport`, `ApiClient`, `BackendConfig`).
3. **HR-10.3:** Employee Repository Backend Adapter.
4. **HR-10.4:** Attendance Repository Backend Adapter.
5. **HR-10.5:** KPI Repository Backend Adapter.
6. **HR-10.6:** Payroll Repository Backend Adapter.
7. **HR-10.7:** Reports Repository Backend Adapter.
8. **HR-10.8:** Approvals Repository Backend Adapter.
9. **HR-10.9:** Notifications Repository Backend Adapter.
10. **HR-10.10:** Final Backend Integration UAT & Cutover.

---

## 36. HR-10.1 Exit Criteria

- [x] Git baseline inspected and clean.
- [x] Project development rules verified.
- [x] Existing HR status verified (HR-1 through HR-9 green).
- [x] Backend source absence documented truthfully.
- [x] Existing HR repositories audited.
- [x] API contract matrix created with explicit statuses.
- [x] Authentication & authorization contracts audited.
- [x] CRM user vs. Employee identity mapping documented.
- [x] Employee, Documents, Attendance, KPI, Payroll, Reports, Approvals, Notifications audited.
- [x] Data types, dates, monetary precision, pagination, and error semantics documented.
- [x] Android and Web networking considerations audited.
- [x] Requirements deliverable created: `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md`.

**Audit Conclusion:**  
`AUDIT COMPLETE — BACKEND CONTRACT PENDING`
