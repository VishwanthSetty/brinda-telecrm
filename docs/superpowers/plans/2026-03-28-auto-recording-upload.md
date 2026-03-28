# Auto Recording Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically scan a configurable device folder for recording files, match them to pending call log uploads by phone number + timestamp, and upload them — triggered on app launch and via a manual sync button.

**Architecture:** A new `RecordingMatcherService` handles folder scanning and file-to-call matching. `PendingRecordingsNotifier` gains a `runAutoUpload()` method that uses the matcher and drives uploads. App launch and a manual sync button both call this method via a shared `isScanningProvider`.

**Tech Stack:** Flutter, Riverpod, `dart:io` (Directory/File), `flutter_secure_storage` (folder path persistence), `permission_handler` (runtime storage permission), `file_picker` (folder browse), `path` package (extension/basename utilities).

---

## File Map

| Action | File | Purpose |
|---|---|---|
| Create | `lib/data/services/recording_matcher_service.dart` | Scan folder, match audio files to pending recordings |
| Modify | `lib/presentation/providers/upload_provider.dart` | Add `isScanningProvider` + `runAutoUpload()` to `PendingRecordingsNotifier` |
| Modify | `lib/presentation/screens/settings/settings_screen.dart` | Add "Recording Folder" section with path field + Browse button |
| Modify | `lib/presentation/screens/upload_status/upload_status_screen.dart` | Add Sync button to AppBar |
| Modify | `lib/presentation/screens/shell/app_shell.dart` | Trigger auto-upload on shell init |
| Create | `test/data/services/recording_matcher_service_test.dart` | Unit tests for matching logic |

---

## Task 1: `RecordingMatcherService` — core matching logic

**Files:**
- Create: `lib/data/services/recording_matcher_service.dart`
- Create: `test/data/services/recording_matcher_service_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/data/services/recording_matcher_service_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brinda_telecrm/data/models/recording.dart';
import 'package:brinda_telecrm/data/services/recording_matcher_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recording_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('RecordingMatcherService.matchFiles', () {
    test('matches file by exact phone digits and timestamp within window', () async {
      // Create a fake recording file whose name contains the phone number
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file = File('${tempDir.path}/+911234567890_20240328_143022.m4a');
      await file.writeAsString('fake');
      // Set last-modified to call end time (within ±5 min)
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 5)));

      final pending = [
        PendingRecording(
          callLogId: 'log-1',
          phoneNumber: '+911234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52), // 90s call
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches.length, 1);
      expect(matches.first.recording.callLogId, 'log-1');
    });

    test('matches by last 10 digits when full number not in filename', () async {
      final callEnd = DateTime(2024, 3, 28, 10, 0, 0);
      final file = File('${tempDir.path}/9876543210_20240328_100000.m4a');
      await file.writeAsString('fake');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-2',
          phoneNumber: '+919876543210',
          direction: 'inbound',
          startedAt: DateTime(2024, 3, 28, 9, 59, 0),
          durationSeconds: 60,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches.length, 1);
      expect(matches.first.recording.callLogId, 'log-2');
    });

    test('does not match when timestamp outside ±5 min window', () async {
      final file = File('${tempDir.path}/1234567890_20240328_143022.m4a');
      await file.writeAsString('fake');
      // Set modified 10 minutes after call end
      file.setLastModifiedSync(DateTime(2024, 3, 28, 14, 40, 22));

      final pending = [
        PendingRecording(
          callLogId: 'log-3',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches, isEmpty);
    });

    test('does not match when phone number not in filename', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file = File('${tempDir.path}/0000000000_20240328_143022.m4a');
      await file.writeAsString('fake');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-4',
          phoneNumber: '+911234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches, isEmpty);
    });

    test('ignores non-audio files', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file = File('${tempDir.path}/1234567890_20240328_143022.txt');
      await file.writeAsString('not audio');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-5',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches, isEmpty);
    });

    test('picks closest file when multiple match same call', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);

      final file1 = File('${tempDir.path}/1234567890_a.m4a');
      await file1.writeAsString('fake');
      file1.setLastModifiedSync(callEnd.add(const Duration(seconds: 10))); // 10s off

      final file2 = File('${tempDir.path}/1234567890_b.m4a');
      await file2.writeAsString('fake');
      file2.setLastModifiedSync(callEnd.add(const Duration(seconds: 2))); // 2s off — closer

      final pending = [
        PendingRecording(
          callLogId: 'log-6',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(pending, tempDir.listSync().whereType<File>().toList());
      expect(matches.length, 1);
      expect(matches.first.file.path, contains('_b.m4a'));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
flutter test test/data/services/recording_matcher_service_test.dart
```

