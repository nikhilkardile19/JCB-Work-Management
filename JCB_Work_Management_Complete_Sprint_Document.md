# JCB Work Management & Billing Application

## Complete Product Scope, Technical Workflow, Architecture, and Sprint Plan

**Document type:** Product Requirements + Software Scope of Work +
Technical Architecture + Delivery Plan\
**Platform:** Flutter mobile application (Android first; iOS-ready
architecture), React.js Developer Admin Portal, Firebase backend\
**Version:** 1.1\
**Status:** Revised development baseline with mandatory mobile UI/UX
standards

------------------------------------------------------------------------

# 1. Executive Summary

The JCB Work Management & Billing Application is an offline-first mobile
application for JCB and earthmoving businesses to manage companies,
clients, work sites, machines, operators, meter readings, work hours,
fuel expenses, invoices, payments, and reports.

A separate web-based Developer Admin Portal will allow the product owner
to manage customer companies, licenses, device limits, activation
requests, replacement requests, license expiry, suspensions, and audit
history.

The product will use one shared application for multiple customer
companies. Each company's data must be isolated from all other
companies. Mobile users will be able to record work offline and
synchronize structured records when internet connectivity returns.

## 1.1 Product objectives

-   Replace paper-based JCB work registers and manual billing.
-   Calculate working hours using start and end hour-meter readings.
-   Capture evidence for meter readings and fuel expenses.
-   Generate client invoices and track payments/outstanding amounts.
-   Support unreliable internet connectivity through local storage and
    synchronization.
-   Allow the developer to approve, suspend, renew, and manage customer
    licenses.
-   Restrict each license to its authorized devices.
-   Support damaged-phone replacement through an approval workflow.
-   Protect company data with authentication, authorization, audit
    trails, and tenant isolation.

## 1.3 Mandatory Mobile UI/UX and Development Instruction

Apply the following instruction throughout the entire mobile application
design and development lifecycle. This is a mandatory product-wide
requirement and must be included in developer prompts, sprint tasks,
code reviews, QA, and release acceptance.

> **Act as an expert Mobile UI/UX Designer and App Developer. Build a
> premium, modern, attractive, and responsive mobile application with
> intuitive navigation, user-friendly interfaces, beautiful layouts,
> smooth animations, reusable components, and clean architecture. Follow
> mobile design guidelines for iOS and Android, ensure touch-friendly
> interactions, consistent styling, accessibility, and optimal
> performance. Avoid generic designs and ensure every screen is
> polished, fully functional, and production-ready.**

### Required implementation standards

-   Create a cohesive design system before implementing feature screens:
    color palette, typography, spacing, layout grids, iconography,
    component states, form patterns, and elevation/surface rules.
-   Use Flutter Material 3 as the baseline while respecting platform
    conventions and adapting behavior where appropriate for iOS and
    Android.
-   Build reusable components for text fields, dropdowns, date
    selectors, cards, buttons, dialogs, bottom sheets, status
    indicators, data tables/lists, empty states, loading states, error
    states, and confirmation flows.
-   Use touch-friendly controls, readable typography, clear visual
    hierarchy, and layouts that adapt to supported screen sizes and
    orientations.
-   Design field-work screens for quick use outdoors and with minimal
    unnecessary typing. Make meter readings, machine/site selection,
    save status, and sync status easy to identify.
-   Include polished loading, success, empty, offline,
    permission-denied, validation-error, and retry states for every
    relevant workflow.
-   Use subtle, purposeful animations only where they improve feedback
    or navigation. Respect reduced-motion/platform preferences where
    feasible and avoid animations that slow field work.
-   Handle keyboard visibility, safe areas, notches, system bars, screen
    readers, contrast, text scaling, and focus order.
-   Do not use placeholder buttons or nonfunctional controls in
    completed screens. Every delivered screen must have working
    navigation, validation, state handling, and expected actions.
-   Keep widgets modular and maintainable. Separate UI, state
    management, domain logic, database access, synchronization, and
    backend services.
-   Avoid hard-coded design values scattered throughout the app. Use
    shared theme tokens and reusable components.
-   Verify the UI on multiple Android screen sizes and at least one iOS
    simulator/device before claiming cross-platform readiness.
-   Treat visual polish and usability as acceptance criteria, not
    optional post-development enhancements.

### Mobile UI/UX Definition of Done

A mobile screen is complete only when: 1. It follows the approved design
system. 2. All fields, buttons, navigation and gestures work as
intended. 3. It handles loading, empty, error, offline and permission
states where applicable. 4. Validation messages are clear and
actionable. 5. It supports touch interaction, text scaling and safe-area
layout. 6. It remains responsive with realistic data volumes. 7. It has
unit/widget tests for important behavior and has been reviewed on target
devices. 8. There are no placeholder elements, broken layouts, or
unhandled actions.

## 1.2 Key product principles

1.  No start/stop timer is required for work-hour calculation.
2.  Working hours = ending meter reading − starting meter reading.
3.  Meter photos, fuel receipt photos, and generated PDFs are stored
    locally in the first release; they are not uploaded to Firebase
    Storage.
4.  Structured business records are stored locally first and
    synchronized to Firestore.
5.  A license suspension or expiry must not automatically delete a
    company's local data.
6.  License activation, device authorization, and administrative actions
    must be validated by trusted backend logic---not by a local Flutter
    flag alone.
7.  One shared mobile application serves multiple companies, with strict
    company-level data isolation.

------------------------------------------------------------------------

# 2. Scope of Work

## 2.1 Included in scope

### A. Mobile application

-   Login and authentication.
-   Company setup and company profile.
-   Client master.
-   Site master linked to clients.
-   JCB machine master.
-   Operator master.
-   Petrol pump/fuel supplier master.
-   Work logs using meter readings.
-   Start and end meter reading photo capture.
-   Reading value entry and validation.
-   Timestamp and location capture, subject to device permissions.
-   Manual work entry with reason and audit trail.
-   Fuel entries and local receipt photo storage.
-   Invoice creation from approved, uninvoiced work logs.
-   Invoice PDF generation, preview, print, and share.
-   Payment recording and outstanding balance tracking.
-   Dashboard and reports.
-   Offline-first local database.
-   Sync queue and synchronization status.
-   License activation and device registration.
-   Device replacement request.
-   User roles and company-level permissions.
-   Audit history for important operations.

### B. Developer Admin Portal

-   Secure developer administrator login.
-   Dashboard for companies, active licenses, expired licenses,
    suspended licenses, and pending device requests.
-   Customer company registration and approval.
-   License creation and assignment to a company.
-   License start date, expiry date, status, and device limit.
-   License activation/deactivation/suspension/revocation.
-   Authorized device list and device history.
-   Device replacement request review and approval/rejection.
-   Device revocation.
-   Customer/user overview.
-   Audit logs.
-   Basic search, filters, and pagination.

### C. Backend and infrastructure

-   Firebase Authentication.
-   Cloud Firestore.
-   Cloud Functions for trusted license/device operations.
-   Firebase Hosting for the Developer Admin Portal.
-   Firestore Security Rules.
-   App Check where supported and appropriate.
-   Monitoring, logging, usage alerts, and deployment configuration.
-   Offline synchronization architecture.
-   Data model and security rules tests.

### D. Mobile UI/UX design and quality

-   Premium, modern, consistent mobile visual design.
-   Design system and reusable Flutter components.
-   Responsive layouts for supported Android and iOS devices.
-   Accessible forms, controls, typography, contrast, and focus
    behavior.
-   Touch-friendly field workflows optimized for quick JCB/site
    operations.
-   Functional loading, empty, error, offline, permission, and sync
    states.
-   Smooth, purposeful animations and interaction feedback.
-   UI/widget tests and device-based visual verification.
-   Production-ready polish included within each feature sprint, not
    postponed until the end.

## 2.2 Not included in the initial release

Unless separately approved, the following are out of scope for version
1:

-   Uploading photos and PDFs to cloud storage.
-   Automatic OCR of meter readings or receipts.
-   GPS tracking of JCB machines or operators.
-   Live tracking or geofencing.
-   Online payment gateway integration.
-   E-invoice/GST portal integration.
-   Accounting software integration.
-   Customer-facing web portal.
-   WhatsApp/SMS/email notification automation.
-   Subscription payment collection and automated payment gateway
    renewals.
-   Advanced multi-level approval chains.
-   Web-based mobile app replacement or remote wipe of a damaged phone.
-   Guaranteed recovery of unsynchronized local data from a destroyed
    phone.

------------------------------------------------------------------------

# 3. Users, Roles, and Permissions

## 3.1 Developer roles

### Developer Super Admin

-   Full access to the Developer Admin Portal.
-   Create and manage companies and licenses.
-   Approve/reject device replacement requests.
-   Suspend, expire, revoke, or reactivate licenses.
-   Review device and audit history.
-   Manage other developer administrators if enabled.

### Developer Support Admin (optional)

-   View customer and device details.
-   Review replacement requests.
-   Perform only the actions granted by the Super Admin.
-   Cannot change critical billing/license settings unless permission is
    explicitly granted.

## 3.2 Customer company roles

### Company Owner/Admin

-   Manage company profile and company users.
-   Manage masters.
-   Create and approve work logs.
-   Create invoices and record payments.
-   View company reports.
-   Request device replacement.

