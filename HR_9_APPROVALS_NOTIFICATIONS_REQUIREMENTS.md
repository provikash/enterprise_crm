# HR-9.1 — Approvals & Notifications Requirements Audit & Freeze Report

**Date:** 2026-10-01  
**Project:** Enterprise CRM  
**Module:** HR / Payroll (`lib/features/hr`) & Shared Approvals & Notifications Integration  
**Status:** `AUDIT COMPLETE — APPROVAL WORKFLOW FREEZE BLOCKED`

---

## 1. Purpose and Scope

This document represents the formal architectural, business requirements, and integration boundary audit for **HR-9.1: Approvals & Notifications Requirements Audit & Freeze** in the Enterprise CRM Flutter application.

The primary objectives of this checkpoint are:
1. Identify all candidate HR approval and notification workflows across Employee Management, Documents, Attendance, KPI / Performance, Payroll, and Reports.
2. Audit the current implementation status of the shared CRM Approvals and Notifications modules.
3. Establish clear ownership and module collaboration boundaries between HR and shared platform capabilities.
4. Classify all candidate HR workflows against authoritative repository requirements to eliminate unconfirmed assumptions.
5. Define the actor, authorization, status, transition, data mutation, notification, and backend dependency boundaries for HR-9.
6. Determine whether HR approval workflows can be formally frozen, or if missing business approvals and backend contracts block a production freeze.

---

## 2. Git Baseline

- **Current Branch:** `feature/hr-9-approvals-notifications` (branched from `feature/hr-8-reports-export` at commit `dd1b07d`)
- **Starting HEAD:** `dd1b07d154c5d5da62bcefd921904a201a3dd0c4` (`test(hr): document reports UAT blockers (HR-8.10)`)
- **Working Tree:** Clean (0 untracked files, 0 uncommitted modifications)
- **Previous HR Checkpoints:**
  - `dd1b07d` test(hr): document reports UAT blockers (HR-8.10)
  - `2fcb5dc` feat(hr): standardize report filters periods and summaries (HR-8.7)
  - `548517a` feat(hr): implement payroll reports (HR-8.6)
  - `7684d59` feat(hr): implement kpi reports (HR-8.5)
  - `9794851` feat(hr): implement attendance reports (HR-8.4)
  - `50dcf56` feat(hr): implement employee reports (HR-8.3)
  - `f742c4c` feat(hr): establish report domain and query contract (HR-8.2)
  - `30db86b` docs(hr): freeze reports and export requirements (HR-8.1)
  - `2935058` test(hr): prepare payroll calculation final UAT (HR-7.10)
  - `783a556` test(hr): audit payroll calculation security (HR-7.9)

---

## 3. Previous HR Phase Dependencies

| HR Phase | Status | Baseline / Blocker Impact on HR-9 |
| :--- | :--- | :--- |
| **HR-1 — Core Architecture** | `COMPLETE / FROZEN` | Core domain entities, `HrAccessPolicy`, and repository contracts established. |
| **HR-2 — Employee Management** | `COMPLETE / FROZEN` | Employee CRUD operational (`EmployeeRepository`); direct Admin mutations; no approvals currently attached. |
| **HR-3 — Employee Documents** | `COMPLETE / FROZEN` | Document upload and binary download operational (`EmployeeDocumentRepository`); document verification was deferred. |
| **HR-4 — Attendance** | `COMPLETE / FROZEN` | Attendance recording and querying operational (`AttendanceRepository`); adjustments are direct mutations by Admin. |
| **HR-5 — KPI / Performance** | `COMPLETE / FROZEN` | KPI creation and update operational (`EmployeeKpiRepository`); approval/finalization lifecycle was explicitly deferred. |
| **HR-6 — Payroll Foundation** | `IMPLEMENTED — AWAITING MANUAL UAT` | Stored `PayrollRecord` and `PayrollPeriod` read-only querying operational; mutations deferred to HR-7/HR-9. |
| **HR-7 — Payroll Calculation** | `COMPLETE / FROZEN` | Itemized calculation preview engine operational; calculation preview strictly separated from stored `PayrollRecord`. Final payroll submission, approval, and disbursement were explicitly deferred. |
| **HR-8 — Reports & Export** | `PARTIAL — IMPLEMENTATION BLOCKED` | Reporting query foundation, cubits, and screens for Employee, Attendance, KPI, and Payroll verified (727/727 tests PASS). However, **HR-8.8 (Export Foundation)** and **HR-8.9 (Permissions, Privacy & Export Security)** remain unimplemented. |