Expected: compile error — `RecordingMatcherService` not defined yet.

- [ ] **Step 3: Create `lib/data/services/recording_matcher_service.dart`**

```dart
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import '../models/recording.dart';

const _kDefaultFolder = '/storage/emulated/0/Call recordings';
const _kFolderKey = 'recordings_folder_path';
const _kMatchWindowSeconds = 300; // ±5 minutes
const _kAudioExtensions = {'.m4a', '.mp3', '.aac', '.wav', '.amr', '.3gp', '.ogg'};

class RecordingMatch {
  final PendingRecording recording;
  final File file;
  const RecordingMatch({required this.recording, required this.file});
}

class RecordingFolderNotFoundException implements Exception {
  final String folderPath;
  const RecordingFolderNotFoundException(this.folderPath);
  @override
  String toString() => 'Recording folder not found: $folderPath';
}

class RecordingMatcherService {
  static const _storage = FlutterSecureStorage();

  static Future<String> getFolderPath() async {
    return await _storage.read(key: _kFolderKey) ?? _kDefaultFolder;
  }

  static Future<void> setFolderPath(String path) async {
    await _storage.write(key: _kFolderKey, value: path);
  }

  /// Scans the configured folder and returns matches for each pending recording.
  /// Throws [RecordingFolderNotFoundException] if the folder does not exist.
  static Future<List<RecordingMatch>> findMatches(
    List<PendingRecording> pending,
  ) async {
    if (pending.isEmpty) return [];

    final folderPath = await getFolderPath();
    final dir = Directory(folderPath);

    if (!await dir.exists()) {
      throw RecordingFolderNotFoundException(folderPath);
    }

    final allFiles = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .where((f) => _kAudioExtensions.contains(p.extension(f.path).toLowerCase()))
        .toList();

    return matchFiles(pending, allFiles);
  }

  /// Pure matching logic — separated for testability.
  static List<RecordingMatch> matchFiles(
    List<PendingRecording> pending,
    List<File> audioFiles,
  ) {
    final matches = <RecordingMatch>[];
    for (final record in pending) {
      final file = _findBestFile(record, audioFiles);
      if (file != null) {
        matches.add(RecordingMatch(recording: record, file: file));
      }
    }
    return matches;
  }

  static File? _findBestFile(PendingRecording recording, List<File> files) {
    final digits = recording.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final shortDigits = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final expectedEnd = recording.startedAt.add(Duration(seconds: recording.durationSeconds));

    File? best;
    int bestDiff = _kMatchWindowSeconds + 1;

    for (final file in files) {
      final nameDigits = p.basenameWithoutExtension(file.path).replaceAll(RegExp(r'\D'), '');
      if (!nameDigits.contains(digits) && !nameDigits.contains(shortDigits)) continue;

      final modified = file.lastModifiedSync();
      final diffSeconds = modified.difference(expectedEnd).inSeconds.abs();
      if (diffSeconds <= _kMatchWindowSeconds && diffSeconds < bestDiff) {
        best = file;
        bestDiff = diffSeconds;
      }
    }
    return best;
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```
flutter test test/data/services/recording_matcher_service_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/services/recording_matcher_service.dart test/data/services/recording_matcher_service_test.dart
git commit -m "feat: add RecordingMatcherService with folder scan and file matching"
```

---

## Task 2: Add `isScanningProvider` and `runAutoUpload()` to upload provider

**Files:**
- Modify: `lib/presentation/providers/upload_provider.dart`

- [ ] **Step 1: Add `isScanningProvider` and `runAutoUpload()` to `upload_provider.dart`**

Open `lib/presentation/providers/upload_provider.dart`. Add `isScanningProvider` after `uploadingIdsProvider`, and add the `runAutoUpload()` method to `PendingRecordingsNotifier`.

Full updated file:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recording.dart';
import '../../data/services/recording_matcher_service.dart';
import '../../data/services/recording_service.dart';
import 'auth_provider.dart';

final recordingServiceProvider = Provider<RecordingService>(
  (ref) => RecordingService(ref.read(apiClientProvider)),
);

final pendingRecordingsProvider =
    AsyncNotifierProvider<PendingRecordingsNotifier, List<PendingRecording>>(
  PendingRecordingsNotifier.new,
);

// Tracks which callLogIds are currently uploading
final uploadingIdsProvider = StateProvider<Set<String>>((ref) => {});

// True while auto-upload scan + upload is running
final isScanningProvider = StateProvider<bool>((ref) => false);

class PendingRecordingsNotifier
    extends AsyncNotifier<List<PendingRecording>> {
  @override
  Future<List<PendingRecording>> build() {
    return ref.read(recordingServiceProvider).getPending();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recordingServiceProvider).getPending(),
    );
  }

  Future<bool> uploadRecording({
    required String callLogId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) async {
    final uploading = ref.read(uploadingIdsProvider.notifier);
    uploading.update((s) => {...s, callLogId});

    try {
      await ref.read(recordingServiceProvider).uploadRecording(
            callLogId: callLogId,
            filePath: filePath,
            fileName: fileName,
            durationSeconds: durationSeconds,
          );
      state = AsyncData(
        state.valueOrNull?.where((r) => r.callLogId != callLogId).toList() ?? [],
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      uploading.update((s) => s.difference({callLogId}));
    }
  }

  /// Scans the recordings folder, matches files to pending calls, and uploads matches.
  /// Returns the number of recordings successfully uploaded.
  /// Throws [RecordingFolderNotFoundException] if the configured folder does not exist.
  Future<int> runAutoUpload() async {
    final pending = state.valueOrNull ?? [];
    if (pending.isEmpty) return 0;

    final matches = await RecordingMatcherService.findMatches(pending);
    if (matches.isEmpty) return 0;

    int uploaded = 0;
    for (final match in matches) {
      final fileName = match.file.path.split('/').last;
      final success = await uploadRecording(
        callLogId: match.recording.callLogId,
        filePath: match.file.path,
        fileName: fileName,
        durationSeconds: match.recording.durationSeconds,
      );
      if (success) uploaded++;
    }
    return uploaded;
  }
}
```

