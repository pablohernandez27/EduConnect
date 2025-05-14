import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';


class CreateChat extends StatefulWidget {
  @override
  _CreateChatState createState() => _CreateChatState();
}

class _CreateChatState extends State<CreateChat> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
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
        data['uid'] = doc.id; // Añadimos el ID del documento como 'uid'
        return data;
      }).toList();
    });
  }

  void _createChatOrOpen(String selectedUserId, String selectedUserEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (selectedUserId == currentUser.uid) {
      // Prevenir chats consigo mismo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No puedes iniciar un chat contigo mismo.')),
      );
      return;
    }

    final chatsRef = FirebaseFirestore.instance.collection('chats');

    final chatQuery = await chatsRef
        .where('users', arrayContains: currentUser.uid)
        .get();

    QueryDocumentSnapshot? existingChat;

    for (var doc in chatQuery.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(selectedUserId)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: existingChat!.id,
            receiverId: selectedUserId,
          ),
        ),
      );
    } else {
      final newChat = await chatsRef.add({
        'users': [currentUser.uid, selectedUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: newChat.id,
            receiverId: selectedUserId,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Añadir Chat')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Buscar por email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(child: Text('No hay resultados'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  title: Text(user['email'] ?? ''),
                  onTap: () {
                    _createChatOrOpen(user['uid'], user['email']);

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
