import 'package:educonnect/firebase_options.dart';
import 'package:educonnect/screen/DashboardPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'screen/home_screen.dart';
import 'user_authentication/login_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);
  // Sólo inicializo con options en Web.
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // En Android/iOS basta con esto:
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'EduConnect',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Escucha los cambios de estado de autenticación
      builder: (context, snapshot) {
        // 1. Mientras espera conexión con Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Si ocurre un error al conectarse a Firebase
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Ocurrió un error. Intenta más tarde.')),
          );
        }

        // 3. Si el usuario está autenticado, mostrar la pantalla principal
        if (snapshot.hasData && snapshot.data != null) {
          return DashboardPage(currentTab: 0);
        }

        // 4. Si el usuario NO está autenticado, mostrar la pantalla de login
        return LoginScreen();
      },
    );
  }
}