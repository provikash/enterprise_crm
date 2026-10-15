# MASTER SPECIFICATION & IMPLEMENTATION ROADMAP: APPROVALS & NOTIFICATIONS MODULE

**Project:** Enterprise CRM  
**Module ID:** Module 07 — Approvals & Notifications (`CrmModule.approvalsNotifications`)  
**Document Type:** Master Architectural Specification, Requirements Contract & Engineering Roadmap  
**Author / Module Owner:** Vikash Chaurasiya  
**Project Lead / Owner:** Vachaspati Mishra  
**Target Platforms:** Android & Responsive Web (Flutter Single Codebase)  
**State Management:** BLoC / Cubit (`flutter_bloc`)  
**Network / HTTP Client:** Dio (Planned Backend Integration)  
**Status:** **AUTHORITATIVE MASTER BLUEPRINT — READY FOR PHASED EXECUTION**

---

## 1. Executive Summary & Module Mission

### 1.1 Module Identity & Core Purpose
The **Approvals & Notifications** module is one of the eight core business modules comprising the Enterprise CRM application:
1. Lead Management
2. Calling / Follow-Up
3. Inventory
4. Dispatch
5. Purchase
6. HR / Payroll
7. **Approvals & Notifications** (`CrmModule.approvalsNotifications`)
8. Vendor Management

As mandated by the project architecture and collaboration contract (`context/Enterprise_CRM_Team_Collaboration_Handoff.md`), Approvals & Notifications is **not** an internal, isolated sub-feature of any single department. Instead, it is a **centralized, reusable, enterprise-grade cross-module capability** designed to govern multi-department decision lifecycles, enforce managerial oversight, deliver real-time operational alerts, and maintain an immutable audit trail across the entire enterprise.

### 1.2 Core Architectural Objectives
- **Centralized Approval Engine:** Provide a unified repository, state machine, and user interface for inspecting, approving, rejecting, and requesting revisions on workflow items originating from Purchase (PI/PO), HR (Leave, Attendance Corrections, Payroll Finalization), Vendor Management (KYC, Banking verification), Inventory (Stock adjustments), and Dispatch.
- **Enterprise Notification System:** Deliver an in-app alert and messaging hub featuring unread badges, category filtering, persistent notification history, deep-link navigation to source entities, and real-time event dispatching.
- **Strict Decoupling & Modular Isolation:** Individual business modules (Purchase, HR, Dispatch, Vendor) must never build their own redundant approval queues or notification drawers. They interact with Approvals & Notifications exclusively through standard, loosely-coupled integration bridges and domain contracts.
- **Zero Third-Party Bloat:** Strictly avoid proprietary cloud or push notification SDKs (no Firebase Cloud Messaging, OneSignal, Pusher, Twilio, or SMTP servers) during frontend/mock development. The system runs on a pure Flutter in-memory reactive stream/event bus, seamlessly swappable to instructor REST/SSE backend endpoints upon backend integration.
- **Strict Dual-Mode Architecture:** Provide a 100% deterministic, seed-populated mock data layer for development and automated testing, paired with a production-grade Dio REST backend adapter governed by an explicit factory with zero silent fallback on errors.

---

## 2. Context Files Audit & Ground Truth Invariants

This master document synthesizes and enforces every directive, architectural standard, and business rule established across the repository's context documents:

### 2.1 Synthesis of Project Context Documents

| Context Source File | Authoritative Requirements & Constraints Applicable to Approvals & Notifications |
| :--- | :--- |
| **`context/Enterprise_CRM_Team_Collaboration_Handoff.md`** | **Section 7 & 16 (Module Ownership & Boundary):** Approvals & Notifications belongs strictly to Vikash Chaurasiya. It must be built as a reusable capability without modifying Purchase, Dispatch, HR, Inventory, or Lead internals during initial development.<br>**Section 8 & 10 (Shared Platform & Account Model):** Shared platform (Auth, Users & Access, Admin/User Dashboard, `AccessPolicy`, `CrmModule`) is lead-owned by Vachaspati. Exactly two top-level account types exist: `Admin` and `User`. No custom "Approver" account type may be created; approval rights are granted via permissions and module assignment.<br>**Section 17 & 18 (Feature Folders & Shared Files):** Code must reside under `lib/features/approvals/` and `lib/features/notifications/` (or a unified `lib/features/approvals_notifications/`). Shared file edits (`crm_app.dart`, `crm_permissions.dart`, `mock_permission_catalog.dart`) must be minimal and strictly backward-compatible.<br>**Section 19–23 (Git Workflow):** Must branch from `frontend-development` via `feature/approvals-notifications`. Requires 100% passing tests, 0 analyzer issues, clean `flutter build web`, and clean git diff before PR. |
| **`context/CRM_PRD.md`** | **Section 2 & 6 (Scope):** "Pending approvals, comments, approval history, PI/PO approval, and departmental notifications." Requires Excel/CSV export of approval history and search/filters/pagination.<br>**Section 4 (Access):** Approver/Manager access is controlled via assigned module permissions.<br>**Section 7 & 8 (Acceptance Criteria):** Comprehensive handling of loading, empty, success, error, forbidden, and unassigned states. Responsive on Android and Web. |
| **`context/CRM_TRD.md`** | **Section 1 (Architecture):** Flutter UI $\rightarrow$ BLoC/Cubit $\rightarrow$ Repository $\rightarrow$ Dio Data Source $\rightarrow$ Instructor REST API.<br>**Section 2 (State Management):** Use Cubit for straightforward list/detail flows; states must explicitly represent `initial`, `loading`, `success`, `empty`, `validationFailure`, `forbidden`, and `error`.<br>**Section 4 (Responsive Strategy):** Single codebase for phone (cards, compact lists, bottom sheets) and desktop Web (tables, side panels, split details, multi-select action toolbars).<br>**Section 7 (Testing & Security):** Test models, Cubits, repositories with mock data, forms, responsive viewports, and permission gates. |
| **`context/CRM_UI_UX.md`** | **Section 4 (Screen Inventory):** `Approval Inbox`, `Approval Details`, `Approval History`, `Notification Centre`.<br>**Section 6 (Components):** "Approval inbox with pending/approved/rejected tabs, detail with comments/attachments, history, unread notifications, timestamps, and deep links when supported." Confirmation dialogs before destructive/critical actions. |
| **`context/CRM_Backend_Schema.md`** | **Section 6.8 (Backend Entities):** Defines `approval_requests` (id, request_type, reference_type, reference_id, requested_by, current_approver_id, status, comments, decided_by, decided_at, audit fields), `approval_steps` (multi-step routing), `notifications` (recipient_user_id, notification_type, title, message, reference_type, reference_id, is_read, read_at, created_at), and `announcements`.<br>**Section 10 (API Endpoints):** `GET /approvals`, `POST /approvals/{id}/approve`, `POST /approvals/{id}/reject`, `GET /notifications`, `PATCH /notifications/{id}/read`. |
| **`context/MASTER_DEVELOPMENT_RULES.md`** | **Rule 1 (Golden Rule):** Understand existing architecture before coding; make the smallest complete, correct, secure, maintainable, tested change.<br>**Rule 5 (Respect Architecture):** Strictly preserve naming conventions, dependency injection via `CrmApp`, constructor injection, defensive immutability, request-version guards, and `isClosed` checks.<br>**Rule 12 (Defensive Coding):** Unmodifiable lists and sets in domain entities, non-nullable safe defaults, robust type safety, and zero speculative field additions. |
| **`context/AI_BRAIN.md` & `SESSION_MEMORY.md`** | Repository precedent established by completed phases (Lead L0–L7, AUTH-1/2, HR-1–HR-10, Vendor VM-0–VM-10). Maintain identical rigor: 100% test pass rate, zero analyzer warnings, responsive viewport tests (320x568, 360x640, 768x1024, 1200x800), and comprehensive documentation at every checkpoint. |

