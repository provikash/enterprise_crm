# HR-9.5 — Approval Decision & History Audit

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) & Shared Approvals Integration  
**Status:** `COMPLETE / VERIFIED`

---

## 1. Purpose

This document provides the architectural and verification audit for **HR-9.5: Approval Decision & History** in the Enterprise CRM Flutter application.

Following the frozen domain contracts (HR-9.1 and HR-9.2), repository foundation (HR-9.3), and request/pending UI (HR-9.4), HR-9.5 establishes:
1. Authorized approval decision execution (`approve`, `reject`).
2. Authorized request cancellation (`cancel`) by requesters or administrators.
3. Strict state machine transition validation via `HrApprovalWorkflowValidator`.
4. Immutable, chronological audit history trail recording and retrieval.
5. Atomic status-plus-history persistence in the repository layer.
6. Reactive presentation and state management via `HrApprovalDecisionCubit`.
7. Responsive, authorization-aware decision and history UI surfaces on `HrApprovalRequestDetailsScreen`.
8. Complete side-effect isolation: strictly zero mutation of underlying HR records (`Employee`, `Attendance`, `KPI`, `Payroll`), and zero notification delivery.

---

## 2. Starting Git Baseline

- **Branch:** `feature/hr-9-approvals-notifications`
- **Checkpoint Baseline:** `e865c79` (`feat(hr): implement approval request and pending workflows (HR-9.4)`)
- **HR-9.1 Commit:** `55c295a` (`docs(hr): audit approval notification requirements (HR-9.1)`)
- **HR-9.2 Commit:** `1019252` (`feat(hr): establish approval workflow domain (HR-9.2)`)
- **HR-9.3 Commit:** `ea21e64` (`feat(hr): implement approval repository foundation (HR-9.3)`)
- **Working Tree State at Entry:** Clean (0 untracked files, 0 uncommitted changes)

---

## 3. HR-9.1–9.4 Dependency Audit

| Checkpoint | Requirement | Verification Status |
| :--- | :--- | :--- |
| **HR-9.1** | Approved Requirements & Decision Authority | Verified (`55c295a`). Confirms that only Administrators (`AccountType.admin`) possess confirmed decision authority. Confirms terminal state invariants and prohibition on premature source-record mutations. |
| **HR-9.2** | Workflow Contract & Domain Primitives | Verified (`1019252`). Domain models `HrApprovalRequest`, `HrApprovalDecision`, `HrApprovalHistoryEntry`, `HrApprovalStatus`, and pure validator `HrApprovalWorkflowValidator` fully implemented and tested. |
| **HR-9.3** | Repository Foundation & Mock Store | Verified (`ea21e64`). `HrApprovalRepository`, `MockHrApprovalStore`, and `MockHrApprovalRepository` establish thread-safe, deterministic data operations. |
| **HR-9.4** | Request & Pending Presentation | Verified (`e865c79`). Confirms request creation, dual-tab pending inbox, and read-only details screen. |

---

## 4. Shared Decision Architecture

In alignment with team collaboration agreements:
- Approvals module ownership resides with collaborator Vikash Chaurasiya (`feature/approvals-notifications`).
- HR implements the domain contracts, repository methods, and UI controllers within `lib/features/hr/` adhering to the shared domain contract.
- When the shared Approvals module is delivered, `HrApprovalRepository` will adapt directly to the shared `ApprovalRepository` interface without breaking HR workflows.

---

## 5. Approved Decision Types

In strict compliance with `HR_9_APPROVAL_WORKFLOW_CONTRACT.md` §14:
1. **`approve` (`HrApprovalDecisionType.approve`):**
   - Transitions request from `pending` $\rightarrow$ `approved`.
   - Requires administrative authorization (`actor.isAdmin == true`).
   - Terminal state.
2. **`reject` (`HrApprovalDecisionType.reject`):**
   - Transitions request from `pending` $\rightarrow$ `rejected`.
   - Requires administrative authorization (`actor.isAdmin == true`).
   - Captures qualitative rejection reason.
   - Terminal state.
3. **`cancel`:**
   - Transitions request from `pending` $\rightarrow$ `cancelled`.
   - Allowed by original requester (`actor.id == request.requesterId`) or global administrator (`actor.isAdmin == true`).
   - Terminal state.

---

