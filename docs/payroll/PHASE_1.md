# Phase 1 — Foundations

Status: **Implemented and verified**

Implemented foundations:

- paise-based `Money` value type and money widgets;
- typed failures and Dio error mapping/interceptors;
- Payroll permissions and access policy;
- typed feature flags and mock/API mode;
- guarded Payroll home and debug widget gallery;
- shared status, summary, stepper, timeline, masking, confirmation, filtering,
  pagination, upload, import-validation, loading, locked, conflict, and re-auth UI;
- cancellable, backoff-enabled job polling with mock and API repositories.

Provisional API assumptions remain in `PLAN.md`. No payroll, tax, statutory, EMI,
or settlement calculation is performed in the Flutter client.