**Impact on HR-9:**
HR-8 is not fully closed (`PARTIAL — IMPLEMENTATION BLOCKED`). Therefore, any approval workflow contemplating "sensitive report export approval" must remain gated. Reporting queries and read-only summaries are operational, but export capabilities do not exist.

---

## 4. Source Documents Reviewed

The following repository specifications, architectural standards, and collaboration agreements were examined:
1. `context/MASTER_DEVELOPMENT_RULES.md`: Core architectural principles, instruction hierarchy, non-negotiable prohibitions against inventing unapproved business rules, tables, roles, or endpoints.
2. `context/Enterprise_CRM_Team_Collaboration_Handoff.md`: Module ownership boundaries, branch workflow, shared platform rules, and separation between Vachaspati Mishra and Vikash Chaurasiya.
3. `context/AI_BRAIN.md`: Durable project memory, verified phase statuses (L0–L5, HR-1–HR-8).
4. `context/CRM_PRD.md`: CRM Product Requirements Document; specifies 8 modules, account workflow, role definitions, and candidate approval/notification capabilities.
5. `context/CRM_TRD.md`: Technical Requirements Document; architecture structure (`lib/features/*`), technology choices, state management.
6. `context/CRM_UI_UX.md`: Screen inventory, approval inbox tabs (pending/approved/rejected), navigation flows.
7. `context/CRM_Backend_Schema.md`: Preliminary backend draft schema; §6.8 proposed `approval_requests`, `approval_steps`, and `notifications` tables (non-authoritative planning draft).
8. `context/CRM_UPDATED_PROJECT_FLOW_AND_STRUCTURE.md`: Project flow, instructor review gates, module structure.
9. `context/HR_REQUIREMENTS.md`: HR-0 architectural baseline; records that Approvals $\rightarrow$ HR workflows are deferred to explicit cross-module integration.
10. `context/HR_KPI_REQUIREMENTS.md`: Confirmed KPI domain invariants; records that KPI Approval / Finalization lifecycle is deferred.
11. `context/HR_PAYROLL_REQUIREMENTS.md`: Payroll domain rules; explicitly excludes approval flags or auto-generators from `PayrollPeriod` and `PayrollRecord`.
12. `HR_7_CALCULATION_REQUIREMENTS.md` & `HR_7_FINAL_UAT_AND_FREEZE.md`: Payroll calculation preview boundaries; confirms payroll finalization and disbursement are deferred.
13. `HR_8_REPORTS_REQUIREMENTS.md` & `HR_8_FINAL_UAT_AND_FREEZE.md`: Reports requirements and current acceptance status (`PARTIAL — IMPLEMENTATION BLOCKED`).

---

## 5. Shared CRM Approvals Module Audit

A thorough code audit of the entire repository (`lib/` and `test/`) was executed for approval-related symbols (`Approval`, `ApprovalRequest`, `ApprovalStatus`, `ApprovalRepository`, `ApprovalCubit`, etc.):

1. **Existence:** There is **NO** `lib/features/approvals/` directory in the repository.
2. **Entities & Domain Models:** No `ApprovalRequest`, `ApprovalDecision`, `ApprovalStatus`, or `ApprovalHistory` classes exist anywhere in the codebase.
3. **Repository Contracts:** No `ApprovalRepository` interface or mock implementation exists.
4. **BLoC / Cubit:** No approval-related Cubit or BLoC exists.
5. **Presentation / UI:** No Approval Inbox screen, Approval Details screen, or approval tab widget exists.
6. **Presence in Enums & Navigation:**
   - `CrmModule.approvalsNotifications` is defined in `lib/features/auth/domain/entities/crm_module.dart`.
   - `CrmModulePresentation` maps it to `'Approvals & Notifications'`, subtitle `'Workflow approvals and system alerts'`, and icon `Icons.notifications_active_outlined`.
   - In both `AdminDashboardScreen` and `UserDashboardScreen`, tapping `CrmModule.approvalsNotifications` routes to `ModulePlaceholderScreen(module: module, user: user)`.
