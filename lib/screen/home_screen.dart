import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/foro.dart';
import 'foro_screen.dart';
import 'create_foro_screen.dart';

enum ForoFilterState { todos, favoritos, misForos }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.email;
  ForoFilterState _currentFilter = ForoFilterState.todos;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Widget _buildEmptyStateWidget({String? message, IconData? iconData}) {
    if (message != null && iconData != null) {
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
              const Spacer(flex: 2),
            ],
          ),
        ),
      );
    }

    String defaultMessage = 'No hay foros.';
    IconData defaultIcon = Icons.list_alt_rounded;

    switch (_currentFilter) {
      case ForoFilterState.favoritos:
        defaultMessage = 'Aún no has añadido ningún foro a favoritos.';
        defaultIcon = Icons.done_all_rounded;
        break;
      case ForoFilterState.todos:
        defaultMessage = 'No hay foros creados todavía.';
        defaultIcon = Icons.note_add_outlined;
        break;
      case ForoFilterState.misForos:
        defaultMessage = 'No has creado ningún foro todavía.';
        defaultIcon = Icons.forum_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 150),
            Icon(defaultIcon, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              defaultMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                height: 1.4,
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
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar foros...',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
                : Text('Foros'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtrar foros",
            onSelected: (value) {
              setState(() {
                if (value is ForoFilterState) {
                  _currentFilter = value;
                }
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<dynamic>>[
                  PopupMenuItem<dynamic>(
                    enabled: false,
                    child: Text(
                      'Filtrar por:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  PopupMenuItem<ForoFilterState>(
                    value: ForoFilterState.todos,
                    enabled: _currentFilter != ForoFilterState.todos,
                    child: Text(
                      'Todos',
                      style:
                          _currentFilter == ForoFilterState.todos
                              ? TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              )
                              : null,
                    ),
                  ),
                  PopupMenuItem<ForoFilterState>(
                    value: ForoFilterState.misForos,
                    enabled: _currentFilter != ForoFilterState.misForos,
                    child: Text(
                      'Mis Foros',
                      style:
                          _currentFilter == ForoFilterState.misForos
                              ? TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              )
                              : null,
                    ),
                  ),
                  PopupMenuItem<ForoFilterState>(
                    value: ForoFilterState.favoritos,
                    enabled: _currentFilter != ForoFilterState.favoritos,
                    child: Text(
                      'Favoritos',
                      style:
                          _currentFilter == ForoFilterState.favoritos
                              ? TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              )
                              : null,
                    ),
                  ),
                ],
          ),
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
        stream:
            _currentFilter == ForoFilterState.misForos
                ? _firestoreService.getForosCreadosPorUsuario()
                : _firestoreService.getForos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget();
          }

          final foros = snapshot.data!;
          List<Foro> ForosFiltrados;

          switch (_currentFilter) {
            case ForoFilterState.favoritos:
              ForosFiltrados = foros.where((t) => t.isFavorite).toList();
              break;
            case ForoFilterState.misForos:
              ForosFiltrados =
                  foros.where((t) => t.createdBy == _currentUserId).toList();
              break;
            case ForoFilterState.todos:
            default:
              ForosFiltrados = foros;
              break;
          }

          // Filtrado por búsqueda
          final forosBuscados =
              ForosFiltrados.where(
                (foro) => foro.title.toLowerCase().contains(_searchQuery),
              ).toList();

          if (forosBuscados.isEmpty) {
            if (_searchQuery.isNotEmpty) {
              return _buildEmptyStateWidget(
                message: 'No se encontró ningún foro con ese título.',
                iconData: Icons.search_off,
              );
            } else {
              return _buildEmptyStateWidget();
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: forosBuscados.length,
            itemBuilder: (context, index) {
              final foro = forosBuscados[index];
              final currentUser = FirebaseAuth.instance.currentUser;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
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
                      FutureBuilder<bool>(
                        future: _firestoreService.esFavorito(foro.id),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () async {
                              await _firestoreService.toggleFavorite(foro.id);
                              setState(() {});
                            },
                          );
                        },
                      ),
                      if (foro.createdBy == currentUser?.email)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: Text('Eliminar foro'),
                                    content: Text(
                                      '¿Estás seguro de que deseas eliminar este foro?',
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancelar'),
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                      ),
                                      TextButton(
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await _firestoreService.deleteForo(foro.id);
                            }
                          },
                        ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
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
