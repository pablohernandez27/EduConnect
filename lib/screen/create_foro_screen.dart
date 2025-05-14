import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CreateForoScreen extends StatelessWidget {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Foro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Título')),
            SizedBox(height: 10,),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'Descripción')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                //Verificar que se ha introducido el título y la descripción
                if(_titleController.text.isEmpty || _descController.text.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Título y descripción son requeridos'))
                  );
                }else{
                  final userId = FirebaseAuth.instance.currentUser?.email; // De tu Auth
                  _firestoreService.createForo(
                    _titleController.text,
                    _descController.text,
                    userId.toString(),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
