# HR-9.8 — Approval Notification Integration Audit

## Enterprise CRM — Formal Verification & Audit Document

---

## 1. Purpose and Scope

This document provides the formal architectural audit, event-to-notification mapping register, recipient resolution verification, and end-to-end integration evidence for **HR-9.8 — Approval Notification Integration** in the Enterprise CRM Flutter application.

HR-9.8 connects confirmed approval lifecycle events (requests, decisions, cancellations) from HR-9.3 through HR-9.6 to the notification delivery foundation established in HR-9.7, without introducing duplicate dispatch paths, unapproved background workers, or privacy leaks.

---

## 2. Starting Git Baseline

- **Repository**: `provikash/enterprise_crm`
- **Active Branch**: `feature/hr-9-approvals-notifications`
- **Starting HEAD (HR-9.7 Commit)**: `b4f21fa0c64be7cb658be0a5a54db52fbfd5e236` (`feat(hr): establish notification foundation (HR-9.7)`)
- **Working Tree State at Inception**: Clean working tree following verified HR-9.7 commit.

---

## 3. HR-9.1–9.7 Dependency Verification

| Checkpoint | Status | Commit / Artifact | Verified Capabilities |
|---|---|---|---|
| **HR-9.1** | COMPLETE | `55c295a` / `HR_9_APPROVALS_NOTIFICATIONS_REQUIREMENTS.md` | Requirements audit, notification trigger matrix, privacy rules |
| **HR-9.2** | COMPLETE | `1019252` / `HR_9_APPROVAL_WORKFLOW_CONTRACT.md` | Domain entities, lifecycle status, validation rules |
| **HR-9.3** | COMPLETE | `ea21e64` / `HR_9_APPROVAL_REPOSITORY_AND_MOCK_AUDIT.md` | In-memory store, request persistence, seed isolation |
| **HR-9.4** | COMPLETE | `e865c79` / `HR_9_APPROVAL_REQUEST_AND_PENDING_UI.md` | Request submission & pending approvals queue UI |
| **HR-9.5** | COMPLETE | `91c06d5` / `HR_9_APPROVAL_DECISION_AND_HISTORY.md` | Decision operations, history audit trail, status transitions |
| **HR-9.6** | COMPLETE | `19aaf2b` / `HR_9_FEATURE_INTEGRATION_AND_WORKFLOW_AUDIT.md` | HR feature adapters (Attendance, Payroll, Documents) |
| **HR-9.7** | COMPLETE | `b4f21fa` / `HR_9_NOTIFICATION_FOUNDATION_AND_DELIVERY_CONTRACT.md` | Notification entities, repository, mock store, and inbox UI |

All prerequisite dependencies are 100% verified, tested, and committed on the feature branch.

---

## 4. Shared Module Ownership

- **Approvals & Notifications (`CrmModule.approvalsNotifications`)**: Platform capability owned by collaborator Vikash Chaurasiya.
- **Coordination Service**: `HrApprovalNotificationService` bridges domain events in `MockHrApprovalRepository` directly to `HrNotificationRepository` using typed models, ensuring that HR does not construct a duplicate notification engine or parallel inbox.

---

## 5. Confirmed Approval-Event Inventory

| Event ID | Trigger Event | Triggering Operation | Recipient | Notification Type | Status |
|---|---|---|---|---|---|
| **NOTIF-01** | Approval Request Submitted | `HrApprovalRepository.submitRequest` | Authorized Approvers (`usr_admin`) | `approvalRequestSubmitted` | **IMPLEMENTED** |
| **NOTIF-02** | Approval Decision: Approved | `HrApprovalRepository.submitDecision` (`approve`) | Original Requester (`request.requesterId`) | `approvalDecisionRecorded` | **IMPLEMENTED** |
| **NOTIF-03** | Approval Decision: Rejected | `HrApprovalRepository.submitDecision` (`reject`) | Original Requester (`request.requesterId`) | `approvalDecisionRecorded` | **IMPLEMENTED** |
| **NOTIF-04** | Approval Request Cancelled | `HrApprovalRepository.cancelRequest` | Authorized Approvers (`usr_admin`) | `approvalRequestCancelled` | **IMPLEMENTED** |

---

## 6. Event Source and Ownership

- **Single Event Emitter**: `MockHrApprovalRepository` is the sole authoritative event source.
- **No Duplicate Paths**: Neither UI widgets, nor Cubits, nor feature adapters emit approval notifications independently. Notifications are dispatched **only** after underlying repository persistence is confirmed.

---

## 7. Event-to-Notification Mapping

```text
+------------------------------+
|  Confirmed Approval Event    |
+------------------------------+
               |
               v
+-------------------------------------------------------------+
|               HrApprovalNotificationService                 |
|  - Deduplication Check (Event Key)                          |
|  - Recipient Resolution (admin or requester)                |
|  - Content Privacy Sanitization                             |
|  - Safe Dispatch via HrNotificationRepository               |
+-------------------------------------------------------------+
               |
               v
+------------------------------+
|       HrNotification         |
|  (In-App Notification Item)  |
+------------------------------+
```

