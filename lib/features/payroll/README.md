# Payroll

The Payroll feature is implemented incrementally behind typed feature flags.

## Phase 1 screens

- `/payroll`: guarded Payroll workspace and responsive navigation.
- `/payroll/gallery`: debug-only shared-widget gallery.

## State

- Cubit states are immutable and explicit.
- `JobPollerCubit` polls long-running API jobs, backs off after transient failures,
  ignores cancelled generations, and stops when disposed.

## Permissions

All Payroll routes require the HR/Payroll module and at least one recognized
`payroll.*` permission. Individual screens and actions require their granular key.
Administrators retain the existing recognized-permission bypass.

## Data sources

`AppConfig.dataSourceMode` is the single selection point for mock or API repository
wiring as each Payroll module is introduced. Presentation code depends only on
domain interfaces; Phase 1 supplies both job-repository implementations.

## API

Phase 1 assumes `GET /api/v1/payroll/jobs/:jobId` and the common failure envelope
documented in `docs/payroll/PLAN.md`. Sensitive request and response values must not
be logged or persisted.