7. **Permissions:** `CrmPermissions` does **not** declare any approval-related permissions (such as `approvals.view` or `approvals.decide`).
8. **Audit Classification:** The shared Approvals module is **NOT IMPLEMENTED** (Contract and UI are currently placeholders).

---

## 6. Shared Notifications Module Audit

A code audit of `lib/` and `test/` for notification-related symbols was executed:

1. **Existence:** There is **NO** `lib/features/notifications/` directory in the repository.
2. **Entities & Domain Models:** No `NotificationItem`, `NotificationEvent`, or `NotificationPayload` models exist.
3. **Repository Contracts:** No `NotificationRepository` interface or mock exists.
4. **BLoC / Cubit:** No `NotificationCubit` exists.
5. **Delivery Infrastructure:** Zero push notification services (no Firebase Cloud Messaging), zero email services, zero local notification plugins, and zero in-app notification badge/inbox components exist.
6. **Audit Classification:** The shared Notifications module is **NOT IMPLEMENTED**.

---

## 7. Ownership and Collaboration Boundaries

According to `context/Enterprise_CRM_Team_Collaboration_Handoff.md` (§7, §14, §16, §17):

1. **Collaborator Vikash Chaurasiya owns:**
   - Calling / Follow-Up (`lib/features/calling/`)
   - Vendor Management (`lib/features/vendor/`)
   - Approvals & Notifications (`lib/features/approvals/`, `feature/approvals-notifications`)
2. **Project Lead Vachaspati Mishra owns:**
   - Lead Management (`lib/features/leads/`)
   - Inventory (`lib/features/inventory/`)
   - Purchase (`lib/features/purchase/`)
   - Dispatch (`lib/features/dispatch/`)
   - HR / Payroll (`lib/features/hr/`)
   - Shared platform / Auth / Users & Access
3. **Collaboration Boundary Rules:**
   - Approvals & Notifications must become a **reusable cross-module capability**, not duplicated inside HR, Purchase, Dispatch, or Vendor modules.
   - HR must **not** build a separate, standalone approval engine inside `lib/features/hr/`.
   - Approvals must not directly rewrite HR domain logic during initial development.
   - Any HR $\leftrightarrow$ Approvals connection must occur via an explicit, typed integration contract.
   - Since Vikash Chaurasiya owns the shared Approvals & Notifications module and it has not yet been built, HR-9.2 must define the domain integration contract and target entity abstractions from the HR boundary without usurping ownership of the shared Approvals module.

---

## 8. Requirements Classification Register

Requirements are classified under the six mandatory project tiers:
- **CONFIRMED:** Explicitly mandated by authoritative specifications or frozen architectural baselines.
- **PROPOSED:** Suggested in planning drafts, awaiting formal business freeze.
- **UNCONFIRMED:** Mentioned in general discussions without workflow, actor, or state definitions.
- **BACKEND-DEPENDENT:** Requires the instructor's authoritative backend contract or database schema.
- **APPROVED DEFERRED:** Explicitly excluded from current phase scope by documented agreement.
- **CONFLICTING:** Incompatible requirements between specifications.

---

## 9. Employee Management Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Employee Creation** | `EmployeeRepository.createEmployee` (via `AddEmployeeScreen`) | **NO** | **CONFIRMED DIRECT** | Authorized administrators create employee records directly. No approval request is required or documented. |
| **Employee Profile Update** | `EmployeeRepository.updateEmployee` (via `EditEmployeeScreen`) | **NO** | **CONFIRMED DIRECT** | Direct update by Administrator. Self-service employee updates do not exist in the app. |
| **Employee Status Change** | Managed within `updateEmployee` (`EmploymentStatus`) | **NO** | **CONFIRMED DIRECT** | Admin directly sets `active`, `inactive`, `on_leave`, etc. |
| **Employee Deactivation** | Setting status to `inactive` | **NO** | **CONFIRMED DIRECT** | Direct administrative operation. |
| **Employee Deletion** | Not supported in repository or UI | N/A | **APPROVED DEFERRED** | Deletion is prohibited by CRM data integrity rules; inactive status is used. |

