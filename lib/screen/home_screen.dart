import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/foro.dart';
import 'foro_screen.dart';
import 'create_foro_screen.dart';

class HomeScreen extends StatelessWidget {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foros'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateForoScreen()),
              );
            },
            icon: Icon(Icons.forum),
          ),
        ],
      ),
      body: StreamBuilder<List<Foro>>(
        stream: _firestoreService.getForos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final foros = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: foros.length,
            itemBuilder: (context, index) {
              final foro = foros[index];
              final currentUser = FirebaseAuth.instance.currentUser;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.shade100,
                    child: Icon(Icons.forum, color: Colors.white),
                  ),
                  title: Text(
                    foro.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    foro.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          foro.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: foro.isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          _firestoreService.toggleFavorite(foro);
                        },
                      ),
                      if (foro.createdBy == currentUser?.email)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Eliminar foro'),
                                content: Text('¿Estás seguro de que deseas eliminar este foro?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancelar'),
                                    onPressed: () => Navigator.pop(ctx, false),
                                  ),
                                  TextButton(
                                    child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    onPressed: () => Navigator.pop(ctx, true),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _firestoreService.deleteForo(foro.id);
                            }
                          },
                        ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForoScreen(foro: foro)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}