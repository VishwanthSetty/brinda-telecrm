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
      // Remove from pending list on success
      state = AsyncData(
        state.valueOrNull?.where((r) => r.callLogId != callLogId).toList() ??
            [],
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      uploading.update((s) => s.difference({callLogId}));
    }
  }

  /// Scans the recordings folder, matches files to pending calls, and uploads
  /// matches. Returns the number of recordings successfully uploaded.
  /// Throws [RecordingFolderNotFoundException] if the configured folder does
  /// not exist.
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
