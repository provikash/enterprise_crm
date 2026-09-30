# HR-7.9 — Permissions, Security & Calculation Audit

## 1. Purpose
This document presents the comprehensive security, authorization, privacy, and calculation integrity audit for the HR-7 Payroll Calculation & Validation module in the Enterprise CRM application. It audits calculation inputs, calculation outputs, route security, session transitions, cross-employee data isolation, error privacy, side-effect prevention, and client-vs-backend boundaries.

---

## 2. Starting Git Baseline
- **Branch:** `feature/hr-7-payroll-calculation`
- **Starting HEAD (HR-7.8):** `2318b03` (`feat(hr): integrate payroll calculation foundation (HR-7.8)`)
- **HR-7 Subphase Deliverables Verified Prior to Audit:**
  - HR-7.1: `5da50d0` (Requirements Audit)
  - HR-7.2: `3903a80` (Input / Policy Contract)
  - HR-7.3: `0902ceb` (Monetary Domain Foundation)
  - HR-7.4: `12e36a5` (Payroll Components)
  - HR-7.5: `b6c1f31` (Payroll Calculation Engine)
  - HR-7.6: `350354b` (Calculation Preview Workflow)
  - HR-7.7: `e77ad11` (Validation & Integrity Audit)
  - HR-7.8: `2318b03` (HR-6 Payroll Integration)

---

## 3. Approved Authorization Contract
The authorization contract is governed centrally by `HrAccessPolicy` (`lib/features/hr/domain/policies/hr_access_policy.dart`):
1. **System Administrator:** `user.isAdmin == true` (`AccountType.admin`). Holds unrestricted view and calculation preview privileges.
2. **Payroll Specialist:** Regular user with `CrmModule.hrPayroll` and explicit `CrmPermissions.payrollView`. Authorized to view payroll records, overview, history, details, and trigger calculation preview.
3. **General HR Specialist:** Regular user with `CrmModule.hrPayroll` and `CrmPermissions.hrView` only (lacking `payrollView`). Strictly **prohibited** from viewing payroll records or calculation preview.
4. **Restricted / Other CRM User:** Users without `payrollView` are completely blocked from payroll calculation routes and presentation surfaces.

---

## 4. Calculation Access Matrix

| Role / Permission Profile | View Overview | View Details | View Payroll History | View Calculation Preview | View Itemized Components | Status |
|---|---|---|---|---|---|---|
| Admin (`accountType == admin`) | Allowed | Allowed | Allowed | Allowed | Allowed | VERIFIED |
| Payroll Specialist (`payrollView`) | Allowed | Allowed | Allowed | Allowed | Allowed | VERIFIED |
| General HR (`hrView` only) | Blocked | Blocked | Blocked | Blocked | Blocked | VERIFIED |
| Unassigned / Sales / Marketing | Blocked | Blocked | Blocked | Blocked | Blocked | VERIFIED |
| Anonymous / Unauthenticated | Blocked | Blocked | Blocked | Blocked | Blocked | VERIFIED |

---

## 5. Route Security
- Direct instantiation and route entry of `PayrollCalculationPreviewScreen` evaluates `HrAccessPolicy.canViewPayroll(widget.user)` immediately at the top of `build()`.
- Unauthorized users receive `const AccessRestrictedScreen()` with zero leakage of preview controls, employee data, or monetary values.
- Cubit initialization is gated inside `initState` and `didUpdateWidget`; unauthorized sessions never instantiate or invoke `PayrollCalculationPreviewCubit`.
- No sensitive financial amounts or calculation formulas are transmitted via URL parameters or route arguments; routing relies solely on opaque IDs (`employeeId`, `payrollPeriodId`, `recordId`).
- **Status:** VERIFIED

---

## 6. Employee Isolation
- Preview calculations are scoped strictly to the `employeeId` present in the authoritative `PayrollCalculationInput`.
- Rapid switching between Employee 1 (`emp_001`) and Employee 2 (`emp_002`) updates the cubit state cleanly without caching or polluting prior financial information.
- Re-querying Employee 1 demonstrates deterministic isolation with zero cross-employee leakage.
- **Status:** VERIFIED

---

## 7. Session Isolation
- Transition from an authorized user to a restricted user (e.g., logout or role switch) immediately clears protected state:
  - `didUpdateWidget` detects authorization revocation, closes the internal cubit, invalidates `_cubit`, and renders `AccessRestrictedScreen`.
- Disposed or aborted calculation requests check `if (requestId != _activeRequestId || isClosed) return;` at all async continuation boundaries, preventing late emissions from leaking into inactive sessions.
- **Status:** VERIFIED

---

## 8. Sensitive Input & Output Review
- All monetary values are encapsulated within immutable `Money` domain objects using minor units (integer cents/paise).
- Calculation inputs and outputs only expose necessary salary components (base salary, itemized additions, itemized deductions).
- No unapproved personal data (PII) or unneeded credentials are accepted or rendered.
- Preview displays are clearly labelled with prominent non-final banners (`PREVIEW ONLY — NON-FINAL`).
- **Status:** VERIFIED

---

## 9. Logging & Error Privacy
- Audited codebase for `print()`, `debugPrint()`, and logging statements: 0 raw prints found in `lib/features/hr`.
- `toString()` methods across domain entities (`PayrollCalculationInput`, `PayrollCalculationResult`, `PayrollComponent`) were audited:
  - **Defect Identified & Fixed:** Prior `toString()` implementations dumped raw monetary numbers (`baseSalary`, `netPayable`, `amount`).
  - **Fix Applied:** Sanitized `toString()` across `PayrollCalculationInput`, `PayrollCalculationResult`, and `PayrollComponent` to omit raw minor-unit numbers, exposing only IDs, counts, and currency codes.
