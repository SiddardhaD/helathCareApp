# Health Companion

A medication, reminders, and health document companion app built with
Flutter, Riverpod, and Clean Architecture (MVVM on top).

## Stack

- **State management:** flutter_riverpod (AsyncNotifier-based ViewModels)
- **Navigation:** go_router with auth-gated redirects
- **Local persistence:** Hive (no backend required for the MVP)
- **Notifications:** flutter_local_notifications + timezone (on-device reminders)
- **Camera / media:** image_picker, camera, image_cropper
- **Document viewing:** pdfx (PDF), photo_view (images)
- **Auth UI:** mock implementation today; google_sign_in is already a
  dependency for when you wire up real Google sign-in

## Architecture

Each feature (`auth`, `medications`, `reminders`, `documents`) follows Clean
Architecture, split into three layers:

```
lib/features/<feature>/
  domain/        # Entities, repository interfaces, use cases — no Flutter/Hive imports here
  data/          # Repository implementations, Hive data sources, models
  presentation/  # Riverpod providers (ViewModels), screens, widgets
```

`lib/core/` holds cross-cutting code shared by every feature: theme, design
tokens, error types (`Failure`/`Result`), shared widgets, the notification
service, and the router.

### Why this split matters in practice

- The **domain** layer defines what each feature needs (e.g.
  `AuthRepository`, `MedicationRepository`) as abstract contracts. Nothing
  in domain or presentation knows about Hive, mock data, or any specific
  backend.
- The **data** layer is the only place that imports `hive`. Swapping local
  storage for a real backend later means writing a new class that
  implements the same repository interface — no other code changes.
- **Presentation** ViewModels (`AsyncNotifier` subclasses) call use cases,
  never repositories directly, keeping business rules (e.g. "what counts as
  low stock," "did the dosage change") out of the UI layer.

## Auth: currently mocked, ready for Firebase

`MockAuthRepository` (in `lib/features/auth/data/repositories/`) simulates
Google sign-in, phone/OTP verification (debug code is always `1234`), and
guest mode, persisting the session locally via Hive.

To move to real Firebase Auth:

1. Add `firebase_auth` and `firebase_core` to `pubspec.yaml`, run
   `flutterfire configure`.
2. Create `FirebaseAuthRepository implements AuthRepository` in the same
   `data/repositories/` folder, implementing each method against real
   Firebase/Google Sign-In APIs.
3. In `lib/features/auth/presentation/providers/auth_providers.dart`, change
   `authRepositoryProvider` to return `FirebaseAuthRepository()` instead of
   `MockAuthRepository()`.

Nothing in the domain layer, ViewModels, or screens needs to change.

## Reminders: local notifications only (MVP)

All reminders — both medication doses and custom appointment/refill
reminders — are scheduled as on-device notifications via
`NotificationService` (in `lib/core/services/`). There is no backend sync;
reminders won't follow the user to another device. If that's needed later,
add a `RemoteReminderRepository` behind the same `ReminderRepository`
interface.

## Getting started

```bash
flutter pub get
flutter run
```

No Firebase project, API keys, or backend setup is required to run the
MVP — everything works fully offline against local mock/Hive storage.

### Notes on permissions

- **Camera/Photos:** the app requests these via `image_picker`/`camera`
  when you first try to add a prescription photo or document. You may need
  to add the relevant `NSCameraUsageDescription` /
  `NSPhotoLibraryUsageDescription` keys to `ios/Runner/Info.plist`, and
  camera/storage permissions to `android/app/src/main/AndroidManifest.xml`,
  depending on your Flutter/plugin versions.
- **Notifications:** requested on first launch via
  `NotificationService.requestPermissions()`.

## What's deferred beyond this MVP

- Family member management (multi-profile support)
- Lab result explainer / structured lab data
- Appointment booking integrations
- Cloud sync / multi-device support
- Automated tests (none included yet)

## Project structure

```
lib/
  core/
    error/         # Failure + Result types
    router/         # go_router setup with auth redirect
    services/       # NotificationService
    theme/           # AppColors, AppTextStyles, AppTheme, spacing/radius tokens
    widgets/         # Shared widgets (buttons, empty states, camera sheet, main shell)
  features/
    auth/
    medications/
    reminders/
    documents/
    home/            # Dashboard aggregating the above
  main.dart
```