### Manager/Supervisor (optional)

-   Manage work logs and assigned sites/machines.
-   Review work entries.
-   View permitted reports.

### Operator/Field User (optional)

-   Enter assigned work and meter readings.
-   Capture meter photos.
-   Record fuel entries if permission is granted.
-   Cannot manage licenses or company settings.

### Accounts User (optional)

-   View approved work logs.
-   Generate invoices.
-   Record payments.
-   View outstanding balances and billing reports.
-   Cannot edit machine master data unless permitted.

The first release can start with Company Owner/Admin and additional
roles can be enabled using role-based permissions.

------------------------------------------------------------------------

# 4. Functional Requirements and Scope Details

## 4.1 Authentication and onboarding

-   User signs in using the configured Firebase Authentication method.
-   App checks the authenticated user's company membership and status.
-   New customer cannot use protected functionality until the company
    and license are approved.
-   First activation requires an internet connection.
-   App registers the device through a trusted backend function.
-   App stores only the minimum license cache needed for offline
    operation.
-   Logout must not delete business records by default.
-   Company switching must require valid membership and must never mix
    company data.

## 4.2 Company profile

Fields: - Company name. - Contact person. - Phone number. - Email. -
Address. - Logo (optional local file in version 1). - GSTIN/tax details
(optional; validate requirements before implementation). - Invoice
prefix. - Invoice numbering preference. - Default currency (INR). -
Financial year or billing settings where required.

Rules: - Company profile must exist before business records can be
created. - Company ID is generated by the backend or a secure UUID
strategy and is immutable. - Invoice number allocation must avoid
duplicates when multiple devices are used. If offline invoice creation
is supported, use a unique local draft ID and assign the final official
invoice number through a safe numbering strategy when online, or use a
company/device sequence with documented constraints.

## 4.3 Client master

Fields: - Client name. - Contact person. - Phone. - Email. - Billing
address. - GSTIN/tax ID (optional). - Notes. - Active/inactive status. -
Created/updated timestamps.

Functions: - Create, view, edit, search, deactivate. - Prevent
accidental deletion where linked to work logs or invoices. - Existing
invoices must retain the client details captured at invoice
finalization.

## 4.4 Site master

Fields: - Site name. - Client/company relationship. - Site address or
location description. - Contact person and phone (optional). - Default
hourly rate (optional). - Notes. - Active/inactive status.

Rules: - A site belongs to a client and company. - Default hourly rate
is a suggestion only. - Invoice-time rate overrides must not modify the
site master rate. - Historical finalized invoice lines retain the rate
and description used at finalization.

## 4.5 JCB machine master

Fields: - Machine name/number. - Registration number (optional). -
Serial/chassis number (optional). - Machine type/model (optional). -
Initial meter reading. - Meter unit (hours). - Notes. - Active/inactive
status.

Rules: - Machine belongs to a company. - Meter readings should not move
backwards without an explicit correction process. - Meter rollover or
meter replacement should be handled as a supervised correction with
reason and audit log. - Machine should not be hard-deleted if referenced
by work logs or invoices.

## 4.6 Operator master

Fields: - Operator name. - Phone number (optional). - Employee/reference
code (optional). - Notes. - Active/inactive status.

Rules: - Operator assignment is optional if the company does not track
operators. - Historical work records should preserve the operator
name/reference as recorded.

## 4.7 Petrol pump / fuel supplier master

Fields: - Supplier/pump name. - Contact details (optional). - Address
(optional). - Notes. - Active/inactive status.

## 4.8 Work log and meter readings

Work log fields: - Company ID. - Work log ID. - Work date. - Client
ID. - Site ID. - Machine ID. - Operator ID (optional). - Starting meter
reading. - Ending meter reading. - Calculated working hours. - Start
meter photo local path and metadata (optional). - End meter photo local
path and metadata (optional). - Start and end capture timestamp. -
Latitude/longitude and accuracy where permission is granted. - Work
description/notes. - Entry mode: photo-assisted or manual. - Manual
entry reason (required for manual entries). - Status: draft, submitted,
approved, rejected, invoiced, cancelled. - Created by/updated by. -
Created/updated timestamps. - Sync status.

Calculation: `workingHours = endingMeterReading - startingMeterReading`

Validation: - Ending reading must be greater than or equal to starting
reading. - Negative hours are not allowed. - Warn or require
confirmation for unusually high daily hours, configurable by the product
owner. - Duplicate machine/date records should be flagged, not
automatically rejected if split shifts are legitimate. - Manual entries
require a reason and must be audit logged. - Photo capture metadata
should include capture time and available location/accuracy. - Location
permission denial must not crash the app; record that location was
unavailable. - Users must not be able to silently alter approved work
logs. Corrections should create an audit entry and follow permissions.

Workflow: 1. Select client. 2. Select site. 3. Select machine. 4. Select
work date and operator if applicable. 5. Capture or enter starting meter
reading. 6. Capture or enter ending meter reading. 7. Calculate working
hours. 8. Add notes. 9. Save locally. 10. Submit for approval or approve
based on role. 11. Synchronize structured data when online.

## 4.9 Manual work entries

Manual work entries are allowed when a photo cannot be captured.

Requirements: - User chooses "Manual Entry." - Reason is mandatory. -
App records who created the entry and when. - Record is clearly marked
as manual. - Manual entry may require manager approval, based on company
settings. - Audit log records edits to readings, dates, machine, site,
and status.

## 4.10 Fuel management

Fuel entry fields: - Fuel entry ID. - Date/time. - Machine. - Petrol
pump/supplier. - Liters. - Price per liter. - Total amount. - Optional
client/site allocation. - Receipt photo local path and metadata. -
Notes. - Created by/updated by. - Sync status.

Calculation: `totalFuelCost = liters × pricePerLiter`

Validation: - Liters must be greater than zero. - Price per liter cannot
be negative. - Total should be calculated automatically, with an
explicit override only if a justified adjustment feature is approved. -
Receipt photo is optional but recommended. - Fuel records must be
editable only according to role and status rules.

## 4.11 Invoice and billing

Invoice generation is based on approved, uninvoiced work logs.

Invoice header: - Company profile snapshot. - Invoice number. - Invoice
date. - Client billing details snapshot. - Billing period/date range. -
Payment terms. - Notes/terms. - Subtotal, taxes if configured, discounts
if enabled, total. - Status: draft, finalized, partially paid, paid,
cancelled. - Created/finalized by and timestamps.

Invoice lines: - Work date. - Site. - Machine. - Start meter reading. -
End meter reading. - Working hours. - Hourly rate. - Amount. - Optional
description.

Calculation: `lineAmount = workingHours × hourlyRate`
`invoiceSubtotal = sum(lineAmount)`
`invoiceTotal = subtotal + configured taxes/charges - discounts`

Requirements: - User selects client and date range. - App lists approved
uninvoiced work logs. - User selects eligible entries. - Hourly rate
defaults to site rate where available but can be overridden on the
invoice. - Rate override must not change the site master. - Different
sites/machines can have different rates. - Finalized invoice preserves
the exact client details, rates, descriptions, calculations, and company
details used at finalization. - Work logs included in a finalized
invoice cannot be invoiced again. - Invoice PDF is generated locally,
previewed, printed/shared through the device. - PDF file is stored
locally in the initial release. - Invoice numbering strategy must
account for multiple devices and offline operation. - Cancellation must
preserve the original invoice record and reason; avoid deleting
finalized invoices.

Tax/GST: - GST support should be implemented only after the client
confirms tax rules, intra/inter-state treatment, tax rate configuration,
and invoice format requirements. - Do not assume all customers require
identical tax configuration.

## 4.12 Payments and outstanding balances

Payment fields: - Payment ID. - Invoice ID. - Payment date. - Amount. -
Method: cash, bank transfer, UPI, cheque, other. - Reference number
(optional). - Notes. - Created by. - Sync status.

Calculations: `totalPaid = sum(valid payments for invoice)`
`outstanding = invoiceTotal - totalPaid`

Requirements: - Allow partial and full payments. - Prevent payment
amount from being negative. - Overpayment should be blocked or handled
through an explicitly approved credit/advance workflow. - Payment
reversal/correction must be auditable. - Dashboard displays paid,
partially paid, overdue, and outstanding totals.

## 4.13 Dashboard and reports

Mobile dashboard: - Today's work hours. - Work hours by machine. - Work
logs pending approval. - Fuel expenses for selected period. - Invoices
created. - Amount received. - Outstanding balance. - Sync status and
last successful sync. - License status and offline grace status, where
appropriate.

Reports: - Daily/weekly/monthly machine work report. - Site/client work
report. - Machine-wise meter readings. - Operator-wise work report. -
Fuel expense report. - Invoice register. - Payment register. -
Outstanding/aging report. - Manual-entry audit report. - Device and sync
status for troubleshooting.

Export: - PDF reports initially. - CSV/Excel export can be added if
required.

## 4.14 Local files and privacy

Version 1 policy: - Meter photos, fuel receipt photos, and generated
PDFs remain on the device. - Use app-private storage. - Store local file
paths and metadata in SQLite. - Do not upload local filesystem paths as
cloud URLs. - Do not upload photos/PDFs to Firestore. - Files are
device-specific and will not automatically appear on another device. -
Uninstall, app data clearing, device failure, or loss may destroy local
files. - Provide backup/export guidance where practical. - If cloud
backup of files is added later, use Firebase Storage or another secured
file storage service with explicit retention, privacy, and cost
requirements.