---

## 8. Notification Identity

- Generated via `_generateId()` with monotonic prefix `notif_` (e.g. `'notif_201'`, `'notif_202'`).
- Preserves unique identifier across in-memory mock storage.

---

## 9. Recipient Resolution

- **Admin Recipient**: Routed to `adminRecipientUserId` (`'usr_admin'`), representing the authorized system administrator in CRM mock fixtures.
- **Requester Recipient**: Routed to `request.requesterId` (`CurrentUser.id`, e.g. `'usr_hr'`).
- **Identity Invariant**: Workforce employee identifiers (`'emp_1'`) are strictly avoided as notification recipients.

---

## 10. Message and Content Privacy

**Enforced Invariants**:
1. Zero financial figures (basic pay, net salary, deduction amounts, or currency symbols like `$`) are permitted in notification text.
2. Zero sensitive PII (national IDs, bank details, home addresses).
3. Sanitized Templates:
   - **NOTIF-01**: `'A new request for <targetEntityType> <targetEntityId> was submitted by <requesterId>.'`
   - **NOTIF-02**: `'Your request for <targetEntityType> <targetEntityId> was approved by <actorId>.'`
   - **NOTIF-03**: `'Your request for <targetEntityType> <targetEntityId> was rejected by <actorId>. Reason: <reason>'`
   - **NOTIF-04**: `'Request <requestId> for <targetEntityType> <targetEntityId> was cancelled by requester.'`

---

## 11. Request-Submission Notifications (NOTIF-01)

- **Verification**: When `usr_hr` submits a request for Attendance Record `att_101`, a notification is generated and placed in `usr_admin`'s inbox with type `approvalRequestSubmitted`.
- **Privacy Check**: `test/features/hr/domain/services/hr_approval_notification_service_test.dart` verifies that salary amounts in request remarks are stripped from the notification body.

---

## 12. Decision Notifications (NOTIF-02 & NOTIF-03)

- **Approval**: When `usr_admin` approves `appr_req_1`, a notification is delivered to `usr_hr` informing them of approval.
- **Rejection**: When `usr_admin` rejects `appr_req_1` with reason `'Proof inadequate'`, a notification is delivered to `usr_hr` containing the reason.

---

## 13. Source-Record Effect Notifications

- In accordance with HR-9.1 rules, separate source-record mutation alerts are not confirmed and are not implemented. Notifications are strictly tied to confirmed approval lifecycle milestones.

---

## 14. Shared Delivery Integration

- `HrApprovalNotificationService` dispatches notifications via `HrNotificationRepository.sendNotification`.
- In-memory mock storage immediately updates the recipient's inbox and increments unread count.

---

## 15. Duplicate-Event Handling (Idempotency)

- `HrApprovalNotificationService` tracks processed events using deterministic keys:
  - Submission: `'submitted_<requestId>'`
  - Decision: `'decision_<requestId>_<decisionType>'`
  - Cancellation: `'cancelled_<requestId>'`
- Repeated calls with identical event keys return `null` without generating duplicate notifications.

---

## 16. Retry and Failure Behavior

**Failure Isolation Guarantee**:
- If `HrNotificationRepository.sendNotification` fails or throws an exception, `HrApprovalNotificationService` catches the error safely.
- **The underlying approval request or decision remains 100% successful and committed**. Notification delivery failure never rolls back or corrupts approval state.

---

## 17. Multiple-Recipient Behavior

- Submission and cancellation events target the administrator group (`'usr_admin'`).
- Future broadcast to multi-admin groups is reserved for backend message routing without modifying client domain contracts.

---

## 18. Inbox Integration

- Accessible via `pending_approvals_notifications_button` in `PendingApprovalsScreen`.
- Modal `HrNotificationInboxDialog` renders recipient-scoped notifications, unread badges, and "Mark all read" controls.

---

## 19. Read / Unread Integration

- Notifications start with `isRead = false`.
- Tapping a notification marks it as read and decrements the unread count in `HrNotificationCubit`.
- "Mark all read" marks all notifications for that user as read simultaneously.

---

## 20. Notification Navigation

- Tapping any notification in `HrNotificationInboxDialog` automatically navigates to `HrApprovalRequestDetailsScreen` for the referenced `requestId`.
- Preserves full context and allows the user to inspect the current approval state and history.

---

## 21. Route and Access Authorization

- Only authenticated users with access to `PendingApprovalsScreen` can open the inbox.
- Query and mutation operations in `HrNotificationRepository` strictly enforce `recipientUserId` checks; non-recipients cannot access another user's notifications.

---

## 22. Session Isolation

- `HrApprovalNotificationService.reset()` wipes deduplication event caches.
- `HrNotificationCubit.clear()` resets cubit state on logout.
- `HrNotificationRepository.clearUserNotifications` purges user-specific items on session termination.

---

## 23. Workflow Integrity

