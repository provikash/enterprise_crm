# HR-11.4 — Android/Web Responsive UAT and Performance Verification

## 1. Purpose

This checkpoint records evidence for responsive behavior, platform builds, loading and async safety. It is not a production or live-backend acceptance certificate.

## 2. Git baseline

- Branch: `feature/hr-10-backend-integration`
- Starting HEAD: `a258ecdd1cadbab34e9048e484daa02885320394`
- Working tree: dirty before HR-11.4; 21 modified tracked HR files, three untracked attendance-form files, and unrelated `output/` and `tools/` directories were present. They were preserved and are not claimed as HR-11.4 work.
- Required `AI_RULES.md` was absent. `MASTER_DEVELOPMENT_RULES.md`, context documents, existing HR checkpoint reports, source, tests, and Git history were reviewed.

## 3. HR-11.1–11.3 status

No HR-11.1, HR-11.2, or HR-11.3 audit document or corresponding commit exists. Their gates are therefore `BLOCKED`, not presumed complete. `HR_10_FINAL_BACKEND_UAT_AND_FREEZE.md` / HR-10.10 is also absent. HR-10.9 reports that cutover blockers remain.

## 4. Test environments

- Flutter 3.47.5 stable; Dart 3.13.4.
- Windows host with Android SDK 36.1.0 and Chrome/Edge available.
- Runtime/build mode: the default application composition remains deterministic mock mode; backend adapters were exercised through mock transport tests, not a live server.
- Android: release APK build only; no emulator or physical device was available for manual interaction.
- Web: release build and automated widget/browser-render evidence; interactive browser control failed because the computer-control runtime exited repeatedly.

## 5. Device/browser matrix

| Surface | Size | Evidence | Result |
|---|---:|---|---|
| Flutter widget harness | 320×568 | HR navigation/screen tests and login regression | PASS (automated) |
| Flutter widget harness | 360×640 | HR navigation/screen tests and login regression | PASS (automated) |
| Flutter widget harness | 768×1024 | HR responsive tests | PASS (automated) |
| Flutter widget harness | 1200×800 | HR responsive tests | PASS (automated) |
| Chrome headless | 360×640, 768×1024, 1200×800 | Initial release-build renders | PARTIAL; login clipping found at 360 and fixed. Post-fix recapture was unreliable. |
| Android release | multi-ABI APK | `flutter build apk` | BUILD PASS; manual device UAT BLOCKED |

Automated results are not recorded as manual UAT passes.

## 6. HR shell

Automated navigation tests cover Admin Dashboard → HR/Payroll and major HR destinations. Direct-route, browser Back/Forward, refresh, and Android Back require interactive platform UAT and remain blocked.

## 7. Employee responsive results

Directory, details, add/edit, search/filter, authorization, long-list card/table variants, loading, empty, error, and retry states are covered by widget/integration tests across compact and desktop layouts. Manual touch/keyboard usability is not verified.

## 8. Documents responsive results

Employee-scoped list/details/upload/download navigation, error/retry, authorization, and four target viewports pass automated tests. Native Android content-URI selection and real browser file-selection/download remain untested.

## 9. Attendance Calendar

Automated tests verify month navigation, year boundaries, leap-year February, 30/31-day grids, date selection, empty dates, record-backed dates, responsive layouts, and the invariant that missing records are not fabricated as Absent. Interactive Android/Web calendar UAT is blocked.

## 10. Attendance filters

Search, employee/date/status filtering, combined filters, clear filters, mobile wrapping, and result refresh are covered by the current attendance tests. The current working tree also contains uncommitted attendance remediation supplied before this checkpoint; this report does not convert that work into committed acceptance.

## 11. Attendance History

Employee Details → Attendance History, correct employee identity, empty/error/retry behavior, and rapid Employee A/B switching are covered by navigation/widget tests. Request-version guards prevent stale late responses from replacing the current employee.

## 12. KPI responsive results

List, details, employee/period filtering, combined search, missing values, stored target/actual/score values, summary consistency, create/edit validation, duplicate-submit protection, employee switching, and protected routes pass automated tests. Scores remain repository-authored.

## 13. Payroll responsive results

Period selection, overview, details, employee history, calculation preview, reports, mobile lists, horizontally scrollable desktop tables, currency, decimal precision, missing-versus-zero behavior, and authorization are covered by tests. No payment, finalization, or payslip capability was added.

## 14. Reports

Employee, Attendance, KPI, and Payroll report screens have responsive list/table variants and automated filter/search/error coverage. Mandatory HR export capability is still absent (see Open blockers).

## 15. Approvals

Request, pending/submitted lists, details, decisions, history, responsive access, authorization, and duplicate-submit protection pass automated tests. Backend-authoritative approval effects are not live-verified.

## 16. Notifications

List, read/unread state, empty/error states, navigation, privacy, and authorization are covered by automated tests. Push/email channels are outside approved scope.

## 17. Themes

Existing HR widget tests cover Material 3 light and dark variants on representative screens. System mode resolves through the app theme configuration but was not manually toggled on a device/browser.

## 18. Accessibility

Forms have labels and validation text; icon controls generally expose tooltips; statuses use text as well as color; compact touch targets render without overflow. A screen-reader audit, text-scale sweep, and physical-device accessibility pass were not executed.

