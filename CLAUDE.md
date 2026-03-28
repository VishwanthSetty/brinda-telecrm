# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (with a connected device or emulator)
flutter run

# Build APK
flutter build apk

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Generate code (if code generation is added later)
flutter pub run build_runner build
```

## Architecture

This is a Flutter mobile app for telecalling CRM. It follows a clean architecture with three layers:

### Layer Structure

- **`lib/core/`** — Shared constants, theme, utilities. No business logic. Never depends on data or presentation.
- **`lib/data/`** — API services (`services/`) and data models (`models/`). Services use Dio; the singleton `ApiClient` in `api_client.dart` adds the JWT Bearer token via interceptor and points to `http://localhost:8000`.
- **`lib/presentation/`** — Riverpod providers, screens, and widgets. Providers mediate between services and screens.

### Navigation

GoRouter in `router.dart` defines all routes. An auth redirect guard checks `authProvider` state — unauthenticated users always land on `/login`. The bottom navigation shell (`AppShell`) wraps the four main tabs: Dashboard (`/`), History (`/history`), Settings (`/settings`), Uploads (`/uploads`).

### State Management (Riverpod)

- `AuthNotifier` (AsyncNotifierProvider) — login/logout, token persistence via FlutterSecureStorage
- Dashboard data — three separate `FutureProvider`s (summary, trend, recording stats)
- `CallLogsNotifier` (AsyncNotifierProvider) — paginated call logs with server-side filtering; exposes `loadMore()` and `refresh()`
- `SettingsNotifier` — optimistic updates: apply locally first, revert on API failure
- `uploadProvider` — pending recordings list

### Key Design Conventions

- **Colors:** Always use `AppColors` constants (e.g., `AppColors.primary`, `AppColors.missed`). The palette is in `core/constants/app_colors.dart`.
- **Spacing:** Always use `AppSpacing` constants (4dp grid). The values are in `core/constants/app_spacing.dart`.
- **Theme:** Material 3 with Plus Jakarta Sans font. Customizations are centralized in `core/theme/app_theme.dart`.
- **Loading states:** Use `SkeletonLoader` widgets for shimmer placeholders while data loads.
- **Error/empty states:** Use the shared `EmptyState` widget (supports retry callbacks).
- **Snackbars:** Use `AppSnackbar.showError()` / `AppSnackbar.showSuccess()` — never `ScaffoldMessenger` directly.
- **Call log direction colors:** Inbound=green, Outbound=primary blue, Missed=red, Rejected=orange — defined in `AppColors`.

### API

Backend is a FastAPI server. All endpoints are under `/api/`. Auth uses JWT — the token is stored in FlutterSecureStorage and injected by the Dio interceptor in `ApiClient`. The base URL is hardcoded to `http://localhost:8000` in `api_client.dart`.

Key endpoint groups:
- `/api/auth/` — login, logout, user info
- `/api/telecalling/dashboard/` — summary, trend, recording stats
- `/api/telecalling/calls/logs` — paginated/filtered call log CRUD
- `/api/telecalling/recordings/` — pending recordings, get URL, delete
- `/api/telecalling/settings` — SIM, recording rules, sync settings
