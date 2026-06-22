import 'song.dart';

enum CommunityPostType { mood, song, playlist }

class CommunityReply {
  const CommunityReply({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String authorEmail;
  final String text;
  final DateTime createdAt;

  CommunityReply copyWith({
    String? text,
  }) {
    return CommunityReply(
      id: id,
      authorName: authorName,
      authorEmail: authorEmail,
      text: text ?? this.text,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    return CommunityReply(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'biMüzik kullanicisi',
      authorEmail: json['authorEmail'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.likedBy,
    required this.replies,
    this.songTitle,
    this.artist,
    this.genre,
    this.moodKey,
    this.playlistName,
    this.playlistSongs = const <Song>[],
  });

  final String id;
  final String authorName;
  final String authorEmail;
  final CommunityPostType type;
  final String text;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<CommunityReply> replies;
  final String? songTitle;
  final String? artist;
  final String? genre;
  final String? moodKey;
  final String? playlistName;
  final List<Song> playlistSongs;

  CommunityPost copyWith({
    String? text,
    List<String>? likedBy,
    List<CommunityReply>? replies,
    String? songTitle,
    String? artist,
    String? genre,
    String? moodKey,
    String? playlistName,
    List<Song>? playlistSongs,
  }) {
    return CommunityPost(
      id: id,
      authorName: authorName,
      authorEmail: authorEmail,
      type: type,
      text: text ?? this.text,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      replies: replies ?? this.replies,
      songTitle: songTitle ?? this.songTitle,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      moodKey: moodKey ?? this.moodKey,
      playlistName: playlistName ?? this.playlistName,
      playlistSongs: playlistSongs ?? this.playlistSongs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'type': type.name,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'songTitle': songTitle,
      'artist': artist,
      'genre': genre,
      'moodKey': moodKey,
      'playlistName': playlistName,
      'playlistSongs': playlistSongs.map((song) => song.toJson()).toList(),
    };
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'mood';
    final rawLikedBy = json['likedBy'] as List<dynamic>? ?? <dynamic>[];
    final rawReplies = json['replies'] as List<dynamic>? ?? <dynamic>[];

    return CommunityPost(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'biMüzik kullanicisi',
      authorEmail: json['authorEmail'] as String? ?? '',
      type: _parseType(rawType),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      likedBy: rawLikedBy.map((item) => item.toString()).toList(),
      replies: rawReplies
          .map((item) =>
              CommunityReply.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      songTitle: json['songTitle'] as String?,
      artist: json['artist'] as String?,
      genre: json['genre'] as String?,
      moodKey: json['moodKey'] as String?,
      playlistName: json['playlistName'] as String?,
      playlistSongs: (json['playlistSongs'] as List<dynamic>? ?? <dynamic>[])
          .map((item) =>
              Song.fromStorageJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  static CommunityPostType _parseType(String rawType) {
    if (rawType == CommunityPostType.song.name) {
      return CommunityPostType.song;
    }
    if (rawType == CommunityPostType.playlist.name) {
      return CommunityPostType.playlist;
    }
    return CommunityPostType.mood;
  }
}
