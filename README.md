# AidTracker

A production-ready, offline-first humanitarian aid distribution and inventory tracking system.

## Key Features

- **Offline-First Architecture:** Full CRUD capabilities without an internet connection, powered by Hive local storage.
- **Bidirectional Sync:** Real-time synchronization with Firebase Firestore when online.
- **Security:** SHA-256 password hashing and comprehensive system audit trails.
- **Operational Intelligence:** Low-stock alerts, pending profile approvals, and dynamic reporting.
- **Data Management:** Batch CSV import/export for rapid data entry and analysis.
- **Role-Based Access:** Distinct workflows for Admins (management & oversight) and Agents (field operations).

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Local Database:** Hive
- **Cloud Database:** Firebase Firestore
- **Utilities:** Connectivity Plus, Crypto, CSV, File Picker, Share Plus

## Getting Started

1.  **Clone the repository.**
2.  **Run `flutter pub get`** to install dependencies.
3.  **Configure Firebase:** Add your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS).
4.  **Launch:** Run `flutter run`.

## Test Credentials

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@ngo.org` | `123456` |
| **Agent** | `agent@ngo.org` | `123456` |

## Development

-   **Analysis:** Run `flutter analyze` to ensure code quality.
-   **Testing:** Run `flutter test` to execute unit and widget tests.
