import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/screen/chat_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'BottomNavbar.dart';
import 'EditProfileScreen.dart';
import 'agenda_screen.dart';
import 'chat_screen.dart';
import 'task_screen.dart';
import 'home_screen.dart';
import '../services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  int currentTab;
  int? indexSelectTab;
  Widget currentPage = HomeScreen();
  String? idCurrentUser = FirebaseAuth.instance.currentUser?.uid;
  DashboardPage({super.key, required this.currentTab, this.indexSelectTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.indexSelectTab ?? widget.currentTab,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.blue,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.05),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              leading: Builder(
                builder:
                    (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/logoedu_solo.png",
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "EduConnect",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                          final doc = snapshot.data!;
                          final user = AppUser.fromFirestore(doc);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: user.photoBase64 != null
                                    ? MemoryImage(base64Decode(user.photoBase64!))
                                    : null,
                                child: user.photoBase64 == null
                                    ? Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              SizedBox(height: 10),
                              Text(user.displayName ?? 'Sin nombre',
                                  style: TextStyle(color: Colors.white, fontSize: 16)),
                              Text(user.email,
                                  style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          );
                        },
                      )


                  ),
                  ExpansionTile(
                    leading: Icon(Icons.settings),
                    title: Text('Configuración'),
                    children: [
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Editar perfil'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
                        },
                      ),
                      ExpansionTile(
                        leading: Icon(Icons.lock),
                        title: Text('Seguridad de la cuenta'),
                        children: [
                          ListTile(
                            leading: Icon(Icons.lock_reset),
                            title: Text('Restablecer contraseña'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirmar'),
                                  content: Text('¿Deseas enviar un correo para restablecer tu contraseña?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null && user.email != null) {
                                          try {
                                            await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Correo de restablecimiento enviado a ${user.email}')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: ${e.toString()}')),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('No se encontró el correo del usuario.')),
                                          );
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: Text('Enviar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete_forever, color: Colors.red),
                            title: Text('Eliminar cuenta'),
                            onTap: () async {
                              Navigator.pop(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('¿Eliminar cuenta?'),
                                  content: Text('Esta acción no se puede deshacer. ¿Estás seguro?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  final user = FirebaseAuth.instance.currentUser;

                                  if (user != null) {
                                    await deleteUserFirestoreData(user.uid);
                                    await user.delete();
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushReplacementNamed(context, '/login');

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cuenta eliminada')),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'requires-recent-login') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Por seguridad, vuelve a iniciar sesión para eliminar tu cuenta.')),
                                    );

                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushReplacementNamed(context, '/login');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al eliminar la cuenta: ${e.message}')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),


                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Cerrar sesión'),
                    onTap: () async {
                      bool? confirmLogout = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Cerrar sesión"),
                            content: Text(
                              "¿Estás seguro de que quieres cerrar sesión?",
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancelar'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: Text('Aceptar'),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmLogout == true) {
                        try {
                          await FirebaseAuth.instance.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sesión cerrada correctamente.'),
                            ),
                          );
                        } catch (e) {
                          print("Error al cerrar la sesión: $e");
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            body: BottomNavbar(
              index: widget.currentTab,
              tabController: tabController,
              unselectedColor: Colors.white,
              barColor: Theme.of(context).primaryColor,
              start: 10,
              end: 2,
              menu: menu(),
              child: TabBarView(
                controller: tabController,
                dragStartBehavior: DragStartBehavior.down,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  HomeScreen(),
                  ChatListScreen(),
                  AgendaScreen(),
                  TaskScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<MenuIcon> menu() {
    return [
      MenuIcon(
        icon: Icon(Icons.home),
        label: Text("Inicio", style: TextStyle(fontSize: 12)),
        color: Colors.white,
      ),
      MenuIcon(
        icon: Icon(Icons.chat_sharp),
        label: Text("Chats", style: TextStyle(fontSize: 12)),
        color: Colors.white,
      ),
      MenuIcon(
        icon: Icon(Icons.view_agenda),
        label: Text("Agenda", style: TextStyle(fontSize: 12)),
        color: Colors.white,
      ),
      MenuIcon(
        icon: Icon(Icons.task),
        label: Text("Tareas", style: TextStyle(fontSize: 12)),
        color: Colors.white,
      ),
    ];
  }
  Future<AppUser?> getUserFromFirestore(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }
  Future<void> deleteUserFirestoreData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // borrar colección "chats" donde participe el usuario
    final chatsSnapshot = await firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();

    for (var doc in chatsSnapshot.docs) {
      await doc.reference.delete();
    }

    final tareasSnapshot = await firestore
        .collection('tareas')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in tareasSnapshot.docs) {
      await doc.reference.delete();
    }

  }

}