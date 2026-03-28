# Auto Recording Upload — Design Spec

**Date:** 2026-03-28
**Status:** Approved

## Overview

Instead of requiring the user to manually pick a recording file for each pending call, the app automatically scans a configurable folder on the device, matches audio files to pending call logs, and uploads them. A manual sync button provides on-demand control.

---

## 1. Settings — Recordings Folder Path

- A new "Recordings folder path" field is added to the existing Settings screen.
- Default value: `/storage/emulated/0/Call recordings` (Samsung built-in dialer default).
- User can edit the path by tapping the field.
- A "Browse" button opens a folder picker using the existing `file_picker` package.
- The path is persisted in `FlutterSecureStorage` under key `recordings_folder_path`.
- The value is read by `RecordingMatcherService` at scan time (not cached in memory, always read fresh so changes take effect immediately).

---

## 2. Recording File Matching Logic

Implemented in a new `RecordingMatcherService` class (`lib/data/services/recording_matcher_service.dart`).

### Steps

1. Read the configured folder path from `FlutterSecureStorage`. If empty, use the Samsung default.
2. List all files in the folder with extensions: `.m4a`, `.mp3`, `.aac`, `.wav`, `.amr`, `.3gp`, `.ogg`.
3. For each `PendingRecording` from the server:
   - Compute the **expected end time**: `started_at + duration_seconds`.
   - Extract digits-only from the pending recording's `phone_number` (strip `+`, spaces, dashes). Also prepare a short form (last 10 digits) for fuzzy matching.
   - Find a file where **both**:
     - The filename (digits-only) contains the full number **or** the last 10 digits of the number.
     - The file's last-modified timestamp is within **±5 minutes** of the expected end time.
4. If a match is found → return `(PendingRecording, File)` pair.
5. If no match → return nothing for that recording; it stays in the pending list with the manual "Upload" button.

### Conflict resolution

If multiple files match a single pending recording, pick the one whose last-modified timestamp is closest to the expected end time.

---

## 3. Triggers

### 3a. App Launch (automatic)

- Runs once after login is confirmed and the auth token is available.
- Triggered from `AppShell` `initState` (or equivalent post-login hook).
- Runs silently in the background — no loading spinner blocking the UI.
- On completion: shows a snackbar:
  - `"X recording(s) uploaded automatically"` if any matched.
  - No snackbar if nothing was found (silent success).
  - `"Auto-upload failed: <reason>"` on error.

### 3b. Manual Sync Button

- A "Sync Recordings" icon button (`Icons.sync`) added to the `UploadStatusScreen` AppBar, next to the existing refresh icon.
- Tapping it runs the same scan → match → upload flow.
- While running: the icon shows a `CircularProgressIndicator` (same pattern as the existing upload button).
- On completion: snackbar with result — `"X recording(s) uploaded"` or `"No new recordings found"`.

---

## 4. New Components

| Component | Location | Responsibility |
|---|---|---|
| `RecordingMatcherService` | `lib/data/services/recording_matcher_service.dart` | Scan folder, match files to pending recordings |
| `autoUploadProvider` | `lib/presentation/providers/upload_provider.dart` | Orchestrate scan → match → upload; expose `isScanning` state |
| `recordings_folder_path` key | `FlutterSecureStorage` | Persisted folder path |
| Folder path field + Browse button | Settings screen | UI to configure the path |
| Sync button | `UploadStatusScreen` AppBar | Manual trigger for auto-upload |

### Modified components

| Component | Change |
|---|---|
| `UploadStatusScreen` | Add sync button to AppBar; update info hint text |
| Settings screen | Add recordings folder path field |
| `AppShell` | Trigger auto-upload scan on launch (post-login) |
| `upload_provider.dart` | Add `autoUploadProvider` notifier |

---

## 5. Permissions

All required permissions are already declared in `AndroidManifest.xml`:
- `READ_EXTERNAL_STORAGE` — for Android ≤ 12
- `READ_MEDIA_AUDIO` — for Android 13+

No new permissions needed.

---

## 6. Error Handling

- Folder does not exist → log warning, show snackbar `"Recordings folder not found. Check path in Settings."`, abort scan.
- Permission denied → show snackbar `"Storage permission required to auto-match recordings."`.
- Upload failure for a matched file → leave it in pending list, show error snackbar. Do not retry automatically.
- Unmatched recordings → silently left in pending list for manual upload (existing behavior).

---

## 7. Out of Scope

- Background upload when app is fully closed (WorkManager) — deferred.
- Watching the folder for new files in real time (FileSystemWatcher) — deferred.
- Deleting local recording files after upload — not included.
