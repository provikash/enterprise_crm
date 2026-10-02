# HR-9.9 — Permissions, Security & Workflow Integrity Audit Report

**Date:** 2026-10-02  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) & Shared Approvals/Notifications Integration Boundary  
**Status:** `AUDITED — BACKEND ENFORCEMENT PENDING`

---

## 1. Purpose and Scope

This document details the formal security, authorization, workflow integrity, notification delivery, sensitive data protection, and session isolation audit for **HR-9.9: Permissions, Security & Workflow Integrity Audit**.

The primary objectives are:
1. Audit the complete end-to-end security boundary of HR approval workflows and notification integrations implemented across HR-9.1 through HR-9.8.
2. Verify authorization rules for request submission, request query/viewing, decision rendering, cancellation, and history review.
3. Verify that state transitions strictly follow the confirmed domain matrix and that duplicate, invalid, or concurrent conflicting decisions are defensively rejected.
4. Verify source-record integrity across Employee Management, Documents, Attendance, KPI, and Payroll, ensuring approvals do NOT prematurely mutate, corrupt, recalculate, finalize, or disburse funds.
5. Audit notification delivery authenticity, recipient isolation, event deduplication, and failure isolation.
6. Ensure sensitive payroll figures (salary, deductions, taxes) and private employee PII are never exposed in notification summaries, payloads, or error logs.
7. Verify session isolation across user login, logout, account switching, and late asynchronous responses.
8. Document backend-dependent guarantees that must be enforced authoritatively in HR-10.

---

## 2. Starting Git Baseline

- **Current Branch:** `feature/hr-9-approvals-notifications`
- **Starting HEAD:** `ba16e3848b6156e7295713488cf41f874bc0a720` (`feat(hr): integrate approval notifications (HR-9.8)`)
- **Working Tree:** Clean (prior to HR-9.9 test and documentation creation)
- **Preceding HR-9 Commits:**
  - `ba16e38` feat(hr): integrate approval notifications (HR-9.8)
  - `b4f21fa` feat(hr): establish notification foundation (HR-9.7)
  - `19aaf2b` feat(hr): integrate approved HR approval workflows (HR-9.6)
  - `91c06d5` feat(hr): implement approval decisions and history (HR-9.5)
  - `e865c79` feat(hr): implement approval request and pending workflows (HR-9.4)
  - `ea21e64` feat(hr): implement approval repository foundation (HR-9.3)
  - `1019252` feat(hr): establish approval workflow domain (HR-9.2)
  - `55c295a` docs(hr): audit approval notification requirements (HR-9.1)

---

## 3. HR-9.1–9.8 Dependency Verification

| Checkpoint | Implementation Status | Audit Verification |
| :--- | :--- | :--- |
| **HR-9.1** | `COMPLETE` | Requirements audit report established; unconfirmed features and auto-approvals rejected. |
| **HR-9.2** | `COMPLETE` | Domain models (`HrApprovalRequest`, `HrApprovalDecision`, `HrApprovalTarget`, `HrApprovalWorkflowType`, `HrApprovalStatus`) established. |
| **HR-9.3** | `COMPLETE` | `HrApprovalRepository`, `MockHrApprovalStore`, and deterministic fixtures established. |
| **HR-9.4** | `COMPLETE` | `HrApprovalRequestScreen`, `PendingApprovalsScreen`, and request creation cubits verified. |
| **HR-9.5** | `COMPLETE` | `HrApprovalDecisionCubit`, decision modal UI, and immutable audit history verified. |
| **HR-9.6** | `COMPLETE` | Cross-module navigation and integration points for Attendance, Documents, and Payroll verified. |
| **HR-9.7** | `COMPLETE` | `HrNotification`, `HrNotificationRepository`, and `HrNotificationInboxDialog` established. |
| **HR-9.8** | `COMPLETE` | `HrApprovalNotificationService` integrated with request/decision events without corrupting approval state. |

---

## 4. Shared-Module Ownership

