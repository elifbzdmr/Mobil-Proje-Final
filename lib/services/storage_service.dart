import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _dataResetVersionKey = 'data_reset_version';
  static const _currentDataResetVersion = 'username_clean_start_v1';
  static const _selectedMoodKey = 'selected_mood';
  static const _moodCountsKey = 'mood_counts';
  static const _profileKey = 'profile';
  static const _accountsKey = 'accounts';
  static const _moodDescriptionKey = 'mood_description';
  static const _preferredGenreKey = 'preferred_genre';
  static const _themeModeKey = 'theme_mode';
  static const _librarySongsKey = 'library_songs';
  static const _playlistsKey = 'playlists';
  static const _playlistOwnersKey = 'playlist_owners';
  static const _sessionKey = 'auth_session';
  static const _communityPostsKey = 'community_posts';

  Future<void> resetForUsernameReleaseIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dataResetVersionKey) == _currentDataResetVersion) {
      return;
    }

    for (final key in prefs.getKeys()) {
      if (key == _themeModeKey) continue;
      await prefs.remove(key);
    }
    await prefs.setString(_dataResetVersionKey, _currentDataResetVersion);
  }

  Future<void> saveSelectedMood(String moodKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMoodKey, moodKey);
  }

  Future<String?> getSelectedMood() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedMoodKey);
  }

  Future<void> saveMoodCounts(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    // Map yapısını SharedPreferences içinde String olarak saklıyoruz.
    await prefs.setString(_moodCountsKey, jsonEncode(counts));
  }

  Future<Map<String, int>> getMoodCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_moodCountsKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      await prefs.remove(_moodCountsKey);
      return <String, int>{};
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
  }

  Future<void> saveAccounts(Map<String, Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<Map<String, Map<String, dynamic>>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          Map<String, dynamic>.from(value as Map),
        ),
      );
    } catch (_) {
      await prefs.remove(_accountsKey);
      return <String, Map<String, dynamic>>{};
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_profileKey);
      return null;
    }
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  Future<void> saveMoodDescription(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_moodDescriptionKey, value);
  }

  Future<String> getMoodDescription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_moodDescriptionKey) ?? '';
  }

  Future<void> savePreferredGenre(String genre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredGenreKey, genre);
  }

  Future<String> getPreferredGenre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredGenreKey) ?? 'Karisik';
  }

  Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_moodCountsKey);
  }

  Future<void> saveThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> saveLibrarySongs(List<Map<String, dynamic>> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_librarySongsKey, jsonEncode(songs));
  }

  Future<void> saveLibrarySongsForUser(
    String email,
    List<Map<String, dynamic>> songs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_librarySongsKey, email), jsonEncode(songs));
  }

  Future<List<Map<String, dynamic>>> getLibrarySongs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_librarySongsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      await prefs.remove(_librarySongsKey);
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getLibrarySongsForUser(
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(_librarySongsKey, email);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      await prefs.remove(key);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> savePlaylists(Map<String, List<String>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistsKey, jsonEncode(playlists));
  }

  Future<void> savePlaylistsForUser(
    String email,
    Map<String, List<String>> playlists,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _userKey(_playlistsKey, email), jsonEncode(playlists));
  }

  Future<Map<String, List<String>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistsKey);
    if (raw == null || raw.isEmpty) {
      return <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          value is List<dynamic>
              ? value.map((item) => item.toString()).toList()
              : <String>[],
        ),
      );
    } catch (_) {
      await prefs.remove(_playlistsKey);
      return <String, List<String>>{};
    }
  }

  Future<Map<String, List<String>>> getPlaylistsForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(_playlistsKey, email);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          value is List<dynamic>
              ? value.map((item) => item.toString()).toList()
              : <String>[],
        ),
      );
    } catch (_) {
      await prefs.remove(key);
      return <String, List<String>>{};
    }
  }

  Future<void> savePlaylistOwners(Map<String, String> owners) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistOwnersKey, jsonEncode(owners));
  }

  Future<void> savePlaylistOwnersForUser(
    String email,
    Map<String, String> owners,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userKey(_playlistOwnersKey, email),
      jsonEncode(owners),
    );
  }

  Future<Map<String, String>> getPlaylistOwners() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistOwnersKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      await prefs.remove(_playlistOwnersKey);
      return <String, String>{};
    }
  }

  Future<Map<String, String>> getPlaylistOwnersForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey(_playlistOwnersKey, email);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      await prefs.remove(key);
      return <String, String>{};
    }
  }

  Future<void> saveCommunityPosts(List<Map<String, dynamic>> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_communityPostsKey, jsonEncode(posts));
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_communityPostsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      await prefs.remove(_communityPostsKey);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveSessionEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, email);
  }

  Future<String?> getSessionEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> clearAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_sessionKey);
    await prefs.remove(_librarySongsKey);
    await prefs.remove(_playlistsKey);
    await prefs.remove(_playlistOwnersKey);
    await prefs.remove(_communityPostsKey);
    await prefs.remove(_moodCountsKey);
    await prefs.remove(_selectedMoodKey);
    await prefs.remove(_moodDescriptionKey);
  }

  Future<void> clearUserData(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey(_librarySongsKey, email));
    await prefs.remove(_userKey(_playlistsKey, email));
    await prefs.remove(_userKey(_playlistOwnersKey, email));
  }

  String _userKey(String baseKey, String email) {
    return '${baseKey}_${email.trim().toLowerCase()}';
  }
}
