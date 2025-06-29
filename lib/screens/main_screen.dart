import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:staff_service_management/screens/aractaki_yolcular.dart';
import 'package:staff_service_management/screens/auth.dart';
import 'package:staff_service_management/constants/color.dart';
import 'package:staff_service_management/main.dart';
import 'package:staff_service_management/screens/profile.dart';
import 'package:staff_service_management/screens/rota.dart';
import 'package:staff_service_management/screens/seyahat_ozeti.dart';
import 'package:staff_service_management/services/user_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void showServiceBottomSheet(BuildContext context) {
    final TextEditingController serviceIdController = TextEditingController();
    final currentUser = Auth().currentUser;
    final firestore = FirebaseFirestore.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyeye göre ayarlanabilmesi için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(
                  context,
                ).viewInsets.bottom, // Klavye alanı kadar boşluk
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Servis Ekle / Sil",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: serviceIdController,
                decoration: const InputDecoration(
                  labelText: "Servis ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final serviceId = serviceIdController.text.trim();
                      if (serviceId.isEmpty || currentUser == null) return;

                      final doc =
                          await firestore
                              .collection('TelegramGroups')
                              .doc(serviceId)
                              .get();

                      if (doc.exists) {
                        await firestore
                            .collection('drivers')
                            .doc(currentUser.uid)
                            .update({
                              'services': FieldValue.arrayUnion([serviceId]),
                            });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Servis başarıyla eklendi."),
                          ),
                        );
                        _loadUserData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Servis ID bulunamadı."),
                          ),
                        );
                      }
                    },
                    child: const Text("Ekle"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final serviceId = serviceIdController.text.trim();
                      if (serviceId.isEmpty || currentUser == null) return;

                      await firestore
                          .collection('drivers')
                          .doc(currentUser.uid)
                          .update({
                            'services': FieldValue.arrayRemove([serviceId]),
                          });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Servis başarıyla silindi."),
                        ),
                      );
                      _loadUserData();
                    },
                    child: const Text("Sil"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String selectedServiceId = '';
  String userName = "User";
  Map<String, String> serviceIdToName = {}; // {id: groupName}
  final UserServices _userServices = UserServices();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<Map<String, String>> fetchServiceNames(List<String> serviceIds) async {
    Map<String, String> result = {};
    var futures = serviceIds.map((id) async {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('TelegramGroups')
              .doc(id)
              .get();
      if (doc.exists) {
        String name = doc.get('groupName');
        result[id] = name;
      }
    });
    await Future.wait(futures);
    return result;
  }

  Future<void> _loadUserData() async {
    final currentUser = Auth().currentUser;
    if (currentUser != null) {
      try {
        final userData = await _userServices.getUserDB(currentUser.uid);
        if (userData != null) {
          Map<String, String> nameMap = await fetchServiceNames(
            userData.services,
          );

          setState(() {
            userName = userData.name;
            serviceIdToName = nameMap;
            selectedServiceId =
                nameMap.keys.isNotEmpty ? nameMap.keys.first : '';
            print("Seçilen servis ID: $selectedServiceId");
            print("Seçilen servis adı: ${serviceIdToName[selectedServiceId]}");
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    print("Device Width: $deviceWidth, Device Height: $deviceHeight");
    double buttonHeight = deviceHeight * 0.2;
    double buttonWidth = deviceWidth * 0.78;

    List<DropdownMenuItem<String>> dropdownItems =
        serviceIdToName.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            )
            .toList();

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
              width: deviceWidth - (deviceWidth % 5),
              height: deviceHeight,
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.fromLTRB(25, 40, 25, 20),
              decoration: BoxDecoration(
                color: HexColor(columnBG),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Flex(
                direction: Axis.vertical,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Servis:",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              iconSize: buttonWidth / 10,
                              dropdownColor: HexColor(columnBG),
                              value:
                                  selectedServiceId.isNotEmpty
                                      ? selectedServiceId
                                      : null,
                              items: dropdownItems,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                              hint: const Text(
                                "Servis Seç",
                                style: TextStyle(color: Colors.black),
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedServiceId = newValue!;

                                  print(
                                    "Seçilen servis ID: $selectedServiceId",
                                  );
                                  print(
                                    "Seçilen servis adı: ${serviceIdToName[selectedServiceId]}",
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            fixedSize: Size(buttonWidth, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => Rota(
                                      selectedServiceId: selectedServiceId,
                                      selectedServiceName:
                                          serviceIdToName[selectedServiceId] ??
                                          "",
                                    ),
                              ),
                            );
                            print("Map is pressed");
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "Rota",
                                style: GoogleFonts.antonio(
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.route_outlined,
                                size: buttonHeight / 2,
                                color: HexColor("#555555"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            fixedSize: Size(buttonWidth, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => AractakiYolcular(
                                      serviceID: selectedServiceId,
                                      serviceName:
                                          serviceIdToName[selectedServiceId] ??
                                          "",
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "Araçtaki Yolcular",
                                style: GoogleFonts.antonio(
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.airline_seat_recline_normal,
                                    size: buttonWidth / 5,
                                    color: Color(0xFF555555),
                                  ),
                                  Icon(
                                    Icons.airline_seat_recline_normal,
                                    size: buttonWidth / 5,
                                    color: Color(0xFF555555),
                                  ),
                                  Icon(
                                    Icons.airline_seat_recline_normal,
                                    size: buttonWidth / 5,
                                    color: Color(0xFF555555),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            fixedSize: Size(buttonWidth, buttonHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SeyahatOzetiScreen(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "Seyahat Özeti",
                                style: GoogleFonts.antonio(
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.pending_actions_outlined,
                                size: buttonHeight / 2,
                                color: HexColor("#555555"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: HexColor(columnBG),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade700,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Servis Ekle sayfasına git (henüz tanımlı değilse geçici olarak print)
                  print("Servis Ekle butonuna tıklandı");
                  showServiceBottomSheet(context);
                  break;
                case 1:
                  // Çıkış işlemi
                  Auth().signOut();
                  print("Çıkış yapıldı");
                  break;
                case 2:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                  print("Profil butonuna tıklandı");
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: 'Servis Ekle/Sil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Çıkış Yap',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: userName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
