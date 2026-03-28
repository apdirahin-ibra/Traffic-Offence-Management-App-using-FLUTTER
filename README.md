# 🚦 TOMS — Traffic Offence Management System

A cross-platform **Flutter** application for managing traffic offences, fines, appeals, and payments. Built with **Firebase** (Auth, Firestore, Storage, Messaging) and designed for three distinct user roles: **Police Officers**, **Drivers**, and **Administrators**.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Data Models](#-data-models)
- [Firestore Collections](#-firestore-collections)
- [Getting Started](#-getting-started)
- [Authentication Flow](#-authentication-flow)
- [Screens Overview](#-screens-overview)
- [Offline Support](#-offline-support)
- [Payment Integration](#-payment-integration)
- [License](#-license)

---

## ✨ Features

### 👮 Police Officer Portal
- **Dashboard** — Overview of daily activity, recent fines, and enforcement stats
- **Driver Search** — Look up drivers by national ID to view their profile, vehicles, and fine history
- **Issue Fine** — Create new traffic fines with offence selection, GPS location capture, evidence photo upload, and demerit point assignment
- **Fine History** — View all fines issued by the logged-in officer

### 🚗 Driver Portal
- **Dashboard** — Summary of active fines, payment status, demerit points, and license status
- **Fine List & Detail** — Browse all fines with status filtering; tap into detailed view with evidence photos, location map, and timeline
- **WaafiPay Payments** — Pay fines via mobile wallet (EVC Plus, Sahal, Zaad) — mock implementation for demonstration
- **Appeal Submission** — Submit appeals against fines with reason, supporting documents, and threaded message history
- **Vehicle Management** — Register, view, and delete vehicles linked to the driver's account
- **Profile Management** — Update personal details (name, phone, license number, email)

### 🛡️ Administrator Panel
- **Dashboard** — Real-time stats: fines today, revenue, pending appeals, overdue fines, active users
- **User Management** — Create, edit, activate/deactivate, and delete users across all roles; clear login lockouts; suspend/restore driver licenses
- **Fines Overview** — Browse all fines system-wide with search and status filters
- **Appeals Management** — Review, approve, or reject appeals; send messages to drivers
- **Analytics** — Visual charts (powered by `fl_chart`) for fine trends, revenue, offence categories, and officer performance
- **Reports** — Generate and view enforcement reports
- **Configuration** — Manage offence types, amounts, demerit points, and categories
- **Audit Logs** — Track all administrative actions with timestamps and user attribution
- **Notifications** — System-wide notification management

### 🌐 Cross-Cutting
- **Offline Support** — Local caching with Hive; offline queue for fine creation that syncs when connectivity is restored
- **Push Notifications** — Firebase Cloud Messaging (FCM) for alerts on new fines, appeal updates, and payment confirmations
- **Account Lockout** — Automatic lockout after 5 failed login attempts (30-minute cooldown)
- **Demerit Point System** — Automatic license suspension when a driver accumulates ≥ 50 demerit points
- **Session Management** — Auto-redirect based on authenticated user's role
- **Connectivity Banner** — Real-time offline indicator banner across the app

---

## 🏗️ Architecture

The app follows a **feature-first** folder structure with a clean separation of concerns:

```
┌─────────────────────────────────────────────────┐
│                    main.dart                     │
│              (App Entry + DI Setup)              │
├─────────────────────────────────────────────────┤
│                   app/ layer                     │
│         router.dart • routes.dart • theme.dart   │
├─────────────────────────────────────────────────┤
│               features/ layer                    │
│    ┌──────────┬───────────┬──────────────┐       │
│    │  police/  │  driver/  │    admin/    │       │
│    │ screens/  │ screens/  │  screens/    │       │
│    └──────────┴───────────┤  widgets/    │       │
│                           └──────────────┘       │
├─────────────────────────────────────────────────┤
│               core/services/ layer               │
│   auth • firestore • offline • storage           │
│   notification • seed • waafipay                 │
├─────────────────────────────────────────────────┤
│              models/ layer                       │
│   UserModel • FineModel • VehicleModel           │
│   AppealModel • OffenceModel • AuditLogModel     │
├─────────────────────────────────────────────────┤
│            widgets/ (shared UI)                  │
│   GlassCard • StatusBadge • TomsCard             │
│   TimelineWidget • FineLocationMap • MobileNav   │
└─────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart SDK ^3.11.0) |
| **Auth** | Firebase Authentication (email/password) |
| **Database** | Cloud Firestore |
| **File Storage** | Firebase Storage |
| **Push Notifications** | Firebase Cloud Messaging |
| **Routing** | GoRouter |
| **State / Streams** | StreamBuilder + Firestore real-time listeners |
| **Offline Cache** | Hive (via `hive_flutter`) |
| **Connectivity** | `connectivity_plus` |
| **Charts** | `fl_chart` |
| **Maps** | Google Maps Flutter |
| **QR Codes** | `qr_flutter` |
| **Typography** | Google Fonts (IBM Plex Sans + Space Grotesk) |
| **UI Effects** | Shimmer loading, glassmorphism cards |
| **Payments** | WaafiPay (mock — EVC Plus, Sahal, Zaad) |

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, Firebase init, offline init
├── firebase_options.dart              # Auto-generated Firebase config
│
├── app/
│   ├── router.dart                    # GoRouter config, auth-aware redirects, role selector screen
│   ├── routes.dart                    # Route path constants
│   └── theme.dart                     # Design tokens, color palette, Material theme
│
├── core/
│   └── services/
│       ├── auth_service.dart          # Firebase Auth: sign-in, register, lockout, profile mgmt
│       ├── firestore_service.dart     # Firestore CRUD: users, fines, vehicles, appeals, audit
│       ├── offline_service.dart       # Hive cache, offline queue, connectivity stream
│       ├── storage_service.dart       # Firebase Storage: evidence, appeal docs, profile images
│       ├── notification_service.dart  # FCM: token management, foreground messages
│       ├── seed_service.dart          # Database seeder: offences + sample vehicles
│       └── waafipay_service.dart      # Mock mobile wallet payment processor
│
├── models/
│   ├── user_model.dart                # User (police/driver/admin), demerit points, license status
│   ├── fine_model.dart                # Fine with offence, amount, GPS location, evidence URLs
│   ├── vehicle_model.dart             # Vehicle: plate, make, model, color, year
│   ├── appeal_model.dart              # Appeal with messages thread
│   ├── offence_model.dart             # Offence type config (name, category, amount, points)
│   └── audit_log_model.dart           # Audit log entry (userId, action, details, timestamp)
│
├── features/
│   ├── police/
│   │   └── screens/
│   │       ├── police_login_screen.dart
│   │       ├── police_dashboard_screen.dart
│   │       ├── driver_search_screen.dart
│   │       ├── issue_fine_screen.dart
│   │       └── officer_fine_history_screen.dart
│   │
│   ├── driver/
│   │   └── screens/
│   │       ├── driver_login_screen.dart
│   │       ├── driver_dashboard_screen.dart
│   │       ├── fine_list_screen.dart
│   │       ├── fine_detail_screen.dart
│   │       ├── payment_screen.dart
│   │       ├── appeal_submission_screen.dart
│   │       ├── vehicle_management_screen.dart
│   │       └── driver_profile_screen.dart
│   │
│   └── admin/
│       ├── screens/
│       │   ├── admin_login_screen.dart
│       │   ├── admin_dashboard_screen.dart
│       │   ├── admin_users_screen.dart
│       │   ├── all_fines_screen.dart
│       │   ├── appeals_management_screen.dart
│       │   ├── admin_analytics_screen.dart
│       │   ├── admin_reports_screen.dart
│       │   ├── admin_configuration_screen.dart
│       │   ├── admin_audit_logs_screen.dart
│       │   ├── admin_notifications_screen.dart
│       │   └── admin_placeholder_screen.dart
│       └── widgets/
│           ├── admin_layout.dart       # Sidebar navigation for desktop admin
│           └── admin_shell.dart        # ShellRoute wrapper for admin pages
│
└── widgets/                            # Shared reusable components
    ├── glass_card.dart                 # Frosted glass card effect
    ├── toms_card.dart                  # Styled card with gradient headers
    ├── status_badge.dart               # Colored badge for fine/appeal status
    ├── timeline_widget.dart            # Visual timeline for fine lifecycle
    ├── fine_location_map.dart          # Google Maps embed showing fine location
    ├── mobile_nav.dart                 # Bottom navigation for mobile views
    └── session_manager.dart            # Auth state listener + auto-redirect
```

---

## 📊 Data Models

### UserModel
| Field | Type | Description |
|-------|------|-------------|
| `uid` | `String` | Firebase Auth UID |
| `name` | `String` | Full name |
| `email` | `String` | Display email |
| `nationalId` | `String` | 13-digit national ID |
| `badgeId` | `String?` | Police badge number (police only) |
| `role` | `String` | `police` \| `driver` \| `admin` |
| `phone` | `String` | Phone number |
| `licenseNumber` | `String` | Driver license number |
| `isActive` | `bool` | Account active flag |
| `demeritPoints` | `int` | Accumulated demerit points |
| `licenseStatus` | `String` | `active` \| `suspended` \| `revoked` |
| `createdAt` | `DateTime?` | Account creation timestamp |

### FineModel
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Firestore document ID |
| `driverId` | `String` | Fined driver's UID |
| `officerId` | `String` | Issuing officer's UID |
| `vehiclePlate` | `String` | Vehicle plate number |
| `offenceType` | `String` | Type of offence |
| `amount` | `double` | Fine amount |
| `demeritPoints` | `int` | Points assigned |
| `status` | `String` | `pending` \| `paid` \| `overdue` \| `appealed` \| `cancelled` |
| `lat` / `lng` | `double?` | GPS coordinates of the offence |
| `evidenceUrls` | `List<String>` | Evidence photo URLs |
| `issuedAt` | `DateTime?` | When the fine was issued |
| `dueDate` | `DateTime?` | Payment due date |
| `paidAt` | `DateTime?` | When the fine was paid |

### AppealModel
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Firestore document ID |
| `fineId` | `String` | Associated fine ID |
| `driverId` | `String` | Appealing driver's UID |
| `reason` | `String` | Appeal reason |
| `documentUrl` | `String?` | Supporting document URL |
| `status` | `String` | `pending` \| `approved` \| `rejected` |
| `messages` | `List<AppealMessage>` | Threaded conversation |
| `createdAt` | `DateTime?` | Submission timestamp |

### VehicleModel
| Field | Type | Description |
|-------|------|-------------|
| `plateNumber` | `String` | License plate |
| `make` / `model` | `String` | Vehicle make and model |
| `color` | `String` | Vehicle color |
| `year` | `String?` | Year of manufacture |
| `registrationExpiry` | `DateTime?` | Registration expiry date |

---

## 🔥 Firestore Collections

| Collection | Description |
|-----------|-------------|
| `users` | All user accounts (police, drivers, admins) |
| `fines` | Traffic fines with status tracking |
| `vehicles` | Registered vehicles linked to drivers |
| `appeals` | Fine appeals with conversation threads |
| `offences` | Configurable offence types (seeded on first run) |
| `auditLogs` | Administrative action audit trail |
| `login_attempts` | Failed login tracking for account lockout |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.11.0
- **Dart SDK** ≥ 3.11.0
- A **Firebase project** with the following enabled:
  - Firebase Authentication (Email/Password)
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
- **Google Maps API key** (for fine location maps)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/apdirahin-ibra/Traffic-Offence-Management-App-using-FLUTTER.git
   cd Traffic-Offence-Management-App-using-FLUTTER
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - The project uses Firebase project ID `toms-2026`
   - Firebase config is already included in `lib/firebase_options.dart`
   - To use your own Firebase project, run:
     ```bash
     flutterfire configure
     ```

4. **Run the app**
   ```bash
   # Web
   flutter run -d chrome

   # Android
   flutter run

   # iOS
   flutter run -d ios
   ```

5. **Seed the database**
   - On the Role Selector screen, tap the **"Seed Database"** button to populate the `offences` collection with 15 default traffic offences and sample vehicles.

### Creating the First Admin Account

Since there is no public admin registration, create the first administrator directly in Firebase:

1. Go to **Firebase Console → Authentication → Users** and create a user with email `admin@toms.com` and a password
2. Go to **Firestore → users** collection and create a document with the Auth UID containing:
   ```json
   {
     "name": "Administrator",
     "email": "admin@toms.com",
     "role": "admin",
     "nationalId": "",
     "isActive": true,
     "createdAt": "<server-timestamp>"
   }
   ```
3. Additional users (police officers, drivers, admins) can then be created from the Admin Panel → User Management

---

## 🔐 Authentication Flow

| Role | Login Credential | Internal Email Pattern |
|------|-----------------|----------------------|
| **Police** | Badge ID + Password | `badge_{badgeId}@police.toms.com` |
| **Driver** | License Number + Password | `nat_{nationalId}@driver.toms.com` |
| **Admin** | Email + Password | Direct email |

- **Drivers** can self-register from the login screen
- **Police** and **Admin** accounts are created by administrators
- **Account lockout** activates after 5 failed attempts (30-min cooldown)
- Locked accounts can be unlocked by admins via User Management

---

## 📱 Screens Overview

### Role Selector (`/`)
Landing page where users select their role (Police, Driver, or Admin) to navigate to the appropriate login screen.

### Police Screens
| Route | Screen | Description |
|-------|--------|-------------|
| `/police/login` | Login | Badge ID + password |
| `/police/dashboard` | Dashboard | Daily stats and recent activity |
| `/police/search` | Driver Search | Lookup by national ID |
| `/police/issue-fine` | Issue Fine | Full fine creation with offence picker, GPS, and evidence |
| `/police/history` | Fine History | Officer's issued fines |

### Driver Screens
| Route | Screen | Description |
|-------|--------|-------------|
| `/driver/login` | Login & Register | License number login or new registration |
| `/driver/dashboard` | Dashboard | Fine summary, demerit points, license status |
| `/driver/fines` | Fine List | All fines with status filtering |
| `/driver/fines/detail?fineId=` | Fine Detail | Evidence, location map, timeline |
| `/driver/payment?fineId=` | Payment | WaafiPay mobile wallet payment |
| `/driver/appeals?fineId=` | Appeals | Submit and track appeals |
| `/driver/vehicles` | Vehicles | Register and manage vehicles |
| `/driver/profile` | Profile | Edit personal details |

### Admin Screens (inside `ShellRoute` with sidebar)
| Route | Screen | Description |
|-------|--------|-------------|
| `/admin/login` | Login | Email + password |
| `/admin/dashboard` | Dashboard | System-wide stats and charts |
| `/admin/users` | User Management | CRUD for all user roles |
| `/admin/fines` | All Fines | System-wide fine browser |
| `/admin/appeals` | Appeals | Review and respond to appeals |
| `/admin/analytics` | Analytics | Visual data charts |
| `/admin/reports` | Reports | Enforcement reports |
| `/admin/config` | Configuration | Offence types and amounts |
| `/admin/audit` | Audit Logs | Action history trail |
| `/admin/notifications` | Notifications | System notifications |

---

## 📶 Offline Support

TOMS uses **Hive** for local data persistence and an offline operation queue:

- **Fine Caching** — Driver fine lists are cached locally for offline viewing
- **Offline Queue** — Fines created while offline are queued and automatically synced when connectivity is restored
- **Connectivity Detection** — Real-time monitoring via `connectivity_plus` with a visible banner when offline
- **Settings Storage** — User preferences persisted in Hive

---

## 💰 Payment Integration

The app includes a **mock WaafiPay** implementation supporting Somali mobile wallets:

| Wallet | Provider |
|--------|----------|
| `evc_plus` | EVC Plus |
| `sahal` | Sahal |
| `zaad` | Zaad |

The mock service:
- Validates phone number format (Somali numbers: `252XXXXXXXXX`)
- Requires a 4-digit PIN
- Simulates a 2-second processing delay
- Generates a transaction ID on success
- Updates the fine status to `paid` in Firestore

> ⚠️ **Note:** This is a simulated payment flow for demonstration purposes. Replace `WaafiPayService` with a real API integration for production use.

---

## 🎨 Design System

The app uses a custom Material 3 theme with:

- **Fonts:** IBM Plex Sans (body) + Space Grotesk (headings)
- **Color Palette:** HSL-based navy blues, semantic greens/oranges/reds
- **Components:** Glass cards, gradient headers, status badges, shimmer loading states
- **Admin Layout:** Responsive sidebar navigation on desktop, collapsible on mobile

---

## 📄 License

This project is developed as a Flutter application for traffic offence management. All rights reserved.

---

<p align="center">
  <b>© 2026 National Traffic Authority — TOMS</b>
</p>
