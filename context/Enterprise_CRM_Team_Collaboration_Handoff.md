# Enterprise CRM — Team Collaboration & Project Handoff Guide

**Project Owner / Lead Developer:** Vachaspati Mishra  
**Collaborator:** Vikash Chaurasiya  
**Repository:** `https://github.com/vachaspatimishraa/enterprise_crm.git`  
**Primary Technology:** Flutter (Android + responsive Web)  
**State Management:** BLoC / Cubit  
**Architecture:** UI → Cubit/BLoC → Repository → Service/Data Source → Backend  

---

# 1. Purpose

This document is the complete collaboration handoff for Vikash Chaurasiya and for any coding agent used by him.

After reading this file, Vikash should understand the project structure, current status, module ownership, technology, branch workflow, backend integration model, testing rules, shared-file boundaries, and how Vachaspati and Vikash should work without overlapping each other's feature areas.

Treat this file as the project collaboration baseline until Vachaspati explicitly updates it.

---

# 2. ChatGPT conversation separation

Vachaspati Mishra and Vikash Chaurasiya may use the same ChatGPT account on different devices and in different chats.

**Important:** separate chats on the same ChatGPT account are not guaranteed to be completely isolated if account-level Memory is enabled. For strict separation, separate ChatGPT accounts are the safest option.

If the same account is used, Vikash should:

- use a dedicated CRM chat of his own,
- attach/share this file in that chat,
- start with the bootstrap prompt at the end of this document,
- never ask the agent to recall or continue Vachaspati's private chat,
- treat this file and the repository as the authoritative source for his work,
- keep his task reports inside his own chat.

The collaboration process must not depend on cross-chat memory.

---

# 3. Project purpose

The project is an **Enterprise CRM application** built in Flutter.

The CRM contains these 8 business modules:

1. Lead Management
2. Calling
3. Inventory
4. Dispatch
5. Purchase
6. HR / Payroll
7. Approvals & Notifications
8. Vendor Management

`Users & Access` / Administration is shared platform infrastructure and is not a ninth business module.

---

# 4. Core technology

## Flutter targets

- Android
- Responsive Web

Typical responsive verification sizes already used:

```text
320x568
360x640
768x1024
1200x800
```

## State management

```text
BLoC / Cubit
```

## Architecture

```text
Flutter Screen / Widget
        ↓
Cubit / BLoC
        ↓
Repository Interface
        ↓
Repository Implementation
        ↓
Service / Data Source / Backend
```

Screens should not directly access databases or backend APIs.

All feature data should flow through repository contracts so mock implementations can later be replaced by backend-backed implementations without rewriting the UI.

---

# 5. Backend situation

The instructor forked Vachaspati's repository and developed backend integration in the instructor's own fork.

The instructor's backend work is reported as ready, but it is not part of Vachaspati's repository until it is merged through Git.

Preferred flow:

```text
Instructor fork
      ↓ Pull Request
Vachaspati main
      ↓ backend validation
frontend-development merges latest main
      ↓
full integration testing
```

Do not invent backend:

- API URLs,
- HTTP methods,
- JSON shapes,
- authentication headers,
- database schemas,
- pagination rules,
- or server behavior.

Use the instructor's actual backend contract.

---

# 6. Important branches and checkpoints

Current branch model:

```text
main
→ stable integration branch

frontend-development
→ team frontend integration branch

feature/<task>
→ individual developer work

inventory-backup
→ preserved historical Inventory checkpoint
```

Last verified frontend checkpoints:

```text
main
→ 02b41a83302a96e29b2206a9e6737a34eafb45ed
→ stable Lead + Calling frontend handoff

frontend-development
→ bdc5b106cc9fe2a5dea564a5b87bbace7e6ecb93
→ Inventory through INVENTORY-3B

inventory-backup
→ 37e1eee88761c7f8412fc20acebe23ea0cf2cd34
→ preserved INVENTORY-1 checkpoint
```

Verified state at `bdc5b10`:

```text
flutter test:
1370 / 1370 PASS

flutter analyze:
CLEAN

flutter build web:
PASS
```

Inventory CSV/XLSX import is planned as the next Inventory phase unless a later implementation report supersedes this file.

Always inspect actual Git state before starting work.

---

# 7. Team ownership

## Vachaspati Mishra owns

```text
Lead Management
Inventory
Purchase
Dispatch
HR / Payroll
Users & Access / Authentication / shared platform integration
Overall integration and review
```

## Vikash Chaurasiya owns exactly three module areas

