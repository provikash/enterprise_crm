# HR / Payroll Frontend Implementation Plan

Status: **Approved; Phase 1 implemented**  
Created: 13 Oct 2026  
Scope: Flutter frontend only; mock-first and API-ready  
Approval gate: No production feature code is implemented until the product owner replies **approved**.

## 1. Decisions from the audit

The implementation will follow the repository's feature-first `data/domain/presentation` structure and Cubit state management. Existing HR, authentication, dashboards, and Inventory code will not be renamed or restructured.

| Concern | Decision |
|---|---|
| State | `flutter_bloc` Cubits with immutable sealed states: initial, loading, success, empty, failure, and workflow-specific locked/submitting states. |
| Navigation | Extend the existing named-route boundary for URL-safe Payroll deep links. A router migration is deferred to avoid destabilizing existing navigation. |
| Networking | Add one shared Dio client with auth, idempotency, redaction, error mapping, cancellation, and retry/backoff support. |
| DI | Continue constructor injection and `RepositoryProvider`; add a composition root that selects mock or API repositories from one runtime config. |
| Models | Keep domain entities hand-written and immutable. API DTOs live in `data/dto`, parse JSON, and map explicitly to domain entities. |
| Money | Store money as integer paise in a `Money` value type. Never use `double`. |
| Dates | API uses ISO-8601; UI uses `intl` with `dd MMM yyyy` and an injected company time-zone policy. |
| Authorization | Extend existing `CrmPermissions` and `AccessPolicy`; guard routes, entry points, and actions. Backend authorization remains authoritative. |
| Feature rollout | Every Payroll module is controlled by a typed feature flag. Disabled routes fail closed and menu entries are omitted. |
| Mocking | Every repository has mock and API implementations. Mocks support success, empty, failure, large/paginated, partial, conflict, and locked scenarios. |
| Sensitive data | Nullable sensitive fields, masked by default, in-memory reveal leases, re-authentication, no persistence or logging. |

## 2. Module map

```text
Payroll
├── Foundations
│   ├── Money and date formatting
│   ├── Failure/result model and API client
│   ├── Permissions, flags, routing, re-authentication
│   ├── Shared widgets and import/export support
│   └── Long-running job polling
├── Configuration
│   ├── Salary components
│   ├── Salary structures and assignments
│   ├── Statutory configuration/versioning
│   └── Pay groups and calendars
├── Employee compensation
│   ├── Salary assignment/revision/history
│   ├── Bulk salary revisions
│   └── Payroll information, bank verification, holds
├── Payroll inputs
│   ├── Bonuses/incentives/adjustments
│   ├── Arrears
│   ├── Loans/advances
│   └── Reimbursements
├── Pay runs
│   ├── Run list/create
│   ├── Calculation and dry run
│   ├── Review/approval/locking/payment lifecycle
│   └── Employees, exceptions, inputs, statutory, comparison, activity
├── Payslips, payments, and F&F
│   ├── Employee and HR payslips
│   ├── Payment batches/reconciliation
│   └── Full-and-final settlement
└── Tax, compliance, accounting, reports, analytics
    ├── Employee tax and HR proof verification
    ├── Compliance filings
    ├── GL mapping and journals
    ├── Reusable reports/export scheduling
    └── Payroll analytics
```

## 3. Planned folder tree

