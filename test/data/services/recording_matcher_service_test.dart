import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brinda_telecrm/data/models/recording.dart';
import 'package:brinda_telecrm/data/services/recording_matcher_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recording_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('RecordingMatcherService.matchFiles', () {
    test('matches file by exact phone digits and timestamp within window',
        () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file =
          File('${tempDir.path}/+911234567890_20240328_143022.m4a');
      await file.writeAsString('fake');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 5)));

      final pending = [
        PendingRecording(
          callLogId: 'log-1',
          phoneNumber: '+911234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches.length, 1);
      expect(matches.first.recording.callLogId, 'log-1');
    });

    test('matches by last 10 digits when full number not in filename',
        () async {
      final callEnd = DateTime(2024, 3, 28, 10, 0, 0);
      final file =
          File('${tempDir.path}/9876543210_20240328_100000.m4a');
      await file.writeAsString('fake');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-2',
          phoneNumber: '+919876543210',
          direction: 'inbound',
          startedAt: DateTime(2024, 3, 28, 9, 59, 0),
          durationSeconds: 60,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches.length, 1);
      expect(matches.first.recording.callLogId, 'log-2');
    });

    test('does not match when timestamp outside ±5 min window', () async {
      final file =
          File('${tempDir.path}/1234567890_20240328_143022.m4a');
      await file.writeAsString('fake');
      // 10 minutes after call end
      file.setLastModifiedSync(DateTime(2024, 3, 28, 14, 40, 22));

      final pending = [
        PendingRecording(
          callLogId: 'log-3',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches, isEmpty);
    });

    test('does not match when phone number not in filename', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file =
          File('${tempDir.path}/0000000000_20240328_143022.m4a');
      await file.writeAsString('fake');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-4',
          phoneNumber: '+911234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches, isEmpty);
    });

    test('ignores non-audio files', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);
      final file =
          File('${tempDir.path}/1234567890_20240328_143022.txt');
      await file.writeAsString('not audio');
      file.setLastModifiedSync(callEnd.add(const Duration(seconds: 3)));

      final pending = [
        PendingRecording(
          callLogId: 'log-5',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches, isEmpty);
    });

    test('picks closest file when multiple files match same call', () async {
      final callEnd = DateTime(2024, 3, 28, 14, 30, 22);

      final file1 = File('${tempDir.path}/1234567890_a.m4a');
      await file1.writeAsString('fake');
      file1.setLastModifiedSync(
          callEnd.add(const Duration(seconds: 10))); // 10s off

      final file2 = File('${tempDir.path}/1234567890_b.m4a');
      await file2.writeAsString('fake');
      file2
          .setLastModifiedSync(callEnd.add(const Duration(seconds: 2))); // 2s off

      final pending = [
        PendingRecording(
          callLogId: 'log-6',
          phoneNumber: '1234567890',
          direction: 'outbound',
          startedAt: DateTime(2024, 3, 28, 14, 28, 52),
          durationSeconds: 90,
        ),
      ];

      final matches = RecordingMatcherService.matchFiles(
        pending,
        tempDir.listSync().whereType<File>().toList(),
      );
      expect(matches.length, 1);
      expect(matches.first.file.path, contains('_b.m4a'));
    });
  });
}
