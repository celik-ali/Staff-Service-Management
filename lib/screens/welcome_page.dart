import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:staff_service_management/screens/log_in.dart';
import 'package:staff_service_management/screens/sign_up.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
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
            backgroundColor: const Color.fromARGB(0, 184, 24, 24),
            body: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 0, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // Hoşgeldiniz
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Hoşgeldiniz",
                      style: GoogleFonts.antonio(
                        textStyle: TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    // Kayıt Olun
                    padding: EdgeInsets.only(bottom: 10),
                    child: Builder(
                      builder:
                          (context) => ElevatedButton(
                            onPressed:
                                () => {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SignUp(),
                                    ),
                                  ),
                                },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Kayıt Olun",
                                style: GoogleFonts.antonio(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  Padding(
                    //Hesabınız var mı? Giriş yapın
                    padding: EdgeInsets.only(bottom: 10),
                    child: Builder(
                      builder:
                          (context) => ElevatedButton(
                            onPressed:
                                () => {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LogIn(),
                                    ),
                                  ),
                                },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Hesabınız var mı? Giriş yapın",
                                style: GoogleFonts.antonio(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
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