- Repository and engine exceptions caught in `PayrollCalculationPreviewCubit` emit sanitized user-facing error messages:
  `'Failed to generate payroll calculation preview. Please review inputs and try again.'`
  No internal SQL strings, server addresses, or stack traces are leaked to the UI or logs.
- **Status:** FIXED AND RETESTED (VERIFIED)

---

## 10. Calculation Tampering Assessment
- All arithmetic and financial calculations reside exclusively within the pure domain service `PayrollCalculationEngine`.
- The presentation layer (`PayrollCalculationPreviewScreen` and widgets) contains zero mathematical formulas, totals summation, or tax calculations.
- Displayed net pay, gross pay, and deductions strictly reflect formatted `Money` strings directly produced by the engine.
- UI manipulation cannot override or alter calculation outputs.
- **Status:** VERIFIED

---

## 11. Side-Effect & Immutability Audit
- Audited all HR-7 calculation code for mutating operations (`save`, `update`, `delete`, `approve`, `finalize`, `pay`, `process`, `persist`, `generatePayslip`):
  - Zero repository writes or persistent mutations are invoked during calculation preview.
  - Stored `PayrollRecord` in `MockPayrollRepository` / `MockPayrollStore` remains completely immutable when preview is triggered.
  - `PayrollCalculationResult.isPreview` is strictly `true`.
- **Status:** VERIFIED

---

## 12. Frontend vs Backend Security Boundary
- The current client-side checks (`HrAccessPolicy`) ensure robust, privacy-respecting UX and prevent accidental frontend access.
- **Critical Architectural Boundary:** Client-side route and cubit guards cannot substitute for authoritative backend authorization.
- When backend integration occurs (HR-10 / Instructor Backend):
  - The backend API must independently enforce JWT token verification, RBAC, tenant isolation, and record-level authorization on all calculation endpoints.
  - The client will treat backend calculation responses as authoritative and verify signatures/IDs.
- **Status:** VERIFIED (Documented as HR-10 dependency)

---

## 13. Defects Found

| Defect ID | Severity | Description |
|---|---|---|
| SEC-01 | MEDIUM | Domain entity `toString()` methods dumped raw financial amounts (`baseSalary`, `netPayable`, `amount`), risking accidental exposure in logging tools. |
| SEC-02 | HIGH | `_PayrollCalculationPreviewScreenState` lacked `didUpdateWidget`, causing state and cubit reuse when inputs or session credentials changed without widget recreation. |
| SEC-03 | MEDIUM | Direct reference to `_cubit` inside widget callbacks rather than `context.read<PayrollCalculationPreviewCubit>()` risked null pointer exceptions during session revocation. |

---

## 14. Fixes Applied

1. **SEC-01 Fix:** Sanitized `toString()` in:
   - `lib/features/hr/domain/entities/payroll_calculation_input.dart`
   - `lib/features/hr/domain/entities/payroll_calculation_result.dart`
   - `lib/features/hr/domain/entities/payroll_component.dart`
2. **SEC-02 Fix:** Implemented comprehensive `didUpdateWidget` in `_PayrollCalculationPreviewScreenState` (`lib/features/hr/presentation/screens/payroll_calculation_preview_screen.dart`):
   - Invalidation and disposal of `_cubit` on session authorization revocation.
   - Dynamic re-triggering of `calculatePreview` when `widget.input` changes across employees or periods.
3. **SEC-03 Fix:** Converted widget callbacks (refresh button, retry button, policy choice chips) to use `context.read<PayrollCalculationPreviewCubit>()` and guarded `build()` with null checks.

---

## 15. Test Evidence
- Dedicated Security Suite: `test/features/hr/presentation/security/payroll_calculation_security_audit_test.dart`
  - 11/11 automated tests passed:
    - 4/4 Authorization & route protection tests
    - 2/2 Session isolation & cancellation tests
    - 1/1 Cross-employee isolation test
    - 2/2 Error privacy, sanitization, and toString tests
    - 2/2 Calculation tampering prevention and immutability tests
- Integration Test Suite: `test/features/hr/presentation/integration/payroll_calculation_integration_test.dart` (6/6 passed)
- Full HR Regression Suite: `flutter test test/features/hr` (604/604 passed)
- Analyzer: `flutter analyze` (0 issues found)

---

## 16. Remaining Blockers
- None. All security and privacy gates for HR-7.9 are fully satisfied.

---

## 17. Backend Dependencies
1. Server-side role and permission enforcement on future payroll endpoints (`/api/v1/hr/payroll/calculate-preview`, etc.).
2. Database-level tenant and employee record isolation.
3. Production cryptographic audit logging on calculation runs.

---

## 18. HR-7.9 Exit Criteria

- [x] Approved access rules reviewed
- [x] Direct routes protected
- [x] Employee isolation verified
- [x] Session isolation verified
- [x] Sensitive data exposure reviewed
- [x] Logging reviewed (zero raw prints found)
- [x] Error privacy reviewed (sanitized error messages)
- [x] UI/result tampering reviewed (pure engine delegation)
- [x] Read-only behavior confirmed (zero mutations on stored records)
- [x] Confirmed vulnerabilities fixed (SEC-01, SEC-02, SEC-03)
- [x] Regression tests added (`payroll_calculation_security_audit_test.dart`)
- [x] Backend limitations documented (HR-10 boundary)
- [x] Full verification passes (604+ tests, zero analyze warnings)
- [x] Audit document created (`HR_7_SECURITY_AND_CALCULATION_AUDIT.md`)
- [ ] Separate HR-7.9 commit created

---

## 19. Commit Reference
- Commit hash: *Pending commit creation*
- Commit message: `test(hr): audit payroll calculation security (HR-7.9)`
