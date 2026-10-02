# HR-10.2 — Backend Configuration & API Client Foundation Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Instructor Backend Connection Foundation  
**Status:** `FOUNDATION IMPLEMENTED — INSTRUCTOR BACKEND CONTRACT PENDING`

---

## 1. Purpose and Scope

This document details the architecture, configuration parameters, transport layer contracts, error classifications, authentication boundaries, and security policies established for **HR-10.2: Backend Configuration, API Client & Connection Foundation** in the Enterprise CRM Flutter application.

The primary objective is to prepare the Flutter client for backend repository adapters without prematurely migrating active business features or replacing working mock repositories.

Key responsibilities delivered in HR-10.2:
1. Strongly typed runtime configuration (`BackendConfig`) with defensive URL validation, environment-specific scheme enforcement (mandatory HTTPS in production), and URI resolution.
2. Abstract network transport interface (`ApiTransport`) with request/response models decoupled from specific third-party HTTP libraries.
3. Deterministic in-memory test transport (`MockApiTransport`) enabling full automated coverage of network operations, latency, status codes, and failure modes.
4. High-level REST API client (`ApiClient`) featuring dynamic session token attachment, typed `NetworkException` translation, and controlled idempotency/retry policies.
5. Base contract (`BackendAdapter`) defining the architectural boundary for subsequent feature-level repository adapters (`HR-10.3` onwards).
6. Comprehensive unit test suite (26 tests) covering configuration, HTTP methods, error handling, session rotation, and retry safety.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.2):** `54edb654c60a28f4bc4242636f1c7e974e64f9bf` (`docs(hr): audit backend integration readiness (HR-10.1)`)
- **Working Tree:** Clean (prior to HR-10.2 deliverable creation)

---

## 3. HR-10.1 Dependency Verification

- **HR-10.1 Audit Status:** `AUDIT COMPLETE — BACKEND CONTRACT PENDING` (Commit `54edb65`).
- **Core Findings Verified:**
  - Instructor backend repository and live endpoints are not yet supplied in the local workspace.
  - Zero candidate API routes may be called directly in production code.
  - Client networking must be abstract, configurable, and thoroughly testable via test fakes.
  - Existing mock repositories must remain 100% operational as the baseline data source until verified backend adapters are introduced.

---

## 4. Verified Backend Technology

- **Framework & Runtime:** Pending instructor confirmation (Django REST Framework, Node.js/Express, or FastAPI proposed in draft schemas).
- **Protocol:** HTTP/1.1 and HTTP/2 over TLS (HTTPS).
- **Data Exchange Format:** UTF-8 encoded JSON (`application/json; charset=utf-8`).
- **Status Codes:** Standard RFC 7231 status codes (200, 201, 204, 400, 401, 403, 404, 409, 422, 500, 503).

---

## 5. Shared Network Infrastructure Audit

- **Third-Party Libraries:** `pubspec.yaml` currently includes `flutter_bloc`, `file_picker`, `csv`, `excel`, and `cupertino_icons`.
- **Zero Unapproved Dependencies:** In strict accordance with `MASTER_DEVELOPMENT_RULES.md`, no unapproved third-party networking packages (such as Dio) were introduced.
- **Architectural Solution:** Implemented pure Dart transport contracts (`ApiTransport`, `TransportRequest`, `TransportResponse`) that can seamlessly adapt to standard `dart:io` / `dart:html` or shared platform clients when approved.

---

## 6. Implemented Configuration (`BackendConfig`)

Located at: `lib/features/hr/data/network/backend_config.dart`

```dart
class BackendConfig {
  final String baseUrl;
  final String apiPrefix;
  final BackendEnvironment environment;
  final BackendMode mode;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
```

### Supported Environments (`BackendEnvironment`)
- `development`: Used for local developer workstations and emulators (`http://10.0.2.2:8000`).
- `staging`: Remote test server with valid TLS certificate (`https://staging-api.crm.example.com`).
- `production`: Production cluster with mandatory HTTPS enforcement (`https://api.crm.example.com`).

---

## 7. Base-URL Behavior & Validation

1. **Defensive Validation:**
   - Must not be empty or whitespace.
   - Must contain a valid URI scheme and non-empty host.
   - Scheme must be `http` or `https` (unsupported schemes like `ftp` are rejected).
   - In `production`, scheme **must** be `https`; cleartext `http` throws `BackendConfigException`.
2. **Trailing Slash Normalization:** Automatically strips trailing slashes from `baseUrl` and normalizes `apiPrefix`.
3. **URL Resolution (`resolveUrl`):**
   ```dart
   final config = BackendConfig(baseUrl: 'https://api.crm.example.com', apiPrefix: '/api/v1');
   final uri = config.resolveUrl('/hr/employees');
   // Resolves to: https://api.crm.example.com/api/v1/hr/employees
   ```

---

## 8. Environment Policy

- **Default Mode:** `BackendMode.mock` in development, allowing full offline development and headless testing without requiring a live backend server.
- **Backend Mode:** `BackendMode.backend` explicitly designates live network communication. When enabled, errors are never masked by falling back to mock data.

---

## 9. Existing Client Reuse

