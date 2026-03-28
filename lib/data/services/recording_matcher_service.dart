import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import '../models/recording.dart';

const _kDefaultFolder = '/storage/emulated/0/Call recordings';
const _kFolderKey = 'recordings_folder_path';
const _kMatchWindowSeconds = 300; // ±5 minutes
const _kAudioExtensions = {
  '.m4a',
  '.mp3',
  '.aac',
  '.wav',
  '.amr',
  '.3gp',
  '.ogg',
};

class RecordingMatch {
  final PendingRecording recording;
  final File file;
  const RecordingMatch({required this.recording, required this.file});
}

class RecordingFolderNotFoundException implements Exception {
  final String folderPath;
  const RecordingFolderNotFoundException(this.folderPath);
  @override
  String toString() => 'Recording folder not found: $folderPath';
}

class RecordingMatcherService {
  static const _storage = FlutterSecureStorage();

  static Future<String> getFolderPath() async {
    return await _storage.read(key: _kFolderKey) ?? _kDefaultFolder;
  }

  static Future<void> setFolderPath(String path) async {
    await _storage.write(key: _kFolderKey, value: path);
  }

  /// Scans the configured folder and returns matches for each pending recording.
  /// Throws [RecordingFolderNotFoundException] if the folder does not exist.
  static Future<List<RecordingMatch>> findMatches(
    List<PendingRecording> pending,
  ) async {
    if (pending.isEmpty) return [];

    final folderPath = await getFolderPath();
    final dir = Directory(folderPath);

    if (!await dir.exists()) {
      throw RecordingFolderNotFoundException(folderPath);
    }

    final allFiles = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .where((f) =>
            _kAudioExtensions.contains(p.extension(f.path).toLowerCase()))
        .toList();

    return matchFiles(pending, allFiles);
  }

  /// Pure matching logic — separated for testability.
  static List<RecordingMatch> matchFiles(
    List<PendingRecording> pending,
    List<File> audioFiles,
  ) {
    final matches = <RecordingMatch>[];
    for (final record in pending) {
      final file = _findBestFile(record, audioFiles);
      if (file != null) {
        matches.add(RecordingMatch(recording: record, file: file));
      }
    }
    return matches;
  }

  static File? _findBestFile(PendingRecording recording, List<File> files) {
    final digits = recording.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final shortDigits =
        digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final expectedEnd = recording.startedAt
        .add(Duration(seconds: recording.durationSeconds));

    File? best;
    int bestDiff = _kMatchWindowSeconds + 1;

    for (final file in files) {
      final ext = p.extension(file.path).toLowerCase();
      if (!_kAudioExtensions.contains(ext)) continue;

      final nameDigits =
          p.basenameWithoutExtension(file.path).replaceAll(RegExp(r'\D'), '');
      if (!nameDigits.contains(digits) && !nameDigits.contains(shortDigits)) {
        continue;
      }

      final modified = file.lastModifiedSync();
      final diffSeconds = modified.difference(expectedEnd).inSeconds.abs();
      if (diffSeconds <= _kMatchWindowSeconds && diffSeconds < bestDiff) {
        best = file;
        bestDiff = diffSeconds;
      }
    }
    return best;
  }
}