```text
1. Calling / Follow-Up
2. Vendor Management
3. Approvals & Notifications
```

### Calling / Follow-Up

Calling already has a substantial completed frontend foundation.

Vikash owns future Calling maintenance, backend verification after backend merge, approved enhancements, and regression fixes.

He must preserve frozen Calling semantics unless a new requirement is explicitly approved.

### Vendor Management

Vendor Management is Vikash's primary new module development area.

It should be built independently first. Do not directly edit Purchase internals while building Vendor Management.

### Approvals & Notifications

Approvals & Notifications is Vikash's second new module development area.

It should become a reusable cross-module capability. Do not implement duplicate approval systems inside Purchase, HR, Dispatch, or Vendor modules.

---

# 8. Shared platform ownership

Shared platform is integration-owned by Vachaspati.

It includes:

```text
Authentication
Users & Access
CurrentUser
AccountType
AccessPolicy
CrmModule
CrmPermissions
UserManagementRepository
AuthRepository
Admin Dashboard
User Dashboard
Module assignment
Permission assignment
Enable / Disable User
Admin password reset
Logout
```

Vikash should not redesign this infrastructure.

If one of Vikash's modules requires a shared permission/module/route/dependency change:

1. document it in the PR,
2. keep it minimal,
3. let Vachaspati review it,
4. do not refactor unrelated shared code.

---

# 9. Shared platform status

For the current frontend scope, the shared platform is roughly 90–95% complete.

Completed frontend capabilities include:

```text
Login
Admin/User account types
Admin Dashboard
User Dashboard
Logout
CurrentUser
module assignment
permission assignment
central AccessPolicy
AccessRestrictedScreen
Admin all-module semantics
assigned-module User semantics
permission-aware actions
Users & Access directory
user search/filter
user details
Create User
Edit User
Enable / Disable User
Admin password reset
Master Admin protection
shared mock account store
explicit CRM User → LeadAssignee mapping
frontend authorization guards
```

Intentionally excluded:

```text
Signup
Forgot Password
self-service password reset
hardcoded Agent/HR/Sales account types
wildcard permissions
direct Flutter database writes
```

Backend responsibilities still include real authentication, sessions/tokens, password hashing, persistent user storage, and server-side authorization.

---

# 10. Account model

There are exactly two top-level account types:

```text
Admin
User
```

Do not create additional account types such as:

```text
Agent
Sales User
HR User
Inventory User
Vendor User
```

Normal Users receive assigned modules and permissions.

Friendly role labels may exist later, but must not become security primitives without a formal requirement.

---

# 11. Lead Management status

Lead Management is substantially completed and frozen for the current frontend scope.

Major completed features:

```text
Lead Dashboard
Lead list
search
filter
sort
pagination
manual Lead create/edit
CSV import
XLSX import
CSV/XLSX export
manual assignment
bulk assignment
single reassignment
My Assigned Leads
User Lead Details
permission-aware User Lead editing
current ownership guards
```

Important rules:

- LeadStatus is backend/instructor-defined.
- Calling outcomes are not LeadStatus.
- Standard User Lead access uses explicit CRM User → LeadAssignee mapping.
- Never derive that mapping from username/display name/email.
- `lead.update` does not imply `lead.view_assigned`.

Vikash should not change Lead Management while working on Calling unless an explicit Calling integration task requires it.

---

# 12. Calling / Follow-Up status

Calling / Follow-Up is now Vikash's maintenance/future-development ownership area.

Frozen call outcomes:

```text
Follow up
Not connected
Visit scheduled
Irrelevant
Not interested
Lead closed
Sales done
Dispatched
```

Important rules:

- CallOutcome is separate from LeadStatus.
- Recording a call does not automatically change LeadStatus.
- `calling.use` is independent of `lead.update`.
- current Lead assignment determines protected access,
- `performedByUserId` is not proof of ownership,
- historical CallActivity remains immutable,
- no actual VoIP/phone integration is present.

Follow-Up statuses:

```text
pending
completed
cancelled
```

Reschedule is not a status.

Rescheduling keeps status pending and changes `scheduledAt` while recording the lifecycle event.

Completed/cancelled are terminal in the current scope.

---

# 13. Inventory status

Inventory belongs to Vachaspati.

Completed phases:

```text
INVENTORY-1
Read-only Inventory workspace

INVENTORY-2
Admin Item Administration

INVENTORY-3
Stock Movement Core
```

Inventory item identity:

```text
id
name
sku
```

