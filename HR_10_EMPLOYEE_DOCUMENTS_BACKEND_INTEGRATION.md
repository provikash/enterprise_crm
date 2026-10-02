# HR-10.5 — Employee Documents Backend Integration Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) — Employee Documents Backend Integration  
**Status:** `IMPLEMENTED — LIVE UAT PENDING`

---

## 1. Purpose and Scope

This document defines the backend communication contracts, data transfer models, domain mappings, security policies, and controlled cutover mechanism established for **HR-10.5: Employee Documents Backend Integration** in the Enterprise CRM Flutter application.

Following the roadmap established in HR-10.1 and the repository foundation created in HR-10.2 through HR-10.4, HR-10.5 connects the Employee Documents feature (HR-3) to the instructor backend:
1. **`EmployeeDocumentDto`** (`lib/features/hr/data/dto/employee_document_dto.dart`): Strict serialization and validation boundary parsing backend JSON structures, guarding mandatory keys (`id`, `employee_id`, `title`, `file_name`), and normalizing UTC timestamps.
2. **`BackendEmployeeDocumentRepository`** (`lib/features/hr/data/repositories/backend_employee_document_repository.dart`): Production-compatible implementation of `EmployeeDocumentRepository` connecting listing, single document retrieval, document uploading, and authenticated binary downloads to the backend.
3. **Controlled Mock / Backend Cutover**: Introduction of `EmployeeDocumentRepositoryFactory` (`lib/features/hr/data/repositories/employee_document_repository_factory.dart`) ensuring explicit mode selection without silent fallback to mock data on backend failure.
4. **Privacy & File Security**: Enforces local file validation (10 MB cap, non-empty content), prevents plaintext credential leakage, and protects sensitive workforce documents.
5. **Cubit & Screen Wiring**: Direct compatibility with `EmployeeDocumentsCubit`, `EmployeeDocumentsScreen`, `EmployeeDocumentDetailsScreen`, and `UploadDocumentScreen`.

---

## 2. Starting Git State

- **Current Branch:** `feature/hr-10-backend-integration`
- **Starting HEAD (for HR-10.5):** `90f80a1334c9c277bf8238612711dc10d8a55dbb` (`feat(hr): integrate employee management backend (HR-10.4)`)
- **HR-10.1 Commit:** `54edb65f4ca400667d14a4d277d8fe2c61c33f0a`
- **HR-10.2 Commit:** `55288ab2193e60c64cbb8a7bedb8dd409425a410`
- **HR-10.3 Commit:** `326adc3ea6dca1375d86290ea8111e5ae5d78627`
- **HR-10.4 Commit:** `90f80a1334c9c277bf8238612711dc10d8a55dbb`

---

## 3. HR-10.1 Through HR-10.4 Dependency Status

| Checkpoint | Status | Delivery |
| :--- | :--- | :--- |
| HR-10.1 Audit | `VERIFIED` | Document & commit `54edb65` |
| HR-10.2 Connection | `VERIFIED` | `ApiClient`, `BackendConfig`, `NetworkException`, commit `55288ab` |
| HR-10.3 Adapter | `VERIFIED` | `BackendEmployeeRepository` base, commit `326adc3` |
| HR-10.4 Employee | `VERIFIED` | Full Employee CRUD & controlled cutover, commit `90f80a1` |

---

## 4. HR-3 Feature Inventory

| Screen / Component | Role | Interface Method | Integration State |
| :--- | :--- | :--- | :--- |
| `EmployeeDocumentsScreen` | Document list for employee | `getDocumentsForEmployee(id)` | Backend-backed via `BackendEmployeeDocumentRepository` |
| `EmployeeDocumentDetailsScreen` | Single document inspection | `getDocumentById(id)` | Backend-backed via `BackendEmployeeDocumentRepository` |
| `UploadDocumentScreen` | Upload modal / screen | `uploadDocument(input)` | Backend-backed via `BackendEmployeeDocumentRepository` |
| Document Download Action | Binary file download | `downloadDocumentFile(id)` | Backend-backed via `BackendEmployeeDocumentRepository` |

---

## 5. Verified Documents API Contracts

Derived from `CRM_Backend_Schema.md` §10 and `HR_10_BACKEND_INTEGRATION_REQUIREMENTS.md` §13:
- **`GET /api/v1/hr/employees/{id}/documents`**: Returns JSON array or envelope of documents associated with `{id}`.
- **`GET /api/v1/hr/documents/{id}`**: Returns JSON object for single document metadata.
- **`POST /api/v1/hr/employees/{id}/documents`**: Encodes file payload (`file_content_base64`, `file_name`, `title`, `document_type`, etc.) and returns created document metadata.
- **`GET /api/v1/hr/documents/{id}/download`**: Returns authenticated binary stream or base64 JSON envelope.