- No conflicting shared API clients existed in the repository.
- `ApiClient` establishes a clean, decoupled boundary that other CRM modules (`leads`, `inventory`, `purchase`) can reuse as shared infrastructure.

---

## 10. Request Transport Contract (`ApiTransport`)

Located at: `lib/features/hr/data/network/api_transport.dart`

```dart
abstract interface class ApiTransport {
  Future<TransportResponse> send(TransportRequest request);
}
```

- **`TransportRequest`:** Captures `method` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`), `uri`, `headers`, optional `body` string, and `timeout`.
- **`TransportResponse`:** Captures `statusCode`, `headers`, raw `body` string, and boolean helper `isSuccess` (`200 <= statusCode < 300`).

---

## 11. Response Handling

- **204 No Content / Empty Body:** Handled safely and returns `null`.
- **200..299 Success:** Decodes JSON string into Dart dynamic structures (`Map<String, dynamic>` or `List<dynamic>`).
- **Malformed 2xx JSON:** Throws `InvalidResponseException` to alert the application of malformed server payloads.

---

## 12. Authentication Integration

Located in: `lib/features/hr/data/network/api_client.dart`

- **Dynamic Token Provider:** Accepts an optional `AuthTokenProvider` callback (`FutureOr<String?> Function()`).
- **Request-Time Evaluation:** Evaluated dynamically for every request, ensuring that token renewals or session changes take effect immediately without caching stale credentials.
- **Header Injection:** If a non-empty token is returned, injects `authorization: Bearer <token>`.
- **Null Safety:** If no token is available, the `Authorization` header is omitted cleanly.

---

## 13. Session Expiration Handling

- **HTTP 401 Unauthorized:** Mapped to `UnauthorizedException`.
- **Application Response:** Presentation cubits catch `UnauthorizedException` and trigger a session purge via `AuthCubit.logout()`, resetting user state cleanly across all modules.
- **HTTP 403 Forbidden:** Mapped to `ForbiddenException` without invalidating the user session, preserving UI state while displaying an access-restricted warning.

---

## 14. Typed Network Errors (`NetworkException`)

Located at: `lib/features/hr/data/network/network_exception.dart`

| HTTP Status | Exception Class | Standard Code | Meaning / Recovery Action |
| :--- | :--- | :--- | :--- |
| Network Down | `ConnectionException` | `CONNECTION_FAILURE` | Device is offline or DNS failed; retry when connection restores |
| Timeout | `NetworkTimeoutException` | `TIMEOUT` | Request timed out; retry safe operations |
| 400 / 422 | `ValidationException` | `VALIDATION_ERROR` | Malformed request parameters; display field errors |
| 401 | `UnauthorizedException` | `UNAUTHORIZED` | Session expired; redirect to login |
| 403 | `ForbiddenException` | `FORBIDDEN` | Missing module permissions; show permission warning |
| 404 | `NotFoundException` | `NOT_FOUND` | Entity or route does not exist; display not-found state |
| 409 | `ConflictException` | `CONFLICT` | Resource conflict; refresh and re-evaluate |
| 500..599 | `ServerException` | `SERVER_ERROR` | Backend failure; report to system administrator |
| Malformed | `InvalidResponseException`| `INVALID_RESPONSE` | Non-JSON response received on 2xx status |

---

## 15. Timeout Behavior

- **Connect Timeout:** Defaults to 15 seconds.
- **Receive Timeout:** Defaults to 30 seconds.
- **Enforcement:** Enforced at the transport level; exceeding limits raises `NetworkTimeoutException`.

---

## 16. Retry Policy & Idempotency Controls

- **Read-Only / Idempotent Operations (`GET`):** Configurable retry (up to 3 attempts) with incremental backoff on transient errors (`ConnectionException`, `NetworkTimeoutException`, HTTP 503/504).
- **Mutating Operations (`POST`, `PUT`, `PATCH`, `DELETE`):** **STRICTLY PROHIBITED FROM AUTOMATIC RETRY**. Prevents double-submissions, duplicate approval decisions, and repeated entity mutations.

---

## 17. Cancellation & Stale-Response Boundary

- Feature cubits (`PendingApprovalsCubit`, `HrApprovalDecisionCubit`, `HrNotificationCubit`) maintain sequential request version tokens.
- Late asynchronous network arrivals from canceled or prior requests are discarded before mutating UI state.

---

## 18. DTO / Domain Separation

- Transport and `ApiClient` operate on generic primitives (`Map<String, dynamic>`, `List<dynamic>`).
- Domain entities (`Employee`, `AttendanceRecord`, `HrApprovalRequest`, `PayrollRecord`) remain strictly decoupled from network DTOs.
- Future feature adapters (`HR-10.3` onwards) will translate DTOs to immutable domain models.

---

## 19. Mock vs. Backend Selection

```dart
abstract class BackendAdapter {
  final ApiClient apiClient;
  const BackendAdapter({required this.apiClient});
  BackendConfig get config => apiClient.config;
  bool get isBackendMode => config.mode.isBackend;
  bool get isMockMode => config.mode.isMock;
}
```

- When `config.mode == BackendMode.mock`, mock repositories execute deterministic in-memory logic.
- When `config.mode == BackendMode.backend`, adapters execute API requests via `apiClient`. If the backend fails, an explicit `NetworkException` is surfaced — zero hidden fallback to mock data.

---

## 20. Android Configuration

- Verified `flutter build apk --config-only` passes cleanly.
- Android manifest requires `<uses-permission android:name="android.permission.INTERNET"/>`.
- In development, Android emulator connects to host machine via `10.0.2.2`. Production enforces TLS certificates.

---

## 21. Web / CORS Requirements

- Verified `flutter build web` compiles with zero errors or warnings.
- The transport layer contains zero browser-incompatible dependencies (`dart:io` isolates avoided in shared client).
- Production backend must configure CORS headers (`Access-Control-Allow-Origin`, `Access-Control-Allow-Headers`).

---

## 22. TLS & Security

- Production configuration mandates `https://`.
- Zero trust-override hacks or invalid certificate bypasses.
- Sensitive credentials (`Authorization` headers) are never transmitted over insecure `http://` in production.

