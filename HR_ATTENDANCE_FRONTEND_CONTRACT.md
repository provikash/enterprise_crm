# HR and Attendance Frontend Contract

## Implemented in this frontend phase

- `attendance.manage` is the canonical permission for manual attendance mutation. Administrators receive it through the existing admin bypass; standard HR users require both the HR/Payroll module and this explicit permission.
- Manual attendance requires an employee, date, status, and audit reason. Present, half-day, and on-duty entries also require a check-in time.
- Manual IN/OUT events are retained as append-only `AttendanceLog` records with source `manual`, actor, validity, timestamp, and reason. The mock daily record is refreshed without deleting logs.
- Team/company attendance supports a selected date, department filter, recorded totals, and a "not yet checked in" list. Missing daily records are labelled as not checked in; they are not silently converted to absence.
- `AttendanceDaily` and `AttendanceLog` frontend entities mirror the supplied API contract. Widgets do not calculate payroll, overtime, late penalties, geo-fence validity, or leave balances.
- The Workforce Operations workspace presents the integration contracts for punches/geo-fencing, shifts/rosters, policies/overtime, timesheets, regularization, leave, and holidays. Mutating unavailable backend operations clearly report that API integration is required.

## Employee creation rules

Employee creation and editing now require:

- full name;
- syntactically valid email;
- mobile/phone containing 7–15 digits (formatting characters and an optional leading `+` are accepted);
- identity document number;
- department;
- designation.

Validation is applied in both the Flutter forms and mock repository boundary. Production APIs must enforce the same rules and uniqueness constraints.

## Backend-authoritative responsibilities

The backend must remain authoritative for server timestamps, duplicate-punch windows, IN/OUT alternation, geo-fence/Haversine checks, mock-location and IP policy, biometric ingestion, daily recomputation, night-shift attribution, overlapping assignments, rest gaps, effective-dated policies, overtime and late calculations, period locks, approval transitions, leave ledger concurrency, notifications, payroll impact, and audit immutability.

## Required API integration sequence

1. Authentication/RBAC claims for the new permissions.
2. Attendance punch, today, daily, team, raw-log, and manual-entry endpoints.
3. Shift/assignment/roster endpoints.
4. Policy, overtime, and recalculation endpoints.
5. Timesheet/project/report endpoints.
6. Regularization and shared approval endpoints.
7. Leave types, preview, requests, ledger, encashment, year-end, and holiday endpoints.

No frontend success response should be treated as payroll-authoritative until these backend contracts and server-side permission checks are implemented.
