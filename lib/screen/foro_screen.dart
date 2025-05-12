import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(foro.title),
        actions: [
          IconButton(
              onPressed: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreatePostScreen(foroId: foro.id))
                );
              },
              icon: Icon(Icons.chat)
          )
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: _firestoreService.getPosts(foro.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                title: Text(post.text),
                subtitle: Text('Por: ${post.createdBy}'),
              );
            },
          );
        },
      )
    );
  }
}