### 2.2 Requirements Classification Matrix

To adhere to `MASTER_DEVELOPMENT_RULES.md`, requirements are strictly categorized into **CONFIRMED**, **UNCONFIRMED / PROPOSED**, and **DEFERRED**:

| Item / Capability | Classification | Scope Details & Engineering Treatment |
| :--- | :--- | :--- |
| **Module Registration (`CrmModule.approvalsNotifications`)** | **CONFIRMED** | Already registered in `lib/features/auth/domain/entities/crm_module.dart` with presentation titles and icons in `crm_module_presentation.dart`. |
| **Top-Level Account Model (Admin vs User)** | **CONFIRMED** | Only `AccountType.admin` and `AccountType.user`. No synthetic `AccountType.approver` or `AccountType.manager`. |
| **Approval Request Entity (`ApprovalRequest`)** | **CONFIRMED** | Stable UUID, request number, target module, entity reference, requester, status, priority, timestamps, decision audit. |
| **Approval Decision States** | **CONFIRMED** | `pending`, `approved`, `rejected`. Extended with `revisionRequested` and `cancelled` for comprehensive workflow handling. |
| **Mandatory Rejection Comments** | **CONFIRMED** | Approving may have optional remarks; rejecting or requesting revisions strictly requires a non-empty comment. |
| **Multi-Level Approval Steps (`ApprovalStep`)** | **CONFIRMED** | Schema-backed support for sequential approval levels (e.g. Step 1: Department Manager $\rightarrow$ Step 2: Finance Director). |
| **In-App Notification Entity (`CrmNotification`)** | **CONFIRMED** | Unread state, recipient isolation, title, body, priority, category, timestamp, source reference. |
| **Global Notification Bell & Badge** | **CONFIRMED** | Header placement in `CrmApp`, live reactive badge count, dropdown popover with quick actions. |
| **Full Notification Center Screen** | **CONFIRMED** | Paginated/scrollable history, category tabs, mark-as-read, clear-all, deep-link navigation. |
| **Deep-Link Navigation** | **CONFIRMED** | Clicking an approval notification or request navigates directly to the associated entity detail view. |
| **Approval History & CSV Export** | **CONFIRMED** | RFC-4180 compliant CSV export of approval logs with permission guard (`approvals.export`). |
| **External Push Notifications (FCM / APNS)** | **DEFERRED** | Excluded from current scope. Pending instructor backend push gateway. |
| **External Email / SMS Dispatch** | **DEFERRED** | Excluded from frontend CRM scope. Out-of-band email notifications will be managed by the backend server. |
| **Direct Mutations on Other Modules** | **DEFERRED** | Approvals cannot directly rewrite Purchase, Dispatch, or HR internal tables. Connections occur via standardized event hooks and integration adapters. |

---

## 3. Comprehensive Domain Model & Data Contracts

The domain layer is completely decoupled from Flutter UI, external packages, and network libraries. All entities are immutable, provide `copyWith` methods, value equality (`props`), and defensive serialization.

### 3.1 Domain Enums & Value Objects

```dart
/// Represents the overall lifecycle status of an approval request.
enum ApprovalStatus {
  pending,
  approved,
  rejected,
  revisionRequested,
  cancelled;

  bool get isTerminal => this == approved || this == rejected || this == cancelled;
  bool get isActionable => this == pending || this == revisionRequested;
}

/// Operational urgency of an approval request.
enum ApprovalPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName => switch (this) {
    low => 'Low',
    normal => 'Normal',
    high => 'High',
    urgent => 'Urgent',
  };
}

/// Actions recorded in the append-only approval audit trail.
enum ApprovalActionType {
  submitted,
  approved,
  rejected,
  revisionRequested,
  reassigned,
  cancelled,
  commentAdded;
}

/// Individual step status within a multi-tier approval workflow.
enum ApprovalStepStatus {
  pending,
  approved,
  rejected,
  skipped;
}

/// Functional category of system notifications.
enum NotificationCategory {
  approvalRequest,
  approvalDecision,
  systemAlert,
  announcement,
  reminder;
}

/// Visual urgency and semantic styling for notifications.
enum NotificationPriority {
  info,
  success,
  warning,
  critical;
}

/// In-app notification delivery channel.
enum NotificationChannel {
  inApp;
}
```

### 3.2 Core Domain Entities

#### 1. `ApprovalRequest`
The authoritative entity representing an approval transaction across any CRM module.

