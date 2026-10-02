# HR-9.4 — Approval Request & Pending Approvals UI Audit and Completion Report

**Document Status:** Complete & Verified  
**Date:** 2026-10-02  
**Checkpoint:** HR-9.4 — Approval Request & Pending Approvals UI  
**Parent Epic:** HR-9 — Approvals & Notifications Integration  
**Feature Branch:** `feature/hr-9-approvals-notifications`  
**Base Commit (HR-9.3):** `ea21e646fd6aa8823df7a78370cefb7eb2149e89`  

---

## 1. Purpose and Scope

HR-9.4 establishes the presentation and state-management foundation for HR approval workflows within the Enterprise CRM. It provides functional, authorized UI interfaces for:
1. Initiating and submitting authorized HR approval requests with form validation and repository-confirmed states.
2. Viewing actionable pending approval requests visible to the authorized actor (Administrators/Approvers).
3. Viewing approval requests submitted by the current authenticated user ("My Requests").
4. Inspecting detailed request metadata in a read-only details view.
5. Strict adherence to architectural invariants: zero approve/reject decision actions (reserved for HR-9.5), zero automatic HR entity mutations (reserved for HR-9.6), zero notification dispatch (reserved for HR-9.7/9.8), and zero invented permission keys.

---

## 2. Git Baseline

- **Active Branch:** `feature/hr-9-approvals-notifications`
- **HR-9.1 Commit:** `55c295a` (`docs(hr): audit approval notification requirements (HR-9.1)`)
- **HR-9.2 Commit:** `1019252` (`feat(hr): establish approval workflow domain (HR-9.2)`)
- **HR-9.3 Commit:** `ea21e64` (`feat(hr): implement approval repository foundation (HR-9.3)`)
- **Working Tree:** Pristine prior to HR-9.4 presentation additions.

---

## 3. HR-9.1 through HR-9.3 Dependencies

| Checkpoint | Status | Deliverable / Verified Contract |
|---|---|---|
| **HR-9.1** | COMPLETE | Requirements audit in `HR_9_APPROVALS_NOTIFICATIONS_REQUIREMENTS.md`. Identified 3 approved workflows, dual actor roles (Requester vs Decision-Maker), and shared module integration boundaries. |
| **HR-9.2** | COMPLETE | Domain models in `lib/features/hr/domain/entities/`: `HrApprovalRequest`, `HrApprovalTarget`, `HrApprovalWorkflowType`, `HrApprovalStatus`, `HrApprovalHistoryEntry`, and `HrApprovalWorkflowValidator`. 38/38 unit tests passing. |
| **HR-9.3** | COMPLETE | Repository contract and deterministic mock foundation in `lib/features/hr/domain/repositories/hr_approval_repository.dart`, `MockHrApprovalStore`, and `MockHrApprovalRepository`. 18/18 tests passing. |

---

## 4. Shared UI Reuse Decisions

1. **Shared Approvals Module Status:** In the existing CRM architecture, Collaborator Vikash Chaurasiya owns the upcoming shared Approvals & Notifications module (`feature/approvals-notifications`). No shared approvals UI existed in `lib/features/approvals/`.
2. **HR Domain Ownership:** The HR team established modular, self-contained presentation components under `lib/features/hr/presentation/`:
   - `hr_approval_status_badge.dart` (visual status badge adhering to CRM Design System)
   - `hr_approval_request_screen.dart` (request submission form)
   - `pending_approvals_screen.dart` (queue with Pending Approvals vs My Requests toggles)
   - `hr_approval_request_details_screen.dart` (read-only metadata inspection)
3. **Pluggable Integration:** These components interface exclusively with `HrApprovalRepository`, ensuring that once the shared CRM Approvals module is delivered, HR can either adapt to shared screens or provide its dedicated workflows seamlessly.

---

## 5. Implemented Request Workflows

