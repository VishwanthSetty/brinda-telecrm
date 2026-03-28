# Inline Recording Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the external "Play" button in the Call Detail Sheet with an inline audio player that streams the recording URL directly inside the sheet.

**Architecture:** `_CallDetailSheetState` auto-fetches the recording URL when the sheet loads (if the call has a recording) and stores it in `_recordingUrl`. A new private `_InlinePlayer` StatefulWidget owns the `AudioPlayer` instance, renders play/pause + seek slider + elapsed/total time, and is placed at the bottom of the call info card.

**Tech Stack:** `audioplayers ^6.0.0`, existing Riverpod + Dio stack, `AppColors`/`AppSpacing` design constants.

---

## File Map

| File | Change |
|---|---|
| `pubspec.yaml` | Add `audioplayers: ^6.0.0` |
| `lib/presentation/screens/call_history/call_detail_sheet.dart` | Remove `_RecordingButton`, add `_InlinePlayer`; refactor `_playRecording` → `_fetchRecordingUrl`; add player URL state; remove `url_launcher` import |

---

### Task 1: Add `audioplayers` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the package**

In `pubspec.yaml`, under `dependencies:`, add after the `url_launcher` line:

```yaml
  # Audio player (for in-app recording playback)
  audioplayers: ^6.0.0
```

- [ ] **Step 2: Fetch dependencies**

Run:
```bash
flutter pub get
```

Expected output ends with: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add audioplayers dependency"
```

---

### Task 2: Refactor `_CallDetailSheetState` — URL fetch logic

**Files:**
- Modify: `lib/presentation/screens/call_history/call_detail_sheet.dart`

- [ ] **Step 1: Replace recording-related state fields**

Remove:
```dart
bool _loadingRecording = false;
```

Add in its place:
```dart
String? _recordingUrl;
bool _fetchingRecordingUrl = false;
```

- [ ] **Step 2: Remove `_playRecording`, add `_fetchRecordingUrl`**

Delete the entire `_playRecording` method:
```dart
Future<void> _playRecording() async {
  if (_log?.recordingId == null) return;
  setState(() => _loadingRecording = true);
  try {
    final result = await RecordingService(ref.read(apiClientProvider))
        .getUrl(_log!.recordingId!);
    final uri = Uri.parse(result.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) AppSnackbar.showError(context, 'Cannot open recording');
    }
  } catch (e) {
    if (mounted) AppSnackbar.showError(context, 'Failed to load recording');
  } finally {
    if (mounted) setState(() => _loadingRecording = false);
  }
}
```

Add this method in its place:
```dart
Future<void> _fetchRecordingUrl() async {
  if (_log?.recordingId == null) return;
  setState(() => _fetchingRecordingUrl = true);
  try {
    final result = await RecordingService(ref.read(apiClientProvider))
        .getUrl(_log!.recordingId!);
    if (mounted) setState(() => _recordingUrl = result.url);
  } catch (e) {
    if (mounted) AppSnackbar.showError(context, 'Failed to load recording');
  } finally {
    if (mounted) setState(() => _fetchingRecordingUrl = false);
  }
}
```

- [ ] **Step 3: Call `_fetchRecordingUrl` from `_loadLog`**

In `_loadLog`, after `setState(...)` sets `_log`, add an auto-fetch call:

```dart
Future<void> _loadLog() async {
  try {
    final log = await CallLogService(ref.read(apiClientProvider))
        .getLog(widget.callId);
    if (mounted) {
      setState(() {
        _log = log;
        _noteCtrl.text = log.note ?? '';
        _selectedDisposition = log.disposition;
        _loading = false;
      });
      if (log.hasRecording) _fetchRecordingUrl();
    }
  } catch (e) {
    if (mounted) setState(() { _error = e.toString(); _loading = false; });
  }
}
```

- [ ] **Step 4: Remove the `url_launcher` import**

Delete this line from the top of the file:
```dart
import 'package:url_launcher/url_launcher.dart';
```

Add this import instead:
```dart
import 'package:audioplayers/audioplayers.dart';
```

- [ ] **Step 5: Verify no compile errors**

Run:
```bash
flutter analyze lib/presentation/screens/call_history/call_detail_sheet.dart
```

Expected: no errors (there will be one about `_RecordingButton` still being used — that's fixed in Task 3).

---

### Task 3: Build `_InlinePlayer` widget

**Files:**
- Modify: `lib/presentation/screens/call_history/call_detail_sheet.dart`

- [ ] **Step 1: Replace `_RecordingButton` class with `_InlinePlayer`**

Delete the entire `_RecordingButton` class at the bottom of the file:
```dart
class _RecordingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _RecordingButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: AppColors.primaryMid),
        foregroundColor: AppColors.primary,
      ),
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMid),
            )
          : const Icon(Icons.play_circle_outline, size: 16),
      label: const Text('Play', style: TextStyle(fontSize: 13)),
    );
  }
}
```

Add this class in its place (at the bottom of the file, after `_InfoRow`):
```dart
class _InlinePlayer extends StatefulWidget {
  final String url;
  const _InlinePlayer({required this.url});

