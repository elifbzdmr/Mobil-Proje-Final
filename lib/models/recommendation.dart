import 'song.dart';

class Recommendation {
  const Recommendation({
    required this.song,
    required this.score,
    required this.reason,
  });

  final Song song;
  final int score;
  final String reason;
}
