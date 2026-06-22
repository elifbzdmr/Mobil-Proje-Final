import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/song.dart';

class MoodRepository {
  Future<Map<String, List<Song>>> loadSongsByMood() async {
    // JSON verisini tamamen cihaz içindeki assets klasöründen okuyoruz.
    final jsonString = await rootBundle.loadString('assets/moods.json');
    final rawMap = jsonDecode(jsonString) as Map<String, dynamic>;

    final result = <String, List<Song>>{};
    for (final entry in rawMap.entries) {
      final moodKey = entry.key;
      final songs = (entry.value as List<dynamic>)
          .map((item) => Song.fromJson(item as Map<String, dynamic>, moodKey))
          .toList();
      result[moodKey] = songs;
    }
    return result;
  }
}
