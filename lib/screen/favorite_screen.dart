import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/foro.dart';
import 'foro_screen.dart';

class FavoriteScreen extends StatelessWidget {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favoritos')),
      body: StreamBuilder<List<Foro>>(
        stream: _firestoreService.getForos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final foros = snapshot.data!.where((foro) => foro.isFavorite).toList();

          if (foros.isEmpty) {
            return Center(child: Text('No hay foros marcados como favoritos.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: foros.length,
            itemBuilder: (context, index) {
              final foro = foros[index];
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
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForoScreen(foro: foro)),
                    );
                  }
                ),
              );
            },
          );
        },
      ),
    );
  }
}
