import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:staff_service_management/constants/color.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeyahatOzetiScreen extends StatefulWidget {
  const SeyahatOzetiScreen({super.key});

  @override
  State<SeyahatOzetiScreen> createState() => _SeyahatOzetiScreenState();
}

class _SeyahatOzetiScreenState extends State<SeyahatOzetiScreen> {
  String? selectedGroupId;
  String? selectedGroupName;
  String? selectedDateFormatted;
  List<String> groupNames = [];
  Map<String, String> groupIdNameMap = {};
  List<Map<String, dynamic>> bindiList = [];
  List<Map<String, dynamic>> binmediList = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final driverDoc =
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();

    if (!driverDoc.exists) return;

    List<dynamic> serviceGroupIds = driverDoc.data()?['services'] ?? [];

    if (serviceGroupIds.isEmpty) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('TelegramGroups').get();

    setState(() {
      groupNames.clear();
      groupIdNameMap.clear();

      for (var doc in snapshot.docs) {
        if (serviceGroupIds.contains(doc.id)) {
          groupNames.add(doc['groupName']);
          groupIdNameMap[doc['groupName']] = doc.id;
        }
      }
    });
  }

  Future<void> fetchAttendance() async {
    if (selectedGroupId == null || selectedDateFormatted == null) return;

    print("Seçilen Grup: $selectedGroupName");
    print("Seçilen Tarih: $selectedDateFormatted");

    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('yoklama')
            .doc(selectedGroupId)
            .get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data()!;
      Map<String, dynamic>? tarihVerisi =
          data[selectedDateFormatted] as Map<String, dynamic>?;

      setState(() {
        bindiList = List<Map<String, dynamic>>.from(
          tarihVerisi?['bindi'] ?? [],
        );
        binmediList = List<Map<String, dynamic>>.from(
          tarihVerisi?['binmedi'] ?? [],
        );
      });
    } else {
      setState(() {
        bindiList = [];
        binmediList = [];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDateFormatted = DateFormat('yyyy-MM-dd').format(picked);
      });
      fetchAttendance();
    }
  }

  Widget buildPersonCard(
    Map<String, dynamic> person,
    Color iconColor,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          person['name'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Durak: ${person['station'] ?? '-'}"),
            Text("Zaman: ${person['time'] ?? '-'}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Seyahat Özeti")),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/background_light.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                  Text("Grup Seç", style: GoogleFonts.antonio(fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedGroupName,
                    items:
                        groupNames
                            .map(
                              (name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedGroupName = val;
                        selectedGroupId = groupIdNameMap[val]!;
                      });
                      fetchAttendance();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: HexColor(textFieldBG),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      selectedDateFormatted ?? "Tarih Seç",
                      style: GoogleFonts.antonio(),
                      selectionColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (selectedGroupId != null &&
                      selectedDateFormatted != null) ...[
                    Text(
                      "Binenler",
                      style: GoogleFonts.antonio(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...bindiList
                        .map(
                          (person) => buildPersonCard(
                            person,
                            Colors.green,
                            Icons.check_circle,
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 16),
                    Text(
                      "Binmeyenler",
                      style: GoogleFonts.antonio(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...binmediList
                        .map(
                          (person) =>
                              buildPersonCard(person, Colors.red, Icons.cancel),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
