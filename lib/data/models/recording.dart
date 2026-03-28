class RecordingResponse {
  final String id;
  final String callLogId;
  final String userId;
  final int fileSizeBytes;
  final String fileFormat;
  final int durationSeconds;
  final DateTime uploadedAt;

  const RecordingResponse({
    required this.id,
    required this.callLogId,
    required this.userId,
    required this.fileSizeBytes,
    required this.fileFormat,
    required this.durationSeconds,
    required this.uploadedAt,
  });

  factory RecordingResponse.fromJson(Map<String, dynamic> json) =>
      RecordingResponse(
        id: json['id'] as String,
        callLogId: json['call_log_id'] as String,
        userId: json['user_id'] as String,
        fileSizeBytes: json['file_size_bytes'] as int,
        fileFormat: json['file_format'] as String,
        durationSeconds: json['duration_seconds'] as int,
        uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      );
}

class RecordingUrlResponse {
  final String url;
  final int expiresIn;

  const RecordingUrlResponse({required this.url, required this.expiresIn});

  factory RecordingUrlResponse.fromJson(Map<String, dynamic> json) =>
      RecordingUrlResponse(
        url: json['url'] as String,
        expiresIn: json['expires_in'] as int? ?? 3600,
      );
}

class PendingRecording {
  final String callLogId;
  final String phoneNumber;
  final String direction;
  final DateTime startedAt;
  final int durationSeconds;

  const PendingRecording({
    required this.callLogId,
    required this.phoneNumber,
    required this.direction,
    required this.startedAt,
    required this.durationSeconds,
  });

  factory PendingRecording.fromJson(Map<String, dynamic> json) =>
      PendingRecording(
        callLogId: json['call_log_id'] as String,
        phoneNumber: json['phone_number'] as String,
        direction: json['direction'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        durationSeconds: json['duration_seconds'] as int,
      );
}