  @override
  State<_InlinePlayer> createState() => _InlinePlayerState();
}

class _InlinePlayerState extends State<_InlinePlayer> {
  late final AudioPlayer _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_playing) {
        await _player.pause();
      } else if (_position > Duration.zero) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.url));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Playback failed');
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        _error!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.missed,
        ),
      );
    }

    final maxVal = _duration.inSeconds.toDouble();
    final curVal = _position.inSeconds
        .toDouble()
        .clamp(0.0, maxVal > 0 ? maxVal : 1.0);

    return Row(
      children: [
        IconButton(
          icon: Icon(
            _playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
            size: 32,
            color: AppColors.primary,
          ),
          onPressed: _togglePlayPause,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
            ),
            child: Slider(
              value: curVal,
              max: maxVal > 0 ? maxVal : 1.0,
              onChanged: maxVal > 0
                  ? (v) => _player.seek(Duration(seconds: v.toInt()))
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${_fmt(_position)} / ${_fmt(_duration)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify analyze passes**

Run:
```bash
flutter analyze lib/presentation/screens/call_history/call_detail_sheet.dart
```

Expected: errors only about `_RecordingButton` / `_loadingRecording` references still in `_buildContent` (fixed next task).

---

### Task 4: Wire `_InlinePlayer` into `_buildContent`

**Files:**
- Modify: `lib/presentation/screens/call_history/call_detail_sheet.dart`

- [ ] **Step 1: Update the direction badge Row**

In `_buildContent`, find the Row inside the call info card that contains the direction badge and `_RecordingButton`. Replace it:

Old:
```dart
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: directionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.direction.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: directionColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const Spacer(),
    if (log.hasRecording)
      _RecordingButton(
        loading: _loadingRecording,
        onTap: _playRecording,
      ),
  ],
),
```

New:
```dart
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: directionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.direction.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: directionColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const Spacer(),
    if (_fetchingRecordingUrl)
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryMid,
        ),
      ),
  ],
),
```

- [ ] **Step 2: Add `_InlinePlayer` to the bottom of the call info card**

Still in `_buildContent`, find the call info card `Column`. After the last `_InfoRow` (the SIM row), add the player:

Old ending of the Column's children:
```dart
              _InfoRow(
                icon: Icons.sim_card,
                label: 'SIM',
                value: 'SIM ${log.simSlot + 1}',
              ),
```

New:
```dart
              _InfoRow(
                icon: Icons.sim_card,
                label: 'SIM',
                value: 'SIM ${log.simSlot + 1}',
              ),
              if (_recordingUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                _InlinePlayer(url: _recordingUrl!),
              ],
```

- [ ] **Step 3: Run analyze — expect zero issues**

Run:
```bash
flutter analyze lib/presentation/screens/call_history/call_detail_sheet.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/call_history/call_detail_sheet.dart pubspec.yaml pubspec.lock
git commit -m "feat: inline audio player for call recordings in call detail sheet"
```

---

### Task 5: Full project analyze

**Files:** none

- [ ] **Step 1: Run full analyze**

```bash
flutter analyze
```

Expected: `No issues found!` (or pre-existing warnings unrelated to this feature).

- [ ] **Step 2: Fix any issues introduced by this feature**

If `flutter analyze` reports issues in `call_detail_sheet.dart`, resolve them before proceeding.
