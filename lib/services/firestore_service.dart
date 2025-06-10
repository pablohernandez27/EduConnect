import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/foro.dart';
import '../models/post.dart';
import '../models/tarea.dart';

enum TaskSortOrder { createdAtDesc, fechaEntregaAsc, fechaEntregaDesc, tituloAsc }

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Foro>> getForos() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield [];
      return;
    }
    final userId = user.uid;
    await for (final snapshot in _db.collection('foros').orderBy('createdAt').snapshots()) {
      final favSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      final favoriteIds = favSnapshot.docs.map((doc) => doc.id).toSet();
      final foros = snapshot.docs.map((doc) {
        final foro = Foro.fromMap(doc.id, doc.data());
        foro.isFavorite = favoriteIds.contains(foro.id);
        return foro;
      }).toList();
      yield foros;
    }
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
  Future<bool> esFavorito(String foroId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _db.collection('users').doc(userId).collection('favorites').doc(foroId).get();
    return doc.exists;
  }

  Future<void> toggleFavorite(String foroId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favRef = _db.collection('users').doc(userId).collection('favorites').doc(foroId);

    final exists = await favRef.get().then((doc) => doc.exists);

    if (exists) {
      await favRef.delete(); // Elimina de favoritos
    } else {
      await favRef.set({'addedAt': FieldValue.serverTimestamp()}); // Añade a favoritos
    }
  }

  Future<List<String>> getUserFavoriteForoIds() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _db.collection('users').doc(userId).collection('favorites').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<Foro>> getForosFavoritosDelUsuario() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Obtiene los IDs favoritos
    final favSnapshot = await _db.collection('users').doc(userId).collection('favorites').get();
    final favIds = favSnapshot.docs.map((doc) => doc.id).toList();

    if (favIds.isEmpty) return [];

    // Recupera los foros completos
    final forosSnapshot = await _db.collection('foros').where(FieldPath.documentId, whereIn: favIds).get();

    return forosSnapshot.docs.map((doc) => Foro.fromMap(doc.id, doc.data())).toList();
  }



  Future<void> deleteForo(String foroId) async {
    await FirebaseFirestore.instance.collection('foros').doc(foroId).delete();
  }

  Stream<List<Foro>> getForosCreadosPorUsuario() {
    final userId = FirebaseAuth.instance.currentUser!.email;

    return _db
        .collection('foros')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt')
        .snapshots()
        .asyncMap((snapshot) async {
      final favIds = await getUserFavoriteForoIds();
      return snapshot.docs.map((doc) {
        final foro = Foro.fromMap(doc.id, doc.data());
        foro.isFavorite = favIds.contains(foro.id);
        return foro;
      }).toList();
    });
  }

  Future<void> deletePost(String foroId, String postId) async {
    await FirebaseFirestore.instance
        .collection('foros')
        .doc(foroId)
        .collection('posts')
        .doc(postId)
        .delete();
  }

  Stream<List<Tarea>> getTareas(String userId, {TaskSortOrder sortOrder = TaskSortOrder.createdAtDesc}) {
    Query query = _db
        .collection('tareas')
        .where('userId', isEqualTo: userId);

    switch (sortOrder) {
      case TaskSortOrder.fechaEntregaAsc:
        query = query.orderBy('tieneFechaEntrega', descending: true);
        query = query.orderBy('fechaEntrega', descending: false);
        query = query.orderBy('createdAt', descending: true);
        break;
      case TaskSortOrder.fechaEntregaDesc:
        query = query.orderBy('tieneFechaEntrega', descending: true);
        query = query.orderBy('fechaEntrega', descending: true);
        query = query.orderBy('createdAt', descending: true);
        break;
      case TaskSortOrder.tituloAsc:
        query = query.orderBy('titulo', descending: false);
        break;
      case TaskSortOrder.createdAtDesc:
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.where((doc) => doc.data() != null).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Tarea.fromMap(doc.id, data);
      }).toList();
    });
  }

  Future<void> createTarea({
    required String titulo,
    String? descripcion,
    DateTime? fechaEntrega,
    required String userId,
  }) async {
    await _db.collection('tareas').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaEntrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega) : null,
      'completada': false,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'tieneFechaEntrega': fechaEntrega != null,
    });
  }

  Future<void> updateTareaCompletada(String tareaId, bool completada) async {
    await _db.collection('tareas').doc(tareaId).update({
      'completada': completada,
    });
  }

  Future<void> updateTarea({
    required String tareaId,
    required String titulo,
    String? descripcion,
    DateTime? fechaEntrega,
    required bool completada,
  }) async {
    await _db.collection('tareas').doc(tareaId).update({
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaEntrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega) : null,
      'completada': completada,
      'tieneFechaEntrega': fechaEntrega != null,
    });
  }

  Future<void> deleteTarea(String tareaId) async {
    await _db.collection('tareas').doc(tareaId).delete();
  }
}
