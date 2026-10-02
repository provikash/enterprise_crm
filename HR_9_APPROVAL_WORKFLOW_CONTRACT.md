# HR-9.2 — Approval Domain & Workflow Contract

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) & Shared Approvals Integration  
**Status:** `DOMAIN CONTRACT ESTABLISHED — PERSISTENCE & UI GATED`

---

## 1. Purpose

This document defines the formal domain representation, entity contracts, state transition rules, and integration boundaries for **HR-9.2: Approval Domain & Workflow Contract** in the Enterprise CRM Flutter application.

Following the frozen findings of `HR_9_APPROVALS_NOTIFICATIONS_REQUIREMENTS.md` (HR-9.1), this contract establishes the minimum approved domain primitives required for HR features to integrate cleanly with the shared CRM Approvals capability without duplicating approval engines, inventing unapproved workflows, or premature repository mutations.

---

## 2. Starting Git Baseline

- **Branch:** `feature/hr-9-approvals-notifications`
- **Checkpoint Baseline:** `55c295a` (`docs(hr): audit approval notification requirements (HR-9.1)`)
- **Working Tree State at Entry:** Clean (1 commit ahead of `feature/hr-8-reports-export`)

---

## 3. HR-9.1 Dependency Status

The requirements audit executed in HR-9.1 established the following immutable constraints for HR-9.2:
1. **Shared Approvals Module Status:** The shared Approvals module (`lib/features/approvals/`) is currently **NOT IMPLEMENTED** in code (placeholder screen only).
2. **Module Ownership:** The shared Approvals & Notifications module is owned by collaborator Vikash Chaurasiya (`feature/approvals-notifications`). Vachaspati Mishra owns `lib/features/hr/`.
3. **No Duplicate Engine:** HR must not build a duplicate approval engine inside `lib/features/hr/`.
4. **No Premature Mutation:** Source HR entities (`Employee`, `AttendanceRecord`, `EmployeeKpi`, `PayrollRecord`, `PayrollPeriod`) must **never** be mutated while approval is pending.
5. **No Speculative Roles:** The system has exactly two account types (`AccountType.admin` and `AccountType.user`). Only administrators possess confirmed approval decision authority.

---

## 4. Existing CRM Approvals Domain Inventory

Prior to creating any domain code, the repository was audited for existing approval models:
- `lib/features/approvals/`: Does not exist.
- `lib/features/auth/domain/entities/crm_module.dart`: Declares `CrmModule.approvalsNotifications`.
- `lib/features/dashboard/presentation/mappers/crm_module_presentation.dart`: Maps `approvalsNotifications` to display labels and icon.
- `lib/features/auth/domain/policies/crm_permissions.dart`: Declares zero approval-related permissions.
- **Finding:** No reusable shared approval models existed in the repository prior to HR-9.2.

---

## 5. Shared-Module Ownership Decision

In strict adherence to `context/Enterprise_CRM_Team_Collaboration_Handoff.md` §7 and §16:
- HR implements the **HR boundary contracts and target reference models** in `lib/features/hr/domain/`.
- These domain contracts are designed as standard, pure Dart models that can be seamlessly consumed or wrapped by the shared `lib/features/approvals/` module once implemented by Vikash Chaurasiya.
- HR does not implement an approval repository or UI in HR-9.2; those belong to HR-9.3 through HR-9.5.

---

## 6. Reused Shared Models

- **`CrmModule` (`lib/features/auth/domain/entities/crm_module.dart`):** Reused directly to identify module ownership (`CrmModule.hrPayroll`, `CrmModule.approvalsNotifications`).
- **`CurrentUser` (`lib/features/auth/domain/entities/current_user.dart`):** Reused directly as the actor identity (`CurrentUser.id`) for requesters, approvers, and cancellers.
- **`AccountType` (`lib/features/auth/domain/entities/account_type.dart`):** Reused to verify administrative privileges (`user.isAdmin`).

---

## 7. HR-Specific Domain Extensions