- [ ] **Step 2: Analyze to confirm no errors**

```
flutter analyze lib/presentation/providers/upload_provider.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/providers/upload_provider.dart
git commit -m "feat: add isScanningProvider and runAutoUpload to PendingRecordingsNotifier"
```

---

## Task 3: Auto-upload trigger on app launch (`AppShell`)

**Files:**
- Modify: `lib/presentation/screens/shell/app_shell.dart`

- [ ] **Step 1: Add `_runAutoUpload()` to `_AppShellState`**

Open `lib/presentation/screens/shell/app_shell.dart`.

1. Add import at top:
```dart
import '../../../core/utils/app_snackbar.dart';  // already imported via relative path
```

Actually the file already imports via `'../../widgets/common/app_snackbar.dart'` — no, it doesn't currently import `app_snackbar`. Add:
```dart
import '../../widgets/common/app_snackbar.dart';
import '../../providers/upload_provider.dart';
import '../../../data/services/recording_matcher_service.dart';
```

2. In `initState`, after the existing `addPostFrameCallback`, add `_runAutoUpload()`:

Replace:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on shell load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(callSyncProvider);
    });
  }
```

With:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(callSyncProvider);
      _runAutoUpload();
    });
  }
```

3. Add `_runAutoUpload()` method to `_AppShellState`:
```dart
  Future<void> _runAutoUpload() async {
    ref.read(isScanningProvider.notifier).state = true;
    try {
      final count =
          await ref.read(pendingRecordingsProvider.notifier).runAutoUpload();
      if (mounted && count > 0) {
        AppSnackbar.showSuccess(
          context,
          '$count recording${count == 1 ? '' : 's'} uploaded automatically',
        );
      }
    } on RecordingFolderNotFoundException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Recordings folder not found. Check path in Settings.',
        );
      }
      // ignore: avoid_print
      print('[AutoUpload] $e');
    } catch (e) {
      // Network or permission errors — silent on launch to avoid spamming
      // ignore: avoid_print
      print('[AutoUpload] Error: $e');
    } finally {
      if (mounted) ref.read(isScanningProvider.notifier).state = false;
    }
  }
```

