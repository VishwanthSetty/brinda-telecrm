import 'package:dio/dio.dart';
import '../models/recording.dart';
import 'api_client.dart';

class RecordingService {
  final ApiClient _client;

  RecordingService(this._client);

  Future<List<PendingRecording>> getPending() async {
    final response = await _client.dio.get('/api/telecalling/recordings/pending');
    final list = response.data as List;
    return list
        .map((e) => PendingRecording.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecordingResponse> uploadRecording({
    required String callLogId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) async {
    final formData = FormData.fromMap({
      'call_log_id': callLogId,
      'duration_seconds': durationSeconds,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _client.dio.post(
      '/api/telecalling/recordings/upload',
      data: formData,
    );
    return RecordingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecordingUrlResponse> getUrl(String callId) async {
    final response =
        await _client.dio.get('/api/telecalling/recordings/$callId');
    return RecordingUrlResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecording(String callId) async {
    await _client.dio.delete('/api/telecalling/recordings/$callId');
  }
}
