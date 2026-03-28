import '../models/dashboard.dart';
import 'api_client.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService(this._client);

  Future<DashboardSummary> getSummary() async {
    final response =
        await _client.dio.get('/api/telecalling/dashboard/summary');
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TrendResponse> getTrend({int days = 7}) async {
    final response = await _client.dio.get(
      '/api/telecalling/dashboard/trend',
      queryParameters: {'days': days},
    );
    return TrendResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecordingStats> getRecordingStats() async {
    final response =
        await _client.dio.get('/api/telecalling/dashboard/recordings/stats');
    return RecordingStats.fromJson(response.data as Map<String, dynamic>);
  }
}
