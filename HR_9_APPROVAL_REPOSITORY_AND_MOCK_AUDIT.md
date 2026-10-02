# HR-9.3 — Approval Repository & Mock Foundation Audit

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) & Shared Approvals Integration  
**Status:** `COMPLETE / VERIFIED`

---

## 1. Purpose

This document provides the architectural and verification audit for **HR-9.3: Approval Repository & Mock Foundation** in the Enterprise CRM Flutter application.

Following the frozen domain contracts of HR-9.1 and HR-9.2, HR-9.3 establishes a deterministic, thread-safe, and authorization-aware repository layer for HR approval requests. It provides clean interfaces and mock data sources for submitting and querying approval requests without executing unapproved decision mutations, fabricating backend endpoints, or mutating underlying HR domain records.

---

## 2. Starting Git Baseline

- **Branch:** `feature/hr-9-approvals-notifications`
- **Checkpoint Baseline:** `1019252` (`feat(hr): establish approval workflow domain (HR-9.2)`)
- **HR-9.1 Commit:** `55c295a` (`docs(hr): audit approval notification requirements (HR-9.1)`)
- **Working Tree State at Entry:** Clean (0 untracked files, 0 uncommitted changes)

---

## 3. HR-9.1 / HR-9.2 Dependency Verification

| Dependency | Required Contract | Verification Status |
| :--- | :--- | :--- |
| **HR-9.1 Requirements Document** | `HR_9_APPROVALS_NOTIFICATIONS_REQUIREMENTS.md` | Verified (`55c295a`). Establishes audit baseline, requester rules, and prohibition on premature record mutation. |
| **HR-9.2 Workflow Contract** | `HR_9_APPROVAL_WORKFLOW_CONTRACT.md` | Verified (`1019252`). Establishes domain models, transitions, and authorization boundaries. |
| **Domain Entities** | `HrApprovalRequest`, `HrApprovalTarget`, `HrApprovalStatus`, `HrApprovalWorkflowType` | Verified and tested (38/38 tests passing). |
| **Domain Validator** | `HrApprovalWorkflowValidator` | Verified pure state machine and terminal state protection. |
| **Initial Request Status** | `HrApprovalStatus.pending` strictly | Enforced at construction and repository submission. |

---

## 4. Shared Approval Repository Inventory

A thorough audit of the repository confirmed:
- No shared approval repository (`ApprovalRepository`) exists in `lib/features/approvals/`.
- The shared Approvals & Notifications module is currently unbuilt by collaborator Vikash Chaurasiya.
- Consequently, HR must provide its domain-level repository contract (`HrApprovalRepository`) inside `lib/features/hr/domain/repositories/` so that HR-9.4 presentation components can function reliably now and easily adapt to the shared module once it is introduced.

---

## 5. Shared-Module Ownership

In compliance with `Enterprise_CRM_Team_Collaboration_Handoff.md` §7, §16:
- Collaborator Vikash Chaurasiya owns `Approvals & Notifications` (`feature/approvals-notifications`).
- Lead Developer Vachaspati Mishra owns `HR / Payroll` (`lib/features/hr/`).
- HR-9.3 defines the HR-owned repository contract (`HrApprovalRepository`) and mock implementation (`MockHrApprovalRepository`) within `lib/features/hr/`.
- No files in other module boundaries were modified or created.

---

## 6. Implemented Repository Interface & Architecture

The repository layer is organized into:
1. **Domain Contract:** `lib/features/hr/domain/repositories/hr_approval_repository.dart` (`HrApprovalRepository`)
2. **In-Memory Mock Store:** `lib/features/hr/data/mock/mock_hr_approval_store.dart` (`MockHrApprovalStore`)
3. **Repository Implementation:** `lib/features/hr/data/repositories/mock_hr_approval_repository.dart` (`MockHrApprovalRepository`)

---

## 7. Supported Operations

The repository interface declares strictly confirmed, read/submission capabilities:
- `submitRequest({required workflowType, required requesterId, required target, remarks})`: Submits and stores a new request.
- `getRequestById(id)`: Retrieves a single request by its stable identifier, or returns `null`.
- `getRequestsSubmittedBy(requesterId)`: Retrieves all requests submitted by a specific CRM user, sorted newest-first.
- `getPendingRequests({CurrentUser? user})`: Retrieves pending requests visible to the authorized actor.
- `getRequestsForTarget(target)`: Retrieves all requests targeting a specific underlying HR entity.
- `getAllRequests({CurrentUser? user})`: Retrieves all requests visible to the user across all statuses.

**Explicit Exclusion:** `approveRequest` and `rejectRequest` methods are strictly omitted from HR-9.3, as decision execution belongs to HR-9.5.

---

## 8. Request Submission Contract

- **Initial Status:** All submitted requests are initialized to `HrApprovalStatus.pending`.
- **Identity Assignment:** The store automatically assigns an incrementing, stable identifier (`appr_req_101`, `appr_req_102`, etc.).
- **Timestamps:** Normalization to UTC (`DateTime.now().toUtc()`).
- **Input Validation:** Enforces non-empty `requesterId`, valid `target`, and non-empty `workflowType`.

---

## 9. Request Identity

The repository guarantees unambiguous relational separation:
- `requesterId`: References `CurrentUser.id` (e.g. `'usr_hr'`, `'usr_admin'`), **never** an `Employee.id`.
- `target`: `HrApprovalTarget` carrying `targetModule`, `targetEntityType`, and `targetEntityId`.
- Stable string keys are used throughout; zero reliance on list indices or display strings.