```text
lib/
├── app/
│   ├── crm_app.dart                         # existing: router/DI registration only
│   └── app_router.dart                      # new route table and guards
├── core/
│   ├── config/app_config.dart               # mock/API mode and feature flags
│   ├── failures/failure.dart                # typed failures and Result
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_error_mapper.dart
│   │   ├── auth_interceptor.dart
│   │   ├── idempotency_interceptor.dart
│   │   └── sensitive_data_redactor.dart
│   └── time/company_clock.dart
└── features/payroll/
    ├── README.md
    ├── shared/
    │   ├── data/                            # shared DTO helpers and API job repository
    │   ├── domain/
    │   │   ├── money.dart
    │   │   ├── payroll_feature.dart
    │   │   ├── payroll_status.dart
    │   │   ├── paged_result.dart
    │   │   ├── query_page.dart
    │   │   └── job.dart
    │   └── presentation/
    │       ├── bloc/                        # re-auth, filters, import, job polling
    │       ├── services/                    # file selection/delivery abstractions
    │       └── widgets/                     # shared Payroll widget suite
    ├── configuration/
    │   ├── salary_components/{data,domain,presentation}/
    │   ├── salary_structures/{data,domain,presentation}/
    │   ├── statutory/{data,domain,presentation}/
    │   └── pay_groups/{data,domain,presentation}/
    ├── compensation/
    │   ├── employee_salary/{data,domain,presentation}/
    │   ├── bulk_revision/{data,domain,presentation}/
    │   └── payroll_info/{data,domain,presentation}/
    ├── inputs/
    │   ├── adjustments/{data,domain,presentation}/
    │   ├── arrears/{data,domain,presentation}/
    │   ├── loans/{data,domain,presentation}/
    │   └── reimbursements/{data,domain,presentation}/
    ├── pay_runs/{data,domain,presentation}/
    ├── payslips/{data,domain,presentation}/
    ├── payments/{data,domain,presentation}/
    ├── full_and_final/{data,domain,presentation}/
    ├── tax/{data,domain,presentation}/
    ├── compliance/{data,domain,presentation}/
    ├── accounting/{data,domain,presentation}/
    ├── reports/{data,domain,presentation}/
    ├── analytics/{data,domain,presentation}/
    └── gallery/presentation/payroll_widget_gallery_screen.dart

test/features/payroll/                         # mirrors production modules
test/fixtures/payroll/<endpoint>/<case>.json   # contract fixtures
integration_test/payroll/                      # critical end-to-end mock flows
```

Each feature module will contain only the folders it needs. `presentation` imports `domain`, never `data`. The application composition root owns concrete repository selection.

## 4. State design

All list states carry an immutable query and `PagedResult<T>`. Newer query requests receive monotonically increasing request IDs; stale responses are ignored. Dio cancellation tokens cancel superseded API calls.

| Module | Cubits/controllers | Important state |
|---|---|---|
| Foundations | `ReauthCubit`, `ImportCubit`, `JobPollerCubit`, `PayrollFilterCubit` | Reveal lease expiry, import stages, job progress/backoff, URL query state |
| Salary components | `SalaryComponentListCubit`, `SalaryComponentFormCubit`, `ComponentPreviewCubit` | Paginated list; form field errors; preview request ID and result |
| Salary structures | `SalaryStructureListCubit`, `SalaryStructureBuilderCubit`, `StructureSimulationCubit` | Ordered component rows; dependency warnings; server simulation |
| Statutory config | `StatutoryConfigCubit`, `StatutoryVersionFormCubit` | Current/version history; effective-date validation; save confirmation |
| Pay groups | `PayGroupListCubit`, `PayGroupFormCubit`, `MatchCountCubit`, `PayrollCalendarCubit` | Inclusion-rule draft; debounced server count; calendar periods |
| Employee salary | `EmployeeSalaryCubit`, `SalaryRevisionCubit` | Hidden/denied/loading/current/history; old-vs-new preview; approval timeline |
| Bulk revisions | `BulkRevisionWizardCubit` | Selection scope, change definition, preview rows, warnings, reason, submission; state serialized into route extra/session memory only |
| Payroll info | `PayrollInfoCubit`, `PayrollInfoFormCubit`, `HoldActionCubit` | Mask/reveal; pending bank change; hold metadata; verification status |
| Adjustments | `AdjustmentListCubit`, `AdjustmentFormCubit`, `AdjustmentImportCubit` | Period lock; editable rows; totals from API response |
| Arrears | `ArrearsCubit` | Backend-generated rows and included/excluded selection |
| Loans | `LoanListCubit`, `LoanFormCubit`, `LoanDetailsCubit`, `LoanActionCubit` | Server EMI preview; amortization page; pause/foreclose/skip states |
| Reimbursements | `ClaimFormCubit`, `ClaimListCubit`, `ApprovalQueueCubit`, `PayoutCubit` | Receipt uploads; limit warnings; bulk selection; payout status |
| Pay runs | `PayRunListCubit`, `CreatePayRunCubit`, `PayRunDetailsCubit`, one Cubit per lazy tab, `PayRunActionCubit`, `CalculationJobCubit` | Canonical status; pure available actions; conflicts; acknowledged warnings; simulation banner |
| Payslips | `EmployeePayslipCubit`, `PayslipViewerCubit`, `PayslipManagementCubit`, `PayslipQueryCubit` | Masked index; signed-download state; publish/email progress; query thread |
| Payments | `PaymentBatchListCubit`, `PaymentBatchDetailsCubit`, `PaymentReleaseCubit`, `ReconciliationCubit` | Maker-checker; re-auth lease; excluded/failure rows; upload result |
| F&F | `SettlementCubit`, `SettlementActionCubit`, `ClearanceCubit` | Server-calculated settlement; adjustment draft; blocking clearances |
| Tax | `TaxWorkspaceCubit`, `TaxDeclarationCubit`, `TaxProofCubit`, `TaxVerificationQueueCubit` | Draft autosave; deadline lock; server comparison/projection; split-view verification |
| Compliance | `ComplianceDashboardCubit`, `ComplianceReportCubit`, `ComplianceJobCubit` | Due/overdue state from API; paginated rows; generated-file jobs |
| Accounting | `GlMappingCubit`, `JournalCubit`, `AccountingSyncCubit` | Dirty mappings; server journal balance; sync log/job |
| Reports | `ReportCatalogCubit`, `ReportRunnerCubit`, `SavedViewCubit`, `ReportExportCubit` | Global filters; paginated result; totals; async export/download state |
| Analytics | `PayrollAnalyticsCubit` | One global filter; independently loading chart panels |

