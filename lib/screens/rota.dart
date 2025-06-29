import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:staff_service_management/constants/api.dart';
import 'main_screen.dart';
import 'package:geolocator/geolocator.dart';

class Rota extends StatefulWidget {
  final String selectedServiceId;
  final String selectedServiceName;

  const Rota({
    super.key,
    required this.selectedServiceId,
    required this.selectedServiceName,
  });

  @override
  State<Rota> createState() => _RotaState();
}

class _RotaState extends State<Rota> {
  final PageController _pageController = PageController();
  List<Map<String, LatLng>> rotalar = [];
  List<Map<String, String>> yolcular = [];
  bool loading = true;
  Map<String, dynamic>? telegramData;
  List<String> durakNumaralari = [];
  LatLng? currentPosition;
  Map<String, int> durakYolcuSayisi = {};
  StreamSubscription<Position>? _positionStream;
  bool takipModu = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    listenToRotaVeYolcuVerisi();
    startLocationTracking();
  }

  @override
  void dispose() {
    _dailyRouteSub?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied)
        return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  StreamSubscription<DocumentSnapshot>? _dailyRouteSub;

  void listenToRotaVeYolcuVerisi() {
    final firestore = FirebaseFirestore.instance;
    final serviceId = widget.selectedServiceId;

    final tarih = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _dailyRouteSub = firestore
        .collection("dailyRoutes")
        .doc(serviceId)
        .snapshots()
        .listen((dailyRouteDoc) async {
          final dailyData = dailyRouteDoc.data();
          if (dailyData == null || !dailyData.containsKey(tarih)) {
            setState(() {
              rotalar = [];
              yolcular = [];
              loading = false;
            });
            return;
          }

          final Map<String, dynamic> duraklar = dailyData[tarih];
          durakNumaralari =
              duraklar.keys.toList()
                ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

          final telegramDoc =
              await firestore.collection("TelegramGroups").doc(serviceId).get();
          telegramData = telegramDoc.data();

          List<Map<String, LatLng>> rotaList = [];
          for (int i = 0; i < durakNumaralari.length - 1; i++) {
            final start = _stringToLatLng(
              telegramData!["stations"][durakNumaralari[i]]['stationLocation'],
            );
            final end = _stringToLatLng(
              telegramData!["stations"][durakNumaralari[i +
                  1]]['stationLocation'],
            );
            rotaList.add({"start": start, "end": end});
          }

          List<Map<String, String>> yolcuList = [];
          durakYolcuSayisi.clear();
          for (final entry in duraklar.entries) {
            final durakNo = entry.key;
            final stationName =
                telegramData!["stations"][durakNo]['stationName'] ??
                'Bilinmeyen';
            final List yolcularDuraktan = entry.value;
            durakYolcuSayisi[durakNo] = yolcularDuraktan.length;
            for (var isim in yolcularDuraktan) {
              yolcuList.add({"isim": isim.toString(), "durak": stationName});
            }
          }

          setState(() {
            rotalar = rotaList;
            yolcular = yolcuList;
            loading = false;
          });
        });
  }

  LatLng _stringToLatLng(String loc) {
    final parts = loc.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  Future<List<LatLng>> getPolyline(LatLng start, LatLng end) async {
    PolylinePoints polyPoints = PolylinePoints();
    List<LatLng> points = [];

    PolylineResult result = await polyPoints.getRouteBetweenCoordinates(
      googleApiKey: googlemApiKeyM,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      points =
          result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
    }

    return points;
  }

  Future<void> bindiKaydet(int index) async {
    final firestore = FirebaseFirestore.instance;
    final yolcu = yolcular[index];
    final serviceId = widget.selectedServiceId;

    final bindiRef = firestore.collection('yoklama').doc(serviceId);

    try {
      final snapshot = await bindiRef.get();
      List<dynamic> existingList = [];

      if (snapshot.exists && snapshot.data()!.containsKey('bindi')) {
        existingList = List.from(snapshot.data()!['bindi']);
      }

      final yeniKayit = {"name": yolcu['isim'], "station": yolcu['durak']};

      existingList.add(yeniKayit);

      await bindiRef.set({'bindi': existingList}, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Yolcu kaydedildi.")));
    } catch (e) {
      print("Bindi kaydetme hatası: $e");
    }
  }

  Widget rotaHarita(int index) {
    LatLng start = rotalar[index]["start"]!;
    LatLng end = rotalar[index]["end"]!;
    final startName =
        telegramData!["stations"]?[durakNumaralari[index]]?['stationName'] ??
        "Başlangıç";
    final endName =
        telegramData!["stations"]?[durakNumaralari[index +
            1]]?['stationName'] ??
        "Bitiş";

    return FutureBuilder<List<LatLng>>(
      future: getPolyline(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: start, zoom: 14.5),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (_) {
                if (takipModu) {
                  setState(() {
                    takipModu = false;
                  });
                }
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: snapshot.data!,
                  color: Colors.blue,
                  width: 5,
                ),
              },
              markers: {
                Marker(markerId: const MarkerId("start"), position: start),
                Marker(markerId: const MarkerId("end"), position: end),
                if (currentPosition != null)
                  Marker(
                    markerId: const MarkerId("current"),
                    position: currentPosition!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: "Benim Konumum"),
                  ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$startName (${durakYolcuSayisi[durakNumaralari[index]] ?? 0}) - "
                  "$endName (${durakYolcuSayisi[durakNumaralari[index + 1]] ?? 0})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(bottom: 10, left: 10, right: 10, child: butonlar(index)),
            Positioned(
              top: 60,
              right: 10,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: takipModu ? Colors.blue : Colors.grey,
                onPressed: () {
                  if (currentPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(currentPosition!),
                    );
                  }
                  setState(() {
                    takipModu = true;
                  });
                },
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget butonlar(int index) {
    bool isFirst = index == 0;
    bool isLast = index == rotalar.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed:
              isFirst
                  ? null
                  : () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
          icon: const Icon(Icons.arrow_back),
          label: const Text("Önceki", style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(iconColor: Colors.black),
        ),
        isLast
            ? ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text(
                "Ana Sayfa",
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(iconColor: Colors.black),
            )
            : ElevatedButton.icon(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                "Sonraki",
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(iconColor: Colors.black),
            ),
      ],
    );
  }

  void _showOnayDialog(BuildContext context, int index, bool isBindi) {
    final yolcu = yolcular[index];
    final mesaj =
        'Yolcu ${isBindi ? "Bindi" : "Binmedi"} olarak kaydedilecek. Emin misiniz?';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Onay"),
            content: Text(mesaj),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Hayır"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Dialog kapat
                  await _yolcuDurumuKaydet(index, isBindi);
                },
                child: const Text("Evet"),
              ),
            ],
          ),
    );
  }

  Future<void> _yolcuDurumuKaydet(int index, bool isBindi) async {
    final firestore = FirebaseFirestore.instance;
    final yolcu = yolcular[index];
    final serviceId = widget.selectedServiceId;

    final now = DateTime.now();
    final tarih = DateFormat('yyyy-MM-dd').format(now);
    final saatDakika = DateFormat('HH:mm').format(now);

    final field = isBindi ? 'bindi' : 'binmedi';
    final ref = firestore.collection('yoklama').doc(serviceId);

    try {
      final snapshot = await ref.get();
      Map<String, dynamic> data = {};

      if (snapshot.exists) {
        data = snapshot.data() ?? {};
      }

      // Günlük kayıt al
      Map<String, dynamic> dailyData = {};
      if (data.containsKey(tarih)) {
        dailyData = Map<String, dynamic>.from(data[tarih]);
      }

      // Eski array'i al ya da boş başlat
      List<dynamic> list = dailyData[field] ?? [];

      // Yeni kayıt bilgisi
      final yeniKayit = {
        "name": yolcu['isim'],
        "station": yolcu['durak'],
        "time": saatDakika,
      };

      list.add(yeniKayit);

      // Günlük kaydın ilgili field'ını güncelle
      dailyData[field] = list;

      // Tüm dokümanı güncelle
      await ref.set({tarih: dailyData}, SetOptions(merge: true));

      // UI güncelle
      setState(() {
        yolcular[index]["status"] = isBindi ? "bindi" : "binmedi";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Yolcu ${isBindi ? 'bindi' : 'binmedi'} olarak kaydedildi.",
          ),
        ),
      );
    } catch (e) {
      print("Firestore kayıt hatası: $e");
    }
  }

  Widget yolcuListesi() {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (yolcular.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Yolcu bulunamadı."),
      );
    }

    return ListView.builder(
      itemCount: yolcular.length,
      itemBuilder: (context, index) {
        final yolcu = yolcular[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yolcu bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yolcu['isim'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        yolcu['durak'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (yolcu.containsKey("status"))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Yolcu ${yolcu['status']}",
                            style: TextStyle(
                              color:
                                  yolcu['status'] == "bindi"
                                      ? Colors.green[800]
                                      : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Butonlar (eğer kayıt yapılmamışsa göster)
                if (!yolcu.containsKey("status"))
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                        ),
                        onPressed: () {
                          _showOnayDialog(context, index, true); // bindi
                        },
                        child: const Text(
                          "Bindi",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[300],
                        ),
                        onPressed: () {
                          _showOnayDialog(context, index, false); // binmedi
                        },
                        child: const Text(
                          "Binmedi",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        currentPosition = newPosition;
      });

      if (takipModu && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text("Rotalar")),
      body: Column(
        children: [
          SizedBox(
            height: height * 0.45,
            child:
                rotalar.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                      controller: _pageController,
                      itemCount: rotalar.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return rotaHarita(index);
                      },
                    ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Yolcular",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: yolcuListesi()),
        ],
      ),
    );
  }
}
