import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/foro.dart';
import '../models/post.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Foro>> getForos() {
    return _db.collection('foros').orderBy('createdAt').snapshots().map(
            (snapshot) => snapshot.docs.map(
              (doc) => Foro.fromMap(doc.id, doc.data()),
        ).toList());
  }

  Stream<List<Post>> getPosts(String foroId) {
    return _db.collection('foros').doc(foroId).collection('posts').orderBy('createdAt').snapshots().map(
            (snapshot) => snapshot.docs.map(
              (doc) => Post.fromMap(doc.id, doc.data()),
        ).toList());
  }

  Future<void> createForo(String title, String description, String userId) async {
    await _db.collection('foros').add({
      'title': title,
      'description': description,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createPost(String foroId, String text, String userId) async {
    await _db.collection('foros').doc(foroId).collection('posts').add({
      'text': text,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
