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

  Future<RecordingUrlResponse> getUrl(String callId) async {
    final response =
        await _client.dio.get('/api/telecalling/recordings/$callId');
    return RecordingUrlResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecording(String callId) async {
    await _client.dio.delete('/api/telecalling/recordings/$callId');
  }
}