Three confirmed HR workflows are supported for request submission and queue review:
1. **Payroll Period Finalization (`payrollFinalization`):** Target type `payroll_period`, e.g., `period_2026_01`.
2. **Attendance Adjustment (`attendanceCorrection`):** Target type `attendance_record`, e.g., `att_1`.
3. **Employee Document Verification (`documentVerification`):** Target type `employee_document`, e.g., `doc_1`.

---

## 6. Request Form Contract

- **Screen:** `HrApprovalRequestScreen` (`lib/features/hr/presentation/screens/hr_approval_request_screen.dart`)
- **Route Guard:** `HrAccessPolicy.canAccessModule(user)` — unauthorized users receive `AccessRestrictedScreen`.
- **Form Fields:**
  - `Workflow Type`: Dropdown selecting among `HrApprovalWorkflowType.values`.
  - `Target Entity Type`: Dropdown selecting target entity category (auto-defaults to workflow-matched target).
  - `Target Entity ID`: Text field with required non-empty validation (`Key('approval_request_target_id_field')`).
  - `Remarks / Justification`: Optional multiline text field (`Key('approval_request_remarks_field')`).
- **Submit Action:** Single `ElevatedButton.icon` with double-tap protection, loading indicator during in-flight submission, and error banner on failure.
- **Success View:** On successful creation, displays confirmed request ID, workflow type, target context, and initial status (`Pending`), with actions to return ("Done") or view details ("View Details").

---

## 7. Request Cubit Architecture

- **Class:** `HrApprovalRequestCubit` (`lib/features/hr/presentation/bloc/hr_approval_request_cubit.dart`)
- **States:**
  - `HrApprovalRequestInitial`: Idle form state.
  - `HrApprovalRequestSubmitting`: In-flight mutation state; ignores duplicate taps.
  - `HrApprovalRequestSuccess`: Request successfully submitted and confirmed by repository.
  - `HrApprovalRequestFailure`: Contains user-safe sanitized error message.
- **Invariants:**
  - Never mutates underlying source records.
  - Discards emissions if cubit has been closed.

---

## 8. My Requests Behavior

- In `PendingApprovalsScreen`, users can switch the `SegmentedButton` to "My Requests".
- `PendingApprovalsCubit.loadMyRequests(user: currentUser)` queries the repository with `getRequestsSubmittedBy(user.id)`.
- Ordinary users with HR module access can inspect their own submitted requests without seeing other users' pending queues.

---

## 9. Pending Approvals Behavior

- In `PendingApprovalsScreen`, the default tab is "Pending Approvals".
- `PendingApprovalsCubit.loadPendingApprovals(user: currentUser)` queries `getPendingRequests(user: currentUser)`.
- For `adminUser`, returns all pending requests awaiting decision.
- Renders cards with workflow display name, target entity reference (`#id`), requester ID, and `HrApprovalStatusBadge`.

---

## 10. Request Details

- **Screen:** `HrApprovalRequestDetailsScreen` (`lib/features/hr/presentation/screens/hr_approval_request_details_screen.dart`)
- **Fields Rendered:**
  - Request ID (AppBar and card)
  - Current Status (via `HrApprovalStatusBadge`)
  - Workflow Category
  - Target Entity Type and ID
  - Target Module (`crmModule.hrPayroll`)
  - Requester CRM User ID
  - Submission timestamp (UTC normalized)
  - Updated timestamp (if present)
  - Remarks / Justification
- **Zero Decision Mutations:** Strictly zero approve, reject, finalize, pay, or cancel buttons are rendered.

---

## 11. Approved Status Presentation

Implemented in `HrApprovalStatusBadge` (`lib/features/hr/presentation/widgets/hr_approval_status_badge.dart`):
- `pending`: Amber badge with `Icons.hourglass_empty` and label "Pending".
- `approved`: Green badge with `Icons.check_circle_outline` and label "Approved".
- `rejected`: Red badge with `Icons.cancel_outlined` and label "Rejected".
- `cancelled`: Grey badge with `Icons.block_outlined` and label "Cancelled".
- Does not rely on color alone (combines distinct icons, shapes, and clear text labels for accessibility).