SKU uniqueness uses trimmed case-insensitive comparison.

Current quantity is never stored directly on InventoryItem.

It is derived from:

```text
SUM(StockMovement.quantityDelta)
```

Do not add authoritative:

```text
InventoryItem.quantity
InventoryItem.stock
InventoryItem.quantityOnHand
setQuantity()
updateQuantity()
```

Current movement types:

```text
openingStock
adjustment
```

Opening stock rules:

```text
Admin only
separate post-create operation
only when item has zero existing movements
finite quantity > 0
no zero opening-stock movement
no negative opening stock
```

Adjustment rules:

```text
Admin only
initialized item required
Increase / Decrease UI
signed quantityDelta internally
reason required
resulting stock cannot become negative
```

Existing seed movements may have nullable actor/reason. New movements follow current audit rules.

Inventory CSV/XLSX import is planned next unless a later implementation report proves it complete.

Vikash should not modify Inventory without explicit assignment.

---

# 14. Purchase / Dispatch / HR boundaries

These modules belong to Vachaspati.

## Purchase

Purchase must first be built independently.

Later integration:

```text
Purchase Receipt
      ↓
Inventory inward movement
```

Do not add speculative Inventory purchase movements during basic Purchase development.

## Dispatch

Dispatch must first be built independently.

Later integration:

```text
Dispatch completion
      ↓
Inventory outward movement
```

Do not add speculative Inventory dispatch movements during basic Dispatch development.

## HR / Payroll

HR / Payroll belongs to Vachaspati.

Approvals must not directly rewrite HR domain logic during initial development.

Any HR approval integration is a later explicit integration checkpoint.

---

# 15. Vendor boundary

Vendor Management belongs to Vikash.

Build:

```text
Vendor domain
Vendor repository
Vendor Cubits
Vendor UI
Vendor tests
```

without editing Purchase internals.

Later:

```text
Vendor Management
      ↓ Vendor identity/reference
Purchase
```

will be connected through an explicit integration contract.

Do not create duplicate Purchase entities inside Vendor Management.

---

# 16. Approvals boundary

Approvals & Notifications belongs to Vikash.

It must be reusable, not duplicated inside other modules.

Do not modify:

```text
Purchase
Dispatch
HR
Inventory
Lead
```

to insert approval behavior during initial Approvals development.

Potential future integrations:

```text
Purchase → Approvals
HR → Approvals
Dispatch → Approvals
Vendor → Approvals
```

only after their requirements are frozen.

---

# 17. Feature-folder ownership

Vachaspati-owned areas:

```text
lib/features/leads/
lib/features/inventory/
lib/features/purchase/        (future)
lib/features/dispatch/        (future)
lib/features/hr/              (future)
shared Auth / Users & Access integration
```

Vikash-owned areas:

```text
lib/features/calling/
lib/features/vendor/          (future)
lib/features/approvals/       (future)
```

Actual folder names must follow repository conventions. Inspect before creating new folders.

---

# 18. High-conflict shared files

These areas can affect both developers:

```text
lib/main.dart
lib/app/crm_app.dart
routing
navigation
AdminDashboard
UserDashboard
AccessPolicy
CrmModule
CrmPermissions
shared repositories
dependency composition
pubspec.yaml
```

Rules:

- avoid editing shared files unless required,
- keep shared changes minimal,
- call them out clearly in PRs,
- Vachaspati reviews shared architecture changes,
- never refactor unrelated shared code during a feature task.

---

# 19. Collaboration branch model

`frontend-development` is the frontend integration branch.

From now on, each new task should use a feature branch.

Example:

```text
frontend-development
│
├── feature/inventory-import              ← Vachaspati
├── feature/purchase                      ← Vachaspati
├── feature/dispatch                      ← Vachaspati
├── feature/hr-payroll                    ← Vachaspati
│
├── feature/calling-<task>                ← Vikash
├── feature/vendor-management             ← Vikash
└── feature/approvals-notifications       ← Vikash
```

Feature branches merge through PRs into:

```text
frontend-development
```

Do not use `main` as a personal development branch.

---

# 20. Starting a feature branch

Always start from the latest integration branch:

```bash
git checkout frontend-development
git pull origin frontend-development
git checkout -b feature/<task-name>
```

Example:

```bash
git checkout -b feature/vendor-management
git push -u origin feature/vendor-management
```

---

# 21. Updating a feature branch

If `frontend-development` changes while work is in progress:

