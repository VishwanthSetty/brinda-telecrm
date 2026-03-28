# Inline Recording Player — Design Spec

**Date:** 2026-03-28
**Feature:** In-app audio playback for call recordings in the Call Detail Sheet

---

## Overview

Replace the current "Play" button (which opens the recording URL in an external app via `url_launcher`) with an inline audio player rendered directly inside the Call Detail Sheet. The player streams the recording from the URL returned by the API and provides minimal controls: play/pause, a seek slider, and elapsed/total time.

---

## Scope

- **In scope:** Inline player widget in `call_detail_sheet.dart`, `audioplayers` package integration, streaming from URL, play/pause, seek, elapsed/total time display.
- **Out of scope:** Background audio, persistent mini-player, playback speed controls, download/offline playback.

---

## Package

Add `audioplayers: ^6.0.0` to `pubspec.yaml` dependencies.

`audioplayers` is chosen over `just_audio` because:
- Simpler API for the minimal control set required
- Streams directly from a URL with `UrlSource`
- Well-tested on Android and iOS
- Smaller dependency footprint

---

## Architecture

All player state lives in `_CallDetailSheetState`. No new Riverpod provider is needed.

### State additions to `_CallDetailSheetState`

| Field | Type | Purpose |
|---|---|---|
| `_recordingUrl` | `String?` | URL fetched from API, stored for player use |
| `_player` | `AudioPlayer?` | Instantiated when URL is ready |
| `_playing` | `bool` | Whether audio is currently playing |
| `_position` | `Duration` | Current playback position |
| `_duration` | `Duration` | Total duration of the recording |
| `_playerError` | `String?` | Error message if playback fails |

### Data flow

1. Sheet loads → `_loadLog()` fetches call details (existing).
2. If `log.hasRecording == true`, `_fetchRecordingUrl()` calls `RecordingService.getUrl()` and stores the result in `_recordingUrl`. No auto-play.
3. `_buildContent()` renders `_InlinePlayer` in the call info card when `_recordingUrl != null`.
4. User taps play → `AudioPlayer.play(UrlSource(_recordingUrl!))` streams from the URL.
5. `AudioPlayer.onPositionChanged` and `AudioPlayer.onDurationChanged` streams update `_position` and `_duration` via `setState`.
6. `AudioPlayer.onPlayerStateChanged` updates `_playing`.
7. Slider `onChanged` → `AudioPlayer.seek(Duration(seconds: value.toInt()))`.
8. `_player` is disposed in `dispose()` alongside `_noteCtrl`.

---

## UI

The existing `_RecordingButton` widget is removed. In the call info card, `if (log.hasRecording)` now renders `_InlinePlayer` instead.

`_InlinePlayer` is a `StatefulWidget` that owns the `AudioPlayer`. It renders as a single `Row`:

```
[PlayPause IconButton]  [-----Slider-----]  [0:32 / 1:45]
```

- **Play/pause button:** `Icons.play_circle_outline` / `Icons.pause_circle_outline`, size 32, color `AppColors.primary`.
- **Slider:** `Slider` with `value = position.inSeconds.toDouble()`, `max = duration.inSeconds.toDouble()`. Uses `AppColors.primary` for active track.
- **Time label:** `mm:ss / mm:ss` in `textTheme.bodySmall`, color `AppColors.textSecondary`.
- **Loading state:** While URL is being fetched, show a small `CircularProgressIndicator` in place of the play button.
- **Error state:** If URL fetch or playback fails, show a short error text (`AppSnackbar.showError` for URL fetch failure; inline text for playback failure) and hide the player controls.

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| URL fetch fails | `AppSnackbar.showError(context, 'Failed to load recording')` — no player rendered |
| Playback fails (`onPlayerComplete` error / exception) | Inline error text replaces player controls: `"Playback failed"` in `AppColors.missed` |
| Recording does not exist (`log.hasRecording == false`) | Player section not rendered at all (existing behaviour) |

---

## Files Changed

| File | Change |
|---|---|
| `pubspec.yaml` | Add `audioplayers: ^6.0.0` |
| `lib/presentation/screens/call_history/call_detail_sheet.dart` | Refactor `_playRecording` → `_fetchRecordingUrl`; add player state fields; replace `_RecordingButton` with `_InlinePlayer`; dispose player |

No new files are required.
