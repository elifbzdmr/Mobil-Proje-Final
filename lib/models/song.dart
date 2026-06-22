class Song {
  const Song({
    required this.title,
    required this.artist,
    required this.moodKey,
    required this.genre,
    required this.tags,
  });

  final String title;
  final String artist;
  final String moodKey;
  final String genre;
  final List<String> tags;
  String get id => '$title|$artist';

  factory Song.fromJson(Map<String, dynamic> json, String moodKey) {
    final rawTags = (json['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .toList();
    return Song(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      moodKey: moodKey,
      genre: json['genre'] as String? ?? 'Genel',
      tags: rawTags,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'artist': artist,
      'moodKey': moodKey,
      'genre': genre,
      'tags': tags,
    };
  }

  factory Song.fromStorageJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .toList();
    return Song(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      moodKey: json['moodKey'] as String? ?? '',
      genre: json['genre'] as String? ?? 'Genel',
      tags: rawTags,
    );
  }
}
