import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'BottomNavbar.dart';
import 'ChatsScreen.dart';
import 'FavoriteScreen.dart';
import 'TaskScreen.dart';
import 'home_screen.dart';

class DashboardPage extends StatefulWidget {
  int currentTab;
  int? indexSelectTab;
  Widget currentPage = HomeScreen();

  DashboardPage({super.key, required this.currentTab, this.indexSelectTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this, initialIndex: widget.indexSelectTab ?? widget.currentTab);
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
              appBar: AppBar(
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Text('EduConnect', style: TextStyle(color: Colors.white)),
              ),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                      child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                    ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Configuración'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Cerrar sesión'),
                      onTap: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sesión cerrada correctamente.')),
                          );
                        }catch(e){
                          print ("Error al cerrar la sesión.");
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
                    FavoriteScreen(),
                    ChatsScreen(),
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
        label: Text("Inicio",
          style: TextStyle(
            fontSize: 12,
          ),),
        color: Colors.white,
      ),
      MenuIcon(
        icon: Icon(Icons.chat_sharp),
        label: Text("Chats",
          style: TextStyle(
            fontSize: 12,
          ),),
        color: Colors.white,
      ),
      MenuIcon(
        icon: Icon(Icons.favorite_border),
        label: Text("Favoritos",
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        color: Colors.white,

      ),
      MenuIcon(
        icon: Icon(Icons.task),
        label: Text("Tareas",
          style: TextStyle(
            fontSize: 12,
          ),),
        color: Colors.white,
      ),
    ];
  }
}
