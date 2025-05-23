import 'package:flutter/material.dart';
import '../models/foro.dart';
import '../services/firestore_service.dart';
import 'foro_screen.dart';

class FavoritosPage extends StatefulWidget {
  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _firestoreService = FirestoreService();
  late Future<List<Foro>> _favoritosFuture;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  void _loadFavoritos() {
    _favoritosFuture = _firestoreService.getForosFavoritosDelUsuario();
  }

  Future<void> _toggleFavorite(Foro foro) async {
    await _firestoreService.toggleFavorite(foro.id);
    setState(() {
      // Para forzar recarga de favoritos
      _loadFavoritos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favoritos')),
      body: FutureBuilder<List<Foro>>(
        future: _favoritosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No tienes foros favoritos aún.'));

          final foros = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
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
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ForoScreen(foro: foro),
                    ));
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