The following domain contracts were implemented in `lib/features/hr/domain/`:
1. `HrApprovalStatus` (`lib/features/hr/domain/entities/hr_approval_status.dart`): Standard approval lifecycle status enum.
2. `HrApprovalTarget` (`lib/features/hr/domain/entities/hr_approval_target.dart`): Strongly-typed, stable reference to an underlying HR record.
3. `HrApprovalWorkflowType` (`lib/features/hr/domain/entities/hr_approval_workflow_type.dart`): Typed identifier for candidate HR approval workflows.
4. `HrApprovalRequest` (`lib/features/hr/domain/entities/hr_approval_request.dart`): Immutable approval request domain entity.
5. `HrApprovalDecision` (`lib/features/hr/domain/entities/hr_approval_decision.dart`): Immutable decision representation.
6. `HrApprovalHistoryEntry` (`lib/features/hr/domain/entities/hr_approval_history_entry.dart`): Immutable audit trail entry.
7. `HrApprovalWorkflowException` (`lib/features/hr/domain/exceptions/hr_approval_exception.dart`): Typed domain exception with standard error codes.
8. `HrApprovalWorkflowValidator` (`lib/features/hr/domain/services/hr_approval_workflow_validator.dart`): Pure state machine and authorization validation service.

---

## 8. Approval Request Identity

The `HrApprovalRequest` model enforces unambiguous relational identity:
- `id`: Non-empty stable string identifier (e.g. `'appr_req_101'`).
- `workflowType`: Explicit `HrApprovalWorkflowType` enum (`payrollFinalization`, `attendanceCorrection`, `documentVerification`).
- `requesterId`: Non-empty string referencing the authenticated CRM user account (`CurrentUser.id`), e.g. `'usr_admin'` or `'usr_hr'`.
- `target`: `HrApprovalTarget` reference pointing to the target entity.
- `status`: `HrApprovalStatus` (defaults to `HrApprovalStatus.pending`).
- `createdAt`: Normalized UTC timestamp (`DateTime.utc(...)`).
- `updatedAt`: Optional normalized UTC timestamp.
- `remarks`: Optional qualitative notes or submission remarks.

**Identity Separation Invariant:**
`requesterId` $\ne$ `Employee.id`. An employee without a CRM user account cannot be a requester. The requester is always a CRM account.

---

## 9. Target HR Entity Reference (`HrApprovalTarget`)

To prevent embedding large, volatile, or sensitive HR records directly into approval payloads, `HrApprovalTarget` encapsulates a lightweight, stable reference:
- `targetModule`: `CrmModule` (always `CrmModule.hrPayroll` for HR workflows).
- `targetEntityType`: String descriptor (`'payroll_period'`, `'attendance_record'`, `'employee_document'`).
- `targetEntityId`: Stable entity primary key (e.g. `'period_2026_01'`, `'att_001'`).

Helper factory constructors:
- `HrApprovalTarget.payrollPeriod(String periodId)`
- `HrApprovalTarget.attendanceRecord(String recordId)`
- `HrApprovalTarget.employeeDocument(String documentId)`

---

## 10. Confirmed Workflow Types (`HrApprovalWorkflowType`)

```dart
enum HrApprovalWorkflowType {
  payrollFinalization('hr.payroll_finalization', 'Payroll Period Finalization'),
  attendanceCorrection('hr.attendance_correction', 'Attendance Correction'),
  documentVerification('hr.document_verification', 'Employee Document Verification');
}
```

Unrecognized workflow identifiers return `null` via `HrApprovalWorkflowType.fromIdentifier()` and are rejected by validators.

---

## 11. Status Definitions (`HrApprovalStatus`)

- `pending`: Active request awaiting review and decision (`isTerminal == false`, `isPending == true`).
- `approved`: Formally authorized by an administrator (`isTerminal == true`, `isApproved == true`).
- `rejected`: Explicitly rejected by an administrator (`isTerminal == true`, `isRejected == true`).
- `cancelled`: Withdrawn by the requester or administrator (`isTerminal == true`, `isCancelled == true`).

---

