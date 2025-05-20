import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/screen/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateChat extends StatefulWidget {
  @override
  _CreateChatState createState() => _CreateChatState();
}

class _CreateChatState extends State<CreateChat> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    setState(() {
      _searchResults = result.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _createChatOrOpen(String selectedUserId, String selectedUserEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || selectedUserId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes chatear contigo mismo.')),
      );
      return;
    }

    final chatsRef = FirebaseFirestore.instance.collection('chats');
    final chatQuery = await chatsRef.where('users', arrayContains: currentUser.uid).get();

    QueryDocumentSnapshot? existingChat;
    for (var doc in chatQuery.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(selectedUserId)) {
        existingChat = doc;
        break;
      }
    }

    final chatDoc = existingChat == null
        ? await chatsRef.add({
      'users': [currentUser.uid, selectedUserId],
      'createdAt': FieldValue.serverTimestamp(),
    })
        : existingChat.reference;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatDoc.id,
          receiverId: selectedUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final inputFill = theme.colorScheme.surfaceVariant.withOpacity(0.3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Chat'),
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Campo de búsqueda
              TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                decoration: InputDecoration(
                  hintText: 'Buscar usuario por email',
                  prefixIcon: Icon(Icons.search, color: primary),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de resultados
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                  child: Text(
                    'No hay resultados',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: onSurface.withOpacity(0.6)),
                  ),
                )
                    : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final email = user['email'] as String? ?? '';
                    final username = (user['displayName'] as String?)?.trim();
                    final displayName =
                    (username?.isNotEmpty == true) ? username! : null;

                    // Procesamos foto Base64
                    final photoBase64 = user['photoBase64'] as String?;
                    ImageProvider? avatarImage;
                    if (photoBase64 != null && photoBase64.isNotEmpty) {
                      try {
                        avatarImage =
                            MemoryImage(base64Decode(photoBase64));
                      } catch (_) {
                        avatarImage = null;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Text(
                            (displayName ?? email)[0].toUpperCase(),
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                              : null,
                        ),
                        title: Text(
                          displayName ?? email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // Si hay displayName, mostramos email como subtítulo
                        subtitle: displayName != null
                            ? Text(email, style: TextStyle(color: onSurface.withOpacity(0.8)))
                            : null,
                        onTap: () => _createChatOrOpen(user['uid'], email),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
