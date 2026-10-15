# HR-0 — HR / Payroll Requirements Audit & Architecture Preparation Report

**Date:** 2026-09-26  
**Project:** Enterprise CRM (`d:\projects\enterprise_crm` / `c:\Users\vkcha\Desktop\Assets\project\enterprise_crm`)  
**Status:** AUDIT COMPLETE / AWAITING BUSINESS FREEZE (HR-BF)  

---

## 1. Executive Summary

`HR-0` is an architectural and requirements audit checkpoint conducted prior to defining or implementing any production domain entities (`Employee`), state management, repository contracts, or UI screens for the HR / Payroll module.

Following the project's strict engineering principles (as established in `MASTER_DEVELOPMENT_RULES.md`, `CODING_AGENT_MASTER_PROMPT.txt`, and demonstrated in `INVENTORY_REQUIREMENTS.md`), this report strictly distinguishes between **evidence-backed repository facts** and **unconfirmed planning proposals / generic backend draft fields**.

Generic backend schema proposals and early draft PRDs describe potential fields such as:
- `employee_code`
- `user_id`
- `full_name`
- `department_id`
- `designation`
- `joining_date`
- `employment_status`
- `manager_id`
- `salary_reference`

However, **none of these fields have been formally approved, validated, or frozen as client business requirements**. Therefore, creating an `Employee` entity with guessed fields or speculative statuses at this stage would violate project rules.

This document records all verified repository invariants, enumerates unanswered business decisions, analyzes architectural options, and provides a clear **HR-BF (Business Freeze)** decision template.

---

## 2. Baseline Verification (Starting State)

- **Starting Branch:** `main`
- **Active Feature Branch:** `feature/hr-1-core`
- **Git HEAD:** `02b41a83302a96e29b2206a9e6737a34eafb45ed`
- **Flutter Analyzer:** Clean (0 issues found).
- **Full Flutter Test Suite:** **1,132 / 1,132 PASS** (0 failures).
- **HR Targeted Tests:** **11 / 11 PASS** (`test/features/hr/domain/policies/hr_access_policy_test.dart`).
- **Working Tree:** Unrelated developer changes preserved; `lib/features/hr/domain/policies/hr_access_policy.dart` and its test added.

---

## 3. Confirmed Repository State (Implementation Facts)

The following statements represent verified code-level facts from the current repository:

1. **`CrmModule.hrPayroll` exists:**  
   Defined in `lib/features/auth/domain/entities/crm_module.dart`.
2. **`CrmPermissions.hrView` and `CrmPermissions.payrollView` exist:**  
   Defined as `'hr.view'` and `'payroll.view'` in `lib/features/auth/domain/policies/crm_permissions.dart`, both canonically mapped to `CrmModule.hrPayroll`.
3. **`MockPermissionCatalog` registers both permissions:**  
   Registered in `lib/features/user_management/data/mock/mock_permission_catalog.dart` with display names `'View HR Records'` and `'View Payroll'`.
4. **Admin receives unrestricted frontend module access via `AccountType.admin`:**  
   Evaluated through `AccessPolicy.canAccessModule` and `user.isAdmin`. Admin accounts are not restricted by module assignment lists or individual permission strings.
5. **Standard Users require `CrmModule.hrPayroll` assigned in `user.modules`:**  
   Enforced by `AccessPolicy.canAccessModule(user, CrmModule.hrPayroll)`. Direct navigation without assignment returns `AccessRestrictedScreen`.
6. **`ModulePlaceholderScreen` currently handles HR / Payroll:**  
   `AdminDashboardScreen` and `UserDashboardScreen` route `CrmModule.hrPayroll` to `ModulePlaceholderScreen(module: module, user: user)`. If a standard user has `hr.view` or `payroll.view`, the placeholder truthfully displays the assigned capability banner.
7. **`HrAccessPolicy` establishes the non-speculative authorization layer:**  
   Implemented in `lib/features/hr/domain/policies/hr_access_policy.dart`, evaluating module access and operational view permissions against `CurrentUser`.
8. **No Employee domain entity exists in `lib/`:**  
   There is no `Employee`, `Staff`, `Department`, or `Designation` model in `lib/features/hr/` (the feature directory contained only empty subdirectories).