## 6. Actor Authorization

Enforced across domain, repository, and UI boundaries:
- **Decision Authority:** Gated by `actor.isAdmin`. Non-admin accounts (`AccountType.user`) attempting to approve or reject receive `HrApprovalWorkflowException.unauthorizedActor`.
- **Cancellation Authority:** Gated by `actor.id == request.requesterId || actor.isAdmin`. Third-party standard users attempting to cancel receive `HrApprovalWorkflowException.unauthorizedActor`.
- **UI Visibility:** Approve and Reject buttons are rendered only when `user.isAdmin && request.status.isPending`. Cancel button is rendered only when `request.status.isPending && (user.isAdmin || user.id == request.requesterId)`.

---

## 7. State Transition Contract

Validated by `HrApprovalWorkflowValidator`:

| Source Status | Action | Destination Status | Allowed? | Error Code if Prohibited |
| :--- | :--- | :--- | :--- | :--- |
| `pending` | `approve` | `approved` | **YES** | — |
| `pending` | `reject` | `rejected` | **YES** | — |
| `pending` | `cancel` | `cancelled` | **YES** | — |
| `approved` | Any | Any | **NO** | `DUPLICATE_DECISION` / `INVALID_TRANSITION` |
| `rejected` | Any | Any | **NO** | `DUPLICATE_DECISION` / `INVALID_TRANSITION` |
| `cancelled` | Any | Any | **NO** | `DUPLICATE_DECISION` / `INVALID_TRANSITION` |

---

## 8. Decision Repository Operations

The repository interface (`HrApprovalRepository`) was extended with three formal methods:
1. `submitDecision({required String requestId, required HrApprovalDecision decision, required CurrentUser actor})`:
   - Validates existence, transition validity, and actor authority.
   - Updates request status atomically with history recording.
2. `cancelRequest({required String requestId, required CurrentUser actor, String? reason})`:
   - Validates existence, terminal status, and cancellation permissions.
   - Updates request status to `cancelled` with history entry.
3. `getHistoryForRequest(String requestId)`:
   - Returns immutable chronological audit history entries for presentation and traceability.

---

## 9. Duplicate-Decision Handling

- **Domain/Repository Layer:** Attempting to decide a request that is already terminal (`approved`, `rejected`, `cancelled`) throws `HrApprovalWorkflowException.duplicateDecision`.
- **Presentation Layer:** In-flight operations set `isSubmitting = true`, disabling action buttons and replacing controls with a progress indicator to prevent duplicate taps.

---

## 10. Concurrent-Decision Behavior

- In-memory mock store enforces serial atomic updates to `_requests` and `_history`.
- In downstream production backend integration (HR-10), database-level optimistic locking (version tokens / CAS) will enforce authoritative race-condition handling.

---

## 11. Status and History Consistency

- Every status change atomically appends a corresponding `HrApprovalHistoryEntry`.
- Status and history cannot drift: a request cannot transition to `approved` without an `approved` history entry recorded at the same UTC timestamp.

---

## 12. Decision Metadata

- `requestId`: Foreign key matching target request.
- `actorId`: Deciding CRM user (`CurrentUser.id`).
- `decisionType`: `approve` or `reject`.
- `decisionTime`: UTC normalized timestamp.
- `reason`: Optional or required qualitative explanation.

---

## 13. History Storage Contract

- Each entry encapsulates: `id`, `requestId`, `actorId`, `action`, `previousStatus`, `newStatus`, `timestamp`, `reason`.
- Defensive immutability: returns new cloned instances; callers cannot mutate the backing store.

---

## 14. Decision Cubit & UI

### `HrApprovalDecisionCubit` (`lib/features/hr/presentation/bloc/`)
- Manages request detail loading, authority evaluation, decision submission, cancellation, and audit history.
- States: `Initial`, `Loading`, `Ready`, `Submitting`, `Success`, `Failure`.
- Sequence version tokens discard stale asynchronous responses.

### `HrApprovalRequestDetailsScreen` (`lib/features/hr/presentation/screens/`)
- Integrated with `HrApprovalDecisionCubit`.
- **Decision Actions Card:** Renders Approve, Reject, and Cancel controls based on user role and request status.
- **Decision Dialogs:** Prompts for confirmation and optional/required remarks before submission.
- **Audit History Card:** Chronological list showing action badges, actor IDs, transitions, timestamps, and remarks.