- [ ] **Step 2: Analyze**

```
flutter analyze lib/presentation/screens/shell/app_shell.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/shell/app_shell.dart
git commit -m "feat: trigger auto-upload scan on app shell init"
```

---

## Task 4: Sync button in `UploadStatusScreen`

**Files:**
- Modify: `lib/presentation/screens/upload_status/upload_status_screen.dart`

- [ ] **Step 1: Add sync button and update hint text**

Open `lib/presentation/screens/upload_status/upload_status_screen.dart`.

1. Add import at top (already has `upload_provider.dart`, add `recording_matcher_service.dart`):
```dart
import '../../../data/services/recording_matcher_service.dart';
```

2. Replace the `build` method of `UploadStatusScreen` — add sync button to AppBar actions and wire it up. The screen must be a `ConsumerStatefulWidget` to hold a `_syncInProgress` local state for the button spinner. However, since `isScanningProvider` is global, we can watch it directly. Change `UploadStatusScreen` from `ConsumerWidget` to `ConsumerWidget` — just watch `isScanningProvider` and show a spinner on the sync button.

Replace the entire `UploadStatusScreen` class:

```dart
class UploadStatusScreen extends ConsumerWidget {
  const UploadStatusScreen({super.key});

  Future<void> _runSync(BuildContext context, WidgetRef ref) async {
    ref.read(isScanningProvider.notifier).state = true;
    try {
      final count =
          await ref.read(pendingRecordingsProvider.notifier).runAutoUpload();
      if (!context.mounted) return;
      if (count > 0) {
        AppSnackbar.showSuccess(
          context,
          '$count recording${count == 1 ? '' : 's'} uploaded',
        );
      } else {
        AppSnackbar.showSuccess(context, 'No new recordings found');
      }
    } on RecordingFolderNotFoundException {
      if (!context.mounted) return;
      AppSnackbar.showError(
        context,
        'Recordings folder not found. Check path in Settings.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Sync failed. Please try again.');
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRecordingsProvider);
    final isScanning = ref.watch(isScanningProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Status'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Recordings',
              onPressed: () => _runSync(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(pendingRecordingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(pendingRecordingsProvider.notifier).refresh(),
        child: pendingAsync.when(
          loading: () => ListView(
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: SkeletonBox.fill(height: 80, radius: 12),
              ),
            ),
          ),
          error: (e, s) => ErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.read(pendingRecordingsProvider.notifier).refresh(),
          ),
          data: (recordings) {
            if (recordings.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'All recordings uploaded',
                    subtitle: 'No pending uploads at the moment',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${recordings.length} recording${recordings.length == 1 ? '' : 's'} pending upload',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Pending Uploads', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...recordings.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PendingRecordingTile(recording: r),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: AppColors.primaryMid.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tap "Sync" to auto-match recordings, or tap "Upload" on each call to pick a file manually.',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```