Mutations use a submitting flag or dedicated submitting state so double taps cannot produce duplicate requests. The pure `availableActions(status, permissions, isPreparer)` function remains in the Pay Run domain and receives exhaustive unit tests.

## 5. Route table

All routes require `CrmModule.hrPayroll`, their feature flag, and the listed permission. Routes preserve filter/page state in query parameters when useful.

| Route | Screen | Permission |
|---|---|---|
| `/payroll` | Payroll home | any Payroll permission |
| `/payroll/gallery` | Debug widget gallery | debug build + admin |
| `/payroll/config/components` | Salary components | `payroll.config.manage` |
| `/payroll/config/components/new` | Component form | `payroll.config.manage` |
| `/payroll/config/components/:id` | Component details/edit | `payroll.config.manage` |
| `/payroll/config/structures` | Salary structures | `payroll.config.manage` |
| `/payroll/config/structures/:id` | Structure builder | `payroll.config.manage` |
| `/payroll/config/statutory/:type` | Statutory config/version history | `payroll.config.manage` |
| `/payroll/config/pay-groups` | Pay groups and calendar | `payroll.config.manage` |
| `/payroll/employees/:employeeId/salary` | Employee salary tab/deep link | `payroll.salary.view` |
| `/payroll/employees/:employeeId/salary/revise` | Assign/revise salary | `payroll.salary.edit` |
| `/payroll/compensation/bulk-revision` | Bulk revision wizard | `payroll.salary.edit` |
| `/payroll/inputs/adjustments` | Period adjustments | `payroll.run.create` |
| `/payroll/inputs/arrears` | Arrears | `payroll.run.create` |
| `/payroll/loans` and `/payroll/loans/:id` | Loan list/detail | `payroll.salary.view` |
| `/payroll/reimbursements` | Claims/approval/payout workspace | relevant action permission |
| `/payroll/runs` | Pay run list | `payroll.run.view` |
| `/payroll/runs/new` | Create pay run | `payroll.run.create` |
| `/payroll/runs/:id` | Pay run detail | `payroll.run.view` |
| `/payroll/runs/:id/:tab` | Deep-linked lazy tab | `payroll.run.view` |
| `/payroll/payslips` and `/payroll/payslips/:id` | Employee payslips/viewer | authenticated employee or `payroll.payslip.view_all` |
| `/payroll/payslip-management` | HR payslip management | `payroll.payslip.view_all` |
| `/payroll/payments` and `/payroll/payments/:id` | Payment batches | `payroll.payment.release` for release only |
| `/payroll/fnf` and `/payroll/fnf/:id` | Full and final | `payroll.run.view`; mutations use action permissions |
| `/payroll/tax` | Employee tax workspace | authenticated employee |
| `/payroll/tax/verification` | HR verification queue | `payroll.tax.verify` |
| `/payroll/compliance` and `/payroll/compliance/:statute` | Compliance | `payroll.compliance.view` |
| `/payroll/accounting` | GL and journals | `payroll.reports.view` pending backend confirmation |
| `/payroll/reports` and `/payroll/reports/:code` | Reports | `payroll.reports.view` |
| `/payroll/analytics` | Analytics | `payroll.reports.view` |