**Audit Conclusion:** Zero Employee Management operations require an approval workflow in the current CRM design. Adding approval gates to basic Admin CRUD would violate `MASTER_DEVELOPMENT_RULES.md`.

---

## 10. Employee Documents Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Document Upload** | `EmployeeDocumentRepository.uploadDocument` | **NO** | **CONFIRMED DIRECT** | Direct upload by authorized Admin/HR user. |
| **Document Download** | `EmployeeDocumentRepository.downloadDocumentFile` | **NO** | **CONFIRMED DIRECT** | Direct binary retrieval by authorized user. |
| **Document Verification** | None (`EmployeeDocument` has no verification status) | Undefined | **APPROVED DEFERRED** | Deferred in HR-3. Document verification is an internal document status, not a generic CRM approval request. |
| **Document Replacement** | Upload new document with same or updated title | **NO** | **CONFIRMED DIRECT** | No approval gate. |
| **Document Deletion** | Not supported in repository contract | N/A | **APPROVED DEFERRED** | Deferred. |

**Audit Conclusion:** Zero Employee Document operations require an approval workflow.

---

## 11. Attendance Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Daily Attendance Record** | `AttendanceRepository.recordAttendance` | **NO** | **CONFIRMED DIRECT** | Direct daily record entry by Admin/HR. |
| **Attendance Correction** | Overwritten via `recordAttendance` for same date | **NO** (currently direct) | **UNCONFIRMED** | While enterprise systems often support "Attendance Correction Requests" submitted by employees to managers, standard CRM users currently have no self-service attendance UI or correction request pipeline. |
| **Manual Punctuality Adjustment**| None (working hours/punches are not stored) | N/A | **APPROVED DEFERRED** | Excluded in HR-4 freeze. |
| **Leave Approval Request** | None (attendance status can be set to 'On Leave') | Undefined | **APPROVED DEFERRED** | Leave management system is explicitly deferred in `HR_REQUIREMENTS.md` §4 ("Leave / Expense Approvals: DEFERRED"). |

**Audit Conclusion:** There is **no confirmed attendance approval workflow**. Attendance is administered directly.

---

## 12. KPI / Performance Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **KPI Record Creation** | `EmployeeKpiRepository.createKpi` (`AddEmployeeKpiScreen`) | **NO** | **CONFIRMED DIRECT** | Direct Admin mutation. |
| **KPI Record Update** | `EmployeeKpiRepository.updateKpi` (`EditEmployeeKpiScreen`) | **NO** | **CONFIRMED DIRECT** | Direct Admin mutation. |
| **KPI Score Finalization / Lock**| None | Undefined | **APPROVED DEFERRED** | In `HR_KPI_REQUIREMENTS.md` §6.6: "KPI Approval / Finalization Lifecycle: Unconfirmed: Draft/Submitted/Approved/Locked statuses are deferred." |
| **Manager Evaluation Review** | None | Undefined | **UNCONFIRMED** | No manager evaluation hierarchy exists in CRM. |

**Audit Conclusion:** Zero KPI operations currently require an approval workflow.

---