```dart
class ApprovalRequest {
  final String id; // e.g. "appr-001" (stable opaque UUID)
  final String requestNumber; // e.g. "REQ-2026-0001" (human-readable tracking code)
  final CrmModule module; // Originating module (purchase, hrPayroll, etc.)
  final String entityType; // e.g. "purchase_order", "leave_request", "vendor_kyc"
  final String entityId; // e.g. "po-9821", "emp-104"
  final String entityTitle; // e.g. "Purchase Order #PO-9821 (ACME Industrial)"
  final String requesterId; // ID of user submitting request
  final String requesterName; // Display name of requester
  final String? departmentId; // Department identifier
  final String? departmentName; // Department display name
  final ApprovalStatus status; // Current status
  final ApprovalPriority priority; // Urgency level
  final double? amount; // Optional monetary sum (for financial approvals)
  final String? currencyCode; // e.g. "USD", "INR"
  final DateTime submittedAt; // UTC timestamp of submission
  final DateTime? decidedAt; // UTC timestamp of final decision
  final String? decidedByUserId; // User ID of final decision maker
  final String? decidedByUserName; // Display name of final decision maker
  final String? decisionNotes; // Reason for rejection, revision remarks, or approval note
  final int currentStepIndex; // 0-based index of active approval step
  final List<ApprovalStep> steps; // Multi-level approval steps
  final List<ApprovalActivity> auditTrail; // Append-only immutable activity log
  final Map<String, dynamic> metadata; // Extra contextual attributes

  const ApprovalRequest({
    required this.id,
    required this.requestNumber,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.requesterId,
    required this.requesterName,
    this.departmentId,
    this.departmentName,
    required this.status,
    required this.priority,
    this.amount,
    this.currencyCode,
    required this.submittedAt,
    this.decidedAt,
    this.decidedByUserId,
    this.decidedByUserName,
    this.decisionNotes,
    this.currentStepIndex = 0,
    this.steps = const [],
    this.auditTrail = const [],
    this.metadata = const {},
  });
}
```

#### 2. `ApprovalStep`
Defines an individual stage in a multi-tier review process.

```dart
class ApprovalStep {
  final String id; // Step UUID
  final int stepOrder; // 1, 2, 3...
  final String title; // e.g. "Department Head Review", "Finance Sign-off"
  final String? assignedRole; // e.g. "Manager", "Finance Approver"
  final String? assignedUserId; // Specific user assigned to this step
  final String? assignedUserName; // Display name of assigned user
  final ApprovalStepStatus status; // Current status of this step
  final DateTime? decidedAt; // UTC timestamp of step completion
  final String? decidedByUserId; // User who completed step
  final String? comments; // Notes added during step execution

  const ApprovalStep({
    required this.id,
    required this.stepOrder,
    required this.title,
    this.assignedRole,
    this.assignedUserId,
    this.assignedUserName,
    required this.status,
    this.decidedAt,
    this.decidedByUserId,
    this.comments,
  });
}
```

#### 3. `ApprovalActivity`
Append-only immutable record of every mutation, transition, or comment.

```dart
class ApprovalActivity {
  final String id; // Activity UUID
  final String approvalRequestId; // Target request
  final String actorUserId; // User who performed the action
  final String actorUserName; // Name of actor
  final ApprovalActionType action; // Action performed
  final String? comment; // User remark or system note
  final DateTime timestamp; // UTC timestamp
  final Map<String, dynamic> snapshot; // Contextual metadata

  const ApprovalActivity({
    required this.id,
    required this.approvalRequestId,
    required this.actorUserId,
    required this.actorUserName,
    required this.action,
    this.comment,
    required this.timestamp,
    this.snapshot = const {},
  });
}
```

#### 4. `CrmNotification`
Authoritative in-app notification delivered to a specific CRM user.

```dart
class CrmNotification {
  final String id; // Notification UUID (e.g. "notif-001")
  final String recipientUserId; // Recipient user identifier
  final String title; // Short summary headline
  final String body; // Detailed message text
  final NotificationCategory category; // Category
  final NotificationPriority priority; // Urgency level
  final CrmModule? referenceModule; // Originating module
  final String? referenceEntityType; // e.g. "approval_request", "purchase_order"
  final String? referenceEntityId; // Target entity ID for navigation
  final bool isRead; // Read/Unread flag
  final DateTime? readAt; // UTC timestamp when read
  final DateTime createdAt; // UTC timestamp of creation
  final Map<String, dynamic> payload; // Extra routing/display data

  const CrmNotification({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    this.referenceModule,
    this.referenceEntityType,
    this.referenceEntityId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.payload = const {},
  });
}
```

---

## 4. Permissions, Security & Access Control Architecture

The Approvals & Notifications module adheres strictly to the existing shared authentication and RBAC infrastructure defined in `lib/features/auth/` and `lib/features/user_management/`.

### 4.1 Permission Identifiers Contract

The following canonical permission strings are designated for `CrmPermissions`:

```dart
abstract final class CrmPermissions {
  // Existing permissions preserved...

  // Approvals & Notifications Permissions
  static const String approvalsView = 'approvals.view';
  static const String approvalsAction = 'approvals.action';
  static const String approvalsSubmit = 'approvals.submit';
  static const String approvalsExport = 'approvals.export';
  static const String notificationsView = 'notifications.view';
  static const String notificationsManage = 'notifications.manage';
}
```

### 4.2 Presentation & Catalog Mappings

1. **`CrmPermissionPresentation`:**
   - `'approvals.view'` $\rightarrow$ `"View approval requests"`
   - `'approvals.action'` $\rightarrow$ `"Approve or reject requests"`
   - `'approvals.submit'` $\rightarrow$ `"Submit approval requests"`
   - `'approvals.export'` $\rightarrow$ `"Export approval history"`
   - `'notifications.view'` $\rightarrow$ `"View notifications"`
   - `'notifications.manage'` $\rightarrow$ `"Manage and clear notifications"`
2. **`MockPermissionCatalog`:**
   All 6 permissions registered with canonical mapping to `CrmModule.approvalsNotifications`.

### 4.3 `ApprovalsAccessPolicy` Implementation Rules

A centralized, pure Dart domain policy `ApprovalsAccessPolicy` enforces all access rules before any Cubit creation or repository query:

