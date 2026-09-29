# HR-7.2 — PAYROLL INPUT & POLICY CONTRACT SPECIFICATION
## Enterprise CRM — Payroll Calculation & Validation

**Document Version:** 1.0.0  
**Phase:** HR-7.2 — Payroll Input & Policy Contract  
**Execution Date:** 2026-09-29  
**Branch:** `feature/hr-7-payroll-calculation`  
**Baseline HEAD Commit:** `5da50d0` (`docs(hr): audit payroll calculation requirements (HR-7.1)`)  
**Status:** `INPUT CONTRACT AUDIT COMPLETE — POLICY APPROVAL PENDING`  

---

## 1. Purpose and Scope

### 1.1 Objective
The purpose of checkpoint **HR-7.2** is to establish the authoritative input contract and policy framework governing payroll calculations in the Enterprise CRM application. 

This contract formally establishes:
1. The exact inventory of candidate input data required to execute payroll computations.
2. The authoritative ownership, source layer, and lifecycle of each input.
3. The structural separation between workforce identity, period boundaries, attendance records, and compensation values.
4. The handling of missing, optional, invalid, and overridden input values.
5. The boundaries between client-side calculation preview and backend-authoritative persistence.

### 1.2 Non-Implementation Guarantee
In accordance with mandatory project rules:
- **No production calculation logic or statutory formula implementations are introduced during HR-7.2.**
- No assumed statutory rates (PF 12%, ESI 0.75%, TDS slabs) are treated as confirmed.
- Existing HR-6 entities (`PayrollPeriod`, `PayrollRecord`) remain completely untouched.

---

## 2. Starting Git Baseline

| Metric | Recorded Value | Verification Source |
|---|---|---|
| **Active Branch** | `feature/hr-7-payroll-calculation` | `git branch --show-current` |
| **Baseline HEAD Commit** | `5da50d0` | `git rev-parse HEAD` |
| **Commit Subject** | `docs(hr): audit payroll calculation requirements (HR-7.1)` | `git log -1 --oneline` |
| **Working Tree Status** | Clean for HR-7 files; unrelated HR-5.7 KPI scratch files preserved intact | `git status` |
| **Parent Integration Baseline** | `bff4973` (`feature/hr-6-payroll-foundation` HEAD) | Git commit graph |

---

## 3. HR-7.1 Dependency Verification

