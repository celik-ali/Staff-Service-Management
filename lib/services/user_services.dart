import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:staff_service_management/model/user_model.dart';

class UserServices {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> addUserDB(UserModel user) async {
    try {
      print(user.toJson());
      await firestore.collection('drivers').doc(user.id).set(user.toJson());
    } catch (e) {
      print("Error adding user to Firestore: $e");
      throw e;
    }
  }

  Future<UserModel?> getUserDB(String userId) async {
    DocumentSnapshot doc =
        await firestore.collection('drivers').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