```dart
abstract final class ApprovalsAccessPolicy {
  /// Whether the user can view the Approvals & Notifications module.
  static bool canViewModule(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
           (user.hasPermission(CrmPermissions.approvalsView) ||
            user.hasPermission(CrmPermissions.notificationsView));
  }

  /// Whether the user can execute approval decisions (Approve, Reject, Revision).
  static bool canPerformDecision(CurrentUser user, ApprovalRequest request) {
    if (user.isAdmin) return true;
    if (!user.hasModule(CrmModule.approvalsNotifications)) return false;
    if (!user.hasPermission(CrmPermissions.approvalsAction)) return false;

    // Standard Users cannot approve their own requests (Separation of Concerns)
    if (request.requesterId == user.id) return false;

    // Check step assignment if step-specific
    final currentStep = request.currentStepIndex < request.steps.length
        ? request.steps[request.currentStepIndex]
        : null;
    if (currentStep != null && currentStep.assignedUserId != null) {
      return currentStep.assignedUserId == user.id;
    }

    return true;
  }

  /// Whether the user can cancel a pending approval request.
  static bool canCancelRequest(CurrentUser user, ApprovalRequest request) {
    if (user.isAdmin) return true;
    // Only the original requester can cancel their pending request
    return request.requesterId == user.id && request.status.isActionable;
  }

  /// Whether the user can export approval reports.
  static bool canExport(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
           user.hasPermission(CrmPermissions.approvalsExport);
  }
}
```

### 4.4 Data Isolation Invariants
- **User A / User B Notification Isolation:** The repository contract strictly queries notifications by `recipientUserId`. A user can never read, clear, or receive notifications intended for another user ID.
- **Session Reset on Logout:** All active streams, cached notification counts, and in-memory notification subscriptions are systematically cancelled and disposed upon user logout.

---

## 5. State Management & BLoC/Cubit Architecture

