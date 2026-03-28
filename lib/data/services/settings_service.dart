import '../models/settings.dart';
import 'api_client.dart';

class SettingsService {
  final ApiClient _client;

  SettingsService(this._client);

  Future<AppSettings> getSettings() async {
    final response = await _client.dio.get('/api/telecalling/settings');
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppSettings> updateSimSlot(int simSlot) async {
    final response = await _client.dio.put(
      '/api/telecalling/settings/sim',
      data: {'sim_slot': simSlot},
    );
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppSettings> updateRecordingRules({
    bool? recordingEnabled,
    String? recordingMode,
    List<String>? numberList,
    String? directionFilter,
    bool? timeFilterEnabled,
    String? timeFilterStart,
    String? timeFilterEnd,
  }) async {
    final response = await _client.dio.put(
      '/api/telecalling/settings/recording-rules',
      data: {
        'recording_enabled': recordingEnabled,
        'recording_mode': recordingMode,
        'number_list': numberList,
        'direction_filter': directionFilter,
        'time_filter_enabled': timeFilterEnabled,
        'time_filter_start': timeFilterStart,
        'time_filter_end': timeFilterEnd,
      }..removeWhere((_, v) => v == null),
    );
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppSettings> updateSyncSettings({
    bool? logSyncEnabled,
    String? syncFrequency,
    bool? wifiOnlySync,
    bool? wifiOnlyUpload,
  }) async {
    final response = await _client.dio.put(
      '/api/telecalling/settings/sync',
      data: {
        'log_sync_enabled': logSyncEnabled,
        'sync_frequency': syncFrequency,
        'wifi_only_sync': wifiOnlySync,
        'wifi_only_upload': wifiOnlyUpload,
      }..removeWhere((_, v) => v == null),
    );
    return AppSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
