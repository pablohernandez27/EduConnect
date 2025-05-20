import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/screen/create_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("No has iniciado sesión"));
    }

    final chatsRef = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus Chats"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateChat()),
              );
            },
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tienes chats todavía"));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatId = chatDoc.id;
              final users = List<String>.from(chatDoc['users']);
              final otherUserId = users.firstWhere((uid) => uid != currentUser.uid);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Cargando..."));
                  }

                  final userData = userSnapshot.data!;
                  // Mostrar username si existe, sino email
                  final displayName = userData['displayName']?.toString().isNotEmpty == true
                      ? userData['displayName'] as String
                      : userData['email'] as String? ?? 'Usuario desconocido';

                  // Procesar foto Base64
                  final photoBase64 = userData['photoBase64'] as String?;
                  ImageProvider? avatarImage;
                  if (photoBase64 != null && photoBase64.isNotEmpty) {
                    try {
                      avatarImage = MemoryImage(base64Decode(photoBase64));
                    } catch (e) {
                      avatarImage = null;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                            : null,
                      ),
                      title: Text(
                        displayName,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text("Toca para continuar el chat"),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              receiverId: otherUserId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
