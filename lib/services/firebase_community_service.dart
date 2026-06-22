import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_post.dart';
import 'firebase_bootstrap.dart';

class FirebaseCommunityService {
  FirebaseCommunityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('community_posts');

  bool get isEnabled => FirebaseBootstrap.isEnabled;

  Stream<List<CommunityPost>> watchPosts() {
    if (!isEnabled) {
      return const Stream<List<CommunityPost>>.empty();
    }
    return _posts.snapshots().map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = data['id'] ?? doc.id;
        return CommunityPost.fromJson(data);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  Future<void> savePost(CommunityPost post) async {
    if (!isEnabled) return;
    await _posts.doc(post.id).set(post.toJson());
  }

  Future<void> deletePost(String postId) async {
    if (!isEnabled) return;
    await _posts.doc(postId).delete();
  }

  Future<void> savePosts(List<CommunityPost> posts) async {
    if (!isEnabled) return;
    final batch = _firestore.batch();
    for (final post in posts) {
      batch.set(_posts.doc(post.id), post.toJson());
    }
    await batch.commit();
  }
}
