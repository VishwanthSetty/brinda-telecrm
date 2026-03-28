import '../models/call_log.dart';
import 'api_client.dart';

class CallLogService {
  final ApiClient _client;

  CallLogService(this._client);

  Future<CallLogListResponse> getLogs({
    String? direction,
    String? disposition,
    String? phoneNumber,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int skip = 0,
    String? agentId,
  }) async {
    final response = await _client.dio.get(
      '/api/telecalling/calls/logs',
      queryParameters: {
        'direction': direction,
        'disposition': disposition,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'agent_id': agentId,
        'limit': limit,
        'skip': skip,
      }..removeWhere((_, v) => v == null),
    );
    return CallLogListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CallLog> getLog(String callId) async {
    final response = await _client.dio.get('/api/telecalling/calls/logs/$callId');
    return CallLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CallLog> updateLog(String callId, CallLogUpdate update) async {
    final response = await _client.dio.put(
      '/api/telecalling/calls/logs/$callId',
      data: update.toJson(),
    );
    return CallLog.fromJson(response.data as Map<String, dynamic>);
  }
}
