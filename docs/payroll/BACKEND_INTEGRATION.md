# HR and Payroll backend integration boundary

HR and Payroll runtime dependencies are assembled in one place:

- Contract bundle: `lib/app/bootstrap/hr_payroll_dependencies.dart`
- Mock assembly: `lib/app/bootstrap/mock_hr_payroll_dependencies.dart`
- Application selection: `lib/main.dart`

Presentation, Cubit, policy, and routing code consume repository interfaces and
must not construct mock repositories.

## Replacing mocks

1. Implement the repository interfaces with API-backed classes.
2. Create an API dependency factory that returns `HrPayrollDependencies`.
3. Replace `createMockHrPayrollDependencies()` in `main.dart` with the API
   factory selected by environment configuration.
4. Run the HR, Payroll, permission, contract, and integration test suites.
5. Remove `mock_hr_payroll_dependencies.dart` and unused mock stores only after
   no test or development entry point requires them.

The required interfaces cover employees, employee documents, attendance, KPIs,
Payroll configuration, and Payroll operations. Backend authorization remains
authoritative even though the frontend also applies route and action guards.