Unauthorized routes render `AccessRestrictedScreen`; disabled features render a not-available state without instantiating repositories. Authentication redirects retain a sanitized intended URL.

## 6. Permission keys

The following exact keys will be added to `CrmPermissions`, its module mapping, user-management labels, fixtures, and permission tests:

```text
payroll.config.manage
payroll.salary.view
payroll.salary.edit
payroll.run.view
payroll.run.create
payroll.run.approve
payroll.run.lock
payroll.payment.release
payroll.payslip.view_all
payroll.tax.verify
payroll.compliance.view
payroll.reports.view
```

Existing `payroll.view` will remain temporarily for backward compatibility. During rollout it will grant entry to the Payroll home only, not granular actions. Removal or migration requires a backend/user-role contract and is not assumed.

## 7. Feature flags

Typed flags will default to `false` outside debug/mock development:

```text
payrollFoundations
payrollConfiguration
payrollEmployeeCompensation
payrollInputs
payrollPayRuns
payrollPayslips
payrollPayments
payrollFullAndFinal
payrollTax
payrollCompliance
payrollAccounting
payrollReports
payrollAnalytics
payrollWidgetGallery
```

Flags gate route registration/redirects, Payroll home cards, employee-profile tabs, and background polling. Flags do not replace permissions.

## 8. Shared widgets and services

### Reuse or adapt

| Existing asset | Planned use |
|---|---|
| `HrResponsiveGrid` | Dashboard and summary layouts; central breakpoints will wrap it rather than modify unrelated behavior. |
| `HrPageHeader`, `HrSectionCard`, `HrSummaryCard` | Payroll page composition where semantics match. |
| `HrEmptyState`, `HrErrorState` | Base empty/error presentation. |
| `InventoryPaginationControls` | Behavior reference for a neutral Payroll pager. |
| Inventory import parser/preview/error-report patterns | Design reference; Payroll gets typed schema-specific implementations. |
| File-picker abstractions | Pattern for testable upload selection. |
| `DeleteInventoryItemDialog` | Interaction reference for guarded destructive confirmation. |
| Existing Material date pickers/forms | Wrapped with Payroll formatting, validation, and accessibility. |

### Build in Phase 1

`MoneyText`, `MoneyField`, `MaskedField`, `PayrollStatusChip`, `SummaryStrip`, `StepperHeader`, `ApprovalTimeline`, `AuditTimeline`, `PayrollConfirmDialog`, `PayrollFilterBar`, `FileUploadTile`, `PayrollPaginationControls`, `PayrollSkeleton`, `PermissionDeniedState`, `LockedBanner`, `ConflictReloadDialog`, `ImportValidationTable`, `JobProgressPanel`, `ReauthDialog`, and a debug-only widget gallery.

## 9. Proposed packages

No package will be added until this plan is approved.

| Package | Reason |
|---|---|
| `dio` | Cancellation tokens, interceptors, upload/download progress, structured network errors, and idempotency headers. |
| Existing named routes | Preserve the app's current navigation convention while adding guarded Payroll deep links incrementally. |
| `intl` | Locale-aware Indian money grouping and required `dd MMM yyyy` formatting. |
| `timezone` | Company-time-zone conversion independent of device/browser locale. |
| `pdf` | Structured payslip/certificate/report PDF rendering where the API returns render data rather than a signed PDF URL. |
| `path_provider` | Mobile/desktop destination for downloaded payroll documents. |
| `open_filex` | Open downloaded payslips/documents on supported non-web platforms. |
| `fl_chart` | Proposed charting package because the project has no chart dependency; add only in Phase 7 after explicit confirmation. |

Existing `file_picker`, `csv`, `excel`, and `archive` packages will be reused. Money will use integer paise, so `decimal` is not proposed. Code generation packages are not proposed because the project uses manual models.

## 10. API conventions assumed for planning

These contracts are provisional and must be replaced by the backend OpenAPI contract when available.

