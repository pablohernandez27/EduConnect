import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;

  const ChatScreen({
    required this.chatId,
    required this.receiverId,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 1) Método para obtener datos de usuario
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': _messageController.text.trim(),
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'deleted': false
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _mostrarDialogoBorrar(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar mensaje?'),
        content: const Text('¿Estás seguro de que deseas borrar este mensaje?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .doc(messageId)
                  .update({'text': 'Mensaje eliminado', 'deleted': true});
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoBorrado(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar mensaje'),
        content: const Text('El mensaje ya ha sido eliminado'),
        actions: [
          TextButton(
            child: const Text('Volver'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(widget.receiverId),
      builder: (context, userSnapshot) {
        String? displayName;
        String? email;
        if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
          final data = userSnapshot.data!;
          displayName = (data['displayName']?.toString().isNotEmpty == true)
              ? data['displayName'] as String
              : null;
          email = data['email'] as String?;
        }

        return Scaffold(
          appBar: AppBar(
            title: displayName != null
            // Si hay usuario, lo mostramos normal
                ? Text(displayName)
            // Si no, mostramos email con fontSize menor
                : Text(
              email ?? 'Chat',
              style: const TextStyle(fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] ==
                            FirebaseAuth.instance.currentUser!.uid;
                        final isDeleted = msg['deleted'] as bool;
                        final messageText = msg['text'] ?? '';
                        final timestamp = msg['timestamp'] != null
                            ? DateFormat('dd/MM/yyyy HH:mm')
                            .format((msg['timestamp'] as Timestamp).toDate())
                            : '';

                        return GestureDetector(
                          onLongPress: () {
                            if (isMe && !isDeleted) {
                              _mostrarDialogoBorrar(context, msg.id);
                            } else if (isMe && isDeleted) {
                              _mostrarDialogoBorrado(context);
                            }
                          },
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.green[100]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: isMe
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                              ),
                              constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    messageText,
                                    style: isDeleted
                                        ? const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic)
                                        : const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600]),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
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
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Escribe un mensaje...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