---

## 15. Route and Action Security

- Direct access guarded by `HrAccessPolicy.canAccessModule`.
- Action execution enforces actor identity against the authenticated session (`CurrentUser.id`).
- Terminal and unauthorized requests cannot be decided through widget or Cubit bypass.

---

## 16. Session Isolation

- `HrApprovalDecisionCubit.reset()` discards cached request and history state on user logout or session change.
- New user sessions cannot access or decide requests using credentials from a previous session.

---

## 17. Failure Handling

- Repository failures, validation errors, and authorization rejections emit sanitized `HrApprovalDecisionFailure` messages.
- Retry button and SnackBar alerts provide clear, non-cryptic user feedback.

---

## 18. Automated Test Results

### Targeted HR Approval Test Suite:
- `test/features/hr/domain/entities/hr_approval_domain_test.dart`: 19 / 19 PASS
- `test/features/hr/domain/services/hr_approval_workflow_validator_test.dart`: 19 / 19 PASS
- `test/features/hr/data/repositories/mock_hr_approval_repository_test.dart`: 27 / 27 PASS
- `test/features/hr/presentation/bloc/hr_approval_request_cubit_test.dart`: 7 / 7 PASS
- `test/features/hr/presentation/bloc/pending_approvals_cubit_test.dart`: 8 / 8 PASS
- `test/features/hr/presentation/bloc/hr_approval_decision_cubit_test.dart`: 8 / 8 PASS
- `test/features/hr/presentation/screens/hr_approval_request_screen_test.dart`: 5 / 5 PASS
- `test/features/hr/presentation/screens/pending_approvals_screen_test.dart`: 6 / 6 PASS
- `test/features/hr/presentation/screens/hr_approval_request_details_screen_test.dart`: 10 / 10 PASS
- `test/features/hr/presentation/screens/approval_navigation_and_access_test.dart`: 12 / 12 PASS
- **Targeted Total:** **121 / 121 PASS** (0 failures).

---

## 19. Manual UAT Status

| Scenario | Expected Outcome | Result |
| :--- | :--- | :--- |
| **Admin opens pending request** | Approve, Reject, and Cancel buttons visible | **PASS** |
| **Standard user opens pending request** | Approve/Reject buttons hidden | **PASS** |
| **Admin approves with remarks** | Status updates to Approved, history entry recorded | **PASS** |
| **Admin rejects with remarks** | Status updates to Rejected, history entry recorded | **PASS** |
| **Requester cancels request** | Status updates to Cancelled, history entry recorded | **PASS** |
| **Terminal request opened** | Decision controls replaced with terminal status message | **PASS** |
| **Responsive viewports (320px–1200px)** | Zero RenderFlex overflows across all resolutions | **PASS** |

---

## 20. Backend Transaction Dependencies

- Authoritative distributed transaction management between approval decisions and source records is deferred to future backend milestones (HR-10).
- In-memory mock store provides deterministic local atomicity for frontend development.

---

## 21. Deferred Functionality

- Source HR entity mutation upon approval resolution $\rightarrow$ Reserved for HR-9.6.
- Notification event generation and delivery $\rightarrow$ Reserved for HR-9.7 and HR-9.8.
- Payroll fund disbursement $\rightarrow$ Out of scope.

---

## 22. Remaining Blockers

- Zero blockers for HR-9.5. The approval decision and history workflow is complete, verified, and ready for HR feature integration in HR-9.6.

---

## 23. Exit Criteria

- [x] HR-9.4 verified and committed (`e865c79`).
- [x] Shared Approvals architecture reused and respected.
- [x] Approved decision types implemented (`approve`, `reject`, `cancel`).
- [x] Decision authority strictly enforced (`user.isAdmin`).
- [x] State transitions validated via pure domain validator.
- [x] Duplicate decisions on terminal requests blocked.
- [x] History trail recorded atomically and defensively copied.
- [x] Decision UI and history trail rendered in details screen.
- [x] Zero HR source-record mutations introduced.
- [x] Zero notification delivery introduced.
- [x] All 121 targeted unit and widget tests pass.
- [x] Full regression suite passes.
- [x] Documentation `HR_9_APPROVAL_DECISION_AND_HISTORY.md` created.
