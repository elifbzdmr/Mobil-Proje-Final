import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song.dart';
import '../models/user_profile.dart';
import 'firebase_bootstrap.dart';

class FirebaseUserMusicData {
  const FirebaseUserMusicData({
    required this.librarySongs,
    required this.playlists,
    required this.playlistOwners,
  });

  final List<Song> librarySongs;
  final Map<String, List<String>> playlists;
  final Map<String, String> playlistOwners;
}

class FirebaseUserDataService {
  FirebaseUserDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get isEnabled => FirebaseBootstrap.isEnabled;

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _firestore.collection('accounts');

  CollectionReference<Map<String, dynamic>> get _userData =>
      _firestore.collection('user_data');

  Future<Map<String, UserProfile>> getAccounts() async {
    if (!isEnabled) return <String, UserProfile>{};
    final snapshot = await _accounts.get();
    return <String, UserProfile>{
      for (final doc in snapshot.docs)
        doc.id: UserProfile.fromJson(Map<String, dynamic>.from(doc.data())),
    };
  }

  Future<UserProfile?> getAccount(String email) async {
    if (!isEnabled) return null;
    final doc = await _accounts.doc(_accountKey(email)).get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveAccount(UserProfile profile) async {
    if (!isEnabled) return;
    await _accounts.doc(_accountKey(profile.email)).set(profile.toJson());
  }

  Future<void> deleteAccount(String email) async {
    if (!isEnabled) return;
    final key = _accountKey(email);
    await _accounts.doc(key).delete();
    await _userData.doc(key).delete();
  }

  Future<FirebaseUserMusicData?> getUserMusicData(String email) async {
    if (!isEnabled) return null;
    final doc = await _userData.doc(_accountKey(email)).get();
    final data = doc.data();
    if (data == null) return null;

    final rawLibrary = data['librarySongs'] as List<dynamic>? ?? <dynamic>[];
    final rawPlaylists = Map<String, dynamic>.from(
        data['playlists'] as Map? ?? <String, dynamic>{});
    final rawOwners = Map<String, dynamic>.from(
      data['playlistOwners'] as Map? ?? <String, dynamic>{},
    );

    return FirebaseUserMusicData(
      librarySongs: rawLibrary
          .map((item) =>
              Song.fromStorageJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      playlists: rawPlaylists.map(
        (key, value) => MapEntry(
          key,
          value is List<dynamic>
              ? value.map((item) => item.toString()).toList()
              : <String>[],
        ),
      ),
      playlistOwners:
          rawOwners.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<void> saveUserMusicData({
    required String email,
    required List<Song> librarySongs,
    required Map<String, List<String>> playlists,
    required Map<String, String> playlistOwners,
  }) async {
    if (!isEnabled) return;
    await _userData.doc(_accountKey(email)).set(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'librarySongs': librarySongs.map((song) => song.toJson()).toList(),
      'playlists': playlists,
      'playlistOwners': playlistOwners,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _accountKey(String email) {
    return email.trim().toLowerCase();
  }
}