In accordance with `MASTER_DEVELOPMENT_RULES.md` and `Enterprise_CRM_Team_Collaboration_Handoff.md`:
- **Shared Approvals & Notifications Ownership:** Collaborator Vikash Chaurasiya owns the global shared approvals module (`lib/features/approvals/`) and shared notifications infrastructure (`lib/features/notifications/`).
- **HR Module Ownership:** Project Lead Vachaspati Mishra owns `lib/features/hr/`.
- **Integration Boundary:** HR approval and notification workflows utilize dedicated, decoupled adapters (`HrApprovalRepository`, `HrNotificationRepository`, `HrApprovalNotificationService`) located cleanly inside `lib/features/hr/`.
- **No Shared Code Corruption:** No external shared repositories or global databases were mutated or bypassed.

---

## 5. Authorization Matrix

| Action | Approved Actor / Condition | UI Guard | Route Guard | Application Guard | Backend Dependency (HR-10) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Submit Request** | Authenticated user with `CrmModule.hrPayroll` | Form enabled only for module users | `HrAccessPolicy.canAccessModule` | `HrApprovalRequestCubit` rejects unauthorized requester | JWT verification, DB transaction |
| **View Own Requests** | Authenticated requester | Tab filtered by `user.id` | `HrAccessPolicy.canAccessModule` | `PendingApprovalsCubit` calls `getRequestsSubmittedBy(user.id)` | Scoped SQL `WHERE requester_id = ?` |
| **View Pending Requests** | Admin (`all`) / Standard User (`own`) | Switchable filter tabs | `HrAccessPolicy.canAccessModule` | `MockHrApprovalStore` filters non-admin to `r.requesterId == user.id` | Role-based row-level security (RLS) |
| **View Request Details** | Authenticated user with module access | Direct details view | `HrAccessPolicy.canAccessModule` | Details screen displays `AccessRestrictedScreen` if unauthorized | Scoped fetch with authorization check |
| **Approve Request** | Global Administrator (`CurrentUser.isAdmin`) | Approve button hidden from non-admin | `HrAccessPolicy.canAccessModule` | `HrApprovalWorkflowValidator.validateDecision` rejects non-admin | Database transaction with role enforcement |
| **Reject Request** | Global Administrator (`CurrentUser.isAdmin`) | Reject button hidden from non-admin | `HrAccessPolicy.canAccessModule` | `HrApprovalWorkflowValidator.validateDecision` rejects non-admin | Database transaction with role enforcement |
| **Cancel Request** | Original Requester or Global Admin | Cancel button hidden if unauthorized | `HrAccessPolicy.canAccessModule` | `HrApprovalWorkflowValidator.validateCancellation` rejects unauthorized actors | Row ownership check in DB |
| **View Audit History** | Authenticated user with module access | Rendered on details screen | `HrAccessPolicy.canAccessModule` | History queried strictly by `requestId` | Authoritative audit log table |
| **Apply HR Effect** | Blocked / Deferred | No direct action buttons exist | `HrAccessPolicy.canAccessModule` | Source repositories are NOT mutated | Backend transaction coordinator |
| **View Notification** | Intended recipient (`recipientUserId == user.id`) | Inbox dialog scoped to active user | Dialog requires authenticated context | `MockHrNotificationRepository` returns only recipient notifications | Scoped push/fetch query |
| **Mark Notification Read**| Intended recipient only | Tap action in dialog | Dialog requires authenticated context | `MockHrNotificationStore` throws if `recipientUserId` mismatches | Scoped update `WHERE recipient_id = ?` |

---

## 6. Request Submission Security

- **Authentication Guard:** Only authenticated users holding `CrmModule.hrPayroll` can submit requests via `HrApprovalRequestCubit`.
- **Validation Guard:** Empty target entity ID or empty requester ID are rejected at both cubit and repository boundaries with typed validation errors.
- **Side-Effect Free:** Submitting a request never alters the target entity (e.g. submitting a payroll approval request does not lock, mutate, or pay the payroll period).

---

## 7. Pending-Request Visibility

- **Standard User Isolation:** Standard users calling `getPendingRequests(user: user)` only receive pending requests where `r.requesterId == user.id`.
- **Administrative Visibility:** Administrators calling `getPendingRequests(user: admin)` receive all pending requests across all requesters.
- **Direct Query Scoping:** `getAllRequests(user: user)` defensively filters non-admin callers to their own submitted requests.

