# Enterprise CRM

An industrial-grade, multi-platform enterprise operations suite built with **Flutter**, delivering a responsive, zero-compromise experience across **Android** and **Modern Web**.

---

## Overview

Enterprise CRM unifies disparate organizational operations into a single, cohesive portal. It replaces fragmented spreadsheets and disparate SaaS tools with a centralized system that enforces role-based security, comprehensive audit trails, and multi-format document workflows.

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
* **Intake & Profiling:** Manual lead creation, detailed customer profiling, inline updates, and contact histories.
* **Spreadsheet Ingestion Wizard:** Drag-and-drop CSV and XLSX ingestion with interactive column-to-attribute mapping and exact in-file duplicate detection.
* **Intelligent Lead Distribution:** Single and bulk reassignment workflows with strict agent ownership invariants (reps only access assigned leads; administrators maintain global oversight).

### 2. Calling & Telephony Disposition
* **Disposition Tracking:** Structured call outcomes (`Follow up`, `Not connected`, `Visit scheduled`, `Irrelevant`, `Not interested`, `Lead closed`, `Sales done`, `Dispatched`).
* **Follow-up Engine:** Automated scheduling with date/time pickers and telecaller daily activity dashboards.

### 3. Inventory & Warehouse Management
* **Catalog & Custom Attributes:** Standard inventory tracking coupled with dynamic custom field definitions (text, numeric, dropdowns).
* **Multi-Warehouse Stock:** Multi-location stock allocation, opening balance tracking, and low-stock/overstock alerts.
* **Multi-Format Ingestion & Export:** Customizable exports to formatted CSV, styled XLSX with headers, and vector-rendered PDF reports.

### 4. Dispatch Logistics
* **Fulfillment Lifecycle:** Order dispatch state machine (`Pending`, `Packed`, `In Transit`, `Delivered`).
* **Transport Metadata:** Vehicle number, vehicle type, transporter agency, driver phone, and Builty / Lorry Receipt (LR) tracking.
* **Invoicing:** Dynamic line-item invoicing and automated dispatch slip generation.

### 5. Purchase & Procurement
* **Procurement Lifecycle:** End-to-end workflow from Request for Quotation (RFQ) to Vendor Quotes, Proforma Invoices (PI), and Purchase Orders (PO).
* **PDF Engine:** Client-side vector rendering of official Purchase Order documents with tax breakdowns and payment terms.

### 6. HR & Payroll
* **Staff Directory & Compliance:** Employee master records, emergency contacts, KYC documents, and policy management.
* **Attendance & KPI Tracking:** Daily attendance logs, status reporting, and performance evaluations.
* **Compensation Engine:** Salary structure configuration, statutory deductions, gross-to-net pay run calculations, and payslip generation.

### 7. User Management & Access Control (RBAC)
* **Administrative Governance:** Public self-registration is disabled. Account provisioning, role assignments, and credential management are strictly administrator-governed.
* **Granular Permission Matrix:** Module-level and action-level permissions (`*.view`, `*.create`, `*.edit`, `*.export`, `*.approve`).

---

## Technical Architecture & Design Principles

* **Native First & Strict Decoupling:** Uses core Flutter primitives and `flutter_bloc` without reliance on heavy third-party framework layers.
* **Repository Pattern:** The presentation layer depends exclusively on abstract domain contracts. UI widgets never directly invoke network clients.
* **Responsive Parity:** Single codebase dynamically adapts across mobile viewports (cards, bottom sheets, mobile telephone intents) and desktop/web viewports (collapsible navigation rails, dense data tables, modal dialogs, and dual-pane views).
* **Resilient Network Layer:** Configured Dio HTTP client with automatic Bearer token injection, token refresh interception (`POST /auth/refresh`), request idempotency keys, and sensitive data logging redaction.

---

## Tech Stack

| Component | Technology | Version |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK) | `^3.11.5` / `3.41.9` |
| **State Management** | `flutter_bloc` | `^8.1.6` |
| **Networking** | `dio` | `^5.4.3` |
| **Spreadsheets** | `excel` / `csv` | `^4.0.3` / `^6.0.0` |
| **Document Generation** | `pdf` / `printing` | `^3.10.8` / `^5.12.0` |
| **Typography & Icons** | Material 3 / Google Fonts | Modern High-Contrast Theme |

---

## Getting Started

### Prerequisites
* Flutter SDK (3.24.0 or higher)
* Dart SDK (3.5.0 or higher)
* Google Chrome (for Web) or Android Studio / Android Device (for Mobile)

### Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/vachaspatimishraa/enterprise_crm.git
cd enterprise_crm
flutter pub get
```

### Running Locally
To launch on Chrome (Web):
```bash
flutter run -d chrome
```

To launch on an Android device or emulator:
```bash
flutter run -d android
```

### Running Automated Tests
The repository includes a comprehensive regression test suite containing 2,514 automated tests:
```bash
flutter test
```

To check code quality and static analysis:
```bash
flutter analyze
```

---

## Backend Integration

The application is engineered to switch from offline mock storage to a live REST backend with zero changes to UI or state management layers.

1. **Configure Environment:** In `lib/core/config/app_config.dart`, update the target environment:
   ```dart
   class AppConfig {
     static const production = AppConfig(
       dataSourceMode: DataSourceMode.api,
       apiBaseUri: 'https://api.crm.yourcompany.com/v1',
     );
   }
   ```
2. **Wire API Repositories:** In `lib/app/bootstrap/api_crm_dependencies.dart`, provide your concrete API repository implementations.
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
│   ├── theme/             # Material 3 light and dark theme definitions
│   └── utils/             # Formatters, responsive breakpoints, helpers
└── features/
    ├── auth/              # Authentication & session guards
    ├── calling/           # Call activity logging & follow-ups
    ├── dashboard/         # Shell navigation, metrics, account profile
    ├── dispatch/          # Order fulfillment & Builty tracking
    ├── hr/                # Employee directory, attendance, KPI
    ├── inventory/         # Stock catalog, dynamic custom fields, import/export
    ├── leads/             # Lead intake, distribution, spreadsheet import
    ├── payroll/           # Pay run engine, payslips, compensation
    ├── purchase/          # Procurement, RFQ, PO generation & PDF
    └── user_management/   # Admin account provisioning & RBAC
```

---

## Code Quality Standards

* **Static Analysis:** Strict compliance with `flutter_lints` (0 warnings, 0 errors).
* **Test Suite:** Over 2,500 tests covering unit models, BLoC states, widget rendering, responsive layouts, and cross-module workflows.
* **Security:** Sensitive data redaction in logging; zero hardcoded production credentials.
