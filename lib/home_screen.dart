import 'package:educonnect/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget{
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EduConnect'),),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Image.asset(
                'assets/logo_educonnect.png',
                height: 250),
            Text('Bienvenido a EduConnect'),
            TextButton(onPressed: () => signOut(context), child: Text('Salir de la sesión', style: TextStyle(color: Colors.blue),))
          ],


        ),
      ),
    );
  }
}