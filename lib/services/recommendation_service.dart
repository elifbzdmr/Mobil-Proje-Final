import 'dart:math';

import '../models/recommendation.dart';
import '../models/song.dart';

class RecommendationService {
  List<Recommendation> buildRecommendations({
    required List<Song> songs,
    required String? selectedMood,
    required String listeningGenre,
    required String moodDescription,
    required int refreshSeed,
  }) {
    if (songs.isEmpty) {
      return const <Recommendation>[];
    }

    final candidateSongs = songs.where((song) {
      final matchesMood = selectedMood == null || song.moodKey == selectedMood;
      final matchesGenre = listeningGenre == 'Karisik' ||
          song.genre.toLowerCase() == listeningGenre.toLowerCase();
      return matchesMood && matchesGenre;
    }).toList();
    if (candidateSongs.isEmpty) {
      return const <Recommendation>[];
    }

    final moodHints = _extractMoodHints(moodDescription);
    final random = Random(refreshSeed);

    final result = candidateSongs.map((song) {
      var score = 10 + random.nextInt(21);
      final reasons = <String>[];

      if (listeningGenre != 'Karisik') {
        score += 8;
        reasons.add('Dinlemek istedigin ture uygun');
      }

      if (selectedMood != null) {
        score += 5;
        reasons.add('Secili mood ile eslesiyor');
      }

      final lowerTags = song.tags.map((tag) => tag.toLowerCase()).toList();
      for (final hint in moodHints) {
        if (lowerTags.contains(hint)) {
          score += 4;
          reasons.add('Mood yazinla eslesti: $hint');
        }
      }

      if (reasons.isEmpty) {
        reasons.add('Dengeli oneri olarak secildi');
      }

      return Recommendation(
        song: song,
        score: score,
        reason: reasons.join(' - '),
      );
    }).toList();

    result.shuffle(random);
    result.sort((a, b) => b.score.compareTo(a.score));
    final poolSize = result.length < 24 ? result.length : 24;
    final pool = result.take(poolSize).toList()..shuffle(random);
    return pool.take(10).toList();
  }

  List<String> _extractMoodHints(String description) {
    final text = description.toLowerCase();
    const map = <String, List<String>>{
      'mutlu': <String>['happy', 'pozitif', 'dans', 'nese'],
      'huzunlu': <String>['slow', 'huzun', 'yalniz', 'melankoli'],
      'enerjik': <String>['hizli', 'spor', 'enerji', 'pump'],
      'sakin': <String>['calm', 'odak', 'rahat', 'ambient'],
      'romantik': <String>['ask', 'romantik', 'duygu', 'heart'],
    };

    final hints = <String>[];
    for (final entry in map.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          hints.add(keyword);
        }
      }
    }
    return hints;
  }
}
