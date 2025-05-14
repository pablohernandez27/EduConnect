import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/tarea.dart';
import 'CreateTaskScreen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void _navigateToCreateTaskScreen({Tarea? tarea}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(tarea: tarea),
      ),
    );
  }
  void _showDeleteConfirmationDialog(Tarea tarea) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Tarea"),
          content: Text("¿Estás seguro de que quieres eliminar la tarea \"${tarea.titulo}\"?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firestoreService.deleteTarea(tarea.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarea eliminada')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar tarea: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(
        child: Text("Usuario no autenticado. Por favor, inicia sesión."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nueva Tarea',
            onPressed: () {
              _navigateToCreateTaskScreen();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Tarea>>(
        stream: _firestoreService.getTareas(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'No tienes tareas pendientes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ],
            );
          }
          if (snapshot.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Error al cargar tareas: ${snapshot.error}\nPor favor, inténtalo más tarde.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          final tareas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 8.0,
              bottom: 96.0,
            ),
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  leading: Checkbox(
                    value: tarea.completada,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _firestoreService.updateTareaCompletada(tarea.id, value);
                      }
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    tarea.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: tarea.completada
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: tarea.completada ? Colors.grey[600] : Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            tarea.descripcion!,
                            style: TextStyle(
                              fontSize: 14,
                              color: tarea.completada ? Colors.grey[600] : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      if (tarea.fechaEntrega != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Entrega: ${DateFormat('dd/MM/yyyy').format(tarea.fechaEntrega!)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: tarea.completada ? Colors.grey[500] :
                                (tarea.fechaEntrega!.isBefore(DateTime.now().subtract(const Duration(days:1))) && !tarea.completada
                                    ? Colors.redAccent
                                    : Colors.blueGrey[700])
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note_outlined, color: Colors.blueGrey[600]),
                        tooltip: 'Editar Tarea',
                        onPressed: () => _navigateToCreateTaskScreen(tarea: tarea),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                        tooltip: 'Eliminar Tarea',
                        onPressed: () => _showDeleteConfirmationDialog(tarea),
                      ),
                    ],
                  ),
                  onTap: () {
                    _navigateToCreateTaskScreen(tarea: tarea);
                  },
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                ),
              );
            },
          );
        },
      ),
    );
  }
}