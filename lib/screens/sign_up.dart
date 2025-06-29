import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:staff_service_management/constants/color.dart';
import 'package:staff_service_management/model/user_model.dart';
import 'package:staff_service_management/screens/welcome_page.dart';
import 'package:staff_service_management/services/user_services.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  final userServices = UserServices();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> showErrorDialog(String message) async {
    if (!mounted) return; // mounted kontrolü eklendi

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hata"),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("Tamam"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  Future<void> createUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      await showErrorDialog("Şifreler eşleşmiyor.");
      return;
    }

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      await showErrorDialog("Tüm alanları doldurun.");
      return;
    }

    if (!mounted) return; // işlem başlamadan önce kontrol
    setState(() => isLoading = true);

    try {
      final userCred = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userModel = UserModel(
        id: userCred.user!.uid,
        email: emailController.text.trim(),
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        services: [],
      );

      await userServices.addUserDB(userModel);

      // Başarılı kayıt sonrası navigation
      if (mounted) {
        setState(() => isLoading = false);

        // AuthWrapper'ı bypass ederek direkt WelcomePage'e git
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false, // Tüm önceki route'ları temizle
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        await showErrorDialog(e.message ?? "Bir hata oluştu.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        await showErrorDialog("Beklenmeyen bir hata oluştu.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/assets/images/background_light.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 0.5,
                      offset: Offset(-10, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildLabel("Mail Adresi"),
                    buildTextField(
                      emailController,
                      "mail@gmail.com",
                      Icons.mail,
                    ),
                    const SizedBox(height: 15),

                    buildLabel("Ad Soyad"),
                    buildTextField(nameController, "John Doe", Icons.person),
                    const SizedBox(height: 15),

                    buildLabel("Telefon Numarası"),
                    buildTextField(phoneController, "5XXXXXXXXX", Icons.phone),
                    const SizedBox(height: 15),

                    buildLabel("Şifre"),
                    buildTextField(
                      passwordController,
                      "••••••••",
                      Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 15),

                    buildLabel("Şifre (Tekrar)"),
                    buildTextField(
                      confirmPasswordController,
                      "••••••••",
                      Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: isLoading ? null : createUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                              : Text(
                                "Kayıt Ol",
                                style: GoogleFonts.antonio(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.antonio(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: HexColor(textFieldBG),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: hint,

        hintStyle: GoogleFonts.nunito(textStyle: TextStyle(fontSize: 13)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