## 19. Web keyboard/focus

Text actions and form submission have widget coverage. Full Tab/Shift+Tab/Enter/Space/Escape ordering and dialog focus behavior could not be manually verified because interactive browser automation was unavailable.

## 20. Loading performance

Loading/empty/error/retry states are deterministic and non-blocking in tests. No production telemetry or frame-profile capture was available, so no latency percentile is claimed.

## 21. Search

Employee, attendance, KPI, payroll, and report search paths pass functional tests. Local filtering avoids a backend request per keystroke in the current screens; stale request guards are present in async Cubits.

## 22. Filters

Repeated filter and employee changes are protected by request/version identifiers in attendance, KPI, reports, documents, payroll, and summary Cubits. Automated stale-response tests pass.

## 23. Pagination

Repository query/pagination contracts are tested where implemented. Several HR mock screens intentionally render complete deterministic datasets with lazy mobile builders or scrollable desktop tables; large live-backend page transitions were not available for manual profiling.

## 24. Calendar performance

Calendar rendering and month changes use bounded month grids and repository-backed records. Automated interaction completes without errors. Device frame timing was not measured.

## 25. Payroll calculation responsiveness

Calculation preview is separated from stored payroll history and executes deterministically in tests. Exact monetary representation and authority boundaries pass; large live input profiling remains blocked.

## 26. Network delay

Delayed repository responses, route disposal, rapid selection changes, and stale-result suppression pass automated tests. Live slow-network behavior was not tested.

## 27. Network failure

`ApiClient` tests cover connection, timeout, typed HTTP errors, idempotent GET retry, and no retry for mutations. Screen-level failure/retry states pass with mock transports. Offline/live CORS behavior remains unverified.

## 28. Duplicate request audit

Initial loads are issued from provider creation or `initState`, not from widget `build`. Mutation Cubits guard submitting/success states, and request IDs discard superseded reads. No request storm was found in static inspection or automated tests.

## 29. Resource cleanup

State-owned text controllers inspected in HR forms/lists expose `dispose`; Cubits check `isClosed` before late emissions. No HR timer or persistent scroll subscription was found. Dynamic leak profiling on a device/browser was not performed.

## 30. Performance findings

- Lazy `ListView.builder`/`separated` is used for mobile lists; desktop data tables are explicitly scrollable.
- Async reads commonly use request-version guards, preventing old employee/filter data from replacing current state.
- Deterministic fixtures do not establish behavior for production-scale datasets; large live-dataset performance remains open.
- Android toolchain emits future-compatibility warnings for Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20; current builds pass.

## 31. Responsive defects

| ID | Severity | Defect | Evidence | Status |
|---|---|---|---|---|
| HR11.4-R01 | HIGH | Login card could exceed a 360 px web viewport and clip core controls. | Chrome headless 360×640 render | FIXED |

## 32. Fixes

`LoginScreen` now derives an explicit card width from available constraints, reduces compact outer/inner padding below 400 px, and retains the existing 420 px desktop maximum. This is the smallest entry-screen fix needed to keep HR reachable at supported phone widths.

## 33. Regression tests

Two non-pixel-exact widget cases assert that the login card remains within the viewport and renders the submit action at 320×568 and 360×640. The focused file passes 8/8 tests. The final full suite passes 2,259 tests.

## 34. Android result

`flutter build apk` passed and produced `build/app/outputs/flutter-apk/app-release.apk` (59,902,611 bytes / 57.1 MB). Emulator/physical-device navigation, Back, file picker, keyboard, and runtime performance are `BLOCKED`, not passed.

## 35. Web result

`flutter build web` passed, including the Wasm dry run. Automated responsive suites pass. Initial Chrome headless renders found HR11.4-R01; the fixed geometry passes widget verification. Interactive login/navigation, Back/Forward, focus, downloads, CORS, and live backend remain blocked.

## 36. Open blockers

1. No Android emulator/physical-device manual UAT.
2. Interactive browser-control runtime failed twice; critical manual Web UAT is incomplete.
3. No live/staging backend, production CORS environment, or large production-like dataset.
4. HR-11.1, HR-11.2, HR-11.3, and HR-10.10 evidence is absent.
5. HR-8.8/HR-8.9 export implementation/security remain open and unapproved for deferral.

## 37. HR-11.4 status

`PARTIAL — DEVICE/BACKEND VERIFICATION BLOCKED`

## 38. HR-11.5 readiness

Automated regression and both platform builds are ready. Final freeze is not permitted because prerequisite audits, manual platform UAT, live backend acceptance, and required export functionality are not complete.

## 39. Commit

This document, the responsive login fix, and its regression tests are recorded by the HR-11.4 commit containing this file. No push was performed.

## Verification commands

| Command | Result |
|---|---|
| `flutter test test/features/hr` | PASS — 1,125 tests |
| `flutter test test/features/auth/presentation/screens/login_screen_test.dart` | PASS — 8 tests |
| `flutter analyze` | PASS — no issues |
| `flutter test` | PASS — 2,259 tests |
| `flutter build web` | PASS |
| `flutter build apk` | PASS — 57.1 MB release APK |
| `git diff --check` | PASS |