## 13. Payroll Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Payroll Period Creation** | Static mock periods in `MockPayrollStore` | **NO** | **PROPOSED** | In `HR_PAYROLL_REQUIREMENTS.md` §9.5: "No status enum, no approval flag, no automatic month generator." |
| **Calculation Preview Review** | `PayrollCalculationPreviewCubit` | **NO** | **CONFIRMED READ-ONLY** | Pure client-side simulation. `HR_7_SECURITY_AND_CALCULATION_AUDIT.md` verified 0 mutating calls (`approve`, `finalize`, `save`). |
| **Payroll Period Finalization** | None (no repository mutation exists) | **Candidate Workflow** | **UNCONFIRMED / BACKEND-DEPENDENT** | Conceptually, locking a completed monthly payroll run before payment is a standard enterprise approval candidate. However, no finalization endpoint, repository method, or approver policy exists in the CRM. |
| **Payroll Record Approval** | None | **Candidate Workflow** | **UNCONFIRMED / BACKEND-DEPENDENT** | Individual salary approval is unconfirmed; no approval flag exists on `PayrollRecord`. |
| **Salary Payment / Disbursement**| None | **NO** | **APPROVED DEFERRED** | Out of scope (`HR_PAYROLL_REQUIREMENTS.md` §8.3). CRM does not disburse funds. |

**Audit Conclusion:** Payroll Finalization is a **potential future approval candidate**, but currently lacks business approval, repository mutation methods, and backend API contracts. It is classified as **UNCONFIRMED / BACKEND-DEPENDENT / APPROVAL PENDING**.

---

## 14. Reports / Export Workflows Audit

| Operation | Current Implementation | Approval Required? | Classification | Business & Architectural Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Report Query / View** | `HrReportRepository` (Employee, Attendance, KPI, Payroll) | **NO** | **CONFIRMED DIRECT** | Direct querying gated purely by `HrAccessPolicy.canViewHrRecords` and `canViewPayroll`. |
| **Sensitive Report Export Approval**| None (Export foundation is unbuilt) | **NO** | **UNCONFIRMED** | Export authorization is an access control / permission concern (`canExport`), not a multi-step approval workflow. Submitting an approval request to export data is not documented anywhere in CRM requirements. |

**Audit Conclusion:** Zero reporting operations require an approval workflow.

---

## 15. Requester and Decision-Maker Contract

In the CRM architecture (`lib/features/auth/`):
1. **Account Types:** There are exactly two top-level account types:
   - `AccountType.admin`: Global access to all modules and all operations.
   - `AccountType.user`: Restricted to assigned `modules` and assigned `permissions`.
2. **No Role Entities:** There are no distinct account types or entities for `HR Manager`, `Payroll Approver`, `Supervisor`, or `Department Head`.
3. **Requester Identification:**
   - Any authenticated CRM user (`CurrentUser.id`) who has access to an authorized operational screen could conceptually submit a request.
   - The requester identity must be `CurrentUser.id` (`usr_admin`, `usr_hr`, etc.), **never** an `Employee.id` (`emp_1`), because Employees are workforce records and do not necessarily have CRM accounts.
4. **Decision Authority:**
   - `Admin` accounts have global administrative authority (`user.isAdmin`).
   - For standard users, no `approvals.decide` permission currently exists in `CrmPermissions` or `MockPermissionCatalog`.
   - Therefore, until a formal permission is introduced and approved by the shared platform owner, **only Administrator accounts (`AccountType.admin`) possess confirmed decision authority**.
   - Self-approval rules (e.g. can an Admin approve their own request?) are **unconfirmed**.

---

## 16. Approval Status Contract

Review of CRM specifications (`CRM_UI_UX.md` §4, §6; `CRM_Backend_Schema.md` §6.8):
1. **Confirmed Statuses:**
   - `pending`: Awaiting review and decision by an authorized actor.
   - `approved`: Formally authorized by a decision-maker.
   - `rejected`: Explicitly declined by a decision-maker.
2. **Candidate / Unconfirmed Statuses:**
   - `cancelled` (or `withdrawn`): Cancelled by the original requester prior to decision.
   - `expired`: Timed out due to inactivity (unconfirmed).
   - `draft`: Created but not yet submitted for review (unconfirmed).
3. **Approved Status Contract for HR-9:**
   The minimum safe status domain model must represent:
   - `pending`
   - `approved`
   - `rejected`
   - `cancelled`

---

## 17. State Transition Matrix

The table below outlines permitted and prohibited lifecycle state transitions:

