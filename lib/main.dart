import 'package:flutter/material.dart';
import 'package:staff_service_management/screens/main_screen.dart';
import 'package:staff_service_management/screens/sign_up.dart';
import 'package:staff_service_management/screens/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthWrapper());
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Kullanıcı yeni kayıt olmuşsa WelcomePage göster
          // Aksi halde MainScreen'e git
          return FutureBuilder<bool>(
            future: _isNewUser(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (futureSnapshot.data == true) {
                return WelcomePage(); // Yeni kullanıcı
              } else {
                return MainScreen(); // Mevcut kullanıcı
              }
            },
          );
        } else {
          return WelcomePage(); // Giriş yoksa
        }
      },
    );
  }

  Future<bool> _isNewUser(User user) async {
    // Bu metodu kullanıcının yeni olup olmadığını kontrol etmek için kullanabilirsiniz
    // Örneğin: user.metadata.creationTime ile kontrol
    final now = DateTime.now();
    final creationTime = user.metadata.creationTime;
    if (creationTime != null) {
      return now.difference(creationTime).inMinutes <
          5; // Son 5 dakikada kayıt olmuşsa
    }
    return false;
  }
}