- Base path: `/api/v1/payroll`
- Authentication: `Authorization: Bearer <token>` supplied by the existing/future auth session.
- Dates: `YYYY-MM-DD`; timestamps: ISO-8601 with offset/UTC.
- Money: integer fields ending in `Paise`; never floating point.
- Pagination request: `page`, `pageSize`, `sort`, filter query parameters.
- Pagination response: `{items, page, pageSize, totalItems, totalPages}`.
- Mutation headers: `Idempotency-Key` and optional `If-Match`/version.
- Success envelope: `{data, meta?, requestId?}`.
- Validation: `422 {code, message, fieldErrors: {field: [message]}}`.
- Conflict: `409 {code, message, currentVersion?, updatedAt?}`.
- Job: `{jobId, status, completed, total, progressPercent, resultId?, errors?}`.
- Sensitive fields omitted or returned as `null` when unauthorized.
- Standard errors: `400`, `401`, `403`, `404`, `409`, `422`, `429`, `5xx`.

## 11. Assumed endpoint contract table

### Foundations and configuration

| Endpoint | Method | Request | Response |
|---|---|---|---|
| `/session/reauth` | POST | `{method, passwordOrOtp}` | `{elevatedToken, expiresAt}` |
| `/jobs/:jobId` | GET | none | job envelope |
| `/components` | GET | paging/filter/sort | page of component summaries |
| `/components` | POST | component fields + calculation config | component |
| `/components/:id` | GET/PATCH | version + changed fields | component |
| `/components/:id/deactivate` | POST | `{reason, version}` | component/use warning or conflict |
| `/components/preview` | POST | component draft + example inputs | backend-computed example |
| `/structures` | GET/POST | query or structure draft | page or structure |
| `/structures/:id` | GET/PATCH | ordered rows + version | structure |
| `/structures/:id/assignments` | POST | targets + effective date | assignment summary |
| `/structures/simulate` | POST | structure draft/id + CTC paise | monthly/annual backend breakup |
| `/statutory/:type` | GET | optional effective date | current version + history |
| `/statutory/:type/versions` | POST | effective-from + typed config | new version |
| `/pay-groups` | GET/POST | query or group draft | page or group |
| `/pay-groups/:id` | GET/PATCH | group fields + version | pay group |
| `/pay-groups/match-count` | POST | inclusion rule draft | `{employeeCount}` |
| `/pay-groups/:id/calendar` | GET | year/range | payroll periods |

### Employee compensation and inputs

| Endpoint | Method | Request | Response |
|---|---|---|---|
| `/employees/:id/salary` | GET | optional effective date | nullable masked current salary + breakup + history |
| `/employees/:id/salary/preview` | POST | structure/change/effective date | old/new backend comparison + arrears warning |
| `/employees/:id/salary/revisions` | POST | revision draft + reason | submitted revision + approval timeline |
| `/salary-revisions/preview` | POST | employee selection token + change definition | paginated preview/warnings |
| `/salary-revisions/bulk` | POST | preview token + retained rows + reason | job/submission summary |
| `/employees/:id/payroll-info` | GET/PATCH | version + editable fields | masked info + verification/hold metadata |
| `/employees/:id/bank/verify` | POST | reauth token + version | verification status |
| `/employees/:id/holds` | POST | hold type + enabled + reason | hold metadata |
| `/adjustments` | GET/POST/PATCH | period query or amountPaise input | page/adjustment + server totals |
| `/adjustments/import/validate` | POST | uploaded file | validation job/result |
| `/adjustments/import` | POST | validation token | import job |
| `/arrears` | GET | period/employee paging | backend-generated arrears page |
| `/arrears/:id/inclusion` | PATCH | `{included, version}` | arrear row |
| `/loans` | GET/POST | query or loan draft | page or loan |
| `/loans/preview` | POST | loan terms | backend EMI/interest schedule + cap warnings |
| `/loans/:id` | GET | paging for schedule | loan + amortization page |
| `/loans/:id/actions` | POST | pause/foreclose/skip + reason | updated loan + schedule |
| `/reimbursements` | GET/POST | query or claim with lines | page or claim |
| `/reimbursements/:id` | GET/PATCH | draft changes/version | claim |
| `/reimbursements/:id/submit` | POST | version | locked submitted claim |
| `/reimbursements/:id/actions` | POST | approve/reject/withdraw + reason | updated claim |
| `/reimbursements/bulk-actions` | POST | ids + action + reason | per-id outcomes |
| `/reimbursements/:id/payout` | POST | payout mode/reference | payout status |

### Pay runs

