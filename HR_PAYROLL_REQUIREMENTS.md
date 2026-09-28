# HR-6.1 — Payroll Requirements Audit & Business Freeze Report

**Date:** 2026-09-28  
**Project:** Enterprise CRM (`c:\Users\vkcha\Desktop\Assets\project\enterprise_crm`)  
**Feature Branch:** `feature/hr-6-payroll-foundation`  
**Git Baseline HEAD:** `825ac57f75a2e418907ed5f069d646a6d6ba2dba`  
**Status:** HR-6.1 AUDIT COMPLETE / REQUIREMENTS FROZEN FOR HR-6.2  

---

## 1. Purpose and Scope

This document establishes the verified requirements, architectural boundaries, privacy rules, and frozen domain specifications for **Payroll Foundation & Read-Only Payroll Management** in the Enterprise CRM HR / Payroll module.

Following the mandatory governance rules established in `MASTER_DEVELOPMENT_RULES.md`, `CRM_PRD.md`, `CRM_TRD.md`, `CRM_Backend_Schema.md`, and the precedents set in `HR_REQUIREMENTS.md` (HR-0) and `HR_KPI_REQUIREMENTS.md` (HR-5.1), this checkpoint (**HR-6.1**) audits the codebase, verifies previous phase status, classifies all proposed and unconfirmed payroll concepts, and freezes the minimal non-speculative contract required for the domain foundation (**HR-6.2**).

### Primary HR-6.1 Directives:
1. **Strictly Read-Only:** Phase 6 focuses exclusively on read-only domain models, repository abstractions, and viewing interfaces. All payroll mutations, processing routines, and statutory calculations are strictly excluded.
2. **Evidence-Based Contract:** No field, formula, or permission is treated as approved without explicit codebase or PRD evidence. Proposed backend schemas (`CRM_Backend_Schema.md`) are treated as tentative integration drafts, not authoritative requirements.
3. **No Speculative Calculations:** The Flutter client must NEVER calculate gross, net, deductions, tax, PF, ESI, or overtime. The client displays only stored values provided by the authoritative data source.
4. **Implementation Plan:** Define the exact domain entities to be implemented in HR-6.2 and repository contracts for HR-6.3.

---

## 2. Starting Git State

Before initiating modifications, repository inspection was conducted:
- **Active Feature Branch:** `feature/hr-6-payroll-foundation` (branched from `feature/hr-5-kpi` at commit `825ac57`)
- **Baseline Git HEAD:** `825ac57f75a2e418907ed5f069d646a6d6ba2dba` (`feat(hr): implement KPI add and edit (HR-5.6)`)
- **Working Tree Inspection:**
  - Preserved unrelated modified files: `.gitignore`, `lib/features/hr/presentation/screens/employee_kpi_list_screen.dart`, `test/features/hr/presentation/navigation/hr_kpi_navigation_test.dart`.
  - Preserved unrelated untracked files: HR-5.7 summary cubit/state/screens and tests (`employee_kpi_summary_cubit.dart`, `employee_kpi_summary_screen.dart`, etc.).
  - No unrelated files reset, discarded, or staged.
- **Verification Baseline:**
  - Flutter Analyzer: Clean (0 issues found).
  - HR Targeted Tests: 269 / 269 PASS.
  - Previous submodules verified in baseline: HR-1 (Core Employee), HR-2 (Employee Documents), HR-3 (Employee Directory & Details), HR-4 (Attendance Management), HR-5 (KPI Management through HR-5.6).

---

## 3. HR-5 Dependency Verification

In accordance with mandatory audit rules, the completion status of Phase 5 (Employee KPI Management) was inspected:

1. **Commit History Check:**
   - Commit `825ac57` (`feat(hr): implement KPI add and edit (HR-5.6)`) represents the latest committed HR-5 checkpoint.
   - HR-5.7 (`KPI Summary & Visualization`) exists as untracked/unstaged working files in the working directory.
   - HR-5.8 (`Employee Details KPI Integration`), HR-5.9 (`Full KPI Permission Integration`), and HR-5.10 (`Final KPI UAT`) have NOT been committed.
2. **Manual Acceptance Check:**
   - Inspection of `doc/HR_Payroll_Manual_UAT.md` verifies that the overall manual UAT status is **"Not Started"**.
   - No acceptance checkboxes are signed off for HR-5 (H5-01 through H5-28) or Final UAT (FINAL-01 through FINAL-20).
