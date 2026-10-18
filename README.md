# Enterprise CRM

An industrial-grade, multi-platform enterprise operations suite built with **Flutter**, delivering a responsive, zero-compromise experience across **Modern Web**, **Android**, and **Desktop**.

---

## Architectural Overview

Enterprise CRM unifies core organizational operations into a single cohesive portal. It replaces fragmented spreadsheets and disparate third-party tools with an integrated system enforcing role-based security, comprehensive audit trails, and multi-format document workflows.

```text
               +-------------------------------------------------+
               |              Flutter Presentation Layer         |
               |        (Responsive Web & Mobile Layouts)        |
               +-------------------------------------------------+
                                        |
                                        v
               +-------------------------------------------------+
               |             BLoC / Cubit State Layer            |
               |   (Explicit State Machines & Event Streams)     |
               +-------------------------------------------------+
                                        |
                                        v
               +-------------------------------------------------+
               |             Domain Repository Boundary          |
               |      (Abstract Interfaces & Value Objects)      |
               +-------------------------------------------------+
                                        |
                    +-------------------+-------------------+
                    |                                       |
                    v                                       v
     +-----------------------------+         +-----------------------------+
     |      Mock Repositories      |         |     REST API Repositories   |
     |   (In-Memory Local Mode)    |         | (Dio Client -> REST Backend)|
     +-----------------------------+         +-----------------------------+
```

---

## Completed Enterprise Modules

### 1. Lead Management & Distribution
* **Intake & Profiling:** Manual lead creation, detailed customer profiling, inline updates, and timeline activity history.
* **Spreadsheet Ingestion Wizard:** Drag-and-drop CSV and XLSX ingestion with interactive column-to-attribute mapping and exact in-file duplicate detection.
* **Intelligent Lead Distribution:** Single and bulk reassignment workflows with strict agent ownership invariants (reps only access assigned leads; administrators maintain global oversight).
* **Deep-Link Filter Cards:** Dashboard KPI metric cards directly filter the lead workspace (`Total`, `Assigned`, `Unassigned`, `Manual`, `Excel`, `CSV`).

### 2. Calling & Telephony Disposition
* **Disposition Tracking:** Structured call outcomes (`Follow up`, `Not connected`, `Visit scheduled`, `Irrelevant`, `Not interested`, `Lead closed`, `Sales done`, `Dispatched`).
* **Follow-up Engine:** Automated scheduling with date/time pickers and telecaller daily activity dashboards.

### 3. Inventory & Warehouse Management
* **Catalog & Custom Attributes:** Standard inventory tracking coupled with dynamic custom field definitions (text, numeric, dropdowns).
* **Multi-Warehouse Stock:** Multi-location stock allocation, opening balance tracking, and low-stock/overstock alerts.
* **Multi-Format Ingestion & Export:** Customizable exports to formatted CSV, styled XLSX with headers, and vector-rendered PDF reports.

### 4. Purchase & Procurement
* **Procurement Lifecycle:** End-to-end workflow progression from Request for Quotation (RFQ) to Vendor Quotes, Proforma Invoices (PI), and Purchase Orders (PO).
* **Approval & Governance Card:** Live stage progression, approver assignment, direct actions (`Submit for Approval`, `Approve PO`, `Reject PO`), and deep linking into the Approvals Inbox.
* **PDF Bill Engine:** Client-side vector rendering and file download of official Purchase Order bills with tax breakdowns and payment terms.

### 5. Vendor Management
* **Vendor Master Directory:** Complete vendor profiling, GSTIN/tax identification, contact directory, and transaction histories.
* **Compliance & KYC Tracking:** Verification status badges (`Verified`, `Pending KYC`, `Suspended`), catalog linking, and multi-format data export.

### 6. Dispatch & Logistics
* **Fulfillment Lifecycle:** Order dispatch state machine (`Pending`, `Packed`, `In Transit`, `Delivered`).
* **Transport Metadata:** Vehicle number, vehicle type, transporter agency, driver phone, and Builty / Lorry Receipt (LR) tracking.
* **Invoicing:** Dynamic line-item invoicing and automated dispatch slip generation.

### 7. HR & Employee Directory
* **Staff Directory & Compliance:** Employee master records, emergency contacts, KYC documents, and policy management.
* **Document Management:** Document upload simulation, category tagging, and identity verification.

### 8. Attendance & KPI Tracking
* **Time & Attendance:** Punch-in / punch-out recording, status logging, and monthly team attendance calendar.
* **KPI Goal Management:** Employee performance targets, milestone tracking, and quarterly performance appraisals.

### 9. Payroll & Compensation Engine
* **Pay Run Execution:** Gross-to-net pay run calculations, statutory deductions, bonuses, and reimbursement management.
* **Salary Structure Configurator:** Base pay, allowances, provident fund, tax brackets, and vector PDF payslip generation.

### 10. Approvals & Multi-Tier Governance
* **Approvals Workspace:** Centralized inbox for pending requests across all business modules with priority categorization (`Urgent`, `High`, `Normal`, `Low`).
* **Cross-Module Synchronization:** Actions taken in Approvals automatically synchronize the underlying purchase order or transaction status in real-time.
* **Audit History & Export:** Complete step-by-step decision audit logs with CSV export.