| Current State | Action | Next State | Authorized Actor | Preconditions / Side Effects | Classification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `[None]` | `submit` | `pending` | Authorized Requester | Valid target entity reference; timestamp recorded. | **CONFIRMED** |
| `pending` | `approve` | `approved` | Authorized Decision-Maker (`admin`) | Valid decision comment (optional/required); terminal state. | **CONFIRMED** |
| `pending` | `reject` | `rejected` | Authorized Decision-Maker (`admin`) | Reason/comment recorded; terminal state. | **CONFIRMED** |
| `pending` | `cancel` | `cancelled` | Original Requester | Can only cancel while still `pending`; terminal state. | **PROPOSED** |
| `approved` | `reopen` / `reject` | Any | None | **PROHIBITED:** Terminal state cannot be transitioned. | **CONFIRMED** |
| `rejected` | `reopen` / `approve`| Any | None | **PROHIBITED:** Terminal state cannot be transitioned. | **CONFIRMED** |
| `cancelled`| `resubmit` / `approve` | Any | None | **PROHIBITED:** Terminal state cannot be transitioned. Resubmission requires a new request. | **CONFIRMED** |

---

## 18. Underlying HR Record Mutation Rules

When an approval workflow is attached to an HR entity:
1. **Model Selection:**
   - *Option A (Request before change):* Proposed change is captured in the approval request payload. The source HR record remains untouched until the request reaches `approved`.
   - *Option B (Apply immediately, rollback on reject):* Source record is mutated with a "pending review" flag.
2. **Current HR Domain Reality:**
   - No HR entity (`Employee`, `AttendanceRecord`, `EmployeeKpi`, `PayrollRecord`, `PayrollPeriod`) contains a `pendingApproval` boolean or `ApprovalStatus` property.
   - Mutating source entities directly would violate existing frozen contracts across HR-2, HR-4, HR-5, and HR-6.
3. **Mandatory Rule for HR-9:**
   - **Underlying HR records must NOT be mutated while approval is pending.**
   - If an HR approval workflow is executed in later checkpoints, the proposed change or reference must reside inside the approval request, and mutation of the source repository must occur **only upon confirmed approval**.
   - Because no HR approval workflows are currently confirmed for production mutation, **all source-record mutation integrations remain blocked**.

---

## 19. Approval Request Identity Relationships

An approval request must strictly preserve unambiguous relational identities:
1. `id`: Stable, unique identifier of the approval request (e.g. `appr_req_101`).
2. `requesterId`: References the CRM user who submitted the request (`CurrentUser.id`, e.g. `usr_admin` or `usr_hr`).
3. `targetModule`: `CrmModule` identifier (e.g. `CrmModule.hrPayroll`).
4. `targetEntityType`: String descriptor identifying the HR entity type (e.g. `'payroll_period'`, `'attendance_record'`, `'employee'`).
5. `targetEntityId`: Stable identifier of the target HR entity (e.g. `period_2026_01`, `att_001`, `emp_1`).
6. `workflowType`: Identifier distinguishing specific workflows (e.g. `'hr.payroll_finalization'`).
7. **Identity Separation Invariant:**
   - `CurrentUser.id` $\ne$ `Employee.id`. An approval request must never use an employee code or employee name as `requesterId`.

---

## 20. Approval History Requirements

1. **Audit Entries:**
   Each approval request lifecycle event must be traceable via immutable history entries:
   - `id`: Unique history entry identifier.
   - `requestId`: Foreign key to `ApprovalRequest.id`.
   - `actorId`: CRM user who performed the action (`CurrentUser.id`).
   - `action`: String or enum describing the transition (`'submitted'`, `'approved'`, `'rejected'`, `'cancelled'`).
   - `previousStatus`: Status prior to action.
   - `newStatus`: Resulting status.
   - `timestamp`: UTC timestamp of the action.
   - `reason`: Optional or required qualitative explanation.
2. **Storage Authority:**
   Authoritative persistent audit history belongs strictly to the instructor backend. Client-side domain models provide presentation and mock traceability only.

---

## 21. Notification Trigger Matrix

