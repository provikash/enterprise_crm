# Payroll

The Payroll feature is implemented incrementally behind typed feature flags.

## Available screens

- `/payroll`: guarded Payroll workspace and responsive navigation.
- `/payroll/config/*`: salary components, structures, statutory versions and pay groups.
- `/payroll/compensation`: employee salary assignments and payroll holds.
- `/payroll/inputs`: bonuses, overtime, reimbursements and deductions.
- `/payroll/runs`: calculate, review, approve and lock pay runs.
- `/payroll/payslips`: generated gross-to-net statements for locked runs.
- `/payroll/payments`: release and track salary payment batches.
- `/payroll/reports`: payroll register and operational summaries.

Operational screens currently use a shared in-memory repository. Data survives
navigation during the running process but resets when the app restarts. The mock
tax rule exists only to exercise gross-to-net workflow; production statutory and
tax results must come from the authoritative backend.

## State

- Cubit states are immutable and explicit.
- `JobPollerCubit` polls long-running API jobs, backs off after transient failures,
  ignores cancelled generations, and stops when disposed.

## Permissions

All Payroll routes require the HR/Payroll module and at least one recognized
`payroll.*` permission. Individual screens and actions require their granular key.
Administrators retain the existing recognized-permission bypass.

## Data sources

Presentation and routing code depend only on domain repository interfaces.
`HrPayrollDependencies` is the single composition boundary for HR and Payroll.
The demo entry point creates it through `createMockHrPayrollDependencies()`.

During backend integration, create an API-backed `HrPayrollDependencies` using
the same six interfaces and replace that one factory call in `main.dart`. Mock
stores and repositories can then be removed without changing screens, Cubits,
routes, or access policies.

## API

Phase 1 assumes `GET /api/v1/payroll/jobs/:jobId` and the common failure envelope
documented in `docs/payroll/PLAN.md`. Sensitive request and response values must not
be logged or persisted.
