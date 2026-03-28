import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recording.dart';
import '../../data/services/recording_service.dart';
import 'auth_provider.dart';

final recordingServiceProvider = Provider<RecordingService>(
  (ref) => RecordingService(ref.read(apiClientProvider)),
);

final pendingRecordingsProvider =
    AsyncNotifierProvider<PendingRecordingsNotifier, List<PendingRecording>>(
  PendingRecordingsNotifier.new,
);

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
}