3. **Dependency Assessment:**
   - **HR-5 manual acceptance remains outstanding.**
   - In compliance with project rules, HR-5 is NOT marked complete.
   - HR-6 begins on the approved baseline with this dependency explicitly recorded.
   - No HR-1 through HR-5 business semantics, models, or tests will be altered during Payroll development.

---

## 4. Existing HR Architecture

The HR module in Enterprise CRM adheres to a strict feature-first, layered architecture:

```text
Flutter Presentation (Screens, Widgets, Dialogs)
     ↓
BLoC / Cubit (State Management, View State)
     ↓
Domain Layer (Entities, Value Objects, Policies, Repository Interfaces)
     ↓
Data Layer (Repositories, In-Memory Mock Stores with Copy Isolation)
     ↓
Backend Integration Layer (Future Dio / REST integration with Instructor backend)
```

### Established Conventions from HR-1 through HR-5:
1. **Domain Entity Location:** `lib/features/hr/domain/entities/`.
2. **Immutability Pattern:** Plain Dart classes with `final` fields, null-safe typing, `const` or validating constructors, and `copyWith` preserving required and optional field semantics.
3. **Equality & Hashing:** Manual `operator ==(Object other)` using `identical(this, other)`, `runtimeType == other.runtimeType`, and value field equality; `hashCode` implemented via `Object.hash(...)`. No `Equatable` or code-generation packages (`Freezed`) permitted.
4. **Repository Abstraction:** `abstract interface class` defined in `lib/features/hr/domain/repositories/` declaring strongly-typed `Future` methods.
5. **Exception Pattern:** Strongly-typed domain exceptions (`EmployeeException`, `AttendanceException`, `EmployeeKpiException`) containing clear, non-leaking error messages.
6. **Mock Data Organization:** Isolated in-memory stores (`MockEmployeeStore`, `MockAttendanceStore`, `MockEmployeeKpiStore`) utilizing defensive cloning on read/write and deterministic fixtures.
7. **Dependency Injection:** Constructor injection at composition root (`CrmApp` / Screen constructors) with fallback to default mock instances. No service locators (`GetIt`).
8. **Date Representation:** Calendar dates are normalized to UTC midnight (`DateTime.utc(year, month, day)`) to eliminate cross-platform timezone anomalies.
9. **Authorization Pattern:** Centralized policy evaluation via `HrAccessPolicy` delegating to `AccessPolicy`, `CurrentUser`, `CrmModule.hrPayroll`, and specific permissions (`CrmPermissions.hrView`, `CrmPermissions.payrollView`).

---

## 5. Confirmed Payroll Requirements

The following requirements are confirmed by existing codebase evidence:

1. **Module Identity:** Payroll is an integral part of `CrmModule.hrPayroll` (`lib/features/auth/domain/entities/crm_module.dart`).
2. **Dedicated Operational Permission:**
   - `CrmPermissions.payrollView` ('payroll.view') is explicitly defined and canonically mapped to `CrmModule.hrPayroll` (`lib/features/auth/domain/policies/crm_permissions.dart`).
   - Registered in `MockPermissionCatalog` with display name `'View Payroll'` (`lib/features/user_management/data/mock/mock_permission_catalog.dart`).
3. **Centralized Access Evaluation:**
   - `HrAccessPolicy.canViewPayroll(CurrentUser user)` is already implemented (`lib/features/hr/domain/policies/hr_access_policy.dart`).
   - Requires `user.isAdmin` OR `AccessPolicy.hasPermission(user, CrmPermissions.payrollView)`.
4. **Privacy Separation from General HR:**
   - Standard HR view permission (`hr.view`) does **NOT** grant salary or payroll visibility.
   - An HR user with only `hr.view` can access Employee Directory, Documents, Attendance, and KPIs, but is strictly blocked from Payroll data.
5. **Workforce Identity Relationship:**
   - Payroll records reference the authoritative workforce entity `Employee.id` via a non-nullable `employeeId`.
   - Employee identity must never be inferred from employee name, email, department, or list index.
6. **Periodic Structure:**
   - Payroll is structured around distinct evaluation/disbursement periods (`PayrollPeriod`).
   - Every payroll record must reference a valid `payrollPeriodId`.