---

## 12. Target HR Identity

All approval requests stably reference:
- `targetModule`: `CrmModule.hrPayroll`
- `targetEntityType`: String domain entity category (`payroll_period`, `attendance_record`, `employee_document`)
- `targetEntityId`: Persistent domain identifier (e.g. `period_2026_01`, `att_1`), never UI row indexes or display names.

---

## 13. Route Integration

Integrated into `EmployeeDirectoryScreen` (`lib/features/hr/presentation/screens/employee_directory_screen.dart`):
- Added `employee_directory_approvals_button` in the AppBar.
- Tapping navigates to `PendingApprovalsScreen`.
- Accepts optional `approvalRepository` constructor parameter for dependency injection and testing, defaulting to `MockHrApprovalRepository()`.

---

## 14. Authorization

1. **Route Level:** All approval screens evaluate `HrAccessPolicy.canAccessModule(user)`. Unauthorized users are presented with `AccessRestrictedScreen`.
2. **Cubit Level:** Both `HrApprovalRequestCubit` and `PendingApprovalsCubit` verify `HrAccessPolicy.canAccessModule(user)` before invoking repository operations.
3. **Queue Visibility:** The mock store and repository filter visible pending requests according to user role (`admin` vs standard).

---

## 15. Sensitive-Data Protection

- Raw employee compensation breakdowns, tax figures, bank accounts, and personal contact details are never stored or rendered in approval request metadata.
- Error messages are sanitized to strip internal stack traces and database exceptions before display.

---

## 16. Loading / Empty / Error / Retry

- **Loading State:** Centered `CircularProgressIndicator` with explicit test keys.
- **Empty State:** Contextual empty view with icon and "Create Request" call-to-action button (`Key('pending_approvals_empty_view')`).
- **Error State:** Error banner or card with safe user-facing message and retry button (`Key('pending_approvals_retry_button')`).

---

## 17. Stale-Request Protection

`PendingApprovalsCubit` implements a monotonically increasing `_activeRequestId` sequence counter. Out-of-order or late asynchronous responses are discarded if a newer query has been dispatched or if the cubit has been closed.

---

## 18. Session Isolation

- `PendingApprovalsCubit.clear()` resets `_currentUser`, increments the active request counter to cancel any in-flight async operations, and emits `PendingApprovalsInitial()`.
- State does not persist across user logout or account switching.

---

## 19. Responsive Behavior

Tested and verified without `RenderFlex` overflow across:
- Small Mobile: 320 × 568
- Standard Mobile: 360 × 640
- Tablet: 768 × 1024
- Desktop Web: 1200 × 800
Cards and forms employ `ConstrainedBox(maxWidth: 600 / 1000)` and `FittedBox` scale-down constraints for button labels.

---

## 20. Theme & Accessibility

- Supports Flutter Material 3 Light and Dark themes.
- Clear text contrast on cards and badges.
- Status communicated via text and icons, not color alone.
- Explicit tooltips and semantic keys on all interactive icon buttons.

---

## 21. Automated Tests Summary

| Test File | Tests | Status |
|---|---|---|
| `test/features/hr/presentation/bloc/hr_approval_request_cubit_test.dart` | 7 | PASS |
| `test/features/hr/presentation/bloc/pending_approvals_cubit_test.dart` | 8 | PASS |
| `test/features/hr/presentation/screens/hr_approval_request_screen_test.dart` | 5 | PASS |
| `test/features/hr/presentation/screens/pending_approvals_screen_test.dart` | 6 | PASS |
| `test/features/hr/presentation/screens/hr_approval_request_details_screen_test.dart` | 4 | PASS |
| `test/features/hr/presentation/screens/approval_navigation_and_access_test.dart` | 10 | PASS |
| `test/features/hr/presentation/screens/employee_directory_screen_test.dart` | 8 | PASS |
| **Total HR-9.4 Presentation Tests** | **48** | **ALL PASS** |