### 11. Notifications & Real-Time Alerts
* **Header Popover & Dynamic Badge:** Global top-right bell button with dynamic unread counter badge and anchored popover dropdown.
* **Notification Center:** Dedicated notification hub with category filtering (`Approval Request`, `Approval Decision`, `System Alert`, `Announcement`, `Reminder`).
* **Deep Linking Navigation:** Tapping notification alerts navigates directly into the target approval request or record.

### 12. User Management & Access Control (RBAC)
* **Administrative Governance:** Public self-registration is disabled. Account provisioning, role assignments, and credential management are strictly administrator-governed.
* **Granular Permission Matrix:** Module-level and action-level permissions (`*.view`, `*.create`, `*.edit`, `*.export`, `*.approve`).

### 13. Dashboard & Global Navigation Shell
* **Role-Adaptive Home:** Distinct dashboard views for Administrators and Standard Users.
* **Theme System:** Modern high-contrast Light, Dark, and Lavender themes with responsive navigation rails and top headers.

---

## Technical Architecture & Design Principles

* **Native First & Strict Decoupling:** Uses core Flutter primitives and `flutter_bloc` without reliance on heavy, fragile third-party framework layers.
* **Repository Pattern:** The presentation layer depends exclusively on abstract domain contracts. UI widgets never directly invoke network clients.
* **Responsive Parity:** Single codebase dynamically adapts across mobile viewports (cards, bottom sheets, mobile telephone intents) and desktop/web viewports (anchored popovers, dense data tables, modal dialogs, and dual-pane views).
* **Resilient Network Layer:** Pre-configured Dio HTTP client with automatic Bearer token injection, token refresh interception (`POST /auth/refresh`), request idempotency keys, and sensitive data logging redaction.
* **Zero Hardcoded Data Invariant:** In API mode (`DataSourceMode.api`), mock stores and seed fixtures are never loaded into memory. All screens render exclusively from the live backend database.

---

## Tech Stack

| Component | Technology | Version |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK) | `^3.11.5` / `3.41.9` |
| **State Management** | `flutter_bloc` | `^8.1.6` |
| **Networking** | `dio` | `^5.4.3` |
| **Spreadsheets** | `excel` / `csv` | `^4.0.3` / `^6.0.0` |
| **Document Generation** | `pdf` / `printing` | `^3.10.8` / `^5.12.0` |
| **Design System** | Material 3 / Google Fonts | Responsive Light / Dark / Lavender |

---

## Quality & Stability Standards

* **Static Analysis:** Strict compliance with `flutter_lints` (**0 warnings, 0 errors** on `flutter analyze`).
* **Automated Regression Suite:** **2,768 automated tests** passing across unit, BLoC, widget, and end-to-end integration flows (**100% pass rate**).
* **Viewport Zero Overflow Invariant:** Form layouts, data tables, and modal cards render cleanly without overflow errors from 320px mobile viewports to 4K widescreen displays.

---

## Getting Started

### Prerequisites
* Flutter SDK (3.24.0 or higher)
* Dart SDK (3.5.0 or higher)
* Google Chrome / Edge (for Web) or Android Studio / Android Device (for Mobile)

### Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/vachaspatimishraa/enterprise_crm.git
cd enterprise_crm
flutter pub get
```

### Running Locally
To launch on Modern Web:
```bash
flutter run -d chrome
# or
flutter run -d edge
```

To launch on an Android device or emulator:
```bash
flutter run -d android
```

### Running Automated Tests
Run the entire regression test suite:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## Backend Integration

The application is engineered to transition from offline mock mode to a live REST backend with zero changes to UI or state management layers.

1. **Configure Environment:** In `lib/core/config/app_config.dart`, update the target environment:
   ```dart
   class AppConfig {
     static const production = AppConfig(
       dataSourceMode: DataSourceMode.api,
       apiBaseUri: 'https://api.crm.yourcompany.com/v1',
     );
   }
   ```
2. **Wire API Repositories:** In `lib/app/bootstrap/api_crm_dependencies.dart`, provide your concrete API repository implementations (or use the pre-built `Backend*Repository` classes).
3. **Data Disappearance Invariant:** Once switched to `DataSourceMode.api`, all in-memory mock repositories and demo seed accounts are completely bypassed and never loaded into memory.

---

## Project Structure

```text
lib/
├── app/
│   ├── bootstrap/         # Dependency injection containers (Mock vs API)
│   ├── crm_app.dart       # Root application widget & route handling
├── core/
│   ├── config/            # Environment configurations (AppConfig)
│   ├── network/           # Dio HTTP client, interceptors, error mappers
│   ├── theme/             # Material 3 light, dark, and lavender themes
│   └── utils/             # Formatters, responsive breakpoints, helpers
└── features/
    ├── approvals/         # Multi-tier governance, inbox, audit timeline
    ├── auth/              # Authentication & session guards
    ├── calling/           # Call activity logging & follow-ups
    ├── dashboard/         # Shell navigation, metrics, account profile
    ├── dispatch/          # Order fulfillment & Builty tracking
    ├── hr/                # Employee directory, attendance, KPI tracking
    ├── inventory/         # Stock catalog, dynamic custom fields, import/export
    ├── leads/             # Lead intake, distribution, spreadsheet import
    ├── notifications/     # Header bell, popover, notification center
    ├── payroll/           # Pay run engine, payslips, compensation
    ├── purchase/          # Procurement, RFQ, PO generation & PDF bill
    ├── user_management/   # Admin account provisioning & RBAC
    └── vendors/           # Vendor directory, KYC tracking, catalog linking
```
