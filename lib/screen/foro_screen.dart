import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/foro.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';

class ForoScreen extends StatefulWidget {
  final Foro foro;

  ForoScreen({required this.foro});

  @override
  _ForoScreenState createState() => _ForoScreenState();
}

class _ForoScreenState extends State<ForoScreen> with WidgetsBindingObserver {
  final _firestoreService = FirestoreService();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendPost() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _firestoreService.createPost(
      widget.foro.id,
      text,
      currentUser?.email ?? 'Usuario desconocido',
    );

    _textController.clear();
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _confirmDeletePost(Post post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar post'),
        content: Text('¿Seguro que quieres eliminar este post?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _firestoreService.deletePost(widget.foro.id, post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.foro.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _firestoreService.getPosts(widget.foro.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final posts = snapshot.data!;
                // Aquí invocas el scroll automático hacia abajo al recibir datos nuevos
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isMe = post.createdBy == currentUser?.email;
                    final postDate = post.createdAt != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt)
                        : 'Fecha desconocida';

                    return GestureDetector(
                      onLongPress: isMe ? () => _confirmDeletePost(post) : null,
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Card(
                            color: isMe ? Colors.green[100] : Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),

                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.text, style: TextStyle(fontSize: 16)),
                                  const SizedBox(height: 3),
                                  Divider(height: 3, thickness: 0.5,),
                                  Text(
                                    'Publicado por: ${isMe ? 'Tú' : post.createdBy}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Fecha: $postDate',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu post...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendPost,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
