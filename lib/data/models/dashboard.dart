class DashboardSummary {
  final int total;
  final int inbound;
  final int outbound;
  final int missed;
  final int rejected;
  final double avgDurationSeconds;
  final int totalDurationSeconds;

  const DashboardSummary({
    required this.total,
    required this.inbound,
    required this.outbound,
    required this.missed,
    required this.rejected,
    required this.avgDurationSeconds,
    required this.totalDurationSeconds,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        total: json['total'] as int? ?? 0,
        inbound: json['inbound'] as int? ?? 0,
        outbound: json['outbound'] as int? ?? 0,
        missed: json['missed'] as int? ?? 0,
        rejected: json['rejected'] as int? ?? 0,
        avgDurationSeconds: (json['avg_duration_seconds'] as num?)?.toDouble() ?? 0.0,
        totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
      );

  factory DashboardSummary.empty() => const DashboardSummary(
        total: 0,
        inbound: 0,
        outbound: 0,
        missed: 0,
        rejected: 0,
        avgDurationSeconds: 0,
        totalDurationSeconds: 0,
      );
}

class DailyTrend {
  final String date;
  final int total;
  final int inbound;
  final int outbound;
  final int missed;

  const DailyTrend({
    required this.date,
    required this.total,
    required this.inbound,
    required this.outbound,
    required this.missed,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) => DailyTrend(
        date: json['date'] as String,
        total: json['total'] as int? ?? 0,
        inbound: json['inbound'] as int? ?? 0,
        outbound: json['outbound'] as int? ?? 0,
        missed: json['missed'] as int? ?? 0,
      );
}

class TrendResponse {
  final int days;
  final List<DailyTrend> data;

  const TrendResponse({required this.days, required this.data});

  factory TrendResponse.fromJson(Map<String, dynamic> json) => TrendResponse(
        days: json['days'] as int,
        data: (json['data'] as List)
            .map((e) => DailyTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RecordingStats {
  final int totalRecordings;
  final int totalSizeBytes;
  final double totalSizeMb;

  const RecordingStats({
    required this.totalRecordings,
    required this.totalSizeBytes,
    required this.totalSizeMb,
  });

  factory RecordingStats.fromJson(Map<String, dynamic> json) => RecordingStats(
        totalRecordings: json['total_recordings'] as int? ?? 0,
        totalSizeBytes: json['total_size_bytes'] as int? ?? 0,
        totalSizeMb: (json['total_size_mb'] as num?)?.toDouble() ?? 0.0,
      );

  factory RecordingStats.empty() =>
      const RecordingStats(totalRecordings: 0, totalSizeBytes: 0, totalSizeMb: 0.0);
}