## 12. Transition Matrix

Enforced by `HrApprovalStatus.canTransitionTo()` and `HrApprovalWorkflowValidator`:

| Source Status | Destination Status | Allowed? | Enforced Condition |
| :--- | :--- | :--- | :--- |
| `pending` | `approved` | **YES** | Decision by Admin |
| `pending` | `rejected` | **YES** | Decision by Admin |
| `pending` | `cancelled` | **YES** | Cancellation by Requester or Admin |
| `pending` | `pending` | **NO** | Throws `invalidTransition` |
| `approved` | Any | **NO** | Terminal state; throws `invalidTransition` |
| `rejected` | Any | **NO** | Terminal state; throws `invalidTransition` |
| `cancelled` | Any | **NO** | Terminal state; throws `invalidTransition` |

---

## 13. Requester and Decision-Maker Relationships

1. **Requester (`requesterId`):**
   - Must be an authenticated CRM user (`CurrentUser.id`).
   - Standard users with HR module access can initiate requests.
   - May cancel their own request while it remains `pending`.
2. **Decision-Maker (`actorId` in `HrApprovalDecision`):**
   - Must be an authenticated administrator (`user.isAdmin`).
   - If a standard user attempts to decide a request, the validator throws `HrApprovalWorkflowException.unauthorizedActor`.

---

## 14. Decision Contract (`HrApprovalDecision`)

Represents a formal decision action:
- `requestId`: Foreign key matching target `HrApprovalRequest.id`.
- `actorId`: Deciding CRM user (`CurrentUser.id`).
- `decisionType`: `HrApprovalDecisionType.approve` or `HrApprovalDecisionType.reject`.
- `decisionTime`: Normalized UTC timestamp.
- `reason`: Optional qualitative feedback/reason.

---

## 15. History Contract (`HrApprovalHistoryEntry`)

Represents an immutable chronological audit trail item:
- `id`: Stable history entry ID.
- `requestId`: Associated request ID.
- `actorId`: CRM user who performed the action.
- `action`: Descriptive action verb (`'submitted'`, `'approved'`, `'rejected'`, `'cancelled'`).
- `previousStatus`: Status prior to action (`null` for creation).
- `newStatus`: Resulting status.
- `timestamp`: UTC timestamp.
- `reason`: Optional reason/notes.

---

## 16. Proposed-Change / Source-Record Relationships

- **Read-Only / Reference Authority:** The approval request references the target HR entity by `HrApprovalTarget`.
- **No In-Flight Mutation:** Source records in `EmployeeRepository`, `AttendanceRepository`, and `PayrollRepository` remain unmodified while a request is `pending`.
- **Applying Changes:** In later checkpoints (HR-9.6), when an approval reaches `approved`, the business logic will invoke the authoritative repository mutation.

---

## 17. Versioning and Concurrency Requirements

- **Client State Concurrency:** `HrApprovalWorkflowValidator.validateDecision()` verifies that requests are currently in `pending` status. Deciding an already decided/terminal request throws `HrApprovalWorkflowException.duplicateDecision`.
- **Server Concurrency:** True database-level transactional concurrency and optimistic locking (e.g. version tokens or row locks) remain the responsibility of the instructor backend.

---

## 18. Validation

Domain invariants enforced at construction:
- Non-empty `id`, `requesterId`, `targetEntityType`, `targetEntityId`, `requestId`, `actorId`.
- Assertion failure on whitespace or empty string parameters.
- Timestamps automatically normalized to UTC.

---

## 19. Authorization Boundary

- `HrApprovalWorkflowValidator` enforces `actor.isAdmin` for all decisions.
- Cancellations verify `actor.id == request.requesterId || actor.isAdmin`.
- Unauthorized attempts throw `HrApprovalWorkflowException.unauthorizedActor`.

---

## 20. Failure Semantics