State management is strictly implemented using `flutter_bloc` (Cubit pattern) following established repository patterns:
- Unidirectional data flow: UI $\rightarrow$ Cubit $\rightarrow$ Repository $\rightarrow$ Data Store.
- Explicit lifecycle states with immutable value equality.
- Request-version sequence guards (`_loadSequence`) to discard out-of-order asynchronous responses.
- Active `isClosed` checks prior to emitting states to eliminate memory leaks and test errors.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CUBIT ARCHITECTURE MAP                          │
├────────────────────────┬───────────────────────────────────────────────┤
│ Cubit Class            │ Responsibilities & Scope                      │
├────────────────────────┼───────────────────────────────────────────────┤
│ ApprovalInboxCubit     │ Manages multi-tab inbox (Pending, Approved,   │
│                        │ Rejected, My Requests). Handles search,       │
│                        │ filter synchronization, and pagination.       │
├────────────────────────┼───────────────────────────────────────────────┤
│ ApprovalDetailCubit    │ Fetches single request by ID with full audit  │
│                        │ timeline and multi-step progress.             │
├────────────────────────┼───────────────────────────────────────────────┤
│ ApprovalActionCubit    │ Executes Approve, Reject, Revision, or Cancel │
│                        │ mutations. Enforces non-empty comments on     │
│                        │ rejection. Guards against duplicate submits.  │
├────────────────────────┼───────────────────────────────────────────────┤
│ NotificationCubit      │ Subscribes to reactive notification stream,   │
│                        │ calculates real-time unread count, marks read,│
│                        │ and clears read notifications.                │
├────────────────────────┼───────────────────────────────────────────────┤
│ NotificationToastCubit │ Emits transient toast alerts when new high-   │
│                        │ priority notifications arrive at runtime.     │
└────────────────────────┴───────────────────────────────────────────────┘
```

### 5.1 State Machine Lifecycles

#### `ApprovalInboxState`
- `ApprovalInboxInitial`
- `ApprovalInboxLoading`
- `ApprovalInboxLoaded` (contains `items`, `tab`, `searchQuery`, `moduleFilter`, `priorityFilter`, `filteredItems`, `countsByTab`)
- `ApprovalInboxFailure` (contains human-readable error message and retry action)

#### `ApprovalActionState`
- `ApprovalActionInitial`
- `ApprovalActionSubmitting` (disables UI buttons, blocks dialog dismissal via `PopScope`)
- `ApprovalActionSuccess` (returns updated `ApprovalRequest`, triggers caller refresh)
- `ApprovalActionFailure` (preserves input fields, displays user-friendly error)

#### `NotificationState`
- `NotificationInitial`
- `NotificationLoading`
- `NotificationLoaded` (contains `notifications`, `unreadCount`, `selectedCategory`, `filteredNotifications`)
- `NotificationFailure`

---

## 6. UI / UX & Responsive Design System

The presentation layer strictly adheres to `CRM_UI_UX.md`, using Flutter Material 3 tokens, accessibility semantics, high-contrast readability, and responsive multi-platform adaptations.

### 6.1 Viewport Breakpoints & Responsive Behavior

| Viewport Category | Width Dimension | Screen Layout Adaptation |
| :--- | :--- | :--- |
| **Mobile Compact** | `320px – 359px` | Single-column vertically stacked cards. Compact status chips. Touch targets $\ge 48\text{px}$. Bottom-sheet action dialogs with full-width buttons. Horizontal scrolling metrics row (preventing `RenderFlex` overflow). |
| **Mobile Standard** | `360px – 599px` | Card list with expandable details. Floating action button for quick refresh. Modal bottom sheets for decision comments. |
| **Tablet** | `600px – 999px` | 2-column dashboard layout. Medium-density data table with horizontal scrolling. Side-sheet detail drawer. |
| **Desktop Web** | `1000px – 1920px` | Full multi-column `DataTable` with sortable headers, sticky filter bar, split-view master-detail panes, top bar notification popover bell. |

### 6.2 Screen & Widget Inventory

```
lib/features/approvals/presentation/
├── screens/
│   ├── approvals_workspace_screen.dart       // Main module entrypoint with responsive layout
│   ├── approval_inbox_screen.dart            // Tabbed inbox (Pending, Approved, Rejected, Mine)
│   ├── approval_detail_screen.dart           // Full request inspection, steps & timeline
│   └── approval_history_export_screen.dart   // Filtered CSV export configuration
├── widgets/
│   ├── approval_card.dart                    // Mobile card component with priority & status
│   ├── approval_data_table.dart              // Desktop multi-column table with action pills
│   ├── approval_step_stepper.dart            // Visual multi-tier progress indicator
│   ├── approval_activity_timeline.dart       // Chronological audit log with user avatars
│   ├── approval_action_dialog.dart           // Modal confirmation with mandatory reason field
│   └── approval_filter_bar.dart              // Unified search, module, & priority filter bar
│
lib/features/notifications/presentation/
├── screens/
│   └── notification_center_screen.dart       // Full notification hub with category tabs
├── widgets/
│   ├── notification_bell_button.dart         // Header icon with reactive unread badge
│   ├── notification_dropdown_popover.dart    // Quick popup showing latest alerts & actions
│   ├── notification_list_item.dart           // Visual tile with category icon & time-ago
│   └── notification_toast_banner.dart        // Floating animated in-app snackbar/banner
```

### 6.3 Detailed Component Specifications

#### 1. `ApprovalInboxScreen`
- **Tab Hierarchy:**
  1. *Pending Review* (Badge counter with actionable requests).
  2. *Approved* (Historical approved items).
  3. *Rejected* (Historical rejected items with visible reason chips).
  4. *My Submissions* (Items submitted by current user across all statuses).
- **Search & Filter Controls:**
  - Real-time case-insensitive search matching `requestNumber`, `entityTitle`, and `requesterName`.
  - Module selector dropdown (`All Modules`, `Purchase`, `HR`, `Vendor`, `Inventory`, `Dispatch`).
  - Priority filter chips (`All`, `Urgent`, `High`, `Normal`, `Low`).
  - Date-range picker for historical queries.
- **Visual Feedback:**
  - Distinct colored badges: `Pending` (amber/orange), `Approved` (emerald green), `Rejected` (rose red), `Revision` (purple), `Cancelled` (slate gray).

#### 2. `ApprovalDetailScreen`
- **Top Summary Card:** Request tracking code, title, module badge, priority, submission date, and monetary amount (formatted with currency if applicable).
- **Multi-Step Stepper (`ApprovalStepStepper`):** Displays each required review step in order, showing step name, reviewer role/name, step status, decision timestamp, and comments.
- **Reference Payload View:** Read-only snapshot of originating entity (e.g. Purchase Order line items, Leave dates & reason, Vendor KYC documents). Includes a direct "View Source Entity" button.
- **Decision Action Bar:**
  - *Approve Button (Green):* Prompts confirmation dialog; optional note.
  - *Reject Button (Red):* Opens dialog; **strictly requires non-empty rejection reason**.
  - *Request Revision Button (Amber):* Prompts for requested modifications.
  - *Cancel Button (Gray):* Visible only if requester is current user and status is actionable.

#### 3. `NotificationBellButton` & `NotificationDropdownPopover`
- Positioned in the global authenticated header (`CrmApp`) for both Admin and Standard Users.
- Displays a prominent red numeric badge when `unreadCount > 0`.
- Clicking opens a desktop overlay popover or mobile bottom sheet displaying the 5 most recent notifications, relative timestamps (`"2m ago"`, `"1h ago"`), a "Mark all as read" button, and a link to the complete `NotificationCenterScreen`.
- Clicking any notification marks it as read and invokes the `DeepLinkNavigationResolver` to open the referenced entity.

---

## 7. Cross-Module Reusable Integration Bridge

To ensure Approvals & Notifications functions as a true shared enterprise capability without creating cyclical dependencies, other modules communicate via the **`ApprovalBridge`** and **`NotificationDispatcher`** abstractions.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   CROSS-MODULE INTERACTION FLOW                        │
└────────────────────────────────────────────────────────────────────────┘

     [ Purchase Module ]     [ HR Module ]     [ Vendor Module ]
             │                     │                  │
             ▼                     ▼                  ▼
   ┌─────────────────────────────────────────────────────────┐
   │                    ApprovalBridge                       │
   │  (Standardized Request Submission & Status Webhook API) │
   └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
   ┌─────────────────────────────────────────────────────────┐
   │               ApprovalRepository & Engine               │
   │      - Multi-level step routing                         │
   │      - Decision persistence                             │
   │      - Immutable audit trail                            │
   └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
   ┌─────────────────────────────────────────────────────────┐
   │               NotificationDispatcher                    │
   │  (Generates in-app alerts for approvers and requesters) │
   └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
   ┌─────────────────────────────────────────────────────────┐
   │                  NotificationStore                      │
   │   (Reactive broadcast stream to User Header Bell & UI)  │
   └─────────────────────────────────────────────────────────┘
```

### 7.1 `ApprovalBridge` Contract

```dart
abstract interface class ApprovalBridge {
  /// Submits an entity for approval from any calling CRM module.
  Future<ApprovalRequest> submitForApproval({
    required CrmModule module,
    required String entityType,
    required String entityId,
    required String entityTitle,
    required CurrentUser requester,
    ApprovalPriority priority = ApprovalPriority.normal,
    double? amount,
    String? currencyCode,
    List<ApprovalStepInput>? customSteps,
    Map<String, dynamic> metadata = const {},
  });

  /// Queries the active approval status for a specific entity.
  Future<ApprovalRequest?> getApprovalForEntity({
    required String entityType,
    required String entityId,
  });
}
```

### 7.2 Integration Mapping by Business Module

1. **Purchase Module Integration:**
   - *Workflow:* Material requirement $\rightarrow$ RFQ $\rightarrow$ Quotation $\rightarrow$ Purchase Order (PO).
   - *Approval Trigger:* PO creation above threshold or Proforma Invoice verification.
   - *Payload:* Total PO amount, vendor reference, line item summary.
2. **HR / Payroll Module Integration:**
   - *Workflow:* Attendance corrections, Employee leave requests, Payroll run sign-off.
   - *Approval Trigger:* Employee requests attendance adjustment or HR Manager submits payroll period for lock.
   - *Payload:* Employee code, period start/end, total calculated net pay.