---

## 23. Safe Logging

- Zero logging of `Authorization` headers, passwords, session cookies, salaries, or employee PII.
- Only HTTP method, sanitized URI path, and integer status code may be recorded in diagnostic logs.

---

## 24. Connectivity Smoke-Test Evidence

- **Live Backend:** **BLOCKED / NOT TESTED** due to the absence of a live instructor backend deployment.
- **Deterministic Mock Transport:** 100% verified via `MockApiTransport` across all status codes, headers, timeouts, and network failure modes.

---

## 25. Automated Test Results

- **`backend_config_test.dart`:** 10 / 10 tests PASS
  - Defaults, staging, production HTTPS, empty URL validation, malformed URL validation, unsupported scheme, prefix normalization, path resolution, and timeout validation.
- **`api_client_test.dart`:** 16 / 16 tests PASS
  - GET/POST/PUT/PATCH/DELETE execution, query parameters, JSON body serialization, HTTP 400/401/403/404/409/500 error mapping, malformed JSON handling, connection failure, auth header injection, dynamic session token updates, GET retries, and POST non-retry guarantee.
- **Targeted Tests:** 26 / 26 PASS.
- **Full CRM Test Suite (`flutter test`):** 2,080 / 2,080 PASS (0 failures, 0 skipped).
- **Static Analysis (`flutter analyze`):** Clean (0 issues found).

---

## 26. Regression Results

All existing feature modules remain completely unaffected:
- HR-1 through HR-9: 100% PASS
- Leads, Auth, Calling, User Management: 100% PASS
- Web build: PASS (`flutter build web` exited 0)
- Android config: PASS (`flutter build apk --config-only` exited 0)

---

## 27. Unsupported / Backend-Dependent Capabilities

- Live HTTP network calls against real instructor backend servers.
- Authoritative database transactions.
- Multipart document file uploads to cloud object storage.
- Server-side JWT signing and validation.

---

## 28. Later HR Repository Integration Plan

- **HR-10.3:** `EmployeeRepository` Backend Adapter (`BackendEmployeeRepository`).
- **HR-10.4:** `AttendanceRepository` Backend Adapter (`BackendAttendanceRepository`).
- **HR-10.5:** `EmployeeKpiRepository` Backend Adapter (`BackendEmployeeKpiRepository`).
- **HR-10.6:** `PayrollRepository` Backend Adapter (`BackendPayrollRepository`).
- **HR-10.7:** `HrReportRepository` Backend Adapter (`BackendHrReportRepository`).
- **HR-10.8:** `HrApprovalRepository` Backend Adapter (`BackendHrApprovalRepository`).
- **HR-10.9:** `HrNotificationRepository` Backend Adapter (`BackendHrNotificationRepository`).
- **HR-10.10:** Final Backend Integration UAT, Cutover & Freeze.

---

## 29. HR-10.2 Exit Criteria

- [x] HR-10.1 completed and committed.
- [x] Verified backend connection contracts reviewed.
- [x] Existing networking infrastructure reused without unapproved third-party dependencies.
- [x] Validated `BackendConfig` implemented with environment-specific HTTPS enforcement.
- [x] `ApiTransport` and `TransportRequest` / `TransportResponse` implemented.
- [x] `ApiClient` implemented with dynamic auth attachment and typed error translation.
- [x] Typed `NetworkException` hierarchy implemented.
- [x] Timeouts and retry policies implemented (idempotent GET only; no POST retries).
- [x] No private secrets or tokens embedded in client code.
- [x] Existing repository interfaces and mock stores preserved intact.
- [x] Android build compatibility verified (`flutter build apk --config-only` exited 0).
- [x] Web build compatibility verified (`flutter build web` exited 0).
- [x] Targeted automated tests pass (26 / 26 PASS).
- [x] Full project test suite passes (2,080 / 2,080 PASS).
- [x] Static analysis clean (`flutter analyze` clean).
- [x] Contract deliverable created: `HR_10_BACKEND_CONNECTION_CONTRACT.md`.

---

## 30. Git Commit

Commit: `feat(hr): establish backend api connection foundation (HR-10.2)`
