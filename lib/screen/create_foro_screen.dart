import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CreateForoScreen extends StatelessWidget {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Foro'),
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crear un nuevo foro',
              style: theme.textTheme.headlineSmall?.copyWith(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                if (_titleController.text.isEmpty || _descController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título y descripción son requeridos')),
                  );
                } else {
                  final userId = FirebaseAuth.instance.currentUser?.email ?? 'Anónimo';
                  _firestoreService.createForo(
                    _titleController.text,
                    _descController.text,
                    userId,
                  );
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.forum),
              label: const Text('Crear Foro', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