7. **Read-Only Scope for Phase 6:**
   - Phase 6 covers reading payroll periods, reading payroll records, reading per-employee payroll history, and inspecting payroll details.

---

## 6. Proposed Payroll Requirements

The proposed backend schema (`CRM_Backend_Schema.md` §6.7) states:
> *"Payroll may need `payroll_periods`, `payroll_records`, allowances, deductions, and payslip file references. Payroll details are not fully defined in the available requirements, so this area must be confirmed before implementation."*

From this tentative proposal and standard enterprise CRM patterns, the following concepts are classified as **PROPOSED**:

1. **`PayrollPeriod` Entity:**
   - `id`: Stable unique identifier string.
   - `name`: Human-readable label (e.g., 'January 2026', 'February 2026').
   - `startDate`: Normalized UTC start date.
   - `endDate`: Normalized UTC end date.
   - `paymentDate`: Optional normalized UTC disbursement date.
2. **`PayrollRecord` Entity:**
   - `id`: Stable unique identifier string.
   - `employeeId`: Foreign key to `Employee.id`.
   - `payrollPeriodId`: Foreign key to `PayrollPeriod.id`.
   - Stored compensation fields (nullable, stored as received, never computed):
     - `grossSalary`: Total pre-deduction earnings.
     - `netSalary`: Total payable take-home earnings.
     - `totalAllowances`: Optional total additions.
     - `totalDeductions`: Optional total subtractions.
     - `currency`: Optional ISO currency code string (e.g., 'INR', 'USD').
     - `paymentStatus`: Optional stored status string (e.g., 'Paid', 'Pending', 'Processing').
     - `paymentDate`: Optional actual payment date.
     - `remarks`: Optional administrative remarks.

---

## 7. Unconfirmed Business Rules

The following rules have **NOT** been approved and must **NOT** be implemented:

1. **Salary Calculation Formulas:**
   - Formulas such as `grossSalary = basicSalary + allowances`, `netSalary = grossSalary - deductions`, or `deductions = tax + pf + esi` are **UNCONFIRMED**.
   - The Flutter client must NEVER perform client-side salary arithmetic or assert formula reconciliation.
2. **Statutory Deduction Schemes:**
   - Provident Fund (PF @ 12%), Employee State Insurance (ESI @ 0.75%), Tax Deducted at Source (TDS slab calculations), and Professional Tax are unconfirmed and jurisdiction-dependent.
   - No statutory rules will be hardcoded.
3. **Automated Period Generation:**
   - Generating 12 calendar periods for every year automatically is **PROHIBITED**.
   - Period generation is owned by the authoritative backend / mock store.
4. **Period Overlap Invariants:**
   - Whether payroll periods may overlap (e.g., standard vs off-cycle vs bonus runs) is unconfirmed. The client will not impose overlap blocks.
5. **Fixed Period Status Lifecycle:**
   - Status enums like `Draft`, `Processing`, `Finalized`, `Paid`, `Closed`, `Cancelled` are unconfirmed.
   - Status will be stored as an optional free string if supplied, not an enforced finite state machine.
6. **Duplicate Record Policy:**
   - Whether an employee can have multiple payroll records within the same period (e.g., adjustment runs) is backend-dependent.
7. **Currency Conversion:**
   - Multi-currency conversion rates and FX calculations are strictly excluded.
8. **Negative Amount Policy:**
   - Client will not artificially reject negative salary values (which may represent net clawbacks or adjustments in backend accounting).

---

## 8. Backend-Dependent Requirements

The following responsibilities belong to the authoritative instructor backend:

1. **Master Salary Structure & Computation:** Backend computes all earnings, deductions, taxes, and final payable amounts.
2. **Payroll Run Execution & Finalization:** Backend initiates, processes, locks, and finalizes payroll periods.
3. **Disbursement & Payment Gateway Integration:** Backend coordinates bank transfers, UPI payouts, or payment file generation.
4. **Payslip Document Generation:** Backend renders PDF payslips and supplies download URLs or file identifiers.
5. **Server-Side Access Enforcement:** Backend verifies JWT/session tokens, enforcing 403 Forbidden when a user without `payroll.view` requests payroll endpoints.
6. **Data Masking:** Backend redacts sensitive financial fields if an employee accesses self-service records without full payroll administrative clearance.