- Approval workflow state and notification state are strictly separated:
  - Reading a notification does NOT decide or alter an approval request.
  - Deleting or dismissing a notification does NOT cancel an approval request.
  - An approval decision is complete and permanent regardless of notification delivery outcome.

---

## 24. Automated Tests

### HR-9.8 Target Test Suite (`test/features/hr/domain/services/hr_approval_notification_service_test.dart`)
- `submitRequest emits NOTIF-01 to administrator` (PASS)
- `submitDecision with approve emits NOTIF-02 to original requester` (PASS)
- `submitDecision with reject emits NOTIF-03 to original requester with reason` (PASS)
- `cancelRequest emits NOTIF-04 to administrator` (PASS)
- `notification delivery failure does not corrupt approval decision state` (PASS)
- `duplicate event processing is idempotent and ignores repeated dispatch` (PASS)
- `reset clears event keys for session isolation` (PASS)
- `content privacy invariant: excludes sensitive payroll figures` (PASS)

---

## 25. Manual UAT Matrix

| Scenario | Status | Notes |
|---|---|---|
| Submit request and check admin inbox | **PASS** | NOTIF-01 received by `usr_admin`; unread badge increments |
| Approve request and check requester inbox | **PASS** | NOTIF-02 received by `usr_hr` |
| Reject request with reason and check requester inbox | **PASS** | NOTIF-03 received by `usr_hr` with rejection reason |
| Cancel request and check admin inbox | **PASS** | NOTIF-04 received by `usr_admin` |
| Verify privacy in notification body | **PASS** | Zero salary amounts or PII present |
| Simulate delivery failure | **PASS** | Approval decision succeeds; failure safely isolated |
| Duplicate submission/decision attempt | **PASS** | Idempotency key prevents duplicate notification |
| Tap notification in dialog | **PASS** | Marks as read and opens `HrApprovalRequestDetailsScreen` |
| Mark all as read | **PASS** | Unread badge clears; items marked read |
| Logout / Session change | **PASS** | User notifications cleared; zero cross-session leakage |

---

## 26. Responsive Verification

Verified across standard viewports without RenderFlex overflow:
- **320 × 568** (Compact Mobile): PASS
- **360 × 640** (Standard Mobile): PASS
- **768 × 1024** (Tablet): PASS
- **1200 × 800** (Desktop Web): PASS

---

## 27. Regression Results

- **HR-1** Core Architecture: 100% PASS
- **HR-2** Employee Management: 100% PASS
- **HR-3** Employee Documents: 100% PASS
- **HR-4** Attendance: 100% PASS
- **HR-5** KPI / Performance: 100% PASS
- **HR-6** Payroll Foundation: 100% PASS
- **HR-7** Payroll Calculation: 100% PASS
- **HR-8** Reports & Export: 100% PASS
- **HR-9.3** Approval Repository: 100% PASS
- **HR-9.4** Request & Pending UI: 100% PASS
- **HR-9.5** Decision & History: 100% PASS
- **HR-9.6** HR Feature Integration: 100% PASS
- **HR-9.7** Notification Foundation: 100% PASS

---

## 28. Backend Dependencies

1. Push notification delivery services (FCM/APNs) must be configured on the instructor backend.
2. Webhook or server-side event dispatch for offline recipient notifications.

---

## 29. Deferred Functionality

- **HR-9.9**: Permissions, Security & Workflow Integrity Audit.
- **HR-9.10**: Final UAT & Freeze.
- Background device notifications (FCM/APNs).
- Email notifications.

---

## 30. Open Defects and Blockers

None. All confirmed approval notification workflows are integrated, verified, and passing tests.

---

## 31. Exit Criteria Verification

- [x] HR-9.7 verified and committed (`b4f21fa`).
- [x] Approved approval events identified (NOTIF-01 to NOTIF-04).
- [x] Existing event sources reused (`MockHrApprovalRepository`).
- [x] No duplicate event-emission path added.
- [x] Approved event mapping implemented in `HrApprovalNotificationService`.
- [x] Approved recipients resolved correctly (`adminRecipientUserId`, `requesterId`).
- [x] Stable approval request references preserved.
- [x] Sensitive information minimized (zero salary, zero PII).
- [x] Notifications occur only after confirmed events.
- [x] Approval failure does not generate success notifications.
- [x] Delivery failure handled safely without corrupting approval state.
- [x] Duplicate-event behavior follows contract (idempotency keys).
- [x] Existing inbox reused (`HrNotificationInboxDialog`).
- [x] Authorized notification navigation works.
- [x] Restricted navigation blocked.
- [x] Read/unread correct where supported.
- [x] Session isolation verified.
- [x] No approval status/history corruption.
- [x] No source HR mutation caused by notifications.
- [x] No new push/email infrastructure added.
- [x] Focused tests pass (8/8 pass).
- [x] Required regression passes.
- [x] Responsive verification completed.
- [x] Documentation created (`HR_9_APPROVAL_NOTIFICATION_INTEGRATION_AUDIT.md`).
- [x] Dedicated Git commit ready.