------------------------------------------------------------------------

# 5. Technical Architecture

## 5.1 Technology stack

### Mobile

-   Flutter and Dart.
-   Material 3.
-   Riverpod for state management.
-   GoRouter for navigation.
-   Drift/SQLite for local database.
-   Firebase Authentication.
-   Cloud Firestore.
-   Firebase Cloud Functions for trusted license/device operations.
-   `path_provider` for app-private file storage.
-   `camera` or `image_picker` for photos.
-   `geolocator` for location metadata.
-   `permission_handler` where appropriate.
-   `pdf` and `printing` for PDF generation/print/share.
-   `intl` for dates, currency, and formatting.
-   `connectivity_plus` as a connectivity hint (not proof that the
    backend is reachable).
-   `flutter_secure_storage` for suitable small secrets/tokens if
    needed.
-   Flutter Test and integration tests.

### Admin portal

-   React.js + Vite + JavaScript or TypeScript.
-   Firebase Authentication.
-   Firebase SDK for read operations permitted by Security Rules.
-   Sensitive license/device actions through Cloud Functions.
-   Firebase Hosting.

### Backend

-   Firebase Authentication.
-   Cloud Firestore.
-   Cloud Functions.
-   Firestore Security Rules.
-   App Check where supported.
-   Firebase Emulator Suite for local development/testing.
-   Crash reporting/monitoring where budget and platform support allow.

## 5.2 Architecture diagram

``` mermaid
flowchart TB
    DA[Developer Admin]
    CA[Company Admin / Field Users]
    AP[React Admin Portal]
    MA[Flutter Mobile App]
    LOCAL[(SQLite / Drift)]
    FILES[App-private Photos and PDFs]
    AUTH[Firebase Authentication]
    FN[Cloud Functions]
    DB[(Cloud Firestore)]
    HOST[Firebase Hosting]
    LOG[Audit Logs / Monitoring]

    DA --> AP
    CA --> MA
    AP --> HOST
    AP --> AUTH
    AP --> DB
    AP --> FN
    MA --> AUTH
    MA <--> LOCAL
    MA --> FILES
    MA <--> DB
    MA --> FN
    FN <--> DB
    FN --> LOG
    DB --> LOG
```

Note: Sensitive license, activation, device replacement, and revocation
operations should go through Cloud Functions or other trusted
server-side logic. Direct Firestore access is allowed only where
Security Rules enforce the user's company membership and permissions.

## 5.3 Offline-first data flow

``` mermaid
flowchart TD
    A[User creates or edits record] --> B[Validate in Flutter]
    B --> C[Save to local SQLite]
    C --> D[Mark record pending sync]
    D --> E{Backend reachable?}
    E -- No --> F[Keep local record and retry later]
    E -- Yes --> G[Authenticate and validate company/license]
    G --> H[Upload structured record]
    H --> I{Write accepted?}
    I -- No --> J[Record sync error and retry/resolve]
    I -- Yes --> K[Mark record synced]
    F --> E
    J --> E
```

Implementation notes: - Generate stable UUIDs on the client for
offline-created records. - Use idempotent writes to avoid duplicate
records after retries. - Store `createdAt`, `updatedAt`, `createdBy`,
`updatedBy`, `companyId`, `schemaVersion`, and `syncStatus` where
appropriate. - Define conflict policy per entity. For financial records,
avoid silent last-write-wins overwrites. - Use server timestamps for
server-side audit events. - Do not treat `connectivity_plus` as proof
that Firebase is reachable; attempt the actual operation and handle
failures. - Maintain a visible sync status and last successful sync
time. - Avoid syncing photos/PDFs in the initial version.

## 5.4 Multi-tenant data isolation

Each company has a unique immutable `companyId`.

All company-owned data must be scoped to that company. Recommended
structure:

``` text
developerAdmins/{adminUid}

companies/{companyId}
  companyUsers/{userUid}
  licenses/{licenseId}
  authorizedDevices/{deviceId}
  deviceReplacementRequests/{requestId}
  clients/{clientId}
  sites/{siteId}
  machines/{machineId}
  operators/{operatorId}
  petrolPumps/{pumpId}
  workLogs/{workLogId}
  fuelEntries/{fuelEntryId}
  invoices/{invoiceId}
  payments/{paymentId}
  auditLogs/{auditLogId}
```

Security requirements: - Verify authenticated user membership in the
requested company. - Verify role and permission for writes. - Prevent a
user from changing `companyId` to access another tenant. - Prevent
company users from writing developer-admin records. - Do not rely on
hidden UI controls as security. - Protect license keys; store hashes
where applicable rather than plaintext activation secrets. - Never embed
server credentials or license-generation secrets in the Flutter app or
web bundle. - Restrict developer admin access to designated
administrator identities. - Test Security Rules with authorized and
unauthorized users.

## 5.5 License and device architecture

License fields (example): - `companyId` - `status`: pending, active,
suspended, expired, revoked - `validFrom` - `validUntil` -
`maxDevices` - `createdAt` - `createdBy` - `updatedAt` -
`licenseKeyHash` or another secure activation identifier -
`lastValidatedAt` where appropriate

Authorized device fields: - `deviceId` - `companyId` - `userId` -
`deviceModel` - `platform` - `status`: pending, active, revoked -
`activatedAt` - `lastSeenAt` - `revokedAt` - `replacementForDeviceId`

Device ID: - Use a generated installation/device registration ID stored
securely by the app where possible. - Do not rely solely on a hardware
identifier that may be unavailable or resettable. - Define what happens
after app reinstall, device reset, or secure-storage loss. - A device
registration token is not proof of strong hardware identity.

### Activation workflow

``` mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant Auth as Firebase Auth
    participant CF as Cloud Function
    participant DB as Firestore

    User->>App: Sign in and enter activation code
    App->>Auth: Authenticate
    Auth-->>App: User identity/token
    App->>CF: Request activation (company, code, installation ID)
    CF->>DB: Validate company, license, expiry, device limit
    alt License valid and slot available
        CF->>DB: Create authorized device record
        CF-->>App: Activation approved
        App->>App: Cache minimal license state
    else Approval required or invalid
        CF-->>App: Deny or return pending status
    end
```

### Device replacement workflow

``` mermaid
flowchart TD
    A[New phone installed] --> B[User signs in]
    B --> C{License device limit reached?}
    C -- No --> D[Request activation]
    C -- Yes --> E[Submit replacement request]
    E --> F[Developer Admin reviews request]
    F --> G{Approve?}
    G -- No --> H[Reject with reason]
    G -- Yes --> I[Backend revokes old device authorization]
    I --> J[Backend authorizes new device]
    J --> K[New phone can use license]
    H --> L[User can contact support or resubmit]
```

Important: - Approve/revoke operations must be atomic or designed to
avoid two active devices accidentally exceeding the limit. - If old
phone is inaccessible, developer may approve replacement based on
customer verification. - Revocation cannot instantly affect a
disconnected offline device. - On reconnection, the app must revalidate
and stop protected cloud access for revoked devices. - Do not delete
company data when a license expires or device is revoked.

## 5.6 Offline license policy

Recommended starting policy: - Initial activation: online required. -
Periodic validation: every 24 hours when online. - Offline grace period:
configurable; a possible starting value is 7 days. - After grace period:
block new protected actions until online validation, but retain local
data and allow appropriate export/recovery workflows. -
Expired/suspended/revoked status is enforced when the device
reconnects. - Clearly display last validation time and offline status. -
The product owner must decide whether existing local records can still
be viewed/exported after license suspension.

This policy is a product decision and should be finalized before
implementation.

## 5.7 Invoice numbering in offline/multi-device use

Invoice numbering is a major design decision.

Recommended approach: - Allow offline invoices to remain drafts. -
Assign the official invoice number during finalization through a trusted
backend while online. - If offline finalization is essential, use a
unique number scheme including company prefix, device/installation code,
and sequence, then reconcile centrally. This may be less suitable for
statutory invoice numbering and must be reviewed with the customer's
accounting requirements. - Never rely on a single local counter across
multiple devices. - Finalized invoice snapshots must remain immutable
except for auditable cancellation/correction workflows.

------------------------------------------------------------------------

# 6. Data Model Summary

  ---------------------------------------------------------------------
  Entity                             Important fields
  ---------------------------------- ----------------------------------
  Company                            companyId, name, contact details,
                                     billing settings, status

  Company User                       userId, companyId, role, status,
                                     permissions

  Client                             clientId, companyId, name, billing
                                     details, status

  Site                               siteId, companyId, clientId, name,
                                     defaultHourlyRate, status

  Machine                            machineId, companyId, name/number,
                                     registration, initialMeterReading,
                                     status

  Operator                           operatorId, companyId, name,
                                     phone, status

  Petrol Pump                        pumpId, companyId, name, contact
                                     details, status

  Work Log                           workLogId, companyId, date,
                                     clientId, siteId, machineId,
                                     startReading, endReading, hours,
                                     status

  Fuel Entry                         fuelEntryId, companyId, machineId,
                                     supplierId, liters, pricePerLiter,
                                     totalAmount, date

  Invoice                            invoiceId, companyId, client
                                     snapshot, invoiceNumber, lines,
                                     totals, status

  Payment                            paymentId, companyId, invoiceId,
                                     amount, date, method, reference

  License                            licenseId, companyId, status,
                                     validFrom, validUntil, maxDevices

  Authorized Device                  deviceId, companyId, userId,
                                     status, activatedAt, lastSeenAt

  Replacement Request                requestId, companyId, oldDeviceId,
                                     newDeviceId, reason, status,
                                     reviewedBy

  Audit Log                          auditLogId, companyId (where
                                     relevant), actorId, action,
                                     entityType, entityId, timestamp
  ---------------------------------------------------------------------