---

## 6. Implemented Operations

1. `getDocumentsForEmployee(String employeeId)`: Resolves all active documents scoped to the specified employee.
2. `getDocumentById(String documentId)`: Returns metadata or `null` if HTTP 404 Not Found.
3. `uploadDocument(UploadDocumentInput input)`: Validates input locally and uploads to backend.
4. `downloadDocumentFile(String documentId)`: Fetches binary content with authenticated header attachment.

---

## 7. DTO / Domain Mapping

`EmployeeDocumentDto` maps:
- `id` -> `EmployeeDocument.id`
- `employee_id` -> `EmployeeDocument.employeeId`
- `title` -> `EmployeeDocument.title`
- `file_name` -> `EmployeeDocument.fileName`
- `file_extension` -> `EmployeeDocument.fileExtension`
- `file_size_bytes` -> `EmployeeDocument.fileSizeBytes`
- `document_type` -> `EmployeeDocument.documentType`
- `expiry_date` -> `EmployeeDocument.expiryDate`
- `uploaded_at` -> `EmployeeDocument.uploadedAt`
- `uploaded_by` -> `EmployeeDocument.uploadedBy`
- `file_reference` -> `EmployeeDocument.fileReference`

---

## 8. Employee / Document Identity

- **`employeeId`**: Foreign key pointing to internal workforce record (`Employee.id`).
- **`id` / `documentId`**: Stable primary key of the document record.
- **Strict Invariant**: Document operations never confuse document identity with employee identity or CRM user identity.

---

## 9. Document Types and Statuses

- **Types**: Flexible strings supported by domain ('Resume', 'Identity', 'Education', 'Contract', 'Other').
- **Status & Expiry**: `isExpired()` computed relative to UTC timestamp without timezone drift.

---

## 10. Document Listing

- Scoped to `employeeId`.
- Empty employee IDs return empty list immediately without unnecessary network calls.
- Encapsulated in `EmployeeDocumentsCubit.loadDocuments()`.

---

## 11. Document Details

- Retrieves document metadata by `documentId`.
- 404 response returns `null`.

---

## 12. Upload Contract & Validation

- `UploadDocumentInput.validate()` enforces:
  - Non-empty `employeeId`, `title`, `documentType`, and `fileName`.
  - File size > 0 and <= 10 MB (10,485,760 bytes).
  - Non-empty byte buffer.

---

## 13. Download & Security Policy

- Downloads executed via authenticated `GET /hr/documents/{id}/download`.
- Bearer token attached dynamically; no private download links exposed in unrestricted client logs.

---

## 14. Replacement and Deletion Policy

- Deletion is deferred from production cutover to preserve audit integrity.
- Replaced documents are handled as new version uploads.

---

## 15. HR-9 Approval Dependencies

- Document verification approval workflows (HR-9) continue to reference stable `documentId` and `employeeId` without premature state mutation.

---

## 16. Authorization and Session Isolation

- Requires `hrView` permission to view documents; `hrEdit` to upload.
- HTTP 403 Forbidden is translated cleanly to `EmployeeDocumentException(code: 'forbidden')`.
- HTTP 401 Unauthorized maps to `EmployeeDocumentException(code: 'unauthorized')`.

---

## 17. Mock / Backend Separation

- Handled via `EmployeeDocumentRepositoryFactory`:
  - `BackendMode.backend`: `BackendEmployeeDocumentRepository`.
  - `BackendMode.mock`: `MockEmployeeDocumentRepository`.
  - Zero silent fallback to mock data on backend error.

---

## 18. Platform Verification

- **Android:** Verified clean via `flutter build apk --config-only`.
- **Web:** Verified clean compilation via `flutter build web`.

---

## 19. Automated Tests

- **`employee_document_dto_test.dart`:** 5 / 5 PASS.
- **`backend_employee_document_repository_test.dart`:** 14 / 14 PASS.
- **`employee_document_backend_integration_test.dart`:** 2 / 2 PASS.
- **Total HR-10.5 Tests:** 21 / 21 PASS.

---

## 20. Live Verification & Manual UAT

- **Live Server Test:** `BLOCKED / NOT TESTED` due to absent instructor live backend server.
- **Automated Mock-Transport UAT:** 100% PASS.
- **Status:** `IMPLEMENTED — LIVE UAT PENDING`.

---

## 21. Git Commit Reference

- **Commit Message:** `feat(hr): integrate employee documents backend (HR-10.5)`
