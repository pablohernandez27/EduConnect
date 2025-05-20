import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/screen/create_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateChat()),
            ),
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No tienes chats todavía"));
          }

          final chatDocs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: chatDocs.length,
            itemBuilder: (context, i) {
              final chat = chatDocs[i];
              final otherUid = (chat['users'] as List)
                  .cast<String>()
                  .firstWhere((u) => u != currentUser.uid);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(otherUid),
                builder: (context, usnap) {
                  if (!usnap.hasData) {
                    return const ListTile(title: Text("Cargando..."));
                  }
                  final data = usnap.data!;
                  final email = data['email'] as String? ?? 'Usuario desconocido';
                  final dn = (data['displayName'] as String?)?.trim();
                  final hasName = dn != null && dn.isNotEmpty;
                  final titleText = hasName ? dn : email;

                  // Foto Base64
                  ImageProvider? avatarImage;
                  final b64 = data['photoBase64'] as String?;
                  if (b64 != null && b64.isNotEmpty) {
                    try {
                      avatarImage = MemoryImage(base64Decode(b64));
                    } catch (_) {
                      avatarImage = null;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.grey.shade600,
                        )
                            : null,
                      ),
                      title: Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: hasName
                          ? Text(
                        email,
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                          : null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chat.id,
                              receiverId: otherUid,
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