| Endpoint | Method | Request | Response |
|---|---|---|---|
| `/runs` | GET/POST | query or pay group/period/type/pay date | page or draft run; duplicate is 409/422 |
| `/runs/:id` | GET | none | header, server totals, status, version, preparer |
| `/runs/:id/employees` | GET | paging/filter/sort | employee calculation page |
| `/runs/:id/employees/:employeeId` | GET | none | calculation, YTD, inputs used, flags |
| `/runs/:id/exceptions` | GET | paging/type/severity | grouped exception page |
| `/runs/:id/exceptions/:exceptionId/acknowledge` | POST | comment + version | exception |
| `/runs/:id/inputs` | GET | paging/filter | input page |
| `/runs/:id/statutory` | GET | paging/filter | statutory totals |
| `/runs/:id/comparison` | GET | previous run/range | variance, movers, chart points |
| `/runs/:id/activity` | GET | paging | audit + approval events |
| `/runs/:id/pull-inputs` | POST | version | run/job |
| `/runs/:id/calculate` | POST | `{dryRun, version}` | job; dry run never persists |
| `/runs/:id/submit` | POST | version | under-review run |
| `/runs/:id/approve` | POST | version + optional comment | next approval/run status |
| `/runs/:id/send-back` | POST | version + mandatory reason | draft/calculated run |
| `/runs/:id/lock` | POST | version + confirmation | locked run |
| `/runs/:id/reopen` | POST | version + mandatory reason | reopened run + banner metadata |
| `/runs/:id/holds` | POST | employee id + held + reason | row/run totals |
| `/runs/:id/delete` | DELETE | version + confirmation | `204` |

### Payslips, payments, F&F, tax, compliance, accounting, reports

| Endpoint | Method | Request | Response |
|---|---|---|---|
| `/payslips` | GET | employee/year/month paging | masked payslip summaries |
| `/payslips/:id` | GET | reauth token when required | render JSON with backend totals |
| `/payslips/:id/download` | POST | format | signed URL + expiry |
| `/payslips/:id/queries` | GET/POST | query message | query thread/message |
| `/payslips/actions` | POST | ids/run id + publish/resend/retry | job |
| `/payslips/downloads` | POST | ids/run id + ZIP | export job |
| `/payment-batches` | GET/POST | query or run/bank/source/date | page or batch |
| `/payment-batches/:id` | GET | employee paging | batch + masked rows |
| `/payment-batches/:id/release` | POST | elevated token + version | released batch/job |
| `/payment-batches/:id/reconciliation` | POST | bank response file | reconciliation job/result |
| `/payment-batches/:id/failures/:rowId/actions` | POST | retry/fix/manual + reason | row status |
| `/fnf` | GET | paging/filter | settlement page |
| `/fnf/:id` | GET | none | backend-computed settlement + clearances |
| `/fnf/:id/preview` | POST | adjustment draft | recomputed preview |
| `/fnf/:id/actions` | POST | recalculate/submit/approve/pay + reason/version | settlement/job |
| `/tax/regime-comparison` | POST | employee/year + declaration draft | backend comparison and estimated impact |
| `/tax/declarations/:year` | GET/PATCH | version + draft sections | declaration + API limits/deadline |
| `/tax/declarations/:year/submit` | POST | version | locked declaration |
| `/tax/proofs` | GET/POST | query or proof metadata/file | page/proof |
| `/tax/proofs/:id/actions` | POST | verify/reject/adjust + reason | proof |
| `/tax/projection/:year` | GET | employee | server projection + month TDS |
| `/compliance` | GET | period/statute filters | statute dashboard |
| `/compliance/:statute/reports` | GET | paging/filter | rows + server totals |
| `/compliance/:statute/generate` | POST | period/file type | job |
| `/compliance/files/:id/mark-paid` | POST | date + reference | updated file/status |
| `/accounting/gl-mappings` | GET/PATCH | mappings + version | mapping page/result |
| `/accounting/runs/:runId/journal` | GET | paging | entries + debit/credit totals + balanced flag |
| `/accounting/runs/:runId/sync` | POST | destination/config id | job |
| `/reports/catalog` | GET | search/category/favorites | report definitions |
| `/reports/:code/run` | POST | filters + paging/sort | page + totals or async job |
| `/reports/:code/exports` | POST | filters + format | export job |
| `/reports/saved-views` | GET/POST/PATCH/DELETE | report code + filters | saved view(s) |
| `/reports/schedules` | GET/POST/PATCH/DELETE | cadence + recipients + filters | schedule(s) |
| `/reports/downloads` | GET | paging | generated downloads |
| `/analytics` | GET | global filters | KPI cards and chart series with per-panel status |

