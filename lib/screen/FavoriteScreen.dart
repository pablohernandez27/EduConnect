import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/foro.dart';
import 'foro_screen.dart';
import 'create_foro_screen.dart';

class FavoriteScreen extends StatelessWidget {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foros Favoritos')),
      body: StreamBuilder<List<Foro>>(
        stream: _firestoreService.getForos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final foros = snapshot.data!;
          return ListView.builder(
            itemCount: foros.length,
            itemBuilder: (context, index) {
              final foro = foros[index];
              return ListTile(
                title: Text(foro.title),
                subtitle: Text(foro.description),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ForoScreen(foro: foro),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CreateForoScreen(),
          ));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}