import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '../models/foro.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import 'create_post_screen.dart';

class ForoScreen extends StatelessWidget {
  final Foro foro;
  final _firestoreService = FirestoreService();

  ForoScreen({required this.foro});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(foro.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(foroId: foro.id),
                ),
              );
            },
            icon: Icon(Icons.add_comment),
          )
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: _firestoreService.getPosts(foro.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final posts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isMe = post.createdBy == currentUser?.uid;

              // Verificamos que createdAt no sea nulo y lo formateamos
              final postDate = post.createdAt != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt)
                  : 'Fecha desconocida'; // Si es nulo, muestra "Fecha desconocida"

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.text,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publicado por: ${isMe ? 'Tú' : post.createdBy}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: $postDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