---

## 8. Decision Authority

- **Administrative Exclusivity:** In strict accordance with the HR-9.1 requirements audit, only Administrators (`actor.isAdmin == true`) hold confirmed decision authority.
- **Unauthorized Decision Rejection:** Non-admin users attempting to execute `submitDecision` are immediately rejected with `HrApprovalWorkflowException.unauthorizedActor`.
- **Actor Integrity:** The decision payload `actorId` must match the authenticated user `actor.id`; mismatches throw `HrApprovalWorkflowException.validationError`.

---

## 9. Direct Action / Route Protection

- **UI Button Disabling is Not Security:** `HrApprovalRequestDetailsScreen` hides decision buttons from non-admin users, but security is redundantly enforced in `HrApprovalWorkflowValidator` and `MockHrApprovalStore`.
- **Direct Navigation:** Navigating directly to `PendingApprovalsScreen` or `HrApprovalRequestDetailsScreen` without HR module access renders `AccessRestrictedScreen`.

---

## 10. State Transition Integrity

- **Valid Transitions:**
  - `pending` $\rightarrow$ `approved` (Admin decision)
  - `pending` $\rightarrow$ `rejected` (Admin decision)
  - `pending` $\rightarrow$ `cancelled` (Requester or Admin action)
- **Terminal Immutability:** Once a request transitions to `approved`, `rejected`, or `cancelled`, any subsequent decision or transition attempt is strictly prohibited and throws `HrApprovalWorkflowException.duplicateDecision` or `invalidTransition`.

---

## 11. Duplicate Decision Behavior

- **Idempotency & Rejection:** Submitting a decision for a request already in a terminal state throws `HrApprovalWorkflowException.duplicateDecision`.
- **No Duplicate History:** Repeated decision attempts do not create duplicate audit trail entries.

---

## 12. Concurrent Decision Behavior

- **Controlled Race Test:** When two decision actors read the same pending request simultaneously and submit conflicting decisions (e.g. approve vs reject), the first committed operation atomically updates the store to a terminal state; the second concurrent operation fails with `duplicateDecision`.
- **Backend Dependency:** In production, true concurrent serialization requires database transactions (e.g. `SELECT FOR UPDATE` or optimistic locking version checks) implemented in HR-10.

---

## 13. Status and History Consistency

- **Atomic Pairing:** In `MockHrApprovalStore`, every successful decision atomically transitions `request.status` and appends an immutable `HrApprovalHistoryEntry`.
- **Failure Cleanliness:** If a decision fails validation, no history entry is created and the request status remains untouched.

---

## 14. Source-Record Mutation Integrity

- **Zero Unapproved Mutations:** In accordance with the non-negotiables, HR approval workflows do NOT directly modify source records in `EmployeeRepository`, `AttendanceRepository`, `EmployeeKpiRepository`, or `PayrollRecordRepository`.
- **Clean Boundary:** The approval request acts as an authorization record; source record state mutations are reserved for future authorized backend transaction coordinators.

---

## 15. Stale Source-Record Protection

- Because client-side mock repositories do not execute background mutations, stale target conflicts are documented as an authoritative backend dependency for HR-10 (e.g. entity version check `ETag` or `updated_at` optimistic lock).

---

## 16. Employee Management Integrity

- Employee records remain authored directly by Administrators.
- Approval targets referencing `employee` preserve stable employee IDs without modifying profile fields.

---

## 17. Documents Security

- Document verification requests reference `employeeDocument` without exposing binary document bytes or unverified external URLs in approval metadata.

---

## 18. Attendance Integrity

- Attendance correction approval requests reference `attendanceRecord` without automatically recalculating working hours, penalties, or absence flags.

---

## 19. KPI / Performance Integrity

- KPI approval requests reference `employeeKpi` without modifying metric targets, actual scores, or auto-generating performance bonuses.

---

## 20. Payroll Integrity

- **Strict Data Minimization:** Payroll approval requests reference `payrollPeriod` by ID.
- **Zero Payment / Finalization:** Approval does NOT trigger payment disbursement, salary calculation, payslip generation, or tax calculation.
- **No Monetary Values in Approval Entities:** Financial numbers remain encapsulated in `PayrollRecord` and are not duplicated into approval requests or history records.