The HR-7.1 audit deliverable ([HR_7_CALCULATION_REQUIREMENTS.md](file:///c:/Users/vkcha/Desktop/Assets/project/enterprise_crm/HR_7_CALCULATION_REQUIREMENTS.md)) was audited and verified:
1. **Status:** `AUDIT COMPLETE — CALCULATION FREEZE BLOCKED BY BUSINESS DECISIONS`.
2. **Key Finding:** Zero calculation formulas (gross, net, statutory deductions, LOP divisors) have been approved by the project owner or instructor backend.
3. **Missing Source Identified:** `Employee` intentionally excludes salary data (`employee.dart` line 5); no base compensation store currently exists in the application.
4. **Scope Preservation:** Ephemeral calculation preview model defined; client-side calculation prohibited from mutating stored HR-6 `PayrollRecord` rows.

---

## 4. Reviewed Source Material

The input contract was synthesized from an audit of the following authoritative sources:
- `lib/features/hr/domain/entities/employee.dart`
- `lib/features/hr/domain/entities/attendance_record.dart`
- `lib/features/hr/domain/entities/payroll_period.dart`
- `lib/features/hr/domain/entities/payroll_record.dart`
- `lib/features/hr/domain/repositories/payroll_repository.dart`
- `lib/features/hr/domain/repositories/employee_repository.dart`
- `lib/features/hr/data/repositories/mock_payroll_repository.dart`
- `lib/features/hr/data/mock/mock_payroll_store.dart`
- `lib/features/auth/domain/policies/hr_access_policy.dart`
- `context/MASTER_DEVELOPMENT_RULES.md`
- `context/HR_PAYROLL_REQUIREMENTS.md`
- `HR_7_CALCULATION_REQUIREMENTS.md`

---

## 5. Confirmed Input Inventory

To compute or simulate payroll for an individual employee within a specific period, the calculation engine requires inputs from four distinct functional domains:

```text
+-----------------------------------------------------------------------------------+
|                           PAYROLL INPUT DOMAINS                                   |
+-----------------------------------------------------------------------------------+
| 1. WORKFORCE IDENTITY (Employee)                                                  |
|    - employeeId: String (Required, Foreign Key to Employee.id)                    |
|    - employmentStatus: EmploymentStatus (Required, must be Active)                |
|    - joiningDate: DateTime? (Optional, UTC normalized)                            |
|                                                                                   |
| 2. PERIOD BOUNDARIES (PayrollPeriod)                                              |
|    - periodId: String (Required, Foreign Key to PayrollPeriod.id)                 |
|    - startDate: DateTime (Required, UTC normalized midnight)                      |
|    - endDate: DateTime (Required, UTC normalized midnight)                        |
|                                                                                   |
| 3. BASE COMPENSATION STRUCTURE (EmployeeSalaryProfile — Proposed)                 |
|    - baseSalary: Money (Required, contracted monthly compensation)                |
|    - currency: String (Required, ISO-4217 code, e.g. 'INR')                       |
|    - fixedAllowances: List<EarningComponent> (Optional itemized allowances)       |
|    - fixedDeductions: List<DeductionComponent> (Optional itemized deductions)     |
|                                                                                   |
| 4. PERIODIC ADJUSTMENTS (Attendance & Overrides — Optional)                       |
|    - unpaidLeaveDays: int? (Optional, days of Loss of Pay)                        |
|    - manualAdjustments: List<AdjustmentLineItem>? (Optional, approved overrides)  |
+-----------------------------------------------------------------------------------+
```

---

## 6. Input Contract Register

| Input ID | Business Meaning | Source | Data Type | Required? | Effective Date | Classification | Evidence / Source Document |
|---|---|---|---|---|---|---|---|
| **INP-01** | Employee Identifier | `Employee.id` | `String` | **YES** | At calculation | **CONFIRMED** | `Employee.dart` line 8 |
| **INP-02** | Employment Status | `Employee.employmentStatus` | `EmploymentStatus` | **YES** | Current | **CONFIRMED** | `Employee.dart` line 15 |
| **INP-03** | Date of Joining | `Employee.joiningDate` | `DateTime?` | NO | Inception | **CONFIRMED** | `Employee.dart` line 16 |
| **INP-04** | Payroll Period Identifier | `PayrollPeriod.id` | `String` | **YES** | At calculation | **CONFIRMED** | `PayrollPeriod.dart` line 11 |
| **INP-05** | Period Start Date | `PayrollPeriod.startDate` | `DateTime` | **YES** | Period Start | **CONFIRMED** | `PayrollPeriod.dart` line 13 |
| **INP-06** | Period End Date | `PayrollPeriod.endDate` | `DateTime` | **YES** | Period End | **CONFIRMED** | `PayrollPeriod.dart` line 14 |
| **INP-07** | Contracted Base Salary | `EmployeeSalaryProfile` | `Money` | **YES** | Effective Date | **UNCONFIRMED** | Missing in current schema |
| **INP-08** | Currency Code | `EmployeeSalaryProfile` | `String` | **YES** | Effective Date | **PROPOSED** | Defaults to ISO `'INR'` |
| **INP-09** | Itemized Allowances | `EmployeeSalaryProfile` | `List<Component>` | NO | Effective Date | **UNCONFIRMED** | `HR_PAYROLL_REQUIREMENTS.md` §15.1 |
| **INP-10** | Itemized Deductions | `EmployeeSalaryProfile` | `List<Component>` | NO | Effective Date | **UNCONFIRMED** | `HR_PAYROLL_REQUIREMENTS.md` §15.2 |
| **INP-11** | Unpaid Absence Days (LOP) | `AttendanceRepository` | `int` | NO | Period Window | **UNCONFIRMED** | `AttendanceRecord.dart` line 7 |
| **INP-12** | Overtime Hours | Time-tracking | `double` | NO | Period Window | **APPROVED DEFERRED** | `HR_PAYROLL_REQUIREMENTS.md` §15.4 |
| **INP-13** | One-Time Adjustments | Manual Override | `List<Adjustment>`| NO | Single Period | **PROPOSED** | HR-7.6 Preview Feature |

---

## 7. Employee Identity Contract

### 7.1 Relational Invariants
1. **Primary Reference:** The calculation engine consumes `Employee.id` exclusively as the stable workforce foreign key.
2. **Prohibition of Soft References:** Identity must NEVER be inferred from `fullName`, `email`, `phone`, `department`, `designation`, or list indices.
3. **Decoupling from CRM Login (`userId`):**
   - An employee might not have an associated CRM login account (`userId == null`).
   - Calculations operate on the physical workforce identity (`Employee.id`), not the authenticated actor's `CRM User ID`.
4. **Resolution Failure:**
   - If an `Employee.id` cannot be resolved via `EmployeeRepository.getEmployeeById()`, the calculation service must return a controlled `InputValidationIssue(code: 'EMPLOYEE_NOT_FOUND')`.
   - The engine must NEVER substitute a default or random employee.

---

## 8. Payroll Period Input Contract

### 8.1 Period Semantics
1. **Identity:** Calculations are bound to a single `PayrollPeriod.id`.
2. **Date Invariant:** `startDate` and `endDate` are normalized UTC dates where `startDate.isBefore(endDate)` or `startDate.isAtSameMomentAs(endDate)`.
3. **Inclusive Calendar Boundaries:** Both `startDate` and `endDate` represent inclusive days. A period from 2026-01-01 to 2026-01-31 encompasses exactly 31 calendar days.
4. **No Speculative Periods:** Calculations cannot be executed against synthetic or non-existent period IDs. The period must be backed by the authoritative repository or mock store.

### 8.2 Effective-Date Matching
- An employee's compensation profile must be valid for the target period.
- If an employee's `joiningDate` is strictly after `period.endDate`, the calculation is rejected as `INVALID_PERIOD_FOR_EMPLOYEE` (cannot pay an employee before they joined the organization).

---

## 9. Salary and Compensation Input Semantics

### 9.1 The Missing Base Compensation Store
- In Phase HR-1 through HR-6, compensation data was intentionally excluded from `Employee` to protect data privacy.
- In HR-6, `PayrollRecord` stored pre-computed historical figures (`grossSalary`, `netSalary`) but did not define an ongoing compensation contract.
- **Architectural Specification for HR-7.2:**
  To supply inputs cleanly without modifying `Employee`, we specify the abstract input model:
  ```dart
  class EmployeeSalaryProfile {
    final String employeeId;
    final Money baseSalary;
    final String currency;
    final List<EarningItemContract> allowances;
    final List<DeductionItemContract> deductions;
    final DateTime effectiveFrom;
  }
  ```
- **Authority Status:** While the abstract contract structure is ready, actual persistence of salary profiles remains **BACKEND-DEPENDENT** and requires instructor API confirmation.

---

## 10. Attendance and Leave Dependencies

### 10.1 Active Codebase Constraints
In `lib/features/hr/domain/entities/attendance_record.dart`:
> *"Line 7: Working hours and payroll calculations are strictly excluded."*

### 10.2 Mandatory Rules for HR-7:
1. **No Automatic Absence Penalty:** The calculation engine must NOT automatically deduct salary for `Absent` records unless an explicit Loss of Pay (LOP) policy is supplied as an approved input.
2. **No Presumed Absence on Missing Attendance:** If no attendance record exists for an employee on a given day, the client must NOT assume the employee was absent.
3. **Attendance Divisor Status:** The mathematical divisor for calculating a single day's deduction ($\frac{\text{Base Pay}}{30}$ vs $\frac{\text{Base Pay}}{26}$ vs $\frac{\text{Base Pay}}{\text{Days in Month}}$) remains **UNCONFIRMED**.
4. **Policy Boundary:** In HR-7.2, attendance input is treated as an **optional, explicit numeric count of unpaid absence days (`unpaidLeaveDays`)**, passed directly into the input contract rather than inferred dynamically from raw attendance tables.

---

## 11. Earnings Input Definitions

| Component | Status | Required / Optional | Input Structure | Validation Rule |
|---|---|---|---|---|
| **Base Salary** | **UNCONFIRMED** | **REQUIRED** | Immutable `Money` | Must be strictly positive ($> 0$). |
| **House Rent Allowance (HRA)** | **UNCONFIRMED** | OPTIONAL | Fixed `Money` or % of Base | Non-negative ($\ge 0$). |
| **Dearness Allowance (DA)** | **UNCONFIRMED** | OPTIONAL | Fixed `Money` or % of Base | Non-negative ($\ge 0$). |
| **Conveyance Allowance** | **UNCONFIRMED** | OPTIONAL | Fixed `Money` | Non-negative ($\ge 0$). |
| **Special Allowance** | **UNCONFIRMED** | OPTIONAL | Fixed `Money` | Non-negative ($\ge 0$). |

**Contract Rule:** In HR-7, earning components are defined as discrete, named line items. The calculation engine must accept arbitrary valid earning items rather than relying on hardcoded fields.

---

## 12. Deduction Input Definitions

| Component | Status | Required / Optional | Input Structure | Validation Rule |
|---|---|---|---|---|
| **Provident Fund (PF)** | **UNCONFIRMED** | OPTIONAL | Explicit `Money` or rule tag | Capped at statutory limit if specified. |
| **Employee State Insurance (ESI)**| **UNCONFIRMED** | OPTIONAL | Explicit `Money` or rule tag | Evaluated against gross threshold. |
| **Income Tax Withholding (TDS)**| **BACKEND-DEPENDENT**| OPTIONAL | Explicit `Money` | Supplied by backend tax engine. |
| **Professional Tax (PT)** | **UNCONFIRMED** | OPTIONAL | Explicit `Money` | State slab based. |
| **Loss of Pay (LOP)** | **UNCONFIRMED** | OPTIONAL | Explicit `Money` or day count | Non-negative ($\ge 0$). |

**Contract Rule:** Because statutory deduction formulas are not confirmed, deduction inputs must be supplied as explicit monetary amounts or deferred to backend evaluation.

---

## 13. Monetary Policy Contract

The calculation engine must operate under strict financial integrity rules:

1. **Precision Rule:** Zero floating-point (`double`) arithmetic. All financial operations must use exact integer minor units (paisa/cents) encapsulated in an immutable `Money` value object.
2. **Currency Consistency:** All components within an individual calculation must share the identical ISO-4217 currency code (e.g., `'INR'`). Cross-currency addition or subtraction throws an `IncompatibleCurrencyException`.
3. **Explicit Zero Semantics:** A component with an explicit amount of zero (₹0.00) is mathematically valid and distinct from a missing/omitted component (`null`).
4. **Negative Value Behavior:** An individual earning or deduction component cannot be negative. If aggregate deductions exceed gross earnings, the resulting net payable is negative, triggering a `NegativeNetPayIssue` validation flag rather than silent truncation to zero.
5. **Rounding:** Intermediate components round to nearest minor unit using half-up midpoint rounding:
   $$\text{paise} = \lfloor \text{value} + 0.5 \rfloor$$

---

## 14. Missing, Optional, and Invalid Inputs

| Scenario | Behavior | Error / Warning Code |
|---|---|---|
| **Missing Employee ID** | Hard Rejection (Throws `ArgumentError`) | `EMPTY_EMPLOYEE_ID` |
| **Unknown Employee ID** | Validation Failure | `EMPLOYEE_NOT_FOUND` |
| **Missing Period ID** | Hard Rejection (Throws `ArgumentError`) | `EMPTY_PERIOD_ID` |
| **Unknown Period ID** | Validation Failure | `PERIOD_NOT_FOUND` |
| **Missing Base Salary** | Validation Failure | `MISSING_BASE_SALARY` |
| **Joining Date After Period** | Validation Failure | `INVALID_PERIOD_FOR_EMPLOYEE` |
| **Currency Mismatch** | Hard Rejection (Throws `CurrencyMismatchException`) | `CURRENCY_MISMATCH` |
| **Inactive Employment Status** | Validation Warning (Allowed with flag) | `EMPLOYEE_NOT_ACTIVE` |
| **Deductions Exceed Gross** | Calculation Succeeds + Warning Flag | `NEGATIVE_NET_PAYABLE` |

---

## 15. Override and Authorization Policy

1. **Authorization Gate:**
   - Viewing or modifying calculation inputs is strictly restricted to users with `CrmPermissions.payrollView` or `AccountType.admin`.
   - General HR users (`hr.view`) are blocked with `AccessRestrictedScreen`.
2. **Override Permissions:**
   - Only `admin` or authorized payroll officers may supply temporary manual adjustment line items (e.g., one-off discretionary bonuses or penalty clawbacks).
   - All overrides must include an explicit `reason` string and audit author tag.
3. **Non-Destructive Overrides:**
   - A client-side calculation override affects only the active ephemeral preview calculation. It does NOT mutate master employee records or historical payroll store data.

---

## 16. Historical-Data Requirements

1. **Immutability of Finalized Runs:** Calculations must NEVER alter or overwrite previously finalized `PayrollRecord` rows in `PayrollRepository`.
2. **Reproducibility Invariant:** Given the identical input profile (base salary, days absent, period dates), the calculation engine must produce the exact identical monetary output deterministically.
3. **Rule Versioning:** Each calculation output must record the metadata identifier of the rule set applied (e.g., `'RULE_SET_V1_MOCK'`).

---

## 17. Input Ownership Matrix

| Data Category | Authoritative Owner | Retrieval Mechanism | Override Allowed? | Client Mutability |
|---|---|---|---|---|
| **Employee Identity** | `EmployeeRepository` | `getEmployeeById(id)` | NO | Read-Only |
| **Payroll Period** | `PayrollRepository` | `getPayrollPeriodById(id)` | NO | Read-Only |
| **Base Compensation** | Instructor Backend / Mock Store | Proposed Service Interface | Admin Only | Preview Only |
| **Attendance Days** | `AttendanceRepository` / Backend | Aggregated Period Query | Admin Only | Preview Only |
| **Statutory Rates** | Instructor Backend | Remote Configuration | NO | Immutable |
| **Calculation Preview** | Ephemeral Cubit State | `PayrollCalculationInput` | YES | In-Memory Only |

---

## 18. Backend Dependencies

The following capabilities are confirmed as backend-owned and cannot be finalized on the client:
1. **Master Salary Profiles Database:** Authoritative storage and CRUD APIs for employee compensation packages.
2. **Yearly Tax Slab Engine (TDS):** Complex calculation of income tax withholding based on tax declarations.
3. **Payroll Batch Locking:** Official closing and finalization of payroll periods.
4. **Disbursement:** Integration with banking and payment rails.

---

## 19. Unresolved Decisions

The following business rules remain unapproved by the project owner and block statutory calculation implementation:
1. **Base Salary Breakdown:** Fixed percentage vs stored absolute numbers for HRA, DA, and Special Allowances.
2. **Statutory Deduction Schemes:** Confirmation of applicable national jurisdiction (India EPFO/ESIC vs other).
3. **Loss of Pay (LOP) Divisor:** Selection of standard divisor (30 days vs 26 working days vs calendar days).
4. **Overtime Multipliers:** Hourly overtime pay rates.

---

## 20. HR-7.3 Implementation Readiness

With the input contract formally specified in HR-7.2, the technical foundation for **HR-7.3 (Monetary & Calculation Domain Foundation)** is fully defined:

### Safe Scope for HR-7.3:
1. **`Money` Value Object:** Immutable, 64-bit integer minor units (paisa/cents), ISO-4217 currency code, precision arithmetic (`+`, `-`, `*`), equality, formatting, and zero/negative handling.
2. **`PayrollCalculationInput` Entity:** Immutable domain container binding `employeeId`, `payrollPeriodId`, `baseSalary` (`Money`), optional allowances, optional deductions, and optional unpaid leave days.
3. **`PayrollCalculationResult` Entity:** Immutable ephemeral output container binding `calculationId`, `employeeId`, `payrollPeriodId`, `grossEarnings` (`Money`), `totalDeductions` (`Money`), `netPayable` (`Money`), and validation issues list.
4. **`CalculationValidationIssue` Value Object:** Typed domain model for validation warnings and errors (`code`, `message`, `severity`).

---

## 21. Explicitly Deferred Requirements

1. **Statutory Tax Calculators:** PF, ESI, TDS calculation engines deferred to backend or future approved subphases.
2. **Automated Attendance Sync:** Real-time polling and parsing of raw biometric logs.
3. **PDF Payslip Rendering:** Deferred to document pipeline.
4. **Direct Database Writeback:** Client calculation engine remains preview-only; persistence deferred.

---

## 22. HR-7.2 Exit Criteria & Completion Gate

- [x] HR-7.1 findings and baseline reviewed and verified.
- [x] Candidate input inventory compiled and classified.
- [x] Input Contract Register established with 13 discrete fields.
- [x] Employee identity contract decoupled from CRM login.
- [x] Payroll period boundary invariants documented.
- [x] Absence of base salary in `Employee` addressed via abstract input model.
- [x] Attendance dependency policy bounded (optional explicit absence count; no automatic salary clawback).
- [x] Monetary policy defined (prohibition of floats, integer minor units, currency consistency).
- [x] Missing and invalid input handling specified.
- [x] Override and authorization policies reviewed.
- [x] Input ownership matrix established.
- [x] Backend dependencies and unresolved business questions documented.
- [x] Technical readiness for HR-7.3 domain models confirmed.
- [x] Dedicated Git commit created and verified.

---

## 23. Final Status

**FINAL STATUS:**  
`INPUT CONTRACT AUDIT COMPLETE — POLICY APPROVAL PENDING`

*(The input contract structure and domain interfaces are 100% defined and ready for HR-7.3 domain implementation. Statutory deduction policies and salary proration business rules remain pending formal stakeholder approval).*