---

## 9. Payroll Period Contract

### Proposed `PayrollPeriod` Representation:
```dart
class PayrollPeriod {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? paymentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### Frozen Period Rules for HR-6.2:
1. **Identity:** `id` is a required non-empty string uniquely identifying the period (e.g., `'period_2026_01'`).
2. **Label:** `name` is a non-empty human-readable string (e.g., `'January 2026'`) used in selection headers and dropdowns.
3. **Date Boundaries:**
   - `startDate` and `endDate` are required `DateTime` instances normalized to UTC midnight (`DateTime.utc(y, m, d)`).
   - Invariant: `!startDate.isAfter(endDate)` (start date must precede or equal end date).
   - End date represents an inclusive calendar date boundary.
4. **Payment Date:** `paymentDate` is an optional normalized UTC date capturing the scheduled or executed disbursement date.
5. **No Speculative Fields:** No status enum, no approval flag, no automatic month generator.

---

## 10. Payroll Record Contract

### Requirements Matrix for Domain Fields:

| Field | Business Meaning | Type | Required? | Classification | Source |
|---|---|---|---|---|---|
| `id` | Stable unique record identifier | `String` | Yes | **CONFIRMED** | Architectural baseline / Repository standard |
| `employeeId` | Foreign key referencing `Employee.id` | `String` | Yes | **CONFIRMED** | Workforce relational invariant |
| `payrollPeriodId` | Foreign key referencing `PayrollPeriod.id` | `String` | Yes | **CONFIRMED** | Periodic payroll structure |
| `grossSalary` | Stored total gross earnings before deductions | `double?` | No | **PROPOSED** | `CRM_Backend_Schema.md` §6.7 / Read-only contract |
| `netSalary` | Stored final net take-home earnings | `double?` | No | **PROPOSED** | `CRM_Backend_Schema.md` §6.7 / Read-only contract |
| `totalAllowances`| Stored aggregate allowances / additions | `double?` | No | **PROPOSED** | `CRM_Backend_Schema.md` §6.7 / Read-only contract |
| `totalDeductions`| Stored aggregate deductions / subtractions | `double?` | No | **PROPOSED** | `CRM_Backend_Schema.md` §6.7 / Read-only contract |
| `currency` | ISO currency code (e.g., 'INR', 'USD') | `String?` | No | **PROPOSED** | `CRM_Backend_Schema.md` §4 / Financial convention |
| `paymentStatus` | Stored payment status string (e.g., 'Paid') | `String?` | No | **PROPOSED** | Tentative status indicator |
| `paymentDate` | Normalized UTC date of actual payment | `DateTime?` | No | **PROPOSED** | Audit / disbursement history |
| `remarks` | Qualitative notes or adjustments | `String?` | No | **PROPOSED** | Administrative context |
| `createdAt` | Record creation timestamp | `DateTime?` | No | **CONFIRMED** | Standard audit metadata |
| `updatedAt` | Last modification timestamp | `DateTime?` | No | **CONFIRMED** | Standard audit metadata |

### Critical Nullability & Value Rules:
- `grossSalary` and `netSalary` are nullable (`double?`).
- **Null vs. Zero:** A `null` amount indicates unrecorded, pending, or redacted compensation. The domain model must NEVER substitute `null` with `0.0`.
- **No Float Arithmetic:** No arithmetic operations will be performed on amounts. Stored values are passed directly to formatting/presentation widgets.

---

## 11. Employee Identity Relationship

```text
Employee (authoritative workforce root)
   │
   ├── id: "emp_1" (unique, stable)
   ├── fullName: "Vikash Sharma"
   └── userId: "user_101" (optional CRM login)
         │
         ▼
   PayrollRecord
         ├── id: "pay_rec_101"
         ├── employeeId: "emp_1"  <── Foreign Key
         └── payrollPeriodId: "period_2026_01"