```bash
git fetch origin
git checkout feature/vendor-management
git merge origin/frontend-development
```

Resolve conflicts in the feature branch and rerun validation.

Avoid force-pushing or rewriting shared history unless both developers explicitly agree.

---

# 22. Pull Request requirements

Every module/task PR into `frontend-development` should report:

```text
What was implemented
Business rules
Files/modules changed
Shared files changed
Tests added
Full test result
Analyzer result
Web build result
Deferred work
Known limitations
```

Do not merge an incomplete PR.

---

# 23. Validation before PR

Required:

```bash
flutter analyze
flutter test
flutter build web
git diff --check
git status --short
```

Expected:

```text
Analyzer: CLEAN
Tests: ALL PASS
Web build: PASS
git diff --check: CLEAN
```

Use one authoritative full `flutter test` run for final reporting.

---

# 24. Formatting

Prefer scoped formatting:

```bash
dart format lib/features/<feature> test/features/<feature>
```

If `dart format .` touches unrelated stable code, restore unrelated formatting-only changes.

Never mix unrelated cleanup/refactors into a feature PR.

---

# 25. Do not bypass repositories

Never build:

```text
Widget → API
Widget → Database
Widget → locally-created MockRepository
```

Use:

```text
Widget
  ↓
Cubit
  ↓
Repository
```

Repositories should normally be app-scoped and explicitly injected.

---

# 26. Authorization

Hiding buttons is not enough.

Protected flows use the existing style:

```text
route
 ↓
authorization
 ├── denied → AccessRestrictedScreen
 └── allowed → Cubit/repository workflow
```

Tests should prove unauthorized users cannot trigger protected mutations.

---

# 27. One module at a time

Recommended Vikash sequence:

```text
Vendor Requirements Audit
        ↓
Vendor Business Freeze
        ↓
Vendor Implementation
        ↓
Tests
        ↓
PR + Vachaspati review
        ↓
Vendor Freeze

then

Approvals Requirements Audit
        ↓
Approvals Business Freeze
        ↓
Approvals Implementation
        ↓
Tests
        ↓
PR + Vachaspati review
```

Calling work is done only when a Calling task is explicitly assigned.

---

# 28. Requirement-freeze process

For each new module:

```text
Audit repository / existing code
        ↓
List confirmed facts
        ↓
List unconfirmed business decisions
        ↓
Business freeze
        ↓
Implementation
        ↓
Tests
        ↓
Review
        ↓
Freeze
```

A coding agent must not invent business rules merely to finish a task.

---

# 29. Coding-agent rules

Every coding agent must:

- inspect Git state first,
- inspect existing architecture before adding new patterns,
- work on the correct feature branch,
- avoid `main`,
- avoid touching unrelated modules,
- avoid inventing backend contracts,
- avoid inventing business rules,
- run the full regression suite,
- report exact test/analyzer/build results,
- stop at the requested checkpoint,
- never automatically start the next phase.

---

# 30. Backend merge workflow

Because the instructor used a fork:

```text
Instructor backend branch
        ↓ PR
Vachaspati main
        ↓
backend validation
        ↓
frontend-development merges latest main
        ↓
resolve integration conflicts
        ↓
full application QA
```

After backend is merged to `main`:

```bash
git checkout frontend-development
git pull origin frontend-development
git merge main
```

Then run:

```bash
flutter analyze
flutter test
flutter build web
```

A new instructor fork is not required for each future module; the existing fork can sync from Vachaspati's repository.

---

# 31. Cross-module integration

Complete independent modules first.

Integration is a separate checkpoint.

Examples:

```text
Vendor → Purchase
Purchase → Inventory
Dispatch → Inventory
Approvals → Purchase / HR / Dispatch / Vendor
```

This prevents simultaneous edits to the same domain.

---

# 32. What Vikash must not change without approval

Do not casually change:

```text
Lead business rules
Inventory ledger rules
Purchase domain
Dispatch domain
HR / Payroll domain
AccountType
AccessPolicy semantics
Users & Access architecture
existing permission meanings
Instructor backend contract
```

If Vikash's module requires one of these changes, stop and agree on an integration contract first.

---

# 33. What Vachaspati should avoid

While Vikash is actively developing a module, Vachaspati should avoid independently creating or modifying the same feature domain on another branch.

Example:

```text
Vikash → feature/vendor-management
```

means Vachaspati should not create a competing Vendor domain elsewhere.

---

# 34. Conflict ownership