File uploads are multipart. Every mutation returns field-level validation errors where applicable. Approval, locking, release, payment, and destructive endpoints require idempotency keys and server-side maker-checker enforcement.

## 12. Existing files expected to be modified

Only these categories are planned, matching the allowed integration points:

| Existing file | Reason |
|---|---|
| `pubspec.yaml` | Register approved dependencies and localization support. |
| `lib/main.dart` | Construct app config/network/repository composition. |
| `lib/app/crm_app.dart` | Register router and repository providers; clear Payroll state on logout. |
| `lib/features/auth/domain/policies/crm_permissions.dart` | Register Payroll permission keys and module ownership. |
| `lib/features/auth/presentation/mappers/crm_permission_presentation.dart` | User-facing permission labels. |
| `lib/features/hr/presentation/screens/hr_home_screen.dart` | Feature-flagged Payroll menu entry. |
| `lib/features/hr/presentation/screens/employee_details_screen.dart` | Lazy, permission-gated Salary/Payroll profile tabs. |
| User-management permission fixtures/tests | Make new permission keys assignable and verified. |
| Dashboard/navigation tests | Verify route and permission registration. |

If route integration requires another existing file, it will be reported before modification. No existing feature implementation will be moved or renamed.

## 13. Phase schedule, gates, and risks

| Phase | Deliverable | Verification gate | Primary risks |
|---|---|---|---|
| 1. Foundations | Architecture seams, shared widgets, flags, permissions, router, mocks, gallery | Money/failure/permission/job unit tests; widget state tests; accessibility pass | Routing migration, auth-token contract, localization scope |
| 2. Configuration | Components, structures, statutory versions, pay groups/calendar | Mock end-to-end configuration flows and mapper fixtures | Formula/slab contracts; effective-date semantics |
| 3. Compensation | Employee salary tabs, revisions, Payroll info, bulk wizard | Permission/masking/re-auth tests; salary revision integration flow | Sensitive fields; employee profile coupling |
| 4. Inputs | Adjustments, arrears, loans, reimbursements | Locked-period/import/receipt/action tests | File rules and server calculation ownership |
| 5. Pay runs | State-design note, list/detail/tabs, calculation, approval, lock | Exhaustive `availableActions`; critical lifecycle integration test; summary golden | Highest workflow complexity; conflicts and resumable jobs |
| 6. Payslips/payments/F&F | Employee/HR payslips, payment batches, reconciliation, settlements | Payslip golden; maker-checker/re-auth tests; platform download tests | Banking security; signed URLs; platform file behavior |
| 7. Tax/compliance/accounting/reports | Remaining workspaces, exports, charts | Tax submission integration test; report and chart state tests | Regulatory contracts; chart package; large exports |

Each phase ends with formatting, `flutter analyze`, focused and full tests, documentation, changed-file inventory, API contract delta, run instructions, and known limitations. The next phase begins only after `next`.

## 14. Security and data-integrity rules

1. Payroll calculations and statutory limits are never derived on the client.
2. `Money` validates range and represents paise exactly; API mappers reject floating-point monetary payloads.
3. Sensitive values are omitted for null/unauthorized responses and never replaced with guessed placeholders.
4. Reveal state and elevated tokens stay in memory, expire automatically, and clear on navigation/logout/idle timeout.
5. Log redaction covers authorization, PAN, Aadhaar, bank, salary, tax, uploaded files, and arbitrary request bodies by default.
6. Maker-checker UI checks are advisory; the backend remains authoritative.
7. Mutations are idempotent or locally disabled until completion.
8. Stale preview/search results never overwrite a newer request.
9. Conflicts show reload/review UI; the client never silently overwrites newer server data.
10. Mock data is realistic but contains no real personal or banking information.

## 15. Definition of ready for Phase 1

Phase 1 may begin after the product owner replies **approved** and confirms or accepts these provisional assumptions:

- Dio, `intl`, and `timezone` may be added; the existing named-route approach remains in place for Phase 1.
- Integer paise is the canonical client money representation.
- The existing `payroll.view` permission remains as a temporary entry-only compatibility key.
- `/api/v1/payroll` and the documented error envelope are placeholders until backend OpenAPI is supplied.
- Company time zone is injected by configuration; it is not inferred from the device.
- `fl_chart` is deferred until Phase 7 and needs separate confirmation before installation.
