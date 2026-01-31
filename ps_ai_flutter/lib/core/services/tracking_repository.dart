import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';

class TrackingRepository {
  Future<String> saveSession(TrackingSession session) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'session_${session.sessionId}_$timestamp.json';
    final file = File('${directory.path}/$filename');

    final jsonString = jsonEncode(session.toJson());
    await file.writeAsString(jsonString);

    return file.path;
  }

  Future<List<File>> getSavedSessions() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('session_'))
        .toList();
    return files;
  }
}
