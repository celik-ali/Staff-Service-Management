import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:staff_service_management/constants/color.dart';
import 'package:staff_service_management/model/user_model.dart';
import 'package:staff_service_management/screens/auth.dart';
import 'package:staff_service_management/services/user_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserServices _userServices = UserServices();
  UserModel? _user;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final currentUser = Auth().currentUser;
    if (currentUser != null) {
      UserModel? user = await _userServices.getUserDB(currentUser.uid);
      if (user != null) {
        setState(() {
          _user = user;
          _nameController = TextEditingController(text: user.name);
          _emailController = TextEditingController(text: user.email);
          _phoneController = TextEditingController(text: user.phone);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate() && _user != null) {
      UserModel updatedUser = UserModel(
        id: _user!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        services: _user!.services,
      );
      await _userServices.addUserDB(updatedUser);
      setState(() => _user = updatedUser);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bilgiler güncellendi.')));
    }
  }

  Future<void> _deleteAccount() async {
    final currentUser = Auth().currentUser;
    if (currentUser != null) {
      await _userServices.firestore
          .collection('drivers')
          .doc(currentUser.uid)
          .delete();
      await Auth().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profilim'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Hesabı Sil'),
                        content: const Text(
                          'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                        ),
                        actions: [
                          TextButton(
                            child: const Text('İptal'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('Sil'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await _deleteAccount();
                }
              },
            ),
          ],
        ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildLabel("Ad Soyad"),
                      buildTextFormField(
                        _nameController,
                        "John Doe",
                        Icons.person,
                      ),
                      const SizedBox(height: 15),

                      buildLabel("E-posta"),
                      buildTextFormField(
                        _emailController,
                        "mail@gmail.com",
                        Icons.mail,
                        inputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),

                      buildLabel("Telefon Numarası"),
                      buildTextFormField(
                        _phoneController,
                        "5XXXXXXXXX",
                        Icons.phone,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: _updateUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Bilgileri Güncelle",
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
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.antonio(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget buildTextFormField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Bu alan zorunludur' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: HexColor(textFieldBG),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: hint,
        hintStyle: GoogleFonts.nunito(textStyle: const TextStyle(fontSize: 13)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
