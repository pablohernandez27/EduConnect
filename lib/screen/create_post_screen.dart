import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CreatePostScreen extends StatelessWidget {
  final String foroId;
  final _textController = TextEditingController();
  final _firestoreService = FirestoreService();

  CreatePostScreen({required this.foroId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nuevo Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _textController, decoration: InputDecoration(labelText: 'Mensaje')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.email; // De tu Auth
                //Verificar que se ha introducido el texto
                if(_textController.text.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Texto es requerido'))
                );
                }else {
                  _firestoreService.createPost(
                    foroId,
                    _textController.text,
                    userId.toString(),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