9. **No Employee repository exists:**  
   There is no `EmployeeRepository` interface or mock implementation in the codebase.
10. **No Employee Cubit or BLoC exists:**  
    State management for HR has not been implemented.
11. **No HR / Payroll business screen exists:**  
    There is no Employee List, Employee Details, Attendance, KPI, or Payroll screen.
12. **Cross-module integrations are strictly inactive:**  
    No Approvals $\rightarrow$ HR, Payroll calculation, or Purchase/Vendor $\rightarrow$ HR workflows exist.

---

## 4. Requirements Matrix (Confirmed vs Unconfirmed)

All domain and business concepts are classified below. Every item lacking an explicit, user-approved requirement is strictly marked **UNCONFIRMED**.

| Category | Item / Question | Status | Classification Details |
|---|---|---|---|
| **Employee Identity** | Entity Name (`Employee`) | **CONFIRMED** | Canonical concept for workforce records. |
| **Employee Identity** | Primary Key (`id`) | **CONFIRMED** | UUID or stable unique identifier required by repository contracts. |
| **Employee Identity** | Employee Code (`employeeCode`) | **UNCONFIRMED** | Mandatory, optional, auto-generated, or free text format unconfirmed. |
| **Employee Identity** | Full Name vs First/Last | **UNCONFIRMED** | Single `fullName` field vs structured `firstName` / `lastName` unconfirmed. |
| **Employee Identity** | Email address | **UNCONFIRMED** | Work email vs personal email, required vs optional unconfirmed. |
| **Employee Identity** | Phone number | **UNCONFIRMED** | Contact number required vs optional unconfirmed. |
| **User Linkage** | Link to CRM User (`userId`) | **UNCONFIRMED** | Whether every employee has a login, or only some employees have logins, is unconfirmed. Do not assume 1:1 parity between `Employee` and `ManagedUser`. |
| **Department** | Department model | **UNCONFIRMED** | Standalone entity with ID, enum, or free-text string unconfirmed. |
| **Designation** | Designation / Job Title | **UNCONFIRMED** | Standardized list vs free-text role description unconfirmed. |
| **Employment** | Status vocabulary | **UNCONFIRMED** | Allowed states (`active`, `probation`, `notice`, `terminated`, `onLeave`) unconfirmed. String value-object vs fixed enum unconfirmed. |
| **Hierarchy** | Reporting Manager (`managerId`) | **UNCONFIRMED** | Direct supervisor relationship and hierarchical structure unconfirmed. |
| **Dates** | Date of Joining (`joiningDate`) | **UNCONFIRMED** | Timestamp representation and date validation rules unconfirmed. |
| **Compensation** | Salary / CTC / Bank details | **DEFERRED** | **Strictly excluded from HR-1. Detailed payroll calculations and salary privacy are deferred.** |
| **Documents** | Employee Documents & KYC | **DEFERRED** | **Belongs to HR-3. Excluded from HR-1.** |
| **Attendance** | Attendance & Time Tracking | **DEFERRED** | **Belongs to HR-4. Excluded from HR-1.** |
| **KPI** | Performance & Metrics | **DEFERRED** | **Belongs to HR-5. Excluded from HR-1.** |
| **Payroll** | Payroll Runs & Payslips | **DEFERRED** | **Belongs to HR-6. Excluded from HR-1.** |
| **Approvals** | Leave / Expense Approvals | **DEFERRED** | **Cross-module Approvals capability is deferred to explicit integration phase.** |

---

## 5. Summary of Removed Assumptions

The following items from old planning drafts are explicitly rejected as premature assumptions:

1. **`salary_reference` / Salary on Employee:** Rejected for HR-1. Compensation data requires privacy rules, backend authorization contracts, and specific business approval.
2. **Preset Department Enums:** Rejected. Department names must not be hardcoded without confirmed organizational structure.
3. **Preset Status Enums (`probation`, `terminated`, etc.):** Rejected until the project owner or instructor specifies the exact lifecycle states.
4. **Mandatory `userId`:** Rejected. Many enterprises employ field staff or operational personnel who do not have CRM login accounts.
5. **Immediate CRUD Repository:** Rejected. HR-1 is read/foundation-focused; mutations without confirmed field validation risk breaking later backend integration.

---

## 6. Architecture Options Analysis

Three primary architectural alternatives exist for the HR Employee domain:

### Option A — Simple Employee Directory (Recommended for Initial Foundation)
```text
Employee
├── id: String (UUID)
├── employeeCode: String?
├── fullName: String
├── email: String?
├── phone: String?
├── department: String?
├── designation: String?
├── employmentStatus: String (or Value Object)
├── joiningDate: DateTime?
└── userId: String? (optional link to ManagedUser)
```
- **Pros:** Minimal, clean, covers 95% of CRM employee listing needs without overengineering.
- **Cons:** Flat taxonomy; does not enforce relational department entities.

### Option B — Relational Workforce Model
```text
Employee
├── id: String
├── employeeCode: String
├── fullName: String
├── departmentId: String -> Department(id, name, code)
├── designationId: String -> Designation(id, title)
├── managerId: String? -> Employee.id
├── employmentStatus: EmploymentStatus enum
└── linkedUserId: String?
```
- **Pros:** Strict relational integrity; matches normalized enterprise database design.
- **Cons:** Requires multiple supporting entities (`Department`, `Designation`) that are currently unconfirmed and lack backend contracts.

### Option C — Comprehensive Aggregate HRMS Model
- Includes embedded documents, attendance summaries, payroll references.
- **Verdict:** Strictly rejected as premature and violating single-responsibility module phases.

---

## 7. Minimum Business Decisions Required for HR-BF (Business Freeze)

Before the `Employee` entity and `EmployeeRepository` can be implemented in HR-1, the project owner / user must answer these 6 essential questions:

1. **Core Identity Fields:** Which fields are mandatory vs optional on an Employee?  
   *(e.g., Is `employeeCode` required and unique? Is `fullName` sufficient? Are `email` and `phone` optional?)*
2. **User Account Linkage:** What is the relationship between `Employee` and CRM `ManagedUser`?  
   *(e.g., Can an Employee exist without a CRM login? Can a CRM login exist without being an Employee?)*
3. **Department & Designation Representation:** Are Department and Designation free-text strings, predefined enums, or IDs referencing future entities?
4. **Employment Status Vocabulary:** What are the valid employment statuses?  
   *(e.g., `Active`, `Inactive`, `Probation`, `Terminated`, `On Leave`? Or a string value-object that accepts any backend value?)*
5. **Reporting Hierarchy:** Is `managerId` (reporting manager) required in the initial read model?
6. **Repository Read Scope:** Is `getEmployees()` and `getEmployeeById(String id)` sufficient for the initial foundation, and what is the default ordering?

---

## 8. HR-BF — Business Freeze Template (Awaiting User Approval)

```text
==================================================================
HR-BF — BUSINESS FREEZE TEMPLATE
Status: PENDING USER APPROVAL
==================================================================

1. Entity Name:
   [ ] Employee

2. Identity Fields:
   - id: String (required, UUID)
   - employeeCode: [ ] Required [ ] Optional [ ] Excluded
   - fullName: [ ] Required
   - email: [ ] Optional [ ] Required
   - phone: [ ] Optional [ ] Required
   - department: [ ] Free-text String [ ] Enum [ ] Excluded
   - designation: [ ] Free-text String [ ] Enum [ ] Excluded
   - joiningDate: [ ] DateTime? [ ] Excluded
   - userId: [ ] Optional String (link to ManagedUser) [ ] Excluded

3. Employment Status:
   - Type: [ ] String Value Object (backend-flexible) [ ] Fixed Enum
   - Allowed Initial Values: ____________________________________

4. Default Repository Ordering:
   [ ] Deterministic by fullName A-Z
   [ ] Deterministic by employeeCode A-Z
   [ ] Deterministic by joiningDate descending

5. Operations for HR-1 Foundation:
   - Future<List<Employee>> getEmployees();
   - Future<Employee?> getEmployeeById(String id);

6. Deferred to Later Phases:
   - Documents & KYC -> HR-3
   - Attendance -> HR-4
   - KPI -> HR-5
   - Payroll & Compensation -> HR-6
   - Approvals -> Cross-module integration phase
==================================================================
```

Once the user approves or completes this HR-BF freeze, the `Employee` entity, `EmployeeRepository`, deterministic mock repository, and `EmployeeDirectoryCubit` can be implemented immediately with 100% compliance and zero guesswork.