| Event ID | Workflow Event | Recipient | Delivery Channel | Payload Content | Classification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NOTIF-01** | Approval Request Submitted | Authorized Approvers (`admin`) | In-app notification | Request ID, Target Entity Type, Requester Name, Timestamp | **PROPOSED** |
| **NOTIF-02** | Approval Request Approved | Original Requester | In-app notification | Request ID, Target Entity Type, Decision Maker, Timestamp | **PROPOSED** |
| **NOTIF-03** | Approval Request Rejected | Original Requester | In-app notification | Request ID, Target Entity Type, Decision Maker, Reason, Timestamp | **PROPOSED** |
| **NOTIF-04** | Approval Request Cancelled | Assigned Approvers | In-app notification | Request ID, Target Entity Type, Cancelled By, Timestamp | **PROPOSED** |

**Audit Finding:** All notification triggers are currently **PROPOSED**. Because the shared Notifications module has zero implementation in the repository, no notification dispatch can occur in production code during HR-9.1 or HR-9.2.

---

## 22. Notification Recipient & Content Privacy Contract

1. **Recipient Resolution:**
   - Notifications must be routed exclusively to CRM user accounts (`recipientUserId`), not to employee records.
   - The recipient must hold legitimate authorization to view the referenced entity.
2. **Sensitive Data Protection (Strict Privacy Invariant):**
   - **Zero financial figures:** Net salaries, basic pay, allowances, and deduction amounts must **never** appear in notification titles, summaries, or push payloads.
   - **Zero sensitive PII:** National identity numbers, bank accounts, home addresses, and personal credentials must be omitted.
   - **Allowed notification payload:** Only generic, non-sensitive metadata is permitted:
     - Notification Title (e.g. `'Approval Decision Recorded'`)
     - Message (e.g. `'Your request for Payroll Period January 2026 was approved.'`)
     - Reference Type (`'approval_request'`)
     - Reference ID (`requestId`)
     - Timestamp (`createdAt`)

---

## 23. Authorization and Privacy Boundaries

1. **Module Access:** Gated by `AccessPolicy.canAccessModule(user, CrmModule.approvalsNotifications)` or `user.isAdmin`.
2. **Operational Access:** Standard users must have explicit permissions assigned to interact with approvals.
3. **Frontend Guards vs Backend Enforcement:**
   - Frontend UI guards (`AccessRestrictedScreen`, hidden action buttons) protect user experience.
   - Authoritative authorization enforcement is strictly owned by the backend. Client-side validation does not guarantee security.

---

## 24. Concurrency and Idempotency Requirements

1. **Double-Click / Rapid Action:**
   - The UI and BLoC layer must track active request IDs or submission states to prevent duplicate submission of the same approval request.
2. **Terminal State Immutability:**
   - A request that has been decided (`approved` or `rejected`) must reject any subsequent decision calls.
3. **Concurrent Decisions:**
   - In a multi-user environment, if two administrators attempt to decide the same request simultaneously, the backend must enforce optimistic locking or atomic transactions. The client domain model must expect and handle `InvalidTransitionException` or `ConflictException`.

---

## 25. Frontend vs Backend Ownership

| Responsibility | Frontend Domain & UI | Authoritative Backend |
| :--- | :--- | :--- |
| **Request Creation Contract** | Validates input format, constructs immutable request | Persists record, generates database UUID, validates uniqueness |
| **Decision Execution** | Dispatches decision event, provides optimistic feedback | Validates actor permission, checks state concurrency, commits transaction |
| **State Machine Enforcement** | Validates client-side transition rules | Enforces strict database-level lifecycle constraints |
| **Audit Log & History** | Renders timeline from retrieved records | Immutable append-only audit trail storage |
| **Notification Dispatch** | Displays in-app inbox and badge counts | Generates notification records, sends push/email (if supported) |
| **Source HR Record Mutation** | Triggers repository refresh upon successful approval | Executes transactional updates to source business tables |

---

## 26. Open Questions and Conflicting Decisions

