# Attendance Enterprise Implementation

## 1. Objective

Provide a simple Attendance landing dashboard over the existing HR Attendance architecture without introducing unsupported policies or a second state-management stack.

## 2. Starting Git state

- Branch: `feature/hr-payroll-frontend`
- Starting HEAD: `c956b771d32919f530684fce5ed40a968b065356`
- The branch was one commit ahead of `origin/feature/hr-payroll-frontend`.
- Four pre-existing uncommitted Dashboard navigation/test files were preserved and are not Attendance implementation work.

## 3. Existing Attendance audit

The entity/repository/mock store, responsive list/table, local search and filters, calendar, record detail, employee history, permissions, deterministic seed data, and backend repository seam were already working. Attendance was accessible from HR but landed directly in the large list. A feature dashboard, date-scoped summary, explicit entry modes, and stale dashboard-request protection were missing.

## 4. Confirmed requirements

Stable record/employee identity; approved stored fields; statuses `Present`, `Absent`, `Half-day`, `On Leave`; date/employee/status queries; `hr.view` access; mock/backend repository abstraction.

## 5. Attendance architecture

`AttendanceHomeScreen -> AttendanceDashboardCubit -> AttendanceRepository`. Existing list/calendar remains `AttendanceListScreen -> AttendanceListCubit -> AttendanceRepository`.

## 6. Dashboard

Added a responsive, date-scoped Attendance home with refresh, date selection, direct stored-record counts, empty/error/loading handling, and implemented-feature navigation.

## 7. Today's Attendance

The default dashboard date is the current local calendar date. A user can select another date. The dashboard requests only that date and does not infer missing employees as absent.

## 8. Employee Attendance

Existing employee history remains stable-ID scoped. The new work preserves it rather than creating a duplicate view.

## 9. Calendar

The existing calendar remains the authoritative calendar view. The dashboard opens it directly through an initial view-mode contract.

## 10. History

The dashboard opens the existing searchable/filterable full record history.

## 11. Corrections

APPROVED DEFERRED / POLICY AND BACKEND CONTRACT PENDING. No correction UI or mutation was invented.

## 12. Shifts

POLICY CONTRACT PENDING. No Shift entity or hardcoded schedule was added.

## 13. Leave integration

BACKEND CONTRACT PENDING. Stored `On Leave` records are displayed, but no independent Leave truth source was fabricated.

## 14. Holidays

POLICY CONTRACT PENDING. Weekends and holidays are not inferred.

## 15. Working hours

POLICY CONTRACT PENDING and explicitly excluded by the current Attendance entity contract.

## 16. Breaks

POLICY CONTRACT PENDING.

## 17. Exceptions

POLICY CONTRACT PENDING. Missing punch, late arrival, and early departure are not inferred.

## 18. Overtime

POLICY CONTRACT PENDING. No formula was added.

## 19. Employee Self-Service

UNCONFIRMED. No ownership permission or punch/correction contract exists.

## 20. Manager Self-Service

UNCONFIRMED. No authoritative manager/team scope contract exists.

## 21. Approvals

APPROVED DEFERRED. Attendance-specific approval integration is not frozen on this branch.

## 22. Payroll integration

BACKEND CONTRACT PENDING. Attendance remains separate and does not mutate Payroll.

## 23. Period locking

BACKEND/POLICY CONTRACT PENDING.

## 24. Audit trail

PARTIAL. Existing recorded-by and timestamps are displayed. No immutable event repository exists.

## 25. Reports

APPROVED DEFERRED. Existing filters are not represented as an authoritative report contract.

## 26. Notifications

BACKEND CONTRACT PENDING.

## 27. Permissions

Reuses only existing HR module assignment and `hr.view`; no new permission identifiers or roles were added. Direct dashboard and list routes are guarded.

## 28. Session isolation

Dashboard and list Cubits reject stale responses using monotonic request IDs and ignore responses after disposal. New screen instances receive the current user/repositories.

## 29. Backend status

Repository abstraction is preserved. No endpoint or response schema was invented.

## 30. Mock status

Deterministic mock records remain available through `MockAttendanceRepository`. Backend mode must never silently fall back to them.

## 31. Responsive behavior

Summary and feature grids adapt from one/two columns on compact widths to multi-column desktop layouts. Existing list uses cards below 600px and a horizontal table on desktop.

## 32. Automated tests

Added dashboard summary, authorization, navigation, responsive-layout, and stale-response coverage. Updated HR-home navigation coverage. The full HR suite and focused Dashboard navigation tests pass. The repository-wide test command remains red only because an unrelated Inventory screenshot test writes to a hard-coded, missing `C:\Users\vacha\...` directory.

## 33. Manual UAT

NOT TESTED. Device/browser interaction remains pending.

## 34. Deferred features

Corrections, approvals, shifts, leave/holiday integration, exceptions, self-service, reports, payroll locking, notifications, overtime, breaks, and optional geo/IP/kiosk/biometric features.

## 35. Backend blockers

Authoritative API, pagination/summary, RBAC/object scope, correction, shift, leave, payroll lock, audit, notification, and report/export contracts.

## 36. Policy blockers

Working time, grace/late/early, breaks, missing punches, holidays/weekends, overtime, employee/team ownership, approvals, and retention.

## 37. Files added

- `attendance_dashboard_state.dart`
- `attendance_dashboard_cubit.dart`
- `attendance_home_screen.dart`
- `attendance_feature_card.dart`
- Dashboard Cubit and screen tests
- `ATTENDANCE_ENTERPRISE_REQUIREMENTS.md`
- `ATTENDANCE_ENTERPRISE_IMPLEMENTATION.md`

## 38. Files modified

- Attendance list Cubit/screen for initial date/view mode and stale-response safety
- HR home to open Attendance dashboard
- HR home test navigation expectation

## 39. Commits

- `b945f07 fix(hr-navigation): open HR dashboard from module entry`
- Attendance implementation commit containing this document

## 40. Final status

`PARTIAL - POLICY CONTRACTS REMAIN`

The confirmed P0 frontend scope is implemented and verified by HR tests, Dashboard navigation tests, a clean Attendance/HR analysis, `git diff --check`, a production web build, and a release APK build. Repository-wide analysis still reports one unrelated Inventory style lint; repository-wide tests still report the unrelated hard-coded Inventory screenshot path. Manual UAT and the policy/backend contracts listed above remain pending.