```

1. **Stable Identifier Reference:** `PayrollRecord.employeeId` strictly references `Employee.id`.
2. **Decoupling from CRM Login:** An employee does NOT need a linked CRM user account (`userId`) to have payroll records. Field staff, contractors, or operational employees without CRM access are fully supported.
3. **No Field Duplication:** `PayrollRecord` does not duplicate employee fields (`fullName`, `email`, `department`). Employee metadata is resolved by the UI/presentation layer via `EmployeeRepository.getEmployeeById`.
4. **Historical Persistence:** If an employee's employment status transitions to `terminated` or `inactive`, their historical payroll records remain accessible and unaltered.

---

## 12. Monetary Representation and Currency Decisions

1. **No Existing Value Object:** Inspection of `lib/` reveals no `Money` or `Currency` class in the existing codebase.
2. **Numeric Representation:** Following the established precedent of `EmployeeKpi` (`targetValue`, `actualValue`, `score` as `double`), amounts are represented as `double?`.
3. **Preservation of Stored Values:**
   - Amounts are preserved exactly as returned by the repository.
   - No rounding, truncating, or floating-point transformations in domain logic.
4. **Currency Handling:**
   - Represented as an optional `String? currency`.
   - The client does not assume 'INR' or 'USD' globally; it defaults gracefully when null or displays the provided currency code.
5. **No Negative Substitution:** Negative values (representing legitimate adjustments or recovery balances) are preserved without artificial validation blocks.

---

## 13. Payroll Authorization and Privacy Matrix

Payroll data constitutes sensitive financial information. Access must be strictly governed by `HrAccessPolicy`.

| Role / Capability | Module Entry (`hrPayroll`) | View Employee Directory | View Documents | View Attendance | View KPIs | View Payroll Periods | View Payroll Records / Salary |
|---|---|---|---|---|---|---|---|
| **Admin (`user.isAdmin`)** | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed | **Allowed** |
| **HR User (`hr.view` only)** | Allowed | Allowed | Allowed | Allowed | Allowed | **Blocked** | **Blocked** |
| **Payroll User (`hr.view` + `payroll.view`)** | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed | **Allowed** |
| **Payroll-Only User (`payroll.view` only)** | Allowed | **Blocked** | **Blocked** | **Blocked** | **Blocked** | Allowed | **Allowed** |
| **Standard User (no HR permissions)** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** |
| **Unassigned User (`hrPayroll` not in modules)** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** | **Blocked** |

### Authorization Guards:
- Direct navigation to Payroll screens will be guarded by:
  ```dart
  if (!HrAccessPolicy.canViewPayroll(user)) {
    return const AccessRestrictedScreen();
  }
  ```
- No user without `payroll.view` (or admin status) can view salary amounts.

---

## 14. Read-Only Operation Boundaries

Phase 6 is strictly limited to read-only capabilities:

### Approved HR-6 Operations:
1. **Read Payroll Periods:** Retrieve all available payroll periods.
2. **Read Single Period:** Retrieve details of a specific payroll period.
3. **Read Payroll Records:** Retrieve records for a selected period, optionally filtered by employee.
4. **Read Employee Payroll History:** Retrieve historical records for a specific employee across periods.
5. **Read Payroll Record Details:** Inspect the complete breakdown of a single payroll record.

### Prohibited Operations in HR-6:
- Create / Update / Delete Payroll Period
- Create / Update / Delete Payroll Record
- Calculate Salaries or Deductions
- Process or Run Payroll
- Finalize or Approve Payroll
- Execute Payments or Disbursements
- Generate or Download Payslip PDFs
- Export Payroll Reports

---

## 15. Explicitly Deferred Payroll Calculations

All financial calculations and processing workflows are deferred to subsequent phases (HR-7 and beyond) upon receipt of authoritative instructor backend specifications:

1. **Basic Salary & Allowances:** Calculation of HRA, DA, Special Allowance, Conveyance, Medical, and Performance Bonuses.
2. **Deductions:** Statutory computations for Employee PF, Employer PF, ESI, TDS (Income Tax withholding), and Professional Tax.
3. **Attendance-Based Proration:** Unpaid leave deductions (`Loss of Pay`), half-day proration, and working day multipliers.
4. **Overtime Multipliers:** Normal vs holiday overtime hourly rates.
5. **Reimbursements & Claims:** Travel and expense reimbursement additions.
6. **Net Pay Formulation:** The final equation linking gross earnings to total deductions.
7. **Payslip Document Pipeline:** PDF rendering, storage, signing, and distribution.

---

## 16. HR-6.2 Domain Entity Plan

During the upcoming **HR-6.2** checkpoint, the following domain files will be created in `lib/features/hr/domain/entities/`:

1. `payroll_period.dart`:
   - Class `PayrollPeriod` with immutable fields: `id`, `name`, `startDate`, `endDate`, `paymentDate`, `createdAt`, `updatedAt`.
   - UTC date normalization in constructor.
   - Date boundary invariant validation (`!startDate.isAfter(endDate)`).
   - `formattedPeriod` and `formattedPaymentDate` presentation getters.
   - `copyWith`, `operator ==`, `hashCode`, `toString`.
2. `payroll_record.dart`:
   - Class `PayrollRecord` with immutable fields: `id`, `employeeId`, `payrollPeriodId`, `grossSalary`, `netSalary`, `totalAllowances`, `totalDeductions`, `currency`, `paymentStatus`, `paymentDate`, `remarks`, `createdAt`, `updatedAt`.
   - Required identity and relational invariants (`id.isNotEmpty`, `employeeId.isNotEmpty`, `payrollPeriodId.isNotEmpty`).
   - Null-safe `copyWith` supporting explicit null clearing (`clearPaymentDate`, `clearRemarks`, etc.).
   - `operator ==`, `hashCode`, `toString`.
3. Unit Test Files:
   - `test/features/hr/domain/entities/payroll_period_test.dart`
   - `test/features/hr/domain/entities/payroll_record_test.dart`

---

## 17. HR-6.3 Repository Plan

For the subsequent checkpoint (**HR-6.3**), the repository layer will be implemented:
1. `PayrollRepository` abstract interface:
   - `Future<List<PayrollPeriod>> getPayrollPeriods();`
   - `Future<PayrollPeriod?> getPayrollPeriodById(String id);`
   - `Future<List<PayrollRecord>> getPayrollRecords({String? payrollPeriodId, String? employeeId});`
   - `Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId);`
   - `Future<PayrollRecord?> getPayrollRecordById(String id);`
2. `PayrollException`:
   - Typed domain exception with `message` and optional `code`.
3. `MockPayrollStore` & `MockPayrollRepository`:
   - In-memory store with defensive copy isolation.
   - Seeded periods (`period_2026_01`, `period_2026_02`).
   - Seeded records referencing existing employees (`emp_1`, `emp_2`, `emp_3`).

---

## 18. Risks and Open Decisions

1. **Risk — Premature Calculation Logic:** Any attempt to compute net pay from gross pay on the client risks diverging from the backend accounting engine.  
   *Mitigation:* Strict policy prohibiting client-side arithmetic.
2. **Risk — Salary Visibility Leakage:** Displaying payroll records to general HR users would violate financial confidentiality.  
   *Mitigation:* Enforcement of `CrmPermissions.payrollView` via `HrAccessPolicy.canViewPayroll`.
3. **Risk — Employee Self-Service Scope:** Whether non-admin employees can view their own payroll records via a dedicated self-service view remains unconfirmed.  
   *Mitigation:* Deferred until backend authentication and user-employee linkage are finalized.
4. **Open Decision — Monetary Precision:** Backend decimal representation (floating-point vs integer cents/paisa vs string) awaits final API specification.  
   *Mitigation:* Store as `double?` without modification.

---

## 19. HR-6.1 Exit Criteria

- [x] Existing HR architecture inspected and documented.
- [x] Previous HR checkpoint status verified (HR-5 manual UAT dependency reported).
- [x] Payroll requirements classified (Confirmed, Proposed, Unconfirmed, Deferred).
- [x] Payroll identity defined (`id` string).
- [x] Employee relationship documented (`employeeId` FK referencing `Employee.id`).
- [x] Payroll period requirements documented (`PayrollPeriod` contract).
- [x] Payroll record requirements documented (`PayrollRecord` contract).
- [x] Monetary precision and currency decisions documented.
- [x] Sensitive payroll permissions reviewed (`payroll.view` vs `hr.view`).
- [x] HR-6 read-only scope established.
- [x] HR-7 calculation responsibilities explicitly deferred.
- [x] Backend dependencies documented.
- [x] `HR_PAYROLL_REQUIREMENTS.md` accurately reflects actual evidence.
- [x] No speculative Payroll production code introduced during HR-6.1.
