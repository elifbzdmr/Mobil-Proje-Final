import 'package:flutter/material.dart';

import '../data/mood_data.dart';
import '../models/community_post.dart';
import '../models/recommendation.dart';
import '../models/song.dart';
import '../models/user_profile.dart';
import '../services/mood_repository.dart';
import '../services/recommendation_service.dart';
import '../services/storage_service.dart';

enum PlaylistCreateResult { created, emptyName, duplicateName }

enum AccountSaveResult {
  saved,
  duplicateEmail,
  duplicateUsername,
  duplicatePhone,
}

class MoodProvider extends ChangeNotifier {
  MoodProvider({
    MoodRepository? repository,
    StorageService? storageService,
    RecommendationService? recommendationService,
  })  : _repository = repository ?? MoodRepository(),
        _storageService = storageService ?? StorageService(),
        _recommendationService =
            recommendationService ?? RecommendationService();

  final MoodRepository _repository;
  final StorageService _storageService;
  final RecommendationService _recommendationService;

  Map<String, List<Song>> _songsByMood = <String, List<Song>>{};
  Map<String, int> _moodCounts = <String, int>{};
  String? _selectedMood;
  String _preferredGenre = 'Karisik';
  String _listeningGenre = 'Karisik';
  String _moodDescription = '';
  UserProfile? _userProfile;
  Map<String, UserProfile> _accounts = <String, UserProfile>{};
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isPreparingRecommendations = false;
  int _recommendationSeed = 0;
  List<Recommendation> _recommendations = <Recommendation>[];
  List<Song> _librarySongs = <Song>[];
  Map<String, List<String>> _playlists = <String, List<String>>{};
  Map<String, String> _playlistOwners = <String, String>{};
  List<CommunityPost> _communityPosts = <CommunityPost>[];

  Map<String, List<Song>> get songsByMood => _songsByMood;
  Map<String, int> get moodCounts => _moodCounts;
  String? get selectedMood => _selectedMood;
  String get preferredGenre => _preferredGenre;
  String get listeningGenre => _listeningGenre;
  String get moodDescription => _moodDescription;
  UserProfile? get userProfile => _userProfile;
  ThemeMode get themeMode => _themeMode;
  bool get hasProfile =>
      _userProfile != null && _userProfile!.firstName.isNotEmpty;
  bool get hasAnyAccount => _accounts.isNotEmpty;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isPreparingRecommendations => _isPreparingRecommendations;
  List<Recommendation> get recommendations => _recommendations;
  List<Song> get librarySongs => _librarySongs;
  Map<String, List<String>> get playlists => _playlists;
  Map<String, String> get playlistOwners => _playlistOwners;
  List<CommunityPost> get communityPosts => _communityPosts;

  List<String> get genreOptions => const <String>[
        'Karisik',
        'Pop',
        'Rock',
        'Lo-fi',
        'Acoustic',
        'Electronic',
        'Turkce Pop',
      ];

