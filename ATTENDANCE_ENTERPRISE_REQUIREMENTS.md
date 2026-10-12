# Attendance Enterprise Requirements

## 1. Purpose and evidence boundary

This contract records what the current Flutter repository actually supports. It does not create backend endpoints, statuses, permissions, formulas, approval rules, shift rules, leave rules, holiday rules, or payroll rules.

Evidence inspected: Attendance domain entity/repository, deterministic mock store, list Cubit/state, list/calendar/detail/history screens, HR access policy, canonical CRM permissions, navigation tests, repository tests, and the enterprise Attendance enhancement request.

## 2. Confirmed domain contract

- Attendance records use stable `id` and stable `employeeId`.
- Approved record fields are date, attendance status, optional check-in/check-out, remarks, recorded-by, and timestamps.
- Existing approved status values are `Present`, `Absent`, `Half-day`, and `On Leave`.
- Date, employee, and status filtering are repository-supported.
- Attendance can be queried for one employee or one calendar date.
- Working-hours, late/early, break, overtime, exception, shift, holiday, and payroll calculations are not approved.
- Authorization reuses HR module assignment plus `hr.view`; Admin retains existing unrestricted behavior. No Attendance-specific permission identifier exists.

## 3. Capability matrix

| Capability | Classification | Evidence / boundary |
|---|---|---|
| Attendance dashboard | CONFIRMED | Date-scoped summary and navigation over existing records |
| Selected-date records | CONFIRMED | `getAttendanceForDate` and list date filter |
| Attendance list/history | WORKING | Responsive cards/table, search, status/date/employee filters |
| Employee attendance | WORKING | Stable employee-ID repository query and employee history screen |
| Calendar | WORKING | Month navigation, record indicators, date selection and details |
| Record details | WORKING | Approved fields only |
| Check-in/check-out display | WORKING | Stored values; no punch mutation workflow |
| Check-in/check-out action | BACKEND-DEPENDENT | No authoritative action endpoint or policy |
| Working hours | POLICY-DEPENDENT | Explicitly excluded by current entity contract |
| Late/early/missing punch | POLICY-DEPENDENT | No thresholds or exception semantics |
| Corrections/regularization | APPROVED DEFERRED | HR approval primitives exist elsewhere, but no approved Attendance correction contract in this branch |
| Shifts and assignments | POLICY-DEPENDENT | No Shift entity, repository, permissions, or rules |
| Leave integration | BACKEND-DEPENDENT | `On Leave` is stored status; no authoritative Leave repository integration |
| Holiday calendar | POLICY-DEPENDENT | No holiday/weekend contract |
| Breaks/overtime | POLICY-DEPENDENT | No approved fields or formulas |
| Employee/manager self-service | UNCONFIRMED | No ownership/team relationship permission contract |
| Reports/export | APPROVED DEFERRED | Existing general list is not an authoritative report/export contract |
| Payroll integration/locking | BACKEND-DEPENDENT | No approved Attendance-to-Payroll mutation/locking contract |
| Audit history | PARTIAL | Metadata exists; immutable event repository does not |
| Notifications | BACKEND-DEPENDENT | No Attendance notification contract |
| Geo/IP/kiosk/biometric | OUT OF SCOPE | Explicit optional exclusion |

## 4. Dashboard rules

- The dashboard loads only the selected date through `getAttendanceForDate`.
- Counts are direct counts of stored records by approved status. Absence is never inferred from employee totals.
- Empty dates show zero recorded values and do not fabricate records.
- Cards are exposed only for implemented capabilities: selected-date records, calendar, and history.
- Corrections, shifts, exceptions, approvals, reports, and integrations remain hidden until their contracts exist.

## 5. Security and isolation

- Direct routes must call `HrAccessPolicy.canViewHrRecords`.
- Repository calls stay outside widgets and are owned by Cubits.
- Date loads use request sequencing so an older response cannot overwrite a newer selection.
- List loads ignore late responses after a newer request or Cubit disposal.
- Employee filtering always uses stable `employeeId`.
- Frontend authorization is user-experience enforcement only; the future backend must enforce authorization and tenant/object scope independently.

## 6. Backend requirements before expansion

Authoritative contracts are required for summary/pagination, correction lifecycle and approvals, shifts, leave/holiday sources, exception rules, overtime, employee/team ownership, payroll consumption and locks, audit events, notifications, and exports. Backend failures must never fall back to mock success data.

## 7. Freeze result

P0 dashboard/list/calendar/history improvements are approved against existing records. P1 and P2 features remain deferred or blocked exactly as classified above.
