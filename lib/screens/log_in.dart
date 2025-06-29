import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:staff_service_management/screens/auth.dart';
import 'package:staff_service_management/constants/color.dart';
import 'package:staff_service_management/screens/main_screen.dart';
import 'package:staff_service_management/screens/sign_up.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errMsg;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    try {
      await Auth().signIn(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errMsg = e.message;
      });
    }
  }

  void showMessage(String message, bool auth) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: auth ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/background_light.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white, // arka plan rengi
                borderRadius: BorderRadius.circular(20), // köşeleri yumuşatma
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Mail Adresi",
                    style: GoogleFonts.antonio(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: HexColor(textFieldBG),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'mail@gmail.com',
                      hintStyle: GoogleFonts.nunito(
                        textStyle: TextStyle(fontSize: 13),
                      ),
                      prefixIcon: Icon(Icons.mail),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Şifre",
                    style: GoogleFonts.antonio(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: HexColor(textFieldBG),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Şifrenizi girin',
                      hintStyle: GoogleFonts.nunito(
                        textStyle: TextStyle(fontSize: 13),
                      ),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Builder(
                    builder:
                        (context) => ElevatedButton(
                          onPressed: () async {
                            await signIn();
                            if (errMsg != null) {
                              showMessage(errMsg!, false);
                              return;
                            } else {
                              showMessage("Giriş başarılı", true);
                            }
                            if (Auth().currentUser != null) {
                              // Buraya başka bir doğrulama konmalı. Problemler var
                              print(
                                "Current User bu: ${Auth().currentUser!.email}",
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(),
                                ),
                              );
                            }

                            // errMsg = null;
                          },
                          child: Text(
                            "Giriş Yap",
                            style: GoogleFonts.antonio(
                              color: Colors.black,
                              textStyle: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
