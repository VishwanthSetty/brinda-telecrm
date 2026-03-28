class CallLog {
  final String id;
  final String userId;
  final String phoneNumber;
  final String direction;
  final int simSlot;
  final DateTime startedAt;
  final int durationSeconds;
  final String? contactName;
  final String? note;
  final String? disposition;
  final String? recordingId;
  final DateTime syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CallLog({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.direction,
    required this.simSlot,
    required this.startedAt,
    required this.durationSeconds,
    this.contactName,
    this.note,
    this.disposition,
    this.recordingId,
    required this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) => CallLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        phoneNumber: json['phone_number'] as String,
        direction: json['direction'] as String,
        simSlot: json['sim_slot'] as int,
        startedAt: DateTime.parse(json['started_at'] as String),
        durationSeconds: json['duration_seconds'] as int,
        contactName: json['contact_name'] as String?,
        note: json['note'] as String?,
        disposition: json['disposition'] as String?,
        recordingId: json['recording_id'] as String?,
        syncedAt: DateTime.parse(json['synced_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  bool get hasRecording => recordingId != null;
  bool get isMissed => direction == 'missed';
  bool get isRejected => direction == 'rejected';
  bool get isInbound => direction == 'inbound';
  bool get isOutbound => direction == 'outbound';

  CallLog copyWith({String? note, String? disposition}) => CallLog(
        id: id,
        userId: userId,
        phoneNumber: phoneNumber,
        direction: direction,
        simSlot: simSlot,
        startedAt: startedAt,
        durationSeconds: durationSeconds,
        contactName: contactName,
        note: note ?? this.note,
        disposition: disposition ?? this.disposition,
        recordingId: recordingId,
        syncedAt: syncedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class CallLogListResponse {
  final List<CallLog> data;
  final int total;
  final int limit;
  final int skip;

  const CallLogListResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.skip,
  });

  factory CallLogListResponse.fromJson(Map<String, dynamic> json) =>
      CallLogListResponse(
        data: (json['data'] as List)
            .map((e) => CallLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        limit: json['limit'] as int,
        skip: json['skip'] as int,
      );

  bool get hasMore => skip + data.length < total;
}

class CallLogUpdate {
  final String? note;
  final String? disposition;

  const CallLogUpdate({this.note, this.disposition});

  Map<String, dynamic> toJson() => {
        if (note != null) 'note': note,
        if (disposition != null) 'disposition': disposition,
      };
}

const List<String> dispositionOptions = [
  'Interested',
  'Not Interested',
  'Callback',
  'Wrong Number',
  'Other',
];
