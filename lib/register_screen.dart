import 'package:educonnect/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget{

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>{
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  Future<void> _register() async{
    if(_passwordController.text == _confirmPasswordController.text){
      try{
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim()
        );
        print('SUCCESFUL REGISTRATION');
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } on FirebaseAuthException catch(e) {
        print('Error: ${e.code} - ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}'))
        );
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: La contraseña no coincide con confirmar contraseña.', style: TextStyle(color: Colors.red)))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar cuenta'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
                'assets/logo_educonnect.png',
                height: 250),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: _register, child: Text('Registrarse'))
          ],
        ),
      ),
    );
  }
  
}