---

## 21. Reports / Export Boundary

- Sensitive export approvals were classified as unconfirmed/deferred in HR-8. No export approval triggers or unauthorized data exports exist in HR-9.

---

## 22. Notification Event Authenticity

- Notifications are dispatched strictly after successful persistence of requests, decisions, or cancellations in `MockHrApprovalRepository`.
- No notifications are emitted on speculative button clicks or failed transactions.

---

## 23. Recipient Isolation

- Notifications are strictly addressed to CRM User IDs (`CurrentUser.id`), never workforce `Employee.id`.
- `MockHrNotificationRepository.getNotificationsForUser(userId)` returns only notifications matching `n.recipientUserId == userId`.
- Cross-user retrieval returns an empty list.

---

## 24. Duplicate Notification Behavior

- `HrApprovalNotificationService` maintains an in-memory event registry (`_dispatchedEventKeys`). Repeated invocations for the same event key (e.g. `'submitted_appr_req_1'`) are suppressed and return `null`.

---

## 25. Delivery Failure Handling (Failure Isolation)

- If `HrNotificationRepository.sendNotification` fails (e.g. simulated network or store exception), `HrApprovalNotificationService` catches the error internally and returns `null`.
- The approval decision and request status remain 100% committed and uncorrupted.

---

## 26. Read / Unread Authorization

- Calling `markAsRead` with a `recipientUserId` that does not match `notif.recipientUserId` throws `HrNotificationException` with code `unauthorized_recipient`.

---

## 27. Notification Navigation Security

- Tapping a notification routes to `HrApprovalRequestDetailsScreen`, which independently verifies current user authorization via `HrAccessPolicy.canAccessModule`.
- Possessing a notification does not grant elevated privileges.

---

## 28. Session Isolation

- `PendingApprovalsCubit.clear()` wipes in-flight queries and cached requests on logout.
- `HrApprovalDecisionCubit.reset()` discards loaded request references and resets state to `HrApprovalDecisionInitial`.
- `HrNotificationCubit.clear()` resets active user IDs and loaded notification state.

---

## 29. Cached-State Privacy

- Monotonically increasing version tokens (`_versionToken`, `_activeRequestId`) in Cubits ensure late asynchronous responses from previous sessions are silently discarded.

---

## 30. Sensitive Data Minimization

- Notification titles and bodies contain only generic non-sensitive descriptions:
  - `"New Approval Request"`
  - `"A new request for payroll_period period_2026_01 was submitted by usr_hr."`
- Zero salary numbers, zero tax figures, zero deduction values, and zero national IDs are stored in notifications.

---

## 31. Logging and Error Privacy

- Ripgrep audit confirmed zero raw `print` or `debugPrint` calls in `lib/features/hr/`.
- Exception messages strip stack traces and avoid leaking raw database structures.

---

## 32. Automated Security Tests

Automated tests in `test/features/hr/presentation/security/hr_approval_security_and_workflow_integrity_test.dart` cover:
1. `authorized user submits approval request via cubit` (PASS)
2. `unauthorized user cannot submit approval request` (PASS)
3. `empty target entity ID fails validation` (PASS)
4. `empty requester ID is rejected by repository store` (PASS)
5. `non-admin user cannot submit approval or rejection decision` (PASS)
6. `decision actorId must match authenticated user ID` (PASS)
7. `admin can approve pending request and transition to approved` (PASS)
8. `terminal request cannot be decided again (duplicate decision protection)` (PASS)
9. `concurrent decision race: second decision on same request is rejected` (PASS)
10. `original requester can cancel pending request` (PASS)
11. `unauthorized user cannot cancel another user request` (PASS)
12. `standard user only sees pending requests they submitted` (PASS)
13. `admin user sees all pending requests regardless of requester` (PASS)
14. `getAllRequests filters by requesterId for non-admin users` (PASS)
15. `notifications do NOT contain sensitive salary or financial figures` (PASS)
16. `notification recipient isolation: user cannot view another user notifications` (PASS)
17. `marking another user notification as read is rejected` (PASS)
18. `duplicate event suppression: same event key is dispatched only once` (PASS)
19. `notification delivery failure does not corrupt approval state (Failure Isolation)` (PASS)
20. `PendingApprovalsCubit clear() purges loaded requests and resets to initial` (PASS)
21. `HrApprovalDecisionCubit reset() discards loaded request and resets to initial` (PASS)
22. `HrNotificationCubit clear() purges notifications on logout` (PASS)
23. `unauthorized user navigating to PendingApprovalsScreen sees AccessRestrictedScreen` (PASS)
24. `unauthorized user navigating to HrApprovalRequestDetailsScreen sees AccessRestrictedScreen` (PASS)
25. `validateTransition throws on terminal request` (PASS)
26. `validateDecision throws if decision requestId does not match target request` (PASS)