flutter analyze lib/presentation/screens/upload_status/upload_status_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/upload_status/upload_status_screen.dart
git commit -m "feat: add sync recordings button to upload status screen"
```

---

## Task 5: Recordings folder path setting in Settings screen

**Files:**
- Modify: `lib/presentation/screens/settings/settings_screen.dart`

- [ ] **Step 1: Add `_RecordingFolderSection` widget and wire into `_SettingsBody`**

Open `lib/presentation/screens/settings/settings_screen.dart`.

1. Add imports at the top:
```dart
import 'package:file_picker/file_picker.dart';
import '../../../data/services/recording_matcher_service.dart';
```

2. In `_SettingsBody.build`, add the new section **before** the closing bracket of the `ListView` children, after the last `SettingsSection`:

```dart
        // Recording Folder
        const _RecordingFolderSection(),
```

3. Add the new `_RecordingFolderSection` widget at the end of the file:

```dart
class _RecordingFolderSection extends StatefulWidget {
  const _RecordingFolderSection();

  @override
  State<_RecordingFolderSection> createState() => _RecordingFolderSectionState();
}

class _RecordingFolderSectionState extends State<_RecordingFolderSection> {
  late TextEditingController _controller;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadPath();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    final path = await RecordingMatcherService.getFolderPath();
    if (mounted) {
      setState(() {
        _controller.text = path;
        _loading = false;
      });
    }
  }

  Future<void> _savePath(String value) async {
    setState(() => _saving = true);
    await RecordingMatcherService.setFolderPath(value.trim());
    if (mounted) {
      setState(() => _saving = false);
      AppSnackbar.showSuccess(context, 'Recordings folder saved');
    }
  }

  Future<void> _browsePath() async {
    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked != null) {
      _controller.text = picked;
      await _savePath(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Recording Folder',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md,
          ),
          child: _loading
              ? const SkeletonBox.fill(height: 48)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recordings folder path',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Where your call recorder app saves files (default: Samsung built-in dialer)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: Theme.of(context).textTheme.bodySmall,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.divider),
                              ),
                              suffixIcon: _saving
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: _savePath,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: _saving ? null : _browsePath,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: const Text('Browse'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze**

```
flutter analyze lib/presentation/screens/settings/settings_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/settings/settings_screen.dart
git commit -m "feat: add recordings folder path setting with browse button"
```

---

## Task 6: Full analyze + test run

- [ ] **Step 1: Run all tests**

```
flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run full analyze**

```
flutter analyze
```

Expected: no issues (no new warnings or errors).

- [ ] **Step 3: Final commit if any lint fixes were needed**

If `flutter analyze` required any small fixes, commit them:
```bash
git add -p
git commit -m "fix: address analyzer warnings in auto-upload implementation"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ Settings — Recordings folder path (Task 5)
- ✅ Default `/storage/emulated/0/Call recordings` (Task 1, `_kDefaultFolder`)
- ✅ Browse button with file_picker (Task 5)
- ✅ Persisted in FlutterSecureStorage under `recordings_folder_path` (Task 1)
- ✅ Scan audio extensions: m4a, mp3, aac, wav, amr, 3gp, ogg (Task 1)
- ✅ Match by phone number (full + last-10 digits) AND timestamp ±5 min (Task 1)
- ✅ Conflict resolution: pick closest timestamp (Task 1, test in Step 1)
- ✅ App launch trigger (Task 3)
- ✅ Manual sync button in UploadStatusScreen AppBar (Task 4)
- ✅ Snackbar: "X recording(s) uploaded automatically" on launch (Task 3)
- ✅ Snackbar: "X recording(s) uploaded" / "No new recordings found" on manual sync (Task 4)
- ✅ Error: folder not found → snackbar message (Tasks 3 & 4)
- ✅ Unmatched → left in pending list for manual upload (Task 2, `runAutoUpload` only uploads matches)
- ✅ `isScanningProvider` spinner on sync button (Task 4)
- ✅ Permissions already in manifest — no new changes needed