Standardized `HrApprovalWorkflowException` error codes:
- `INVALID_TRANSITION`: Attempting to transition between incompatible or terminal states.
- `UNAUTHORIZED_ACTOR`: Non-admin attempting to decide, or non-requester attempting to cancel.
- `DUPLICATE_DECISION`: Attempting to decide a request that is already terminal.
- `VALIDATION_ERROR`: Mismatched request IDs or actor IDs.
- `REQUEST_NOT_FOUND`: Target request does not exist.
- `UNSUPPORTED_WORKFLOW`: Unrecognized workflow identifier.

---

## 21. Notification Integration Boundary

- No notifications are dispatched by HR-9.2 domain models.
- Domain transitions produce updated immutable `HrApprovalRequest` instances. In downstream checkpoints (HR-9.8), these transitions will dispatch typed notification events to the shared Notifications module.
- Privacy invariant: Exception messages and domain string representations exclude monetary values and PII.

---

## 22. Immutability and Equality

- All domain models are immutable with `final` fields.
- Value equality is implemented via standard Dart `bool operator ==(Object other)` and `int get hashCode => Object.hash(...)`.
- `copyWith` provides safe, non-destructive state derivation.

---

## 23. Automated Test Results

### Targeted HR Approval Domain Suite:
- `test/features/hr/domain/entities/hr_approval_domain_test.dart`: **19 / 19 PASS**
- `test/features/hr/domain/services/hr_approval_workflow_validator_test.dart`: **19 / 19 PASS**
- **Targeted Total:** **38 / 38 PASS** (0 failures).

### Full Regression Suite:
- **Total Test Count:** **1,897 / 1,897 PASS** (0 failures across all modules).
- **Analyzer:** 0 issues found (`flutter analyze` clean in 5.8s).
- **Flutter Web Build:** `flutter build web` compiled cleanly in 6.4s (`√ Built build\web`).
- **Android Build Config:** `flutter build apk --config-only` succeeded with code 0.

---

## 24. Deferred Functionality

The following items remain strictly out of scope for HR-9.2:
- Repository persistence (`HrApprovalRepository`, `MockHrApprovalRepository`) -> Reserved for HR-9.3.
- Approval request and inbox UI -> Reserved for HR-9.4.
- Approval decision and history UI -> Reserved for HR-9.5.
- Real-time notification delivery (FCM, APNs, email) -> Reserved for HR-9.7/HR-9.8.
- Automatic payroll disbursement -> Out of scope for CRM.

---

## 25. Backend Dependencies

- Long-term storage of `approval_requests`, `approval_steps`, and `approval_history`.
- Server-side access enforcement and transactional concurrency.
- Authoritative notification generation and push delivery.

---

## 26. HR-9.3 Readiness

The approval domain contract is complete, typed, immutable, and 100% covered by passing automated unit tests. The project is ready to proceed to **HR-9.3: Approval Repository & Mock Foundation** when authorized.

---

## 27. Exit Criteria

- [x] HR-9.1 audited and committed (`55c295a`).
- [x] Shared approval architecture and ownership reviewed.
- [x] Reusable shared platform models (`CrmModule`, `CurrentUser`, `AccountType`) reused.
- [x] Approved request identity implemented (`HrApprovalRequest`).
- [x] Stable HR target reference implemented (`HrApprovalTarget`).
- [x] Approved workflow types represented (`HrApprovalWorkflowType`).
- [x] Approved statuses represented (`HrApprovalStatus`).
- [x] Confirmed transitions defined (`HrApprovalWorkflowValidator`).
- [x] Actor relationships preserved (`requesterId`, `actorId`, `isAdmin`).
- [x] Decision contract established (`HrApprovalDecision`).
- [x] History contract established (`HrApprovalHistoryEntry`).
- [x] Validation and failure semantics implemented (`HrApprovalWorkflowException`).
- [x] Privacy rules verified (no salary/PII leakage in exceptions or debug representations).
- [x] Unit tests pass (38/38 targeted, 1897/1897 full suite).
- [x] Flutter analyze clean (0 issues).
- [x] Flutter web build succeeds.
- [x] Contract document `HR_9_APPROVAL_WORKFLOW_CONTRACT.md` created.
