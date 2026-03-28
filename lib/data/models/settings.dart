class AppSettings {
  final String id;
  final String userId;
  final int simSlot;
  final bool recordingEnabled;
  final bool logSyncEnabled;
  final String recordingMode;
  final List<String> numberList;
  final String directionFilter;
  final bool timeFilterEnabled;
  final String? timeFilterStart;
  final String? timeFilterEnd;
  final String syncFrequency;
  final bool wifiOnlySync;
  final bool wifiOnlyUpload;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    required this.userId,
    required this.simSlot,
    required this.recordingEnabled,
    required this.logSyncEnabled,
    required this.recordingMode,
    required this.numberList,
    required this.directionFilter,
    required this.timeFilterEnabled,
    this.timeFilterStart,
    this.timeFilterEnd,
    required this.syncFrequency,
    required this.wifiOnlySync,
    required this.wifiOnlyUpload,
    required this.updatedAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        simSlot: json['sim_slot'] as int,
        recordingEnabled: json['recording_enabled'] as bool,
        logSyncEnabled: json['log_sync_enabled'] as bool,
        recordingMode: json['recording_mode'] as String,
        numberList: List<String>.from(json['number_list'] as List? ?? []),
        directionFilter: json['direction_filter'] as String,
        timeFilterEnabled: json['time_filter_enabled'] as bool,
        timeFilterStart: json['time_filter_start'] as String?,
        timeFilterEnd: json['time_filter_end'] as String?,
        syncFrequency: json['sync_frequency'] as String,
        wifiOnlySync: json['wifi_only_sync'] as bool,
        wifiOnlyUpload: json['wifi_only_upload'] as bool,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  AppSettings copyWith({
    int? simSlot,
    bool? recordingEnabled,
    bool? logSyncEnabled,
    String? recordingMode,
    List<String>? numberList,
    String? directionFilter,
    bool? timeFilterEnabled,
    String? timeFilterStart,
    String? timeFilterEnd,
    String? syncFrequency,
    bool? wifiOnlySync,
    bool? wifiOnlyUpload,
  }) =>
      AppSettings(
        id: id,
        userId: userId,
        simSlot: simSlot ?? this.simSlot,
        recordingEnabled: recordingEnabled ?? this.recordingEnabled,
        logSyncEnabled: logSyncEnabled ?? this.logSyncEnabled,
        recordingMode: recordingMode ?? this.recordingMode,
        numberList: numberList ?? this.numberList,
        directionFilter: directionFilter ?? this.directionFilter,
        timeFilterEnabled: timeFilterEnabled ?? this.timeFilterEnabled,
        timeFilterStart: timeFilterStart ?? this.timeFilterStart,
        timeFilterEnd: timeFilterEnd ?? this.timeFilterEnd,
        syncFrequency: syncFrequency ?? this.syncFrequency,
        wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
        wifiOnlyUpload: wifiOnlyUpload ?? this.wifiOnlyUpload,
        updatedAt: updatedAt,
      );
}

// Sim slot labels
const Map<int, String> simSlotLabels = {
  0: 'SIM 1',
  1: 'SIM 2',
  2: 'Both',
};

// Recording mode labels
const Map<String, String> recordingModeLabels = {
  'all': 'All Calls',
  'whitelist': 'Whitelist Only',
  'blacklist': 'Blacklist (Exclude)',
  'unknown_only': 'Unknown Numbers',
};

// Direction filter labels
const Map<String, String> directionFilterLabels = {
  'all': 'All',
  'inbound': 'Inbound',
  'outbound': 'Outbound',
};

// Sync frequency labels
const Map<String, String> syncFrequencyLabels = {
  'realtime': 'Real-time',
  'hourly': 'Every Hour',
  'end_of_day': 'End of Day',
};