3. **Vendor Management Module Integration:**
   - *Workflow:* Vendor registration $\rightarrow$ KYC & Banking verification.
   - *Approval Trigger:* Vendor KYC documents uploaded, requiring Admin/Compliance review.
   - *Payload:* Legal vendor name, tax ID, bank account verification status.
4. **Inventory Module Integration:**
   - *Workflow:* Stock movement $\rightarrow$ Adjustment.
   - *Approval Trigger:* Stock decrease adjustment exceeding policy threshold.
   - *Payload:* Item SKU, quantity delta, reason.

---

## 8. Data Layer & Repository Architecture

Following repository conventions, all persistent interactions flow through abstract interfaces.

### 8.1 Repository Interfaces

```dart
abstract interface class ApprovalRepository {
  Future<List<ApprovalRequest>> getApprovals({
    ApprovalStatus? status,
    CrmModule? module,
    ApprovalPriority? priority,
    String? requesterId,
    String? search,
  });

  Future<ApprovalRequest?> getApprovalById(String id);

  Future<ApprovalRequest> submitRequest(CreateApprovalRequestInput input);

  Future<ApprovalRequest> approveRequest({
    required String requestId,
    required CurrentUser actor,
    String? comment,
  });

  Future<ApprovalRequest> rejectRequest({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
  });

  Future<ApprovalRequest> requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
  });

  Future<ApprovalRequest> cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  });

  Future<List<ApprovalActivity>> getAuditTrail(String requestId);
}

abstract interface class NotificationRepository {
  Stream<List<CrmNotification>> watchNotifications(String recipientUserId);

  Future<List<CrmNotification>> getNotifications({
    required String recipientUserId,
    bool? unreadOnly,
    NotificationCategory? category,
  });

  Future<int> getUnreadCount(String recipientUserId);

  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  });

  Future<void> markAllAsRead(String userId);

  Future<void> clearNotification({
    required String notificationId,
    required String userId,
  });

  Future<CrmNotification> dispatchNotification(CreateNotificationInput input);
}
```

### 8.2 Deterministic Mock In-Memory Store

`MockApprovalStore` and `MockNotificationStore` provide app-instance-scoped, deterministic in-memory storage seeded with realistic multi-department records:
- **Seed Approval Requests:**
  1. `appr-001` (Purchase): PO-9821 for ACME Steel ($14,500.00, Urgent, Pending Step 2 Finance Review).
  2. `appr-002` (HR): Attendance correction for John Doe (Normal, Pending Manager Review).
  3. `appr-003` (Vendor): KYC verification for Global Logistics Ltd (High, Pending Compliance).
  4. `appr-004` (Inventory): High-value stock adjustment for Titanium Rods (-25 units, Approved).
  5. `appr-005` (HR): Payroll Run for September 2026 ($84,200.00, Approved).
  6. `appr-006` (Purchase): PO-9825 for Office Supplies ($450.00, Rejected: Budget exceeded).
- **Seed Notifications:**
  - Multi-priority notifications seeded for `admin` (`usr_admin`) and standard users (`usr_standard`).
  - Unread count accurately initialized and broadcast via `StreamController<List<CrmNotification>>.broadcast()`.

---

## 9. Backend Integration & Controlled Cutover Strategy

When the instructor's backend contract is delivered through GitHub, the module switches from mock repositories to live REST adapters using the established dual-mode factory pattern.

### 9.1 Backend REST API Contract Alignment