All money values should use a consistent decimal/currency strategy.
Avoid floating-point calculations for currency; use integer minor units
(paise) or a safe decimal representation. Store timestamps consistently,
generally as UTC instants, and display them in the configured local
timezone.

------------------------------------------------------------------------

# 7. Application Screens

## 7.1 Mobile app screens

### Authentication and setup

-   Splash/loading.
-   Login.
-   Forgot password or selected auth recovery.
-   Company/activation status.
-   License activation.
-   Device replacement request.
-   Company profile setup.

### Dashboard

-   Work summary.
-   Pending approvals.
-   Fuel summary.
-   Invoice/payment summary.
-   Sync indicator.
-   License/device status.

### Masters

-   Client list/form/details.
-   Site list/form/details.
-   Machine list/form/details.
-   Operator list/form/details.
-   Petrol pump list/form/details.
-   Company settings.

### Work management

-   Work log list.
-   Create work log.
-   Start meter capture.
-   End meter capture.
-   Manual work entry.
-   Work log detail.
-   Approval/rejection.
-   Correction/audit history.

### Fuel

-   Fuel entry list.
-   Create fuel entry.
-   Capture receipt photo.
-   Fuel entry details.

### Billing

-   Invoice candidate list.
-   Select work logs.
-   Rate review/override.
-   Invoice preview.
-   Invoice PDF preview/share/print.
-   Invoice list/details.
-   Payment entry.
-   Outstanding report.

### Reports/settings

-   Work report.
-   Machine report.
-   Fuel report.
-   Invoice/payment report.
-   Sync queue/errors.
-   User management (authorized roles).
-   Privacy, export and support information.

## 7.2 Developer Admin Portal screens

-   Admin login.
-   Dashboard.
-   Company list/detail/create/edit.
-   License list/create/detail/edit.
-   Device list/detail.
-   Pending device activations.
-   Replacement request queue/detail.
-   License suspension/reactivation.
-   Audit logs.
-   Admin user management (optional).
-   System settings and support details.

------------------------------------------------------------------------

# 8. Non-Functional Requirements

## Security

-   Firebase Authentication for identity.
-   Firestore Security Rules with default-deny posture.
-   Cloud Functions for privileged operations.
-   Least-privilege roles.
-   No secret keys in the mobile app or web bundle.
-   Validate all input on client and backend.
-   Audit important license, device, invoice and payment changes.
-   App Check may be enabled where supported, but it does not replace
    authentication or authorization.

## Performance

-   Main local screens should load from SQLite without waiting for the
    network.
-   Paginate large lists.
-   Use indexes for common Firestore queries.
-   Avoid unbounded listeners and unnecessary reads.
-   Test with realistic data volumes.

## Reliability

-   Local writes should survive app restarts.
-   Sync retries should be safe and idempotent.
-   Network failures should not discard user-entered data.
-   Display clear sync errors.
-   Prevent duplicate invoices/payments/work logs from retry operations.

## Privacy

-   Request camera/location permissions only when needed.
-   Explain why location is captured.
-   Store photos in app-private storage.
-   Do not upload photos/PDFs in version 1.
-   Provide a data retention and customer support policy.

## Accessibility and usability

-   Clear forms and validation.
-   Large tap targets suitable for field use.
-   Readable text in outdoor environments.
-   Confirmation before destructive/corrective actions.
-   Support low-connectivity operation.
-   Localized date and currency formatting.

## Backup and disaster recovery

-   Firestore data is cloud-hosted, but backup/restore procedures still
    need to be designed and tested.
-   Local-only photos and PDFs are not backed up by Firestore.
-   Document how customers export invoices and critical evidence.
-   Establish a recovery procedure for lost phones and unsynchronized
    records.

------------------------------------------------------------------------

# 9. Testing Strategy

## Unit tests

-   Work-hour calculation.
-   Fuel total calculation.
-   Invoice line and invoice total calculations.
-   Payment/outstanding calculation.
-   Reading validation.
-   License status and offline grace rules.
-   Role/permission helpers.

## Widget tests

-   Login and activation screens.
-   Masters forms.
-   Work log forms.
-   Meter capture/entry flow.
-   Invoice creation and rate override.
-   Payment entry.
-   Sync status UI.

## Integration tests

-   Company onboarding.
-   License activation.
-   Device-limit enforcement.
-   Device replacement approval.
-   Offline work log creation and later sync.
-   Fuel entry and receipt file handling.
-   Invoice generation and payment recording.
-   Multi-company isolation.
-   License expiry and suspension behavior.

## Security tests

-   Company A user cannot read/write Company B data.
-   Company users cannot change their own role to admin.
-   Mobile client cannot grant itself a license.
-   Mobile client cannot approve/revoke devices.
-   Non-admin cannot access developer-admin records.
-   Revoked device cannot continue protected cloud operations after
    reconnecting.
-   Invalid or expired license activation is denied.

## Acceptance tests

-   Work hours match ending minus starting meter readings.
-   Manual records require reasons and are auditable.
-   Site default rate remains unchanged after invoice rate override.
-   Finalized invoice snapshot is preserved.
-   Partial payments update outstanding balance correctly.
-   Offline records persist and synchronize without duplication.
-   Device replacement respects license device limits.
-   Photos/PDFs remain local in version 1.

------------------------------------------------------------------------

# 10. Complete Sprint Plan: From Scratch to Deployment

Planning assumption: a small team consisting of one Flutter developer,
one React/backend developer, and QA/part-time product support. A solo
developer should expect the schedule to be longer. Sprint duration is
two weeks. The following is an indicative plan, not a fixed delivery
commitment.

## Sprint Status Tracker

| Sprint | Title | Status |
|--------|-------|--------|
| 0 | Discovery and project setup | ✅ **COMPLETE** (2026-10-29) |
| 1 | UI foundation and navigation | ✅ **COMPLETE** (2026-10-29) |
| 2 | Authentication and company onboarding | ✅ **COMPLETE** (2026-10-29) — console setup + rules deploy pending owner |
| 3 | Masters and local database | ✅ **COMPLETE** (2026-10-29) |
| 4 | Work logs and meter readings | ✅ **COMPLETE** (2026-10-29) |
| 5 | Fuel management | ✅ **COMPLETE** (2026-10-29) |
| 6 | Invoicing, PDF and payments | ✅ **COMPLETE** (2026-10-29) — Cloud Function deploy pending owner (Blaze plan) |
| 7 | Offline sync engine | ✅ **COMPLETE** (2026-10-29) — rules deploy pending owner |
| 8 | License backend and device activation | ✅ **COMPLETE** (2026-10-29) — functions/rules deploy pending owner |
| 9 | Developer Admin Portal | ✅ **COMPLETE** (2026-10-29) — deploy pending owner |
| 10 | Device replacement and user administration | ✅ **COMPLETE** (2026-10-29) — deploy pending owner |
| 11 | Reports, polish and security hardening | ⏳ Not started |
| 12 | QA, UAT and data recovery tests | ⏳ Not started |
| 13 | Deployment and launch | ⏳ Not started |

Detailed board and blockers: `docs/backlog.md`.

**Platform decision (2026-10-29):** Android only. iOS is out of scope for
development, testing and release; iOS items elsewhere in this document no
longer apply.

## Sprint 0 --- Discovery and project setup (Week 1)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Requirements baseline: `docs/product-decisions.md` — all 18 decisions
>   recorded with proposed defaults; **awaiting product-owner confirmation**.
> - Architecture decision record: `docs/adr/0001-architecture-baseline.md`.
> - Backlog, user stories and sprint board: `docs/backlog.md`.
> - Conventions, branching, code review: `docs/conventions.md`.
> - Monorepo initialized (git): `mobile/`, `admin/`, `firebase/`, `docs/`.
> - Flutter starter (`mobile/`) builds for Android (debug APK) and iOS
>   simulator. React + Vite + TS starter (`admin/`) builds and runs.
> - Environment strategy: dev/staging/prod via `APP_ENV` dart-define and
>   Firebase aliases in `firebase/.firebaserc`; default-deny `firestore.rules`.
> - Firebase project `jcb-work-management` provided by owner (used as dev;
>   staging/prod projects to be created before Sprint 12). Firebase CLI
>   installed locally in `firebase/` (`npx firebase`).

### Goals

-   Confirm business rules and product boundaries.
-   Set up repositories, environments and project conventions.

### Tasks

-   Confirm company/user roles.
-   Confirm invoice, GST, numbering, payment and approval rules.
-   Confirm device limits and replacement policy.
-   Confirm offline grace policy.
-   Confirm local-only photo/PDF policy.
-   Create user stories and acceptance criteria.
-   Create Git repositories or monorepo.
-   Install Flutter, Android Studio, Node.js and Firebase CLI.
-   Configure FlutterFire.
-   Create development Firebase project.
-   Configure dev/staging/production environment strategy.
-   Define naming conventions, code style, branching and code review
    process.