```text
Conflict inside feature module
→ feature owner resolves

Conflict in shared infrastructure
→ Vachaspati reviews/finalizes

Conflict involving instructor backend behavior
→ do not guess; use actual backend contract
```

---

# 35. Commit discipline

Use meaningful commits such as:

```text
Add vendor domain foundation
Add vendor directory workspace
Add vendor create and edit flows
Add vendor authorization tests
```

Avoid vague commits such as:

```text
changes
final
update
fix stuff
```

Do not commit:

```text
build output
IDE task files
temporary logs
agent walkthrough files
unrelated generated platform changes
```

---

# 36. Known frontend dependencies

Known packages include:

```text
file_picker
csv
excel
```

Do not add networking/backend packages just because a future module might need a backend.

Use the actual instructor backend implementation when integration happens.

---

# 37. Project-wide frozen principles

Unless explicitly changed:

```text
Exactly two account types: Admin and User
Users receive modules + permissions
Admin has full business-module access
No Signup
No self-service Forgot Password
Admin-only password reset
No direct Flutter database writes
Repositories separate UI from backend/data
No guessed production API contract
No authorization bypass
No unapproved cross-module behavior
Shared infrastructure changes require review
```

---

# 38. Recommended first Vikash task

Unless Vachaspati assigns a Calling task first, Vikash should start with:

```text
VENDOR-0 — Vendor Management Requirements / Repository Audit
```

Do not immediately code a guessed Vendor model.

The first Vendor task should determine:

```text
confirmed Vendor data
unconfirmed fields
relationships
Purchase integration boundaries
Admin/User authorization
repository contract
search/filter/list requirements
create/edit requirements
delete/archive policy
```

Then Vachaspati and Vikash freeze Vendor requirements before implementation.

---

# 39. Vikash agent bootstrap prompt

After attaching this file to Vikash's separate chat, paste:

```text
My name is Vikash Chaurasiya.

I am collaborating with Vachaspati Mishra on the Enterprise CRM project.

Use the attached "Enterprise CRM — Team Collaboration & Project Handoff Guide"
as the authoritative context for my work.

Do not rely on, reconstruct, summarize, or continue Vachaspati's separate private
ChatGPT conversations. My work must be based on this document, the repository,
and messages in this chat.

My owned module areas are:
1. Calling / Follow-Up — maintenance and future assigned changes
2. Vendor Management — new development
3. Approvals & Notifications — new development

Vachaspati owns:
- Lead Management
- Inventory
- Purchase
- Dispatch
- HR / Payroll
- Users & Access / shared platform integration

Do not modify Vachaspati-owned feature modules unless an explicit integration
task requires it.

Before any implementation:
1. inspect Git branch/status,
2. inspect relevant existing architecture,
3. confirm the active feature branch,
4. do not work on main,
5. do not invent backend contracts,
6. do not invent business rules,
7. run full validation before completion.

For a new module, start with requirements/audit and business freeze before coding.

If this document and the repository disagree, report the mismatch instead of guessing.
```

---

# 40. Vachaspati agent identity prompt

For Vachaspati's own chats:

```text
My name is Vachaspati Mishra.

I am the project owner/integration lead for Enterprise CRM.

My owned areas are:
- Lead Management
- Inventory
- Purchase
- Dispatch
- HR / Payroll
- Users & Access / shared platform

Vikash Chaurasiya separately owns:
- Calling / Follow-Up maintenance/future tasks
- Vendor Management
- Approvals & Notifications

Do not treat Vikash's separate chat as my conversation.
Use my current chat and repository state for my work.
```

---

# 41. Final ownership summary

## Vachaspati Mishra

```text
Lead Management
Inventory
Purchase
Dispatch
HR / Payroll
Users & Access / Authentication / Shared Platform
Overall integration/review
```

## Vikash Chaurasiya

```text
Calling / Follow-Up
Vendor Management
Approvals & Notifications
```

## Instructor

```text
Backend integration through fork / Pull Request workflow
```

---

# 42. Standard project workflow

```text
Vachaspati feature branches ─┐
                             │
Vikash feature branches ─────┼──→ frontend-development
                             │
                             ↓
                      integration testing
                             │
Instructor backend ─────→ main
                             │
                             ↓
                backend/frontend synchronization
                             │
                             ↓
                         final main
```

No developer should treat `main` as a personal feature-development branch.

No developer should implement another owner's module without explicit assignment.

No coding agent should invent cross-module rules just to make code compile.

## Standard rule

**Inspect → Freeze → Implement → Test → Review → Merge**