| HTTP Method | API Endpoint | Request Payload | Response Model | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/approvals` | Query params: `status`, `module`, `priority`, `page`, `limit` | `{ "items": [...], "total": 42 }` | Paginated approval list. |
| `GET` | `/api/v1/approvals/{id}` | None | `ApprovalRequestDto` | Detailed request with steps and audit trail. |
| `POST` | `/api/v1/approvals` | `CreateApprovalRequestDto` | `ApprovalRequestDto` | Submits a new workflow request. |
| `POST` | `/api/v1/approvals/{id}/approve` | `{ "comment": "Approved" }` | `ApprovalRequestDto` | Approves active step. |
| `POST` | `/api/v1/approvals/{id}/reject` | `{ "rejection_reason": "Price too high" }` | `ApprovalRequestDto` | Rejects request with mandatory reason. |
| `POST` | `/api/v1/approvals/{id}/revision`| `{ "revision_notes": "Attach invoice" }` | `ApprovalRequestDto` | Returns request for revision. |
| `POST` | `/api/v1/approvals/{id}/cancel` | `{ "reason": "No longer needed" }` | `ApprovalRequestDto` | Cancels pending request. |
| `GET` | `/api/v1/notifications` | Query params: `unread_only`, `category` | `{ "items": [...], "unread_count": 3 }` | Recipient-scoped notification list. |
| `PATCH` | `/api/v1/notifications/{id}/read`| None | `NotificationDto` | Marks single notification as read. |
| `POST` | `/api/v1/notifications/read-all` | None | `{ "success": true }` | Marks all recipient notifications read. |

### 9.2 Controlled Cutover Factory

`ApprovalRepositoryFactory` and `NotificationRepositoryFactory` evaluate `AppConfig.backendMode`:
- If `BackendMode.backend`: Instantiates `BackendApprovalRepository(apiClient)`.
- If `BackendMode.mock`: Instantiates `MockApprovalRepository(mockStore)`.
- **Strict Invariant:** If `BackendMode.backend` is active and an HTTP call fails (e.g. 500 or timeout), a typed `ApprovalsNetworkException` is thrown. Under no circumstances will the system silently fall back to mock data.

---

## 10. Phased Implementation Roadmap (AN-0 through AN-10)

The implementation of Approvals & Notifications is organized into eleven structured, verifiable, and testable sub-phases:

```
┌────────────────────────────────────────────────────────────────────────┐
│               APPROVALS & NOTIFICATIONS ROADMAP PHASES                 │
├─────────┬──────────────────────────────────────────────────────────────┤
│ Phase   │ Description & Key Milestone                                  │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-0    │ Requirements Audit, Invariants & Architectural Business Freeze│
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-1    │ Core Domain Models, Enums & Value Objects Foundation         │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-2    │ Data Layer, Mock Stores & Deterministic Seed Engine          │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-3    │ Approvals State Management (BLoC / Cubits)                   │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-4    │ Approvals UI — Inbox, Stepper, Action Dialogs & Responsive   │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-5    │ Notifications Domain, Real-Time Dispatcher & State Management│
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-6    │ Notifications UI — Header Bell, Popover & Notification Center│
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-7    │ Cross-Module Reusable Integration Bridge (HR, Purchase, etc.)│
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-8    │ Search, Multi-Filter, Audit Trail & CSV Export Engine        │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-9    │ Backend DTOs, API Adapters & Controlled Dual-Mode Cutover    │
├─────────┼──────────────────────────────────────────────────────────────┤
│ AN-10   │ Final Security Audit, Session Isolation, Platform UAT & Freeze│
└─────────┴──────────────────────────────────────────────────────────────┘
```

---

### Detailed Phase Specifications

#### Phase AN-0: Requirements Audit, Invariants & Architectural Business Freeze
- **Objective:** Establish the formal engineering contract, register permission strings in `CrmPermissions`, add labels to `CrmPermissionPresentation`, map permissions in `MockPermissionCatalog`, implement `ApprovalsAccessPolicy`, and record the formal baseline test count.
- **Key Deliverables:**
  - `APPROVALS_AND_NOTIFICATIONS_REQUIREMENTS.md` (Business freeze report).
  - Updates to `lib/features/auth/domain/policies/crm_permissions.dart`.
  - Updates to `lib/features/auth/presentation/mappers/crm_permission_presentation.dart`.
  - Updates to `lib/features/user_management/data/mock/mock_permission_catalog.dart`.
  - `lib/features/approvals/domain/policies/approvals_access_policy.dart`.
  - Unit tests: `test/features/approvals/domain/policies/approvals_access_policy_test.dart`.
- **Exit Criteria:** All permission tests pass, analyzer clean, baseline test count recorded.

#### Phase AN-1: Core Domain Models, Enums & Value Objects Foundation
- **Objective:** Build immutable domain entities representing approval workflows and system notifications.
- **Key Deliverables:**
  - `lib/features/approvals/domain/entities/approval_request.dart`
  - `lib/features/approvals/domain/entities/approval_step.dart`
  - `lib/features/approvals/domain/entities/approval_activity.dart`
  - `lib/features/approvals/domain/entities/approval_status.dart`
  - `lib/features/approvals/domain/entities/approval_priority.dart`
  - `lib/features/notifications/domain/entities/crm_notification.dart`
  - `lib/features/notifications/domain/entities/notification_category.dart`
  - `lib/features/notifications/domain/entities/notification_priority.dart`
  - Comprehensive unit test suites verifying immutability, `copyWith`, and value equality.
- **Exit Criteria:** 100% domain entity unit test coverage, zero Flutter framework dependencies in domain entities.

#### Phase AN-2: Data Layer, Mock Stores & Deterministic Seed Engine
- **Objective:** Implement repository interfaces and thread-safe in-memory mock stores seeded with realistic multi-module approval and notification data.
- **Key Deliverables:**
  - `lib/features/approvals/domain/repositories/approval_repository.dart`
  - `lib/features/approvals/data/mock/mock_approval_store.dart`
  - `lib/features/approvals/data/repositories/mock_approval_repository.dart`
  - `lib/features/notifications/domain/repositories/notification_repository.dart`
  - `lib/features/notifications/data/mock/mock_notification_store.dart`
  - `lib/features/notifications/data/repositories/mock_notification_repository.dart`
  - Target tests: Store seeding, query filtering, state mutations, and stream emission.
- **Exit Criteria:** Repository contracts verified through comprehensive mock tests; deterministic queries return exact expected seed data.

#### Phase AN-3: Approvals State Management (BLoC / Cubits)
- **Objective:** Implement Cubits governing the approval inbox lifecycle, individual request detail views, and decision mutations with sequence guards.
- **Key Deliverables:**
  - `lib/features/approvals/presentation/cubit/approval_inbox_cubit.dart` & `_state.dart`
  - `lib/features/approvals/presentation/cubit/approval_detail_cubit.dart` & `_state.dart`
  - `lib/features/approvals/presentation/cubit/approval_action_cubit.dart` & `_state.dart`
  - Bloc tests for every transition: loading, loaded, tabs filtering, search, retry, approve success, reject failure on empty comment, race condition suppression.
- **Exit Criteria:** All Cubit tests pass, 0 state mutation leaks, sequence guards verified.

#### Phase AN-4: Approvals UI — Inbox, Stepper, Action Dialogs & Responsive Layouts
- **Objective:** Create responsive UI screens for browsing approvals, inspecting multi-step workflows, and executing decisions.
- **Key Deliverables:**
  - `lib/features/approvals/presentation/screens/approvals_workspace_screen.dart`
  - `lib/features/approvals/presentation/screens/approval_inbox_screen.dart`
  - `lib/features/approvals/presentation/screens/approval_detail_screen.dart`
  - `lib/features/approvals/presentation/widgets/approval_data_table.dart`
  - `lib/features/approvals/presentation/widgets/approval_card.dart`
  - `lib/features/approvals/presentation/widgets/approval_step_stepper.dart`
  - `lib/features/approvals/presentation/widgets/approval_action_dialog.dart`
  - Widget tests across 320x568, 360x640, 768x1024, and 1200x800 viewports.
- **Exit Criteria:** Zero `RenderFlex` overflows on compact viewports; touch targets $\ge 48\text{px}$; mandatory comment enforced in UI dialog.

#### Phase AN-5: Notifications Domain, Real-Time Dispatcher & State Management
- **Objective:** Implement the real-time notification engine, reactive subscription streams, and unread counter management.
- **Key Deliverables:**
  - `lib/features/notifications/domain/services/notification_dispatcher.dart`
  - `lib/features/notifications/presentation/cubit/notification_cubit.dart` & `_state.dart`
  - `lib/features/notifications/presentation/cubit/notification_toast_cubit.dart` & `_state.dart`
  - Lifecycle hook connecting approval decisions to automatic notification dispatches.
  - Unit and Cubit tests verifying stream updates, unread count accuracy, and recipient isolation.
- **Exit Criteria:** Unread count dynamically increments upon dispatch and decrements upon read; recipient isolation verified.

#### Phase AN-6: Notifications UI — Header Bell, Popover & Notification Center
- **Objective:** Integrate the notification bell into the top app bar and build the full notification center screen.
- **Key Deliverables:**
  - `lib/features/notifications/presentation/widgets/notification_bell_button.dart`
  - `lib/features/notifications/presentation/widgets/notification_dropdown_popover.dart`
  - `lib/features/notifications/presentation/screens/notification_center_screen.dart`
  - `lib/features/notifications/presentation/navigation/deep_link_navigation_resolver.dart`
  - App header integration in `lib/app/crm_app.dart` and dashboard screens.
  - Widget tests verifying badge rendering, popover toggling, and tap navigation.
- **Exit Criteria:** Bell badge visible across all authenticated screens; tapping item marks it read and routes to target screen.

#### Phase AN-7: Cross-Module Reusable Integration Bridge (HR, Purchase, Vendor, Inventory)
- **Objective:** Expose the decoupled `ApprovalBridge` and integrate mock approval request triggers from external modules.
- **Key Deliverables:**
  - `lib/features/approvals/domain/services/approval_bridge.dart`
  - `lib/features/approvals/data/services/default_approval_bridge.dart`
  - Integration contracts for Purchase Orders, Attendance Corrections, and Vendor KYC.
  - Cross-module end-to-end integration tests verifying approval submission, state reflection, and notification dispatch.
- **Exit Criteria:** Calling modules submit approval requests without circular imports or direct table mutations.

#### Phase AN-8: Search, Multi-Filter, Audit Trail & CSV Export Engine
- **Objective:** Build enterprise reporting, full-text multi-criteria search, timeline auditing, and RFC-4180 compliant CSV export.
- **Key Deliverables:**
  - `lib/features/approvals/presentation/screens/approval_history_export_screen.dart`
  - `lib/features/approvals/domain/services/approval_export_service.dart`
  - Permission gate: `ApprovalsAccessPolicy.canExport(user)`.
  - Comprehensive tests verifying CSV formatting, comma/quote escaping, and filter preservation.
- **Exit Criteria:** CSV export passes automated formatting tests; unauthorized users cannot trigger or view export actions.

#### Phase AN-9: Backend DTOs, API Adapters & Controlled Dual-Mode Cutover
- **Objective:** Construct Dio-powered REST backend adapters and wire the controlled cutover repository factory.
- **Key Deliverables:**
  - `lib/features/approvals/data/dto/approval_request_dto.dart`
  - `lib/features/notifications/data/dto/notification_dto.dart`
  - `lib/features/approvals/data/repositories/backend_approval_repository.dart`
  - `lib/features/notifications/data/repositories/backend_notification_repository.dart`
  - `lib/features/approvals/data/repositories/approval_repository_factory.dart`
  - `lib/features/notifications/data/repositories/notification_repository_factory.dart`
  - DTO serialization tests and mock HTTP client adapter tests verifying 200, 401, 403, 404, 500 error mapping.
- **Exit Criteria:** Zero silent fallback to mock on backend error; DTOs parse all backend JSON shapes safely.

#### Phase AN-10: End-to-End Security, Session Isolation, Platform UAT & Feature Freeze
- **Objective:** Execute exhaustive regression testing, responsive viewport verification, security audits, and formal module freeze.
- **Key Deliverables:**
  - Comprehensive regression test suite (`test/features/approvals/approvals_final_regression_test.dart`).
  - Cross-user data isolation tests (User A cannot view User B notifications or unassigned approvals).
  - Session teardown tests (logout clears active notification streams).
  - Static analysis: `flutter analyze` clean (0 warnings, 0 errors).
  - Production builds: `flutter build web` PASS.
  - Final deliverable: `AN_10_APPROVALS_FINAL_UAT_SECURITY_REGRESSION_FREEZE.md`.
- **Exit Criteria:** All automated tests pass (100%), 0 analyzer issues, builds green, module marked **COMPLETE AND FROZEN**.

---

## 11. Testing, Verification & Quality Standards

Every phase must satisfy the project's non-negotiable quality criteria before moving to the next:

1. **Test Coverage Requirements:**
   - Domain Entities & Value Objects: 100% unit test coverage.
   - Access Policy: 100% matrix coverage (Admin vs Standard User, permitted vs unpermitted).
   - Cubits: 100% `blocTest` coverage for initial, loading, success, failure, retry, and concurrency suppression.
   - Repositories: Full coverage of query filtering, data mutations, stream broadcasts, and network error handling.
   - UI Widgets: Render tests on 4 standard viewports (320x568, 360x640, 768x1024, 1200x800).
2. **Static Analysis Standard:**
   - Must run `flutter analyze` across `lib/features/approvals/`, `lib/features/notifications/`, and corresponding `test/` folders with **0 warnings and 0 errors**.
3. **Responsive Verification:**
   - Text scaling (1.0x and 1.5x) inspected for text truncation.
   - Zero RenderFlex overflows under bounded height/width constraints.
4. **Platform Builds:**
   - `flutter build web` must pass with zero compilation errors.

---

## 12. Team Collaboration, Branching & Git Conventions

- **Git Branch:** Work will occur on a dedicated feature branch:
  ```bash
  git checkout frontend-development
  git pull origin frontend-development
  git checkout -b feature/approvals-notifications
  ```
- **Commit Message Conventions:**
  - `feat(approvals): implement approval request domain entities (AN-1)`
  - `feat(notifications): establish mock notification repository and reactive store (AN-2)`
  - `feat(approvals): implement approval inbox and action cubits (AN-3)`
  - `feat(approvals): build responsive approval inbox and detail screens (AN-4)`
  - `feat(notifications): integrate global header bell and popover (AN-6)`
  - `test(approvals): audit cross-user data isolation and workflow security (AN-10)`
- **Shared Files Preservation:**
  - Only make minimal, strictly necessary additions to `lib/main.dart`, `lib/app/crm_app.dart`, `lib/features/auth/domain/policies/crm_permissions.dart`, and `lib/features/user_management/data/mock/mock_permission_catalog.dart`.
  - Never refactor unrelated shared code or other developer modules (Lead, Calling, Inventory, Purchase, Dispatch, HR).