---

## 33. Defects Found

- **SEC-01 (Medium):** Standard users could potentially query all requests if repository queries lacked user scoping.
  - *Status:* Resolved in HR-9.3 via `getAllRequests({CurrentUser? user})` and `getPendingRequests({CurrentUser? user})`.
- **SEC-02 (Low):** Notification inbox dialog flex layout potential overflow on small viewports.
  - *Status:* Resolved in HR-9.7 by wrapping header text in `Expanded` and `Flexible`.

---

## 34. Defects Fixed

All identified defects have been remediated and confirmed via automated regression tests.

---

## 35. Open Defects

**Zero** open blocker, high, or medium defects in the client-side/mock scope.

---

## 36. Backend Security Dependencies (HR-10)

The following guarantees require authoritative instructor backend enforcement in HR-10:
1. **Persistent Authentication & Authorization:** Server-side JWT signature verification and role-based access control (RBAC) on all `/api/v1/approvals/*` and `/api/v1/notifications/*` endpoints.
2. **ACID Transactional Decisions:** Atomic commit of approval status transitions, audit history insertion, and source-record state updates within a single database transaction.
3. **Optimistic / Pessimistic Concurrency Locking:** Server-side locking or version check to prevent race conditions across distributed mobile/web clients.
4. **Reliable Notification Outbox:** Transactional outbox pattern ensuring notifications are reliably delivered via push (FCM/APNS) or email even after network failure.
5. **Authoritative Audit Log Storage:** Append-only, tamper-proof audit log table in PostgreSQL.

---

## 37. Deferred Functionality

- Self-service employee approval request submission.
- Multi-tier approval workflows (supervisor $\rightarrow$ manager $\rightarrow$ director).
- Push notification device registration and background push messaging.
- External SMTP email notifications.
- Automatic payroll payment and salary disbursement.

---

## 38. Exit Criteria

- [x] Existing authorization audited.
- [x] Request submission protected.
- [x] Pending-request visibility correct.
- [x] Decision authorization correct.
- [x] Direct routes/actions protected.
- [x] Invalid transitions rejected.
- [x] Duplicate decision behavior correct.
- [x] Concurrent decision behavior verified within mock scope.
- [x] Status/history consistency verified.
- [x] Source-record mutation integrity verified.
- [x] Stale record behavior verified or explicitly backend-blocked.
- [x] No unauthorized Employee changes.
- [x] No unauthorized Attendance changes.
- [x] No unauthorized KPI changes.
- [x] No unauthorized Payroll changes.
- [x] Approved notification events only.
- [x] Recipient isolation correct.
- [x] Duplicate-event handling verified.
- [x] Delivery failures handled safely.
- [x] Notification navigation protected.
- [x] Session isolation verified.
- [x] Sensitive-data minimization verified.
- [x] Logs/errors audited.
- [x] Confirmed blocker/high defects fixed.
- [x] Security regression tests pass (26/26 PASS).
- [x] Shared Approvals regression passes.
- [x] Shared Notifications regression passes.
- [x] Required project verification passes (`flutter analyze` clean).
- [x] Audit document created.

---

## 39. Final Security Audit Status

`AUDITED — BACKEND ENFORCEMENT PENDING`

All client-side authorization, state transition, recipient isolation, session purge, failure isolation, and sensitive data privacy rules are fully verified and pass 100% of automated tests. Production-level transactional consistency and persistent push delivery remain pending backend integration in HR-10.