---

## 22. Manual UAT Status

| Checkpoint Item | Result | Notes |
|---|---|---|
| Authorized user can open request form | PASS | Verified in widget and navigation tests |
| Restricted user cannot open unauthorized form | PASS | Verified via `AccessRestrictedScreen` |
| Correct workflow shown | PASS | Dropdown with confirmed HR workflows |
| Correct HR target shown | PASS | Target entity type and ID inputs |
| Required fields validated | PASS | Empty target ID caught with validation message |
| Submission succeeds with mock repository | PASS | Confirmed request created in Pending status |
| Duplicate submit does not create duplicates | PASS | In-flight double-tap protection verified |
| My Requests loads submitted requests | PASS | Filter mode switch tested and verified |
| Pending Approvals loads actionable requests | PASS | Populates for authorized actor |
| Empty state works | PASS | Empty view with Create Request button verified |
| Error/retry works | PASS | Sanitized error banner and retry button verified |
| Request details show correct request | PASS | Read-only details screen verified |
| No approval/reject action available in HR-9.4 | PASS | Verified; zero decision buttons present |
| Session isolation maintained | PASS | Verified via `clear()` |
| Mobile layout (320x568, 360x640) works | PASS | Verified zero overflow |
| Tablet layout (768x1024) works | PASS | Verified zero overflow |
| Desktop Web (1200x800) works | PASS | Verified zero overflow |
| Light and Dark themes work | PASS | Verified with Material 3 ThemeData |

---

## 23. Defects and Fixes

1. **`DropdownButtonFormField` Text Overflow in Ahem Test Font:** Added `isExpanded: true` and `TextOverflow.ellipsis` to dropdowns in `HrApprovalRequestScreen`.
2. **Submit Button Label Overflow:** Wrapped label text in `FittedBox(fit: BoxFit.scaleDown)` to ensure clean rendering on narrow viewports.
3. **Async Microtask Stream Delivery in Tests:** Added event loop yields (`await Future<void>.delayed(Duration.zero)`) to ensure final cubit states are delivered to stream listeners before assertions.

---

## 24. Remaining Blockers

None for HR-9.4. Workflows proceed deterministically.

---

## 25. Backend Dependencies

- Production backend endpoints for submitting requests, assigning approvers, and querying permission-filtered approval queues will be integrated in HR-10.

---

## 26. HR-9.4 Exit Criteria Verification

- [x] HR-9.3 verified and committed independently (`ea21e64`).
- [x] Only approved request workflows implemented.
- [x] Request submission works for authorized actors with form validation.
- [x] Submission success displays repository-confirmed request state.
- [x] Pending requests and My Requests queues function correctly.
- [x] Read-only request details screen implemented.
- [x] Stable request and target identities preserved.
- [x] Zero approve/reject decision execution added.
- [x] Zero notification delivery added.
- [x] Zero HR source-record mutations added.
- [x] Route access protected via `HrAccessPolicy`.
- [x] Session isolation maintained.
- [x] Stale-response protection implemented in Cubit.
- [x] Responsive layouts verified across all viewports (320x568, 360x640, 768x1024, 1200x800).
- [x] Automated tests pass (48 presentation tests, full workspace tests passing).
- [x] Full workspace verification passes (`flutter analyze`, `flutter test`, `flutter build web`).
- [x] Deliverable audit document created (`HR_9_APPROVAL_REQUEST_AND_PENDING_UI.md`).

---

## 27. Git Commit Reference

- **Checkpoint:** HR-9.4 — Approval Request & Pending Approvals UI
- **Commit Message:** `feat(hr): implement approval request and pending workflows (HR-9.4)`
