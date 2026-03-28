import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings.dart';
import '../../data/services/settings_service.dart';
import 'auth_provider.dart';

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.read(apiClientProvider)),
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.read(settingsServiceProvider).getSettings();
  }

  Future<void> updateSimSlot(int slot) async {
    final previous = state;
    // Optimistic update
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(simSlot: slot));
    }
    try {
      final updated = await ref.read(settingsServiceProvider).updateSimSlot(slot);
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateRecordingRules({
    bool? recordingEnabled,
    String? recordingMode,
    List<String>? numberList,
    String? directionFilter,
    bool? timeFilterEnabled,
    String? timeFilterStart,
    String? timeFilterEnd,
  }) async {
    final previous = state;
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(
        recordingEnabled: recordingEnabled,
        recordingMode: recordingMode,
        numberList: numberList,
        directionFilter: directionFilter,
        timeFilterEnabled: timeFilterEnabled,
        timeFilterStart: timeFilterStart,
        timeFilterEnd: timeFilterEnd,
      ));
    }
    try {
      final updated = await ref.read(settingsServiceProvider).updateRecordingRules(
            recordingEnabled: recordingEnabled,
            recordingMode: recordingMode,
            numberList: numberList,
            directionFilter: directionFilter,
            timeFilterEnabled: timeFilterEnabled,
            timeFilterStart: timeFilterStart,
            timeFilterEnd: timeFilterEnd,
          );
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateSyncSettings({
    bool? logSyncEnabled,
    String? syncFrequency,
    bool? wifiOnlySync,
    bool? wifiOnlyUpload,
  }) async {
    final previous = state;
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(
        logSyncEnabled: logSyncEnabled,
        syncFrequency: syncFrequency,
        wifiOnlySync: wifiOnlySync,
        wifiOnlyUpload: wifiOnlyUpload,
      ));
    }
    try {
      final updated = await ref.read(settingsServiceProvider).updateSyncSettings(
            logSyncEnabled: logSyncEnabled,
            syncFrequency: syncFrequency,
            wifiOnlySync: wifiOnlySync,
            wifiOnlyUpload: wifiOnlyUpload,
          );
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
