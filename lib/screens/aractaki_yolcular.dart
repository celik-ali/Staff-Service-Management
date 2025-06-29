import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AractakiYolcular extends StatefulWidget {
  final String serviceID;
  final String serviceName;

  const AractakiYolcular({
    Key? key,
    required this.serviceID,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<AractakiYolcular> createState() => _AractakiYolcularState();
}

class _AractakiYolcularState extends State<AractakiYolcular> {
  late Future<List<Map<String, dynamic>>> _yolcularFuture;

  @override
  void initState() {
    super.initState();
    _yolcularFuture = _fetchYolcular();
  }

  Future<List<Map<String, dynamic>>> _fetchYolcular() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('yoklama')
            .doc(widget.serviceID)
            .get();

    if (snapshot.exists && snapshot.data()!.containsKey(today)) {
      List<dynamic> bindiList = snapshot.data()![today]['bindi'];
      return List<Map<String, dynamic>>.from(bindiList);
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.serviceName),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/background_light.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight + 24),
          child: Center(
            child: Container(
              width: deviceWidth * 0.9,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _yolcularFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  }

                  List<Map<String, dynamic>> yolcular = snapshot.data ?? [];

                  if (yolcular.isEmpty) {
                    return const Center(
                      child: Text('Araçta yolcu bulunmamaktadır.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Araçtaki Yolcular (${yolcular.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero, // boşlukları kaldır
                          itemCount: yolcular.length,
                          itemBuilder: (context, index) {
                            final yolcu = yolcular[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundImage: AssetImage(
                                    'lib/assets/images/profile.png',
                                  ),
                                  radius: 24,
                                ),
                                title: Text(
                                  yolcu['name'] ?? 'İsimsiz',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${yolcu['station'] ?? 'Durak'} ${yolcu['time'] ?? ''}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