---

## 10. Pending Retrieval Semantics

- **Pending Definition:** Only requests with `status == HrApprovalStatus.pending` (`isPending == true`) are returned by `getPendingRequests()`.
- **Terminal Exclusion:** Terminal requests (`approved`, `rejected`, `cancelled`) are strictly excluded from pending query results.
- **Authorization Scoping:**
  - Administrators (`user.isAdmin`) see all pending requests across the HR domain.
  - Standard users (`!user.isAdmin`) only see pending requests that they submitted (`requesterId == user.id`).

---

## 11. Authorization Boundary

- Administrative privileges are evaluated via `user.isAdmin`.
- Standard user access is constrained to requests originating from their authenticated user account.
- Direct repository queries gracefully scope results without leaking unauthorized records.

---

## 12. Mock Data and Fixture Mapping

`MockHrApprovalStore` seeds deterministic fixtures referencing existing seeded entities from HR-1, HR-3, HR-4, and HR-6:
1. `appr_req_1`:
   - Target: `HrApprovalTarget.payrollPeriod('period_2026_01')`
   - Workflow: `HrApprovalWorkflowType.payrollFinalization`
   - Requester: `'usr_hr'`
   - Status: `pending`
   - Date: `2026-02-01 10:00:00Z`
2. `appr_req_2`:
   - Target: `HrApprovalTarget.attendanceRecord('att_1')`
   - Workflow: `HrApprovalWorkflowType.attendanceCorrection`
   - Requester: `'usr_standard'`
   - Status: `pending`
   - Date: `2026-02-02 11:30:00Z`
3. `appr_req_3`:
   - Target: `HrApprovalTarget.employeeDocument('doc_1')`
   - Workflow: `HrApprovalWorkflowType.documentVerification`
   - Requester: `'usr_admin'`
   - Status: `approved` (Terminal)
   - Date: `2026-01-15 09:00:00Z`

---

## 13. Empty vs Error Behavior

- **Empty State:** Queries returning no matching records return an empty list (`[]`), not `null` or synthetic placeholders.
- **Not Found:** `getRequestById()` returns `null` for non-existent IDs.
- **Simulated Error:** When `store.setShouldThrow(true)` is activated, all repository methods throw `HrApprovalWorkflowException`.

---

## 14. Duplicate & Idempotency Policy

- Repeated submission requests generate new distinct request instances with unique IDs.
- Double-click prevention in presentation layers (HR-9.4) will guard against accidental multi-submissions.
- Full transactional deduplication is backend-owned.

---

## 15. Side-Effect Restrictions

`MockHrApprovalRepository` enforces complete side-effect isolation:
- Does **not** mutate `MockEmployeeStore`.
- Does **not** mutate `MockAttendanceStore`.
- Does **not** mutate `MockEmployeeKpiStore`.
- Does **not** mutate `MockPayrollStore`.
- Does **not** dispatch notifications.
- Does **not** execute approval decisions.

---

## 16. Automated Tests

Automated unit tests in `test/features/hr/data/repositories/mock_hr_approval_repository_test.dart`:
- Request submission contract (pending status, stable ID, UTC date): **PASS**
- Validation of requester ID: **PASS**
- Request retrieval by ID (found vs null): **PASS**
- Submitted requests listing & ordering: **PASS**
- Pending queries (admin full visibility vs standard user scoping): **PASS**
- Requests for target reference: **PASS**
- All requests listing: **PASS**
- Deterministic ordering (newest first): **PASS**
- Defensive copy isolation: **PASS**
- Error injection and reset: **PASS**
- Side-effect isolation: **PASS**
- **Suite Result:** **18 / 18 PASS** (0 failures).

---

## 17. Backend Dependencies

- Future mapping of `HrApprovalRepository` to instructor backend REST/GraphQL endpoints (`/api/approvals`).
- Server-side access enforcement and audit persistence.

---

## 18. Deferred Functionality

- Decision mutations (`approve`, `reject`) -> Reserved for HR-9.5.
- Notification dispatch on request events -> Reserved for HR-9.8.
- Source record mutation upon approval -> Reserved for HR-9.6.

---

## 19. Open Blockers

None. The repository foundation is complete, deterministic, tested, and ready for HR-9.4 UI integration.

---

## 20. Exit Criteria

- [x] HR-9.1 verified.
- [x] HR-9.2 verified.
- [x] Shared Approvals ownership respected.
- [x] Approved repository contract implemented (`HrApprovalRepository`).
- [x] Deterministic mock implemented (`MockHrApprovalRepository`, `MockHrApprovalStore`).
- [x] Request submission implemented and verified.
- [x] Request retrieval implemented and verified.
- [x] Pending queries implemented and verified.
- [x] Stable identities preserved (`CurrentUser.id` $\ne$ `Employee.id`).
- [x] Authorization boundary maintained.
- [x] Empty and error states distinct.
- [x] Zero source HR records mutated.
- [x] Zero approval decisions implemented.
- [x] Zero notification delivery implemented.
- [x] Unit tests pass (18/18).
- [x] Flutter analyze clean (0 issues).
- [x] Audit document `HR_9_APPROVAL_REPOSITORY_AND_MOCK_AUDIT.md` created.

---

## 21. Git Commit Reference

- Checkpoint commit to be created: `feat(hr): implement approval repository foundation (HR-9.3)`