### Deliverables

-   Approved requirements baseline.
-   Architecture decision record.
-   Backlog and sprint board.
-   Working Flutter and React starter projects.
-   Firebase development project.

### Exit criteria

-   App builds locally.
-   Admin portal runs locally.
-   Team agrees on data model and product decisions.

## Sprint 1 --- UI foundation and navigation (Weeks 2--3)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Mobile: Material 3 design system (`lib/core/theme/` tokens, light/dark,
>   status colors, reduced-motion aware), reusable components
>   (`lib/core/widgets/`: buttons, text/dropdown/date fields, cards, status
>   chips, metric tiles, dialogs, bottom sheets, snackbars, loading/empty/
>   error/offline/permission states, sync indicator, offline banner),
>   Riverpod 3, GoRouter with auth guard + 4-tab shell, splash, login, Drift
>   database with migration baseline (settings + audit log tables),
>   persisted theme choice, dev component gallery.
> - Admin: React Router layout with sidebar (responsive drawer < 900px),
>   route protection, login screen, dashboard shell, section pages,
>   token-based CSS, accessibility (skip link, focus rings, labels).
> - Quality: `flutter analyze` 0 issues, 23 Flutter tests passing (incl.
>   no-overflow checks at 320/411/800dp × 1.0/2.0 text scale); admin oxlint
>   clean, `tsc` build OK, 5 Vitest tests passing. CI pipeline:
>   `.github/workflows/ci.yml`.
> - Note: sign-in is a development stand-in (any valid email) until Firebase
>   Authentication replaces it in Sprint 2. Production admin builds refuse it.

### Mobile tasks

-   Material 3 theme.
-   App structure and folders.
-   Riverpod setup.
-   GoRouter navigation.
-   Reusable form controls, buttons, dialogs and error states.
-   Login, loading, empty, offline and error screens.
-   Local database setup and migrations baseline.

### Admin tasks

-   React + Vite setup.
-   Shared layout, navigation, route protection shell.
-   Login screen UI.
-   Dashboard shell.
-   Responsive desktop layout.

### Deliverables

-   Navigable mobile skeleton.
-   Admin portal skeleton.
-   Base UI components and lint/test configuration.

### Exit criteria

-   Navigation works.
-   UI follows agreed design system.
-   Build pipeline runs.

## Sprint 2 --- Authentication and company onboarding (Weeks 4--5)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Firebase connected: project `jcb-work-management`, Android package
>   `com.app.jcb_work_management` (`google-services.json`,
>   `lib/firebase_options.dart`). iOS bundle `com.app.jcbWorkManagement` —
>   not yet registered in Firebase (iOS is not in the first release).
> - Mobile: Firebase email/password sign-in with friendly errors, sign-out,
>   password reset; session-driven route guard (splash → login → company
>   setup → pending/suspended → company picker → app); company registration
>   (pending until approved), company profile view/edit for owner/admin;
>   multi-company switching; role/permission model; Drift company cache
>   (schema v2 migration) so the app opens offline after first sign-in.
> - Firestore Security Rules (default-deny): self-registration only as
>   `pending` owner in one batch, no self-granted roles, no self-approval,
>   tenant isolation, profile edits limited to owner/admin and safe fields,
>   developer-admin allowlist (`developerAdmins/{uid}`) not client-writable.
>   Collection-group index for membership lookup.
> - Admin portal: Firebase Auth sign-in restricted to the developer-admin
>   allowlist (non-admins are signed out), session restore, password reset,
>   "not configured" state; Firebase SDK lazy-loaded.
> - Quality: Flutter analyze 0 issues, **64 Flutter tests**; **23 Security
>   Rules tests** in the Firestore emulator; admin **11 tests**, lint and
>   build clean. CI runs all three.
> - ⛔ **Owner actions** (see `firebase/README.md`): enable Email/Password
>   auth, create the Firestore database, deploy rules/indexes, add
>   `developerAdmins` docs, register a Web app for the admin portal.

### Tasks

-   Firebase Authentication integration.
-   Login/logout and recovery flow as applicable.
-   Company profile setup.
-   Company membership and role model.
-   Local company profile caching.
-   Secure route guards.
-   Admin authentication.
-   Initial Firestore Security Rules.
-   Developer admin identity allowlist or protected admin role setup.

### Deliverables

-   User can sign in.
-   Company profile can be created/loaded.
-   Admin portal access is restricted to authorized developer admins.

### Exit criteria

-   Unauthenticated users cannot access protected screens.
-   Company membership is checked.
-   Security rules tests cover basic access.

## Sprint 3 --- Masters and local database (Weeks 6--7)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Drift tables (schema v3, migration from v1/v2 tested) for clients,
>   sites (linked to a client), machines, operators and petrol pumps, with
>   shared tenant/audit/sync columns: `companyId`, `isActive`, `createdAt/By`,
>   `updatedAt/By`, `deletedAt` (tombstone), `syncStatus` (`pending`),
>   `version` (bumped on every change). Indexed by company.
> - Full CRUD offline: list with search, Active/Inactive/All filter and live
>   counts; detail with status, sync state and last-updated; create/edit
>   forms with field validation and unsaved-changes guard; deactivate /
>   reactivate; delete only when unreferenced (a client with sites is
>   refused and offered deactivation).
> - Validation & duplicates: required fields, phone/email/GSTIN formats,
>   money in paise and meter readings in hundredths of an hour (no float
>   maths), case-insensitive duplicate names per company (sites per
>   client), duplicate machine registration numbers; a site cannot link to
>   another company's client.
> - Every change writes an audit log entry (field-level diff on edits).
> - Only owners/admins can change masters; other roles view only.
> - Fixes found by tests: snack bars no longer cover the Add button; form
>   validation now checks fields scrolled off-screen.
> - Quality: analyze 0 issues, **105 Flutter tests** (20 repository tests:
>   tenant isolation, duplicates, references, tombstones, audit), screens
>   checked at 320/411/800dp × 1.0/2.0 text scale; Android build OK.
> - Note: Firestore rules for master collections are added with the sync
>   engine (Sprint 7); until then these collections stay default-deny and
>   records are local-only.

### Tasks

-   Client master CRUD.
-   Site master CRUD and client relationship.
-   Machine master CRUD.
-   Operator master CRUD.
-   Petrol pump master CRUD.
-   Local Drift tables and migrations.
-   Search, filters and active/inactive status.
-   Structured sync metadata.
-   Validation and duplicate detection.

### Deliverables

-   Masters work offline.
-   Local database is stable and migration-tested.

### Exit criteria

-   CRUD works without internet.
-   Linked records validate correctly.
-   Existing referenced records cannot be accidentally hard-deleted.

## Sprint 4 --- Work logs and meter readings (Weeks 8--9)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Work log list (status filters, grouped by date, "Running" for logs
>   awaiting their end reading), form and detail screens; Work tab FAB
>   "Log work". Dashboard "Work hours today" and "Pending approval" tiles now
>   show live values.
> - Start/end meter readings stored in hundredths of an hour;
>   `workingHours = end − start` computed live and on save; end < start is
>   blocked. Start a log in the morning, add the end reading later.
> - Camera capture (`image_picker`), photos moved into app-private storage
>   under `evidence/<companyId>/` with **relative** paths (survive restarts —
>   tested); never uploaded. Capture time, latitude/longitude/accuracy
>   (`geolocator`) recorded; denied permission, location off or no fix are
>   recorded as such and never block saving. Camera denial explains and
>   offers Settings or manual entry. Photos taken in a discarded form are
>   deleted.
> - Manual entry is automatic when a reading has no photo, clearly marked,
>   and requires a reason to submit.
> - States: draft → submitted → approved / rejected (reason) → resubmit;
>   cancelled (reason required once approved); approvers' own entries are
>   approved immediately (decision #6). Approved logs can only be changed
>   by owner/admin through "Correct" with a mandatory reason; every action
>   is in the audit log and shown as History (with reading changes).
> - Anomaly warnings needing confirmation and stored as flags: start below
>   the machine's last reading, more than 12 h (`AppConfig.highDailyHours`,
>   PROPOSED), second log for the same machine and date.
> - Masters used by work logs can no longer be deleted (deactivate instead).
> - Fixes found by tests: spinners left running behind dialogs; text
>   overflow at 320dp with large text.
> - Quality: analyze 0 issues, **142 Flutter tests**; Android build OK.
> - Platform: **Android only** (product decision #15, confirmed by owner).
> - Known limitation: if Android kills the app while the camera is open on
>   very low-memory phones, that one photo is lost (`image_picker`
>   lost-data recovery not wired); the user retakes it.

### Tasks

-   Work log list and form.
-   Start/end meter readings.
-   Working-hours calculation.
-   Camera/image capture integration.
-   Local photo storage and metadata.
-   Timestamp and location capture with permission handling.
-   Manual work entry with required reason.
-   Work log states and approval.
-   Audit trail for corrections.
-   Meter validation and anomaly warnings.

### Deliverables

-   Complete offline work logging.
-   Photos stored locally only.
-   Manual entries visibly marked.

### Exit criteria

-   Working hours calculate correctly.
-   Permissions denied gracefully.
-   Photos remain available after app restart.
-   Corrections are auditable.

## Sprint 5 --- Fuel management (Weeks 10--11)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - New **Fuel** tab (5th bottom-nav destination): period chips (this
>   week / this month / last month), summary card (total cost, litres,
>   fills, weighted average ₹/L, per-machine spend bars), entries grouped
>   by date. Dashboard "Fuel this month" tile is live.
> - Fuel entry create / view / edit / delete (Drift schema v5, offline):
>   date and time, machine, petrol pump/supplier (price prefilled from the
>   last fill at that pump), litres (hundredths), price per litre (paise),
>   optional client/site allocation, notes.
> - `total = litres × price`, integer maths rounded half-up to the paisa;
>   no manual override (doc §4.10). Litres must be > 0; price ≥ 0; sanity
>   limits 2,000 L and ₹500/L; no future times; site must belong to the
>   client.
> - Receipt photo (optional) with time and location, stored app-private
>   with a relative path; never uploaded. Camera/location capture is now one
>   shared helper used by work logs and fuel.
> - Permissions: owner/admin edit any entry; operators/managers edit only
>   their own; accounts view only. Every change is audited, marked
>   `pending` sync and versioned; delete is a tombstone.
> - Pumps, machines, clients and sites used by fuel entries can no longer
>   be deleted.
> - Quality: analyze 0 issues, **167 Flutter tests** (13 fuel unit tests,
>   6 fuel flow tests, fuel screens at 320/411/800dp × 1.0/2.0 text);
>   Android build OK.