The following critical business and technical questions remain unanswered:
1. **Shared Approvals Module Delivery:** Who will implement `lib/features/approvals/`? (Assigned to Vikash Chaurasiya in handoff guide, but currently unbuilt).
2. **Approver Role / Permission:** Will a specific permission (e.g. `approvals.decide`) be added to `CrmPermissions`, or will all approval decisions rely solely on `AccountType.admin`?
3. **Confirmed HR Approval Candidates:** Does the business require any HR workflow (e.g., Attendance adjustment, Employee document verification, or Payroll finalization) to be gated by an approval request?
4. **Notification Delivery Mechanism:** Will the CRM support in-app notifications only, or will push notifications / emails be integrated when the instructor backend arrives?
5. **Self-Approval Policy:** Is an administrator permitted to approve an approval request that they submitted?

---

## 27. Explicitly Deferred Functionality

The following items are explicitly out of scope for HR-9:
- Standalone approval engine implementation inside `lib/features/hr/`.
- Implementation of push notifications, Firebase, APNs, or email delivery.
- Creation of unapproved permissions or new top-level account types.
- Multi-tier or hierarchical approval chains (unless confirmed by backend).
- Payroll payment processing or salary disbursement.
- Automatic payroll finalization on date boundaries.
- Re-engineering existing Employee, Attendance, KPI, or Payroll CRUD screens to force unconfirmed approvals.

---

## 28. HR-9.2 Through HR-9.10 Dependency Map

```text
HR-9.1: Requirements Audit & Freeze (This Checkpoint)
  └── HR-9.2: Approval Domain & Workflow Contract (Define HR target reference, status, and transition contracts)
        └── HR-9.3: Approval Repository & Mock Foundation (Integration interfaces)
              └── HR-9.4: Approval Request & Pending Approvals UI
                    └── HR-9.5: Approval Decision & History UI / Logic
                          └── HR-9.6: HR Feature Integration (Connecting confirmed HR operations)
                                └── HR-9.7: Notifications Domain Foundation
                                      └── HR-9.8: Approval Notification Integration
                                            └── HR-9.9: Security & Workflow Integrity Audit
                                                  └── HR-9.10: Final UAT & Feature Freeze
```

---

## 29. HR-9.1 Exit Criteria

- [x] Git baseline recorded and feature branch `feature/hr-9-approvals-notifications` verified.
- [x] Project development rules (`MASTER_DEVELOPMENT_RULES.md`) reviewed.
- [x] Previous HR phase dependencies (especially HR-8 status: `PARTIAL — IMPLEMENTATION BLOCKED`) audited.
- [x] Existing Approvals module audited (found to be unbuilt; placeholder only).
- [x] Existing Notifications module audited (found to be unbuilt).
- [x] Ownership and collaboration boundaries (Vikash vs Vachaspati) verified.
- [x] Candidate HR approval workflows audited across all 6 HR subdomains.
- [x] Approved requester and decision-maker roles classified.
- [x] Workflow statuses, transitions, and terminal states documented.
- [x] Source-record mutation rules defined (zero mutation while pending).
- [x] Notification triggers and privacy constraints cataloged.
- [x] Backend dependencies and concurrency risks documented.
- [x] Open questions and deferred scope documented.
- [x] Requirements deliverable `HR_9_APPROVALS_NOTIFICATIONS_REQUIREMENTS.md` created.

---

## 30. Final Requirements Freeze Status

### Status: `AUDIT COMPLETE — APPROVAL WORKFLOW FREEZE BLOCKED`

**Rationale:**  
The requirements, architectural, and module collaboration audit is 100% complete and verified against the actual repository source code. However, a production freeze of HR approval workflows is **blocked** by three concrete repository realities:
1. The shared CRM Approvals and Notifications modules (`lib/features/approvals/` and `lib/features/notifications/`) have not yet been built by the responsible collaborator (Vikash Chaurasiya).
2. Zero HR operations have been formally confirmed as approval-gated by the project owner or instructor requirements.
3. No approver permission exists in `CrmPermissions`, leaving decision authority restricted to global administrators.

**Gate to HR-9.2:**  
In accordance with prompt instructions, HR-9.2 may safely proceed to establish the **minimum approved domain representation** (approval request identity, target HR entity references, immutable statuses, transitions, and decision models) so that HR is architecturally prepared to integrate with the shared Approvals module when it becomes available.