  Map<String, List<Song>> get playlistSongs {
    final byId = <String, Song>{
      for (final song in _librarySongs) song.id: song
    };
    return _playlists.map(
      (name, songIds) => MapEntry(
        name,
        songIds
            .where((id) => byId.containsKey(id))
            .map((id) => byId[id]!)
            .toList(),
      ),
    );
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.resetForUsernameReleaseIfNeeded();
    _songsByMood = await _repository.loadSongsByMood();
    _moodCounts = await _storageService.getMoodCounts();
    _selectedMood = await _storageService.getSelectedMood();
    _moodDescription = await _storageService.getMoodDescription();
    _preferredGenre = await _storageService.getPreferredGenre();
    _themeMode = _parseThemeMode(await _storageService.getThemeMode());
    final storedPosts = await _storageService.getCommunityPosts();
    _communityPosts = storedPosts.map(CommunityPost.fromJson).toList();

    await _loadAccounts();
    final profileMap = await _storageService.getProfile();
    if (_accounts.isEmpty && profileMap != null) {
      final legacyProfile = UserProfile.fromJson(profileMap);
      _accounts[_accountKey(legacyProfile.email)] = legacyProfile;
      await _persistAccounts();
    }
    final sessionEmail = await _storageService.getSessionEmail();
    if (sessionEmail != null) {
      _userProfile = _accounts[_accountKey(sessionEmail)];
    } else if (_accounts.length == 1) {
      _userProfile = _accounts.values.first;
    }
    _isAuthenticated = sessionEmail != null && _userProfile != null;
    if (_isAuthenticated && _userProfile != null) {
      await _loadUserMusicData(_userProfile!.email, migrateLegacy: true);
    } else {
      _librarySongs = <Song>[];
      _playlists = <String, List<String>>{};
      _playlistOwners = <String, String>{};
    }
    if (_isAuthenticated) {
      await _ensurePlaylistOwners();
    }

    for (final mood in moodOptions) {
      _moodCounts.putIfAbsent(mood.key, () => 0);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectMood(String moodKey) async {
    _selectedMood = moodKey;
    _moodCounts[moodKey] = (_moodCounts[moodKey] ?? 0) + 1;
    notifyListeners();
    await _storageService.saveSelectedMood(moodKey);
    await _storageService.saveMoodCounts(_moodCounts);
  }

  Future<void> prepareRecommendations(String input,
      {required String listeningGenre}) async {
    _moodDescription = input.trim();
    _listeningGenre = listeningGenre;
    _recommendationSeed += 1;
    _isPreparingRecommendations = true;
    notifyListeners();
    await _storageService.saveMoodDescription(_moodDescription);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final allSongs = _songsByMood.values.expand((songs) => songs).toList();
    _recommendations = _recommendationService.buildRecommendations(
      songs: allSongs,
      selectedMood: _selectedMood,
      listeningGenre: _listeningGenre,
      moodDescription: _moodDescription,
      refreshSeed: _recommendationSeed,
    );
    _isPreparingRecommendations = false;
    notifyListeners();
  }

  Future<void> refreshRecommendations() async {
    if (_moodDescription.isEmpty) return;
    await prepareRecommendations(
      _moodDescription,
      listeningGenre: _listeningGenre,
    );
  }

  Future<void> clearAnalysisDraft() async {
    _moodDescription = '';
    _recommendations = <Recommendation>[];
    _listeningGenre = 'Karisik';
    notifyListeners();
    await _storageService.saveMoodDescription('');
  }

  Future<void> savePreferredGenre(String value) async {
    _preferredGenre = value;
    notifyListeners();
    await _storageService.savePreferredGenre(value);
  }

  AccountSaveResult validateNewAccountIdentity({required String username}) {
    return _findDuplicateAccount(
      email: '',
      username: _cleanUsername(username),
      phone: '',
      checkEmail: false,
      checkPhone: false,
    );
  }

  AccountSaveResult validateNewAccountContact({
    required String email,
    required String phone,
  }) {
    return _findDuplicateAccount(
      email: email.trim().toLowerCase(),
      username: '',
      phone: _normalizePhone(phone),
      checkUsername: false,
    );
  }

  Future<AccountSaveResult> completeProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String avatarId,
    required String favoriteGenre,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      return AccountSaveResult.duplicateEmail;
    }
    final normalizedUsername = _cleanUsername(username);
    final normalizedPhone = _normalizePhone(phone);
    final duplicate = _findDuplicateAccount(
      email: normalizedEmail,
      username: normalizedUsername,
      phone: normalizedPhone,
    );
    if (duplicate == AccountSaveResult.duplicateUsername ||
        duplicate == AccountSaveResult.duplicatePhone) {
      return duplicate;
    }

    _userProfile = UserProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      username: normalizedUsername,
      email: normalizedEmail,
      phone: normalizedPhone,
      avatarId: avatarId,
      favoriteGenre: favoriteGenre,
      passwordHash: _hashPassword(password),
    );
    _accounts = <String, UserProfile>{
      ..._accounts,
      normalizedEmail: _userProfile!,
    };
    _preferredGenre = favoriteGenre;
    _isAuthenticated = true;
    _librarySongs = <Song>[];
    _playlists = <String, List<String>>{};
    _playlistOwners = <String, String>{};
    notifyListeners();
    await _persistAccounts();
    await _storageService.saveProfile(_userProfile!.toJson());
    await _storageService.savePreferredGenre(favoriteGenre);
    await _storageService.saveSessionEmail(_userProfile!.email);
    await _persistLibrary();
    await _persistPlaylists();
    return AccountSaveResult.saved;
  }

  Future<AccountSaveResult> updateProfile(UserProfile profile) async {
    final currentPassword = _userProfile?.passwordHash ?? '';
    final currentEmail = _userProfile?.email ?? profile.email;
    final normalizedEmail = profile.email.trim().toLowerCase();
    final normalizedUsername = _cleanUsername(profile.username);
    final normalizedPhone = _normalizePhone(profile.phone);
    final currentKey = _accountKey(currentEmail);
    final nextKey = _accountKey(normalizedEmail);
    if (nextKey != currentKey && _accounts.containsKey(nextKey)) {
      return AccountSaveResult.duplicateEmail;
    }
    final duplicate = _findDuplicateAccount(
      email: normalizedEmail,
      username: normalizedUsername,
      phone: normalizedPhone,
      currentEmail: currentEmail,
    );
    if (duplicate != AccountSaveResult.saved) {
      return duplicate;
    }

    _userProfile = (profile.passwordHash.isEmpty
            ? profile.copyWith(passwordHash: currentPassword)
            : profile)
        .copyWith(
      email: normalizedEmail,
      username: normalizedUsername,
      phone: normalizedPhone,
    );
    _accounts = <String, UserProfile>{..._accounts}..remove(currentKey);
    _accounts[nextKey] = _userProfile!;
    _preferredGenre = profile.favoriteGenre;
    notifyListeners();
    await _persistAccounts();
    await _storageService.saveProfile(_userProfile!.toJson());
    await _storageService.savePreferredGenre(profile.favoriteGenre);
    await _storageService.saveSessionEmail(_userProfile!.email);
    return AccountSaveResult.saved;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final profile = _accounts[_accountKey(email)];
    if (profile == null) return false;
    if (password.trim().isEmpty) return false;

    final storedHash = profile.passwordHash;
    final nextHash = _hashPassword(password);
    if (storedHash.isNotEmpty && storedHash != nextHash) return false;

    _userProfile = profile;
    if (storedHash.isEmpty) {
      _userProfile = profile.copyWith(passwordHash: nextHash);
      _accounts[_accountKey(_userProfile!.email)] = _userProfile!;
      await _persistAccounts();
    }

    _isAuthenticated = true;
    await _loadUserMusicData(_userProfile!.email, migrateLegacy: true);
    notifyListeners();
    await _storageService.saveProfile(_userProfile!.toJson());
    await _storageService.saveSessionEmail(_userProfile!.email);
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userProfile = _accounts.length == 1 ? _accounts.values.first : null;
    _librarySongs = <Song>[];
    _playlists = <String, List<String>>{};
    _playlistOwners = <String, String>{};
    notifyListeners();
    await _storageService.clearSession();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String nextPassword,
  }) async {
    final profile = _userProfile;
    if (profile == null || nextPassword.trim().length < 6) return false;
    if (profile.passwordHash.isNotEmpty &&
        profile.passwordHash != _hashPassword(currentPassword)) {
      return false;
    }

    _userProfile = profile.copyWith(passwordHash: _hashPassword(nextPassword));
    _accounts[_accountKey(_userProfile!.email)] = _userProfile!;
    notifyListeners();
    await _persistAccounts();
    await _storageService.saveProfile(_userProfile!.toJson());
    return true;
  }

  Future<void> deleteAccount() async {
    final email = _userProfile?.email;
    if (email != null) {
      _accounts = <String, UserProfile>{..._accounts}
        ..remove(_accountKey(email));
    }
    _userProfile = null;
    _isAuthenticated = false;
    _selectedMood = null;
    _moodDescription = '';
    _recommendations = <Recommendation>[];
    _librarySongs = <Song>[];
    _playlists = <String, List<String>>{};
    _playlistOwners = <String, String>{};
    _moodCounts = <String, int>{};
    for (final mood in moodOptions) {
      _moodCounts[mood.key] = 0;
    }
    notifyListeners();
    await _persistAccounts();
    if (email != null) {
      await _removeCommunityActivityForUser(email);
      await _storageService.clearUserData(email);
    }
    await _storageService.clearSession();
    await _storageService.clearProfile();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(_themeModeToString(mode));
  }

  Future<void> resetMoodStats() async {
    _moodCounts = <String, int>{};
    for (final mood in moodOptions) {
      _moodCounts[mood.key] = 0;
    }
    notifyListeners();
    await _storageService.clearStats();
    await _storageService.saveMoodCounts(_moodCounts);
  }

  Future<void> addSongToLibrary(Song song) async {
    if (_librarySongs.any((s) => s.id == song.id)) return;
    _librarySongs = <Song>[..._librarySongs, song];
    notifyListeners();
    await _persistLibrary();
  }

  Future<void> removeSongFromLibrary(String songId) async {
    if (!_librarySongs.any((song) => song.id == songId)) return;
    _librarySongs = _librarySongs.where((song) => song.id != songId).toList();
    _playlists = _playlists.map(
      (name, songIds) => MapEntry(
        name,
        songIds.where((id) => id != songId).toList(),
      ),
    );
    notifyListeners();
    await _persistLibrary();
    await _persistPlaylists();
  }

  Future<void> addCommunityMoodPost(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final post = CommunityPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorName: _currentUserDisplayName,
      authorEmail: _currentUserEmail,
      type: CommunityPostType.mood,
      text: trimmed,
      moodKey: _selectedMood,
      createdAt: DateTime.now(),
      likedBy: const <String>[],
      replies: const <CommunityReply>[],
    );
    _communityPosts = <CommunityPost>[post, ..._communityPosts];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> addCommunitySongPost({
    required String title,
    required String artist,
    required String genre,
    required String note,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedArtist = artist.trim();
    if (trimmedTitle.isEmpty || trimmedArtist.isEmpty) return;

    final song = Song(
      title: trimmedTitle,
      artist: trimmedArtist,
      moodKey: _selectedMood ?? 'topluluk',
      genre: genre,
      tags: <String>['topluluk', genre.toLowerCase()],
    );
    final hasSongInLibrary = _librarySongs.any((item) => item.id == song.id);
    if (!hasSongInLibrary) {
      _librarySongs = <Song>[..._librarySongs, song];
    }

    final post = CommunityPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorName: _currentUserDisplayName,
      authorEmail: _currentUserEmail,
      type: CommunityPostType.song,
      text: note.trim().isEmpty ? 'Bu sarkiyi dinledim.' : note.trim(),
      songTitle: trimmedTitle,
      artist: trimmedArtist,
      genre: genre,
      moodKey: _selectedMood,
      createdAt: DateTime.now(),
      likedBy: const <String>[],
      replies: const <CommunityReply>[],
    );
    _communityPosts = <CommunityPost>[post, ..._communityPosts];
    notifyListeners();
    if (!hasSongInLibrary) {
      await _persistLibrary();
    }
    await _persistCommunityPosts();
  }

  Future<void> addCommunityPlaylistPost({
    required String playlistName,
    required String note,
  }) async {
    final trimmedName = playlistName.trim();
    if (!_playlists.containsKey(trimmedName)) return;
    final songs = playlistSongs[trimmedName] ?? <Song>[];
    if (songs.isEmpty) return;

    final post = CommunityPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorName: _currentUserDisplayName,
      authorEmail: _currentUserEmail,
      type: CommunityPostType.playlist,
      text: note.trim().isEmpty ? 'Bu playlisti paylastim.' : note.trim(),
      playlistName: trimmedName,
      playlistSongs: songs,
      moodKey: _selectedMood,
      createdAt: DateTime.now(),
      likedBy: const <String>[],
      replies: const <CommunityReply>[],
    );
    _communityPosts = <CommunityPost>[post, ..._communityPosts];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> updateCommunityPost({
    required String postId,
    required String text,
    String? songTitle,
    String? artist,
    String? genre,
    String? playlistName,
  }) async {
    final index = _communityPosts.indexWhere((post) => post.id == postId);
    if (index == -1 || !_isOwnPost(_communityPosts[index])) return;
    final current = _communityPosts[index];
    final nextSongTitle = songTitle?.trim();
    final nextArtist = artist?.trim();
    final nextPlaylistName = playlistName?.trim();
    final next = current.copyWith(
      text: text.trim().isEmpty ? current.text : text.trim(),
      songTitle: nextSongTitle == null || nextSongTitle.isEmpty
          ? current.songTitle
          : nextSongTitle,
      artist: nextArtist == null || nextArtist.isEmpty
          ? current.artist
          : nextArtist,
      genre: genre ?? current.genre,
      playlistName: nextPlaylistName == null || nextPlaylistName.isEmpty
          ? current.playlistName
          : nextPlaylistName,
      playlistSongs: current.playlistSongs,
    );
    _communityPosts = <CommunityPost>[
      ..._communityPosts.take(index),
      next,
      ..._communityPosts.skip(index + 1),
    ];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> deleteCommunityPost(String postId) async {
    CommunityPost? target;
    for (final post in _communityPosts) {
      if (post.id == postId) {
        target = post;
        break;
      }
    }
    if (target == null || !_isOwnPost(target)) return;
    _communityPosts =
        _communityPosts.where((post) => post.id != postId).toList();
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> toggleCommunityLike(String postId) async {
    final index = _communityPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;
    final current = _communityPosts[index];
    final userKey = _currentUserEmail;
    final likedBy = current.likedBy.contains(userKey)
        ? current.likedBy.where((email) => email != userKey).toList()
        : <String>[...current.likedBy, userKey];
    final next = current.copyWith(likedBy: likedBy);
    _communityPosts = <CommunityPost>[
      ..._communityPosts.take(index),
      next,
      ..._communityPosts.skip(index + 1),
    ];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> addCommunityReply({
    required String postId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final index = _communityPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;
    final current = _communityPosts[index];
    final reply = CommunityReply(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorName: _currentUserDisplayName,
      authorEmail: _currentUserEmail,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final next = current.copyWith(
      replies: <CommunityReply>[...current.replies, reply],
    );
    _communityPosts = <CommunityPost>[
      ..._communityPosts.take(index),
      next,
      ..._communityPosts.skip(index + 1),
    ];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> updateCommunityReply({
    required String postId,
    required String replyId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final postIndex = _communityPosts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;
    final post = _communityPosts[postIndex];
    final replyIndex = post.replies.indexWhere((reply) => reply.id == replyId);
    if (replyIndex == -1) return;
    final reply = post.replies[replyIndex];
    if (reply.authorEmail != _currentUserEmail) return;

    final replies = <CommunityReply>[
      ...post.replies.take(replyIndex),
      reply.copyWith(text: trimmed),
      ...post.replies.skip(replyIndex + 1),
    ];
    final nextPost = post.copyWith(replies: replies);
    _communityPosts = <CommunityPost>[
      ..._communityPosts.take(postIndex),
      nextPost,
      ..._communityPosts.skip(postIndex + 1),
    ];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<void> deleteCommunityReply({
    required String postId,
    required String replyId,
  }) async {
    final postIndex = _communityPosts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;
    final post = _communityPosts[postIndex];
    final target = post.replies
        .where((reply) => reply.id == replyId)
        .cast<CommunityReply?>()
        .firstWhere((reply) => reply != null, orElse: () => null);
    if (target == null || target.authorEmail != _currentUserEmail) return;

    final nextPost = post.copyWith(
      replies: post.replies.where((reply) => reply.id != replyId).toList(),
    );
    _communityPosts = <CommunityPost>[
      ..._communityPosts.take(postIndex),
      nextPost,
      ..._communityPosts.skip(postIndex + 1),
    ];
    notifyListeners();
    await _persistCommunityPosts();
  }

  Future<PlaylistCreateResult> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return PlaylistCreateResult.emptyName;
    if (_playlists.keys
        .any((key) => key.toLowerCase() == trimmed.toLowerCase())) {
      return PlaylistCreateResult.duplicateName;
    }
    _playlists = <String, List<String>>{
      ..._playlists,
      trimmed: <String>[],
    };
    _playlistOwners = <String, String>{
      ..._playlistOwners,
      trimmed: _currentUserDisplayName,
    };
    notifyListeners();
    await _persistPlaylists();
    return PlaylistCreateResult.created;
  }

  Future<PlaylistCreateResult> createPlaylistWithSongs(
    String name,
    Iterable<Song> songs,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return PlaylistCreateResult.emptyName;
    if (_playlists.keys
        .any((key) => key.toLowerCase() == trimmed.toLowerCase())) {
      return PlaylistCreateResult.duplicateName;
    }

    final uniqueSongs = <String, Song>{
      for (final song in songs) song.id: song,
    }.values.toList();
    final libraryIds = _librarySongs.map((song) => song.id).toSet();
    final songsToAdd =
        uniqueSongs.where((song) => !libraryIds.contains(song.id)).toList();

    if (songsToAdd.isNotEmpty) {
      _librarySongs = <Song>[..._librarySongs, ...songsToAdd];
    }
    _playlists = <String, List<String>>{
      ..._playlists,
      trimmed: uniqueSongs.map((song) => song.id).toList(),
    };
    _playlistOwners = <String, String>{
      ..._playlistOwners,
      trimmed: _currentUserDisplayName,
    };

    notifyListeners();
    if (songsToAdd.isNotEmpty) {
      await _persistLibrary();
    }
    await _persistPlaylists();
    return PlaylistCreateResult.created;
  }

  Future<void> addSongToPlaylist(String playlistName, Song song) async {
    if (!_playlists.containsKey(playlistName)) return;
    final hasSongInLibrary = _librarySongs.any((s) => s.id == song.id);
    if (!hasSongInLibrary) {
      _librarySongs = <Song>[..._librarySongs, song];
    }
    final nextIds = <String>[
      ..._playlists[playlistName]!,
      if (!_playlists[playlistName]!.contains(song.id)) song.id,
    ];
    _playlists = <String, List<String>>{
      ..._playlists,
      playlistName: nextIds.toSet().toList(),
    };
    notifyListeners();
    if (!hasSongInLibrary) {
      await _persistLibrary();
    }
    await _persistPlaylists();
  }

  Future<PlaylistCreateResult> renamePlaylist({
    required String oldName,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return PlaylistCreateResult.emptyName;
    if (!_playlists.containsKey(oldName)) return PlaylistCreateResult.emptyName;
    if (trimmed != oldName &&
        _playlists.keys
            .any((key) => key.toLowerCase() == trimmed.toLowerCase())) {
      return PlaylistCreateResult.duplicateName;
    }
    if (trimmed == oldName) return PlaylistCreateResult.created;

    final songIds = _playlists[oldName] ?? <String>[];
    final owner = _playlistOwners[oldName] ?? _currentUserDisplayName;
    final nextPlaylists = <String, List<String>>{};
    for (final entry in _playlists.entries) {
      nextPlaylists[entry.key == oldName ? trimmed : entry.key] = entry.value;
    }
    final nextOwners = <String, String>{..._playlistOwners};
    nextOwners.remove(oldName);
    nextOwners[trimmed] = owner;
    nextPlaylists[trimmed] = songIds;

    _playlists = nextPlaylists;
    _playlistOwners = nextOwners;
    notifyListeners();
    await _persistPlaylists();
    return PlaylistCreateResult.created;
  }

  Future<void> deletePlaylist(String name) async {
    if (!_playlists.containsKey(name)) return;
    _playlists = <String, List<String>>{..._playlists}..remove(name);
    _playlistOwners = <String, String>{..._playlistOwners}..remove(name);
    notifyListeners();
    await _persistPlaylists();
  }

  Future<void> removeSongFromPlaylist({
    required String playlistName,
    required String songId,
  }) async {
    if (!_playlists.containsKey(playlistName)) return;
    final nextIds =
        _playlists[playlistName]!.where((id) => id != songId).toList();
    _playlists = <String, List<String>>{
      ..._playlists,
      playlistName: nextIds,
    };
    notifyListeners();
    await _persistPlaylists();
  }

  Future<PlaylistCreateResult> saveSharedPlaylist(CommunityPost post) async {
    if (post.type != CommunityPostType.playlist || post.playlistSongs.isEmpty) {
      return PlaylistCreateResult.emptyName;
    }
    final baseName = post.playlistName?.trim().isNotEmpty == true
        ? post.playlistName!.trim()
        : '${post.authorName} playlisti';
    final name = _uniquePlaylistName(baseName);
    final nextLibrary = <Song>[..._librarySongs];
    for (final song in post.playlistSongs) {
      if (!nextLibrary.any((item) => item.id == song.id)) {
        nextLibrary.add(song);
      }
    }
    _librarySongs = nextLibrary;
    _playlists = <String, List<String>>{
      ..._playlists,
      name: post.playlistSongs.map((song) => song.id).toList(),
    };
    _playlistOwners = <String, String>{
      ..._playlistOwners,
      name: post.authorName,
    };
    notifyListeners();
    await _persistLibrary();
    await _persistPlaylists();
    return PlaylistCreateResult.created;
  }

  Future<void> saveCommunitySongToLibrary(CommunityPost post) async {
    final song = _songFromPost(post);
    if (song == null) return;
    await addSongToLibrary(song);
  }

  Future<void> addCommunitySongToPlaylist({
    required CommunityPost post,
    required String playlistName,
  }) async {
    final song = _songFromPost(post);
    if (song == null) return;
    await addSongToPlaylist(playlistName, song);
  }

  Future<void> _persistLibrary() async {
    if (_userProfile == null) return;
    await _storageService.saveLibrarySongsForUser(
      _userProfile!.email,
      _librarySongs.map((song) => song.toJson()).toList(),
    );
  }

  Future<void> _persistPlaylists() async {
    if (_userProfile == null) return;
    await _storageService.savePlaylistsForUser(_userProfile!.email, _playlists);
    await _storageService.savePlaylistOwnersForUser(
      _userProfile!.email,
      _playlistOwners,
    );
  }

  Future<void> _persistCommunityPosts() async {
    await _storageService.saveCommunityPosts(
      _communityPosts.map((post) => post.toJson()).toList(),
    );
  }

  Future<void> _removeCommunityActivityForUser(String email) async {
    final userKey = _accountKey(email);
    var changed = false;
    final nextPosts = <CommunityPost>[];

    for (final post in _communityPosts) {
      if (_accountKey(post.authorEmail) == userKey) {
        changed = true;
        continue;
      }

      final likedBy = post.likedBy
          .where((likedEmail) => _accountKey(likedEmail) != userKey)
          .toList();
      final replies = post.replies
          .where((reply) => _accountKey(reply.authorEmail) != userKey)
          .toList();

      if (likedBy.length != post.likedBy.length ||
          replies.length != post.replies.length) {
        changed = true;
        nextPosts.add(post.copyWith(likedBy: likedBy, replies: replies));
      } else {
        nextPosts.add(post);
      }
    }

    if (!changed) return;
    _communityPosts = nextPosts;
    await _persistCommunityPosts();
  }

  Future<void> _loadAccounts() async {
    final storedAccounts = await _storageService.getAccounts();
    _accounts = storedAccounts.map(
      (key, value) => MapEntry(_accountKey(key), UserProfile.fromJson(value)),
    );
  }

  Future<void> _persistAccounts() async {
    await _storageService.saveAccounts(
      _accounts.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    );
  }

  Future<void> _loadUserMusicData(
    String email, {
    required bool migrateLegacy,
  }) async {
    final storedLibrary = await _storageService.getLibrarySongsForUser(email);
    final storedPlaylists = await _storageService.getPlaylistsForUser(email);
    final storedOwners = await _storageService.getPlaylistOwnersForUser(email);

    _librarySongs = storedLibrary.map(Song.fromStorageJson).toList();
    _playlists = storedPlaylists;
    _playlistOwners = storedOwners;

    if (migrateLegacy &&
        _librarySongs.isEmpty &&
        _playlists.isEmpty &&
        _playlistOwners.isEmpty) {
      final legacyLibrary = await _storageService.getLibrarySongs();
      final legacyPlaylists = await _storageService.getPlaylists();
      final legacyOwners = await _storageService.getPlaylistOwners();
      if (legacyLibrary.isNotEmpty ||
          legacyPlaylists.isNotEmpty ||
          legacyOwners.isNotEmpty) {
        _librarySongs = legacyLibrary.map(Song.fromStorageJson).toList();
        _playlists = legacyPlaylists;
        _playlistOwners = legacyOwners;
        await _persistLibrary();
        await _persistPlaylists();
      }
    }

    await _ensurePlaylistOwners();
  }

  ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  String _hashPassword(String value) {
    var hash = 5381;
    for (final unit in 'mood-tune:${value.trim()}'.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    return hash.toUnsigned(32).toRadixString(16);
  }

  bool _isOwnPost(CommunityPost post) {
    return post.authorEmail == _currentUserEmail;
  }

  String get _currentUserEmail {
    return _userProfile?.email ?? 'local@bimuzik.app';
  }

  String get _currentUserDisplayName {
    final username = _userProfile?.username.trim() ?? '';
    return username.isEmpty ? 'bimuzik_kullanicisi' : '@$username';
  }

  String _cleanUsername(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? 'bimuzik_kullanicisi' : cleaned;
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  AccountSaveResult _findDuplicateAccount({
    required String email,
    required String username,
    required String phone,
    String? currentEmail,
    bool checkEmail = true,
    bool checkUsername = true,
    bool checkPhone = true,
  }) {
    final currentKey =
        currentEmail == null ? null : _accountKey(currentEmail.trim());
    for (final entry in _accounts.entries) {
      if (entry.key == currentKey) continue;
      final account = entry.value;
      if (checkEmail && _accountKey(account.email) == _accountKey(email)) {
        return AccountSaveResult.duplicateEmail;
      }
      if (checkUsername && _cleanUsername(account.username) == username) {
        return AccountSaveResult.duplicateUsername;
      }
      if (checkPhone && _normalizePhone(account.phone) == phone) {
        return AccountSaveResult.duplicatePhone;
      }
    }
    return AccountSaveResult.saved;
  }

  Future<void> _ensurePlaylistOwners() async {
    var changed = false;
    final owners = <String, String>{..._playlistOwners};
    for (final name in _playlists.keys) {
      if (!owners.containsKey(name)) {
        owners[name] = _currentUserDisplayName;
        changed = true;
      }
    }
    if (changed) {
      _playlistOwners = owners;
      await _persistPlaylists();
    }
  }

  String _accountKey(String email) {
    return email.trim().toLowerCase();
  }

  String _uniquePlaylistName(String baseName) {
    var name = baseName;
    var counter = 2;
    while (_playlists.containsKey(name)) {
      name = '$baseName ($counter)';
      counter += 1;
    }
    return name;
  }

  Song? _songFromPost(CommunityPost post) {
    if (post.type != CommunityPostType.song ||
        post.songTitle == null ||
        post.artist == null) {
      return null;
    }
    return Song(
      title: post.songTitle!,
      artist: post.artist!,
      moodKey: post.moodKey ?? 'topluluk',
      genre: post.genre ?? 'Genel',
      tags: <String>['topluluk', (post.genre ?? 'genel').toLowerCase()],
    );
  }
}
