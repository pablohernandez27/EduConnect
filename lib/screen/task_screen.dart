import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/tarea.dart';
import 'create_task_screen.dart';

enum TaskFilterState { todas, pendientes, completadas }

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  TaskFilterState _currentFilter = TaskFilterState.pendientes;

  TaskSortOrder _currentSortOrder = TaskSortOrder.createdAtDesc;

  void _navigateToCreateTaskScreen({Tarea? tarea}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTaskScreen(tarea: tarea)),
    );
  }

  void _showDeleteConfirmationDialog(Tarea tarea) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Tarea"),
          content: Text(
            "¿Estás seguro de que quieres eliminar la tarea \"${tarea.titulo}\"?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  await _firestoreService.deleteTarea(tarea.id);
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tarea eliminada')),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar tarea: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStateWidget() {
    String message = 'No tienes tareas.';
    IconData iconData = Icons.list_alt_rounded;

    switch (_currentFilter) {
      case TaskFilterState.pendientes:
        message = '¡Todo al día!\nNo tienes tareas pendientes.';
        iconData = Icons.check_circle_outline_rounded;
        break;
      case TaskFilterState.completadas:
        message = 'Aún no has completado ninguna tarea.';
        iconData = Icons.done_all_rounded;
        break;
      case TaskFilterState.todas:
        message = 'No hay tareas creadas todavía.';
        iconData = Icons.note_add_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 150),

            Icon(iconData, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_currentFilter != TaskFilterState.completadas)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Nueva Tarea'),
                onPressed: () => _navigateToCreateTaskScreen(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text("Usuario no autenticado. Por favor, inicia sesión."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.sort),
            tooltip: "Filtrar u Ordenar tareas",
            onSelected: (value) {
              setState(() {
                if (value is TaskFilterState) {
                  _currentFilter = value;
                } else if (value is TaskSortOrder) {
                  _currentSortOrder = value;
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
              // --- Sección de Filtro ---
              PopupMenuItem<dynamic>(
                enabled: false,
                child: Text('Filtrar por:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              ),
              PopupMenuItem<TaskFilterState>(
                value: TaskFilterState.pendientes,
                enabled: _currentFilter != TaskFilterState.pendientes,
                child: Text('Pendientes', style: _currentFilter == TaskFilterState.pendientes ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              PopupMenuItem<TaskFilterState>(
                value: TaskFilterState.completadas,
                enabled: _currentFilter != TaskFilterState.completadas,
                child: Text('Completadas', style: _currentFilter == TaskFilterState.completadas ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              PopupMenuItem<TaskFilterState>(
                value: TaskFilterState.todas,
                enabled: _currentFilter != TaskFilterState.todas,
                child: Text('Todas', style: _currentFilter == TaskFilterState.todas ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              const PopupMenuDivider(),
              // --- Sección de Orden ---
              PopupMenuItem<dynamic>(
                enabled: false,
                child: Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              ),
              PopupMenuItem<TaskSortOrder>(
                value: TaskSortOrder.createdAtDesc,
                enabled: _currentSortOrder != TaskSortOrder.createdAtDesc,
                child: Text('Más Recientes', style: _currentSortOrder == TaskSortOrder.createdAtDesc ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              PopupMenuItem<TaskSortOrder>(
                value: TaskSortOrder.fechaEntregaAsc,
                enabled: _currentSortOrder != TaskSortOrder.fechaEntregaAsc,
                child: Text('Fecha Entrega (Próximas)', style: _currentSortOrder == TaskSortOrder.fechaEntregaAsc ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              PopupMenuItem<TaskSortOrder>(
                value: TaskSortOrder.fechaEntregaDesc,
                enabled: _currentSortOrder != TaskSortOrder.fechaEntregaDesc,
                child: Text('Fecha Entrega (Lejanas)', style: _currentSortOrder == TaskSortOrder.fechaEntregaDesc ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
              PopupMenuItem<TaskSortOrder>(
                value: TaskSortOrder.tituloAsc,
                enabled: _currentSortOrder != TaskSortOrder.tituloAsc,
                child: Text('Título (A-Z)', style: _currentSortOrder == TaskSortOrder.tituloAsc ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : null),
              ),
            ],
          ),
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
        stream: _firestoreService.getTareas(_currentUserId!, sortOrder: _currentSortOrder),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar tareas: ${snapshot.error}\nPor favor, revisa tu conexión o inténtalo más tarde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }
          List<Tarea> todasLasTareas = snapshot.data!;
          List<Tarea> tareasFiltradas;

          switch (_currentFilter) {
            case TaskFilterState.pendientes:
              tareasFiltradas =
                  todasLasTareas.where((t) => !t.completada).toList();
              break;
            case TaskFilterState.completadas:
              tareasFiltradas =
                  todasLasTareas.where((t) => t.completada).toList();
              break;
            case TaskFilterState.todas:
            default:
              tareasFiltradas = todasLasTareas;
              break;
          }

          if (tareasFiltradas.isEmpty) {
            return _buildEmptyStateWidget();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 8.0,
              bottom: 96.0,
            ),
            itemCount: tareasFiltradas.length,
            itemBuilder: (context, index) {
              final tarea = tareasFiltradas[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: Checkbox(
                    value: tarea.completada,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _firestoreService.updateTareaCompletada(
                          tarea.id,
                          value,
                        );
                      }
                    },
                    activeColor: Theme.of(context).primaryColor,
                    visualDensity: VisualDensity.compact,
                  ),
                  title: Text(
                    tarea.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration:
                          tarea.completada
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                      color:
                          tarea.completada
                              ? Colors.grey[600]
                              : Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tarea.descripcion != null &&
                          tarea.descripcion!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                          child: Text(
                            tarea.descripcion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  tarea.completada
                                      ? Colors.grey[600]
                                      : Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      if (tarea.fechaEntrega != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaEntrega!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  tarea.completada
                                      ? Colors.grey[500]
                                      : (tarea.fechaEntrega!.isBefore(
                                                DateTime.now().subtract(
                                                  const Duration(days: 1),
                                                ),
                                              ) &&
                                              !tarea.completada
                                          ? Colors.redAccent
                                          : Colors.blueGrey[700]),
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_note_outlined,
                          color: Colors.blueGrey[600],
                        ),
                        tooltip: 'Editar Tarea',
                        onPressed:
                            () => _navigateToCreateTaskScreen(tarea: tarea),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                        tooltip: 'Eliminar Tarea',
                        onPressed: () => _showDeleteConfirmationDialog(tarea),
                      ),
                    ],
                  ),
                  onTap: () {
                    _navigateToCreateTaskScreen(tarea: tarea);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 12.0,
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