### Tasks

-   Fuel entry CRUD.
-   Machine and supplier selection.
-   Liters, price per liter and total calculations.
-   Optional site/client allocation.
-   Receipt photo capture and local storage.
-   Fuel report summary.
-   Audit and sync metadata.

### Deliverables

-   Fuel management module.

### Exit criteria

-   Totals validate correctly.
-   Receipt photo paths are local.
-   Entries persist offline.

## Sprint 6 --- Invoicing, PDF and payments (Weeks 12--13)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Billing tab: outstanding / overdue / received-this-month summary,
>   invoice register with state filters (Draft, Unpaid, Partially paid,
>   Paid, Overdue, Cancelled). Dashboard "Outstanding" tile is live.
> - Invoice builder: client + billing period → approved, unbilled work
>   logs grouped by site and machine, all selected by default; rate per
>   group prefilled from the site default and overridable **for this
>   invoice only** (site master unchanged — tested); invoice date, payment
>   terms, discount, notes; live subtotal/total. `line = hours × rate`,
>   integer paise, half-up.
> - Drafts reserve their work logs so a log can never be on two invoices;
>   editing/deleting a draft releases logs. Finalize issues the official
>   number from the server, freezes company and client details
>   (snapshots) and marks logs `invoiced` (locked from correction).
>   Finalized invoices are immutable; cancellation needs a reason, is
>   blocked while payments exist, keeps the number, and frees the work for
>   re-billing. Every action is in the invoice history.
> - **Invoice numbering (decisions #7–8):** Cloud Function
>   `allocateInvoiceNumber` (`firebase/functions`, `asia-south1`) issues
>   `{prefix}/{FY}/{0001}` per company and Indian financial year in a
>   Firestore transaction; idempotent per invoice; owner/admin/accounts of
>   an active company only. 8 emulator tests incl. 12 concurrent requests
>   with no duplicates. Counters are not client-readable/writable (rules
>   test). Finalizing offline is refused with a clear message; drafts work
>   fully offline.
> - Payments: partial and full, cash/bank/UPI/cheque/other with
>   reference; overpayment blocked; reversal with reason (kept, not
>   counted); outstanding and state derived (overdue after due date).
> - PDF: A4 invoice (bundled Noto Sans for the ₹ sign), multi-page tables,
>   DRAFT/CANCELLED watermark, preview with system print and share
>   (`printing`); finalized PDFs also saved app-private. Never uploaded.
> - Roles: owner/admin/accounts create invoices and record payments;
>   managers view; operators have no billing access.
> - Fixes found by tests: floating buttons sharing an animation tag across
>   tabs; amount column overflow at 320dp with large text.
> - Quality: analyze 0 issues, **198 Flutter tests**, 24 rules tests, 8
>   function tests; Android build OK. CI runs function tests.
> - ⛔ **Owner action:** enable the Blaze plan and run
>   `cd firebase && npm run deploy:functions`; until then invoices can be
>   drafted, previewed and shared but not finalized.
> - GST is not calculated (decision #9 pending); invoice total =
>   subtotal − discount.

### Tasks

-   Select client and billing period.
-   List approved uninvoiced work logs.
-   Select eligible work entries.
-   Rate selection from site default.
-   Invoice-only rate override.
-   Invoice calculation and snapshot.
-   Draft/finalized/cancelled status flow.
-   Invoice PDF generation, preview, print/share.
-   Invoice list/detail.
-   Payment entry and partial payments.
-   Outstanding balance and invoice register.
-   Invoice numbering strategy implementation.

### Deliverables

-   Invoice-to-payment workflow.
-   Local PDF output.

### Exit criteria

-   No work log can be invoiced twice.
-   Rate override does not alter site master.
-   Finalized invoice values are immutable except through auditable
    correction/cancellation.
-   Partial payment balances are correct.

## Sprint 7 --- Offline sync engine (Weeks 14--15)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - Two-way sync of clients, sites, machines, operators, petrol pumps,
>   work logs, fuel entries, invoices (with lines), payments and history to
>   `companies/{companyId}/{collection}/{id}`. Local writes are the queue
>   (`syncStatus = pending`); per-record bookkeeping in a new `sync_records`
>   table (schema v7).
> - **Idempotent and duplicate-free:** records keep their client-generated
>   IDs; a lost server reply is recognised on retry (identical content) and
>   is not a conflict. Tested by re-running sync on two devices.
> - **Optimistic concurrency:** each server document has a revision that
>   must advance by exactly one per write (enforced in the client
>   transaction and in Firestore rules).
> - **Conflict policy per entity:** masters — newest `updatedAt` wins and
>   the overwritten version is written to the history (`sync_overwrite`);
>   work logs, fuel, invoices, payments — never auto-merged: the record is
>   flagged and the user chooses "Keep this phone's" or "Use server
>   version"; history — append-only.
> - **Pull:** paginated (200/page) downloads ordered by server time with a
>   stored cursor, so a new phone gets everything and later syncs only
>   fetch changes. Records with unsynced local edits are never overwritten
>   by a download. Billing collections are skipped for roles without
>   billing access.
> - **Triggers and backoff:** on startup, when connectivity returns, 5 s
>   after local changes, every 5 minutes, and "Sync now"; when the server
>   is unreachable, retries back off from 30 s to 15 min. The app keeps
>   working from the local database throughout.
> - **Status and reconciliation:** dashboard and More show the overall
>   state (Saved on device / Pending / Syncing / Synced / Offline / Needs
>   attention); records show Synced / Pending / Conflict / Error. New
>   **Sync & data** screen: last sync, pending count, Sync now, conflicts
>   and refused changes with their reasons and actions, and a per-collection
>   local-vs-synced data check. Server timestamps (`serverUpdatedAt`),
>   pushing user and device ID are stored on every document.
> - Photo, receipt and PDF paths stay on the device (never uploaded; kept
>   when records are downloaded again); capture time and location sync.
> - **Firestore rules** for all synced collections: revision chain, true
>   IDs/company/pusher, no deletes, active company only, tenant isolation;
>   masters owner/admin only; work-log maths and manual reason, operators
>   own logs only and can't approve, accounts limited to invoice state;
>   fuel total = litres × price; invoice drafts unnumbered, finalizing only
>   with the server-issued number, finalized invoices change only by
>   cancellation with a reason; payments only reversed; history
>   append-only; billing unreadable by operators.
> - Quality: analyze 0 issues, **216 Flutter tests** (14 two-device sync
>   engine tests, 4 sync screen tests), **45 rules tests** (21 new), 8
>   function tests; Android build OK.
> - ⛔ **Owner action:** deploy the updated rules
>   (`cd firebase && npm run deploy:rules`); sync needs an approved
>   (active) company.

### Tasks

-   Sync queue.
-   Stable IDs and idempotent writes.
-   Retry/backoff strategy.
-   Connectivity-aware sync trigger.
-   Sync status indicators.
-   Conflict handling per entity.
-   Server timestamps and metadata.
-   Handling failed syncs and validation errors.
-   Paginated initial download and refresh.
-   Multi-device behavior tests.
-   Data reconciliation tools/logging.

### Deliverables

-   Structured records sync between local database and Firestore.

### Exit criteria

-   Offline entries sync without duplication.
-   App remains usable when backend is unavailable.
-   Conflicts are surfaced instead of silently losing financial data.

## Sprint 8 --- License backend and device activation (Weeks 16--17)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - **License model:** `companies/{id}/licenses/{licenseId}` (status
>   pending/active/suspended/expired/revoked, validFrom/validUntil,
>   maxDevices, `activationCodeHash`, lastValidatedAt) and
>   `companies/{id}/authorizedDevices/{deviceId}` (status, licenseId,
>   userId, model, activatedAt, lastSeenAt). Server history in
>   `auditEvents` (developer admins only).
> - **Activation codes:** random `JCBW-XXXX-XXXX-XXXX` (60 bits, no
>   ambiguous characters); only a SHA-256 hash is stored; the plaintext is
>   returned once. No license secret exists in the app.
> - **Cloud Functions** (`asia-south1`): `createLicense` (developer admins
>   only), `activateDevice` (membership, active company, code, status,
>   dates, revoked device, and the device limit checked inside a
>   transaction — 8 concurrent activations on a 3-device license yield
>   exactly 3), `validateLicense` (returns state, never throws for
>   inactive states, persists date-based expiry). Activations, re-checks
>   and every denial (with reason) are audited. Command-line
>   `createLicense` for issuing licenses until the admin portal.
> - **Rules:** licenses and devices are server-only (no client read or
>   write); every business-data write must come from an active device
>   registered to the same user under an active, in-date license — a
>   revoked device or suspended/expired license is cut off on reconnect
>   while reads of existing data keep working.
> - **App:** one-time online **activation screen** (code entry, clear
>   refusal reasons incl. device limit, device ID for support); license
>   cache per company and user; checks on startup, reconnect and hourly
>   when older than 24 h; **offline grace of 7 days** (warning banner with
>   days left), then **read-only**: data stays viewable/shareable, create
>   and edit screens redirect to the **License** screen and in-place
>   actions (approve, cancel, delete, finalize, payments, deactivate, edit
>   company) explain why they're blocked; sync keeps downloading but pauses
>   uploads. Renewal warning 14 days before the end date. A phone clock
>   set back to stretch the grace period is detected. License screen:
>   state, valid until, last check, devices allowed, device ID, Check now.
> - Quality: analyze 0 issues, **238 Flutter tests** (license policy, flows,
>   screens at 320/411/800dp × 1.0/2.0 text), **51 rules tests**, **21
>   function tests** (13 license); Android build OK.
> - ⛔ **Owner action:** `npm run deploy:rules` and
>   `npm run deploy:functions` (Blaze plan), then issue a license per
>   company (see `firebase/README.md`). Existing phones must be activated
>   once before they can sync changes.

### Tasks

-   License data model.
-   Secure activation code generation/validation.
-   Cloud Functions for activation and validation.
-   Device registration and device limit checks.
-   License status and expiry checks.
-   Periodic online validation.
-   Offline grace behavior.
-   App-side license state UI.
-   Audit events for activation and denial.
-   Emulator-based backend tests.

### Deliverables

-   Secure license activation flow.

### Exit criteria

-   Flutter client cannot self-approve.
-   Invalid, expired, suspended and revoked licenses are denied.
-   Device limit is enforced server-side.
-   License secrets are not embedded in the app.

## Sprint 9 --- Developer Admin Portal (Weeks 18--19)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - **Dashboard:** live counts (companies awaiting approval / active /
>   suspended, active licenses and those ending within 30 days, expired and
>   suspended licenses, active phones, pending replacement requests) linking
>   to filtered lists, plus recent activity.
> - **Companies:** list with status tabs (all / awaiting approval / active /
>   suspended), name search (prefix, via a lower-cased `nameLower` field the
>   app now writes and rules verify) and "Load more" paging; create a
>   company with its owner account (owner sets a password via "Forgot
>   password"); detail with profile edit, approve / suspend / reactivate
>   (reason required), members, licenses, phones and activity.
> - **Licenses:** cross-company list by status, soonest end date first;
>   create (activation code shown once, copy button); detail with extend
>   (an expired license renewed becomes active), change phones allowed
>   (refused below the number of active phones), suspend / reactivate /
>   revoke (final), issue a new activation code (old one stops working),
>   phones on the license, history.
> - **Devices:** cross-company list (active / revoked), detail with
>   license, user, activation and last-seen times, revoke with reason,
>   history.
> - **Audit log viewer:** all license, device and admin actions, newest
>   first, filter by action, paging.
> - **Sensitive actions only through Cloud Functions** (`setCompanyStatus`,
>   `adminCreateCompany`, `adminUpdateCompany`, `setLicenseStatus`,
>   `updateLicense`, `rotateActivationCode`, `revokeDevice`, plus
>   `createLicense`). Each re-checks the admin on the server, requires a
>   reason where it changes state, and writes `auditEvents` with
>   before/after values.
> - **Role-based admin access:** `developerAdmins/{uid}.role` = `super`
>   (everything) or `support` (read-only plus explicit `permissions`:
>   `companies.manage`, `licenses.manage`, `devices.revoke`). Missing role =
>   support (least privilege). The portal shows the role and hides actions
>   the admin isn't allowed; the server refuses them regardless.
> - Rules: developer admins may query licenses, devices, members and
>   replacement requests across companies; new composite indexes for the
>   portal's queries.
> - Fix found by tests: dialog focus jumped back to the first field while
>   typing in later fields.
> - Quality: portal lint clean, type-check and build OK, **22 portal tests**
>   (pages, search, paging, dialogs, roles); **33 function tests** (12
>   admin), **53 rules tests**; mobile still **238 tests** passing.
> - ⛔ **Owner action:** set `role: "super"` on your `developerAdmins` doc,
>   then deploy rules, indexes and functions, and the portal to Hosting
>   (`npm --prefix admin run build && cd firebase && npx firebase deploy
>   --only hosting`).

### Tasks

-   Dashboard metrics.
-   Company list/create/edit/detail.
-   License list/create/edit/detail.
-   License activation/suspension/expiry/revocation.
-   Authorized device list.
-   Device details and history.
-   Search, filtering and pagination.
-   Audit log viewer.
-   Sensitive actions invoke Cloud Functions.
-   Role-based admin access.

### Deliverables

-   Functional Developer Admin Portal.

### Exit criteria

-   Only approved developer admins can manage licenses.
-   Privileged changes are validated by backend.
-   Audit history is recorded.

## Sprint 10 --- Device replacement and user administration (Weeks 20--21)

> **Status: ✅ COMPLETE (2026-10-29)**
>
> - **Request (app):** when activation is refused because the license is
>   full, the activation screen offers "Request a replacement": reason
>   (lost / damaged / stolen / new phone / other + details) and the
>   activation code, which proves the requester was given access. The
>   request registers this phone's installation ID; the phone shows
>   "Request sent", remembers it across restarts, and "Check again" picks up
>   approval (phone unlocks) or rejection (reason shown, new request
>   possible).
> - **Storage:** `companies/{id}/deviceReplacementRequests/{id}` (pending /
>   approved / rejected, requester, new phone, reason, reviewer, review
>   reason, revoked phone). Written only by Cloud Functions; readable by the
>   requester and the company's owner/admins.
> - **Review (portal):** Replacement requests queue (pending / approved /
>   rejected / all). The review dialog lists the license's active phones
>   with last-seen times, preselects the requester's own phone, and offers
>   "none" only when a place is free; approve or reject with a reason.
> - **Safe swap:** `reviewReplacement` revokes the old phone and authorizes
>   the new one in one transaction that re-checks the limit — tested with
>   two approvals racing for the last place (only one wins). Rejected
>   requests never activate the new phone. Old phone lost/destroyed: nothing
>   is needed from it; it can't re-activate itself, becomes read-only on
>   reconnect, and its local data is never deleted. Device history links
>   old ↔ new phone; every step is audited (request, approve/reject, revoke,
>   activate). Replacement limits were not required (left as a policy
>   option).
> - **Company user management (app → More → Users, owner/admin):** add a
>   user by email with a role (account created if needed; they set a
>   password via "Forgot password"), change role, disable / re-enable
>   access. Server rules: never the owner or yourself; only the owner adds,
>   changes or disables admins. Disabled users keep data on their phones but
>   lose server access. All audited.
> - Fixes found by tests: router redirects re-ran inside Riverpod's update
>   pass (double rebuild after an in-app restart); bottom sheets overflowed
>   with large text (now scroll).
> - Quality: **252 Flutter tests**, **25 portal tests**, **45 function
>   tests** (12 new), **56 rules tests**; analyze/lint clean; Android build
>   OK.
> - ⛔ **Owner action:** deploy rules, indexes, functions and the portal.

### Tasks

-   Device replacement request screen in mobile app.
-   Reason and new installation registration.
-   Replacement request storage and status.
-   Admin pending request queue.
-   Approve/reject with reason.
-   Safe old-device revocation and new-device authorization.
-   Device history and replacement limits if required.
-   Customer company user management.
-   Test old phone unavailable/damaged scenarios.

### Deliverables

-   End-to-end device replacement workflow.

### Exit criteria

-   Device limit is not exceeded.
-   Rejected requests do not activate the new device.
-   Replacement is auditable.
-   Local data is not automatically deleted by revocation.

## Sprint 11 --- Reports, polish and security hardening (Weeks 22--23)

### Tasks

-   Dashboard and report totals.
-   Work, fuel, invoice and payment reports.
-   Sync queue/error screen.
-   Empty/loading/error states.
-   App privacy and permission explanations.
-   Firestore Rules review.
-   App Check evaluation.
-   Cloud Functions authorization review.
-   Rate limiting/abuse controls where appropriate.
-   Input validation and error logging.
-   Accessibility and performance review.

### Deliverables

-   Feature-complete release candidate.

### Exit criteria

-   Reports reconcile to source records.
-   Security tests pass.
-   No known critical security issues remain.

## Sprint 12 --- QA, UAT and data recovery tests (Weeks 24--25)

### Tasks

-   Unit/widget/integration test completion.
-   Test on supported Android versions/devices.
-   Offline/online transition testing.
-   Device replacement testing.
-   License expiry/suspension testing.
-   Multi-company data isolation tests.
-   Invoice and payment regression testing.
-   App restart, upgrade and database migration tests.
-   Photo/file loss and export limitations documentation.
-   User acceptance testing with pilot companies.
-   Fix critical/high defects.

### Deliverables

-   UAT sign-off.
-   Release candidate.
-   Known issues and support guide.

### Exit criteria

-   Critical flows pass.
-   No critical/high severity defects remain.
-   Backup, privacy and offline limitations are documented.

## Sprint 13 --- Deployment and launch (Weeks 26--27)

### Mobile deployment

-   Production Firebase configuration.
-   Android app ID/package name.
-   App signing and release build.
-   App icon, splash screen, privacy policy and store listing.
-   Internal testing track.
-   Production rollout.
-   Crash reporting and release monitoring.
-   Versioning and update policy.

### Admin portal deployment

-   Production Firebase Hosting configuration.
-   Production environment variables/configuration.
-   Domain setup if desired.
-   HTTPS verification.
-   Admin access verification.
-   Smoke testing of all privileged actions.

### Backend deployment

-   Production Firestore indexes and Security Rules.
-   Cloud Functions deployment.
-   Production authentication configuration.
-   Billing alerts and usage monitoring.
-   Backup/restore procedure.
-   Emergency rollback/recovery plan.

### Deliverables

-   Production mobile application.
-   Production Developer Admin Portal.
-   Production Firebase backend.
-   Deployment and support documentation.

### Exit criteria

-   License activation works in production.
-   Data isolation tests pass against production-like configuration.
-   Admin portal is protected.
-   Pilot customer can complete work-to-invoice workflow.

------------------------------------------------------------------------

# 11. Indicative Delivery Timeline

  Stage                                    Duration
  ---------------------------------- --------------
  Discovery and setup                        1 week
  UI foundation and authentication          4 weeks
  Masters and work logs                     4 weeks
  Fuel, invoicing and payments              4 weeks
  Offline sync                              2 weeks
  License backend and admin portal          4 weeks
  Device replacement and reports            4 weeks
  QA, UAT and deployment                    4 weeks
  **Total indicative timeline**        **27 weeks**

This is a planning estimate for a small team. A solo developer may
require more time. Complex GST requirements, advanced approval flows,
extensive reporting, or cloud photo backup will increase the timeline.

------------------------------------------------------------------------

# 12. Deployment Environments and Release Process

## Environments

-   Development: test data and Firebase Emulator Suite where possible.
-   Staging/UAT: separate Firebase project and test users.
-   Production: customer data only.

Do not use production credentials or customer data in development. Avoid
manually copying secrets into source code.

## Deployment checklist

-   Verify Firebase project IDs.
-   Deploy Firestore Security Rules.
-   Deploy required Firestore indexes.
-   Deploy Cloud Functions.
-   Build and deploy React admin portal to Firebase Hosting.
-   Verify admin allowlist and role checks.
-   Verify app package ID and signing.
-   Test activation and device replacement.
-   Test invoice generation and payment calculations.
-   Verify sync after offline use.
-   Configure usage monitoring and billing alerts.
-   Publish privacy policy and support contact.
-   Document incident response and rollback procedures.

------------------------------------------------------------------------

# 13. Risks and Mitigations

  ---------------------------------------------------------------------
  Risk                               Mitigation
  ---------------------------------- ----------------------------------
  Customer data leaks between        Company-scoped data model,
  companies                          default-deny Security Rules,
                                     automated isolation tests

  User bypasses client-side license  Trusted backend validation and
  checks                             server-side authorization

  Old phone remains offline after    Revalidate when online;
  revocation                         acknowledge that instant offline
                                     revocation is impossible

  Photos lost when phone is damaged  Clearly disclose local-only
                                     storage; provide export/backup
                                     guidance; consider cloud file
                                     storage in a future version

  Duplicate records after retries    Stable IDs, idempotent writes,
                                     sync state machine

  Invoice number collisions across   Backend-assigned final invoice
  devices                            numbers or a formally designed
                                     distributed numbering scheme

  Financial data silently            Immutable finalized invoices,
  overwritten                        audit logs, conflict detection

  Unexpected Firebase cost           Monitor usage, set alerts, review
                                     reads/writes, keep photo/PDF
                                     uploads disabled initially

  App reinstall loses device         Design reactivation/support flow
  registration token                 and replacement policy

  Unclear tax requirements           Confirm GST and invoice rules
                                     before implementing tax
                                     calculations
  ---------------------------------------------------------------------

------------------------------------------------------------------------

# 14. Product Decisions Required Before Development

The following decisions should be confirmed during Sprint 0:

1.  Login method: email/password, phone OTP, or both.
2.  Whether each customer company has one owner or multiple
    administrators.
3.  Maximum devices per license and whether multiple users can use the
    same company account.
4.  License model: lifetime, annual, monthly, or custom validity.
5.  Offline grace period and behavior after it expires.
6.  Whether work logs require manager approval.
7.  Whether invoices can be finalized offline.
8.  Invoice numbering requirements across multiple devices.
9.  GST/tax configuration and required invoice fields.
10. Whether operators need individual logins.
11. Whether users can edit approved work logs and under what conditions.
12. How to handle meter rollover or machine meter replacement.
13. Data export and recovery requirements when a phone is damaged.
14. Whether cloud photo/PDF backup will be added later.
15. Supported Android versions and whether iOS is part of the first
    release.
16. Data retention and account closure policy.
17. Customer support process for license and device replacement.
18. Whether company users may create multiple invoices for one date
    range or split billing by site/machine.

------------------------------------------------------------------------

# 15. Definition of Done

The product can be considered ready for the first production release
when:

-   All agreed mobile modules are implemented.
-   Developer Admin Portal can manage companies, licenses, and devices.
-   Authentication and role-based access work.
-   Company data isolation is verified by automated tests.
-   License activation, expiry, suspension and device replacement work
    through trusted backend functions.
-   Work hours calculate correctly from meter readings.
-   Manual entries require reasons and are auditable.
-   Fuel totals, invoice totals, payments and outstanding balances are
    correct.
-   Finalized invoice snapshots are preserved.
-   Offline records persist and synchronize without duplication.
-   Photos and PDFs are stored locally as specified.
-   Security Rules and Cloud Functions tests pass.
-   UAT is completed with pilot customers.
-   Production deployment, monitoring, recovery, privacy and support
    documentation is ready.

------------------------------------------------------------------------

# 16. Final Recommended Architecture

Use the following baseline:

-   **Flutter mobile app:** shared by all customers.
-   **SQLite/Drift:** local-first business records.
-   **App-private storage:** meter photos, receipts and PDFs in version
    1.  
-   **Firebase Authentication:** user identity.
-   **Cloud Firestore:** company-scoped structured data.
-   **Cloud Functions:** trusted license/device actions, privileged
    updates and final invoice number allocation where required.
-   **React.js + Vite:** Developer Admin Portal.
-   **Firebase Hosting:** host the admin portal.
-   **Firestore Security Rules:** enforce company-level authorization.
-   **Automated tests:** business calculations, offline sync, device
    replacement, and tenant isolation.
-   **Monitoring and billing alerts:** control reliability and cost.

The main design priority is to keep customer data isolated, preserve
offline work, and place license/device authority on the trusted backend.
This architecture supports a small initial rollout and can grow as more
JCB businesses subscribe.

# 17. Reusable Development Instruction for AI Coding Tools and Developers

Use this instruction at the start of each development sprint, feature
implementation, UI redesign, or code review:

> Act as an expert Mobile UI/UX Designer and App Developer. Build a
> premium, modern, attractive, and responsive mobile application with
> intuitive navigation, user-friendly interfaces, beautiful layouts,
> smooth animations, reusable components, and clean architecture. Follow
> mobile design guidelines for iOS and Android, ensure touch-friendly
> interactions, consistent styling, accessibility, and optimal
> performance. Avoid generic designs and ensure every screen is
> polished, fully functional, and production-ready.

### Additional project-specific instructions

-   Read the product scope, architecture, current sprint tasks, and
    acceptance criteria before making changes.
-   Inspect the existing implementation before replacing code. Preserve
    working features and avoid unnecessary rewrites.
-   Implement the requested feature end-to-end, including UI, state
    management, validation, local persistence, sync behavior, error
    handling, and tests where relevant.
-   Follow Flutter, Riverpod, GoRouter, Drift/SQLite, Firebase, and
    project folder conventions.
-   Do not hard-code secrets, developer license keys, or privileged
    authorization logic in the client.
-   Keep photos and PDFs local in the initial release; sync structured
    business records only.
-   Respect company-level data isolation and role permissions.
-   Do not add decorative controls that do not work. Every button, menu,
    form, and navigation item must perform its intended action.
-   Before marking work complete, run relevant formatting, static
    analysis, unit/widget tests, and a manual UI check at supported
    screen sizes.
-   Report completed changes, files modified, tests run, known
    limitations, and any decisions requiring product-owner confirmation.
