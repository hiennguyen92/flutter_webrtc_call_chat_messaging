import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AppFirebase {
  AppFirebase();

  Future<void> signInAnonymously(String displayName) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      print("Signed in as: ${userCredential.user!.uid}");
      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({"displayName": displayName, "uuid": const Uuid().v4()});
      }
    } catch (e) {
      throw Exception("Error during anonymous sign in: $e");
    }
  }

  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      User? user = await getCurrentUser();
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data;
      }
      return {};
    } catch (e) {
      throw Exception("Error getting Display Name: $e");
    }
  }

  Future<List<dynamic>> getUsersList() async {
    try {
      List<dynamic> users = [];
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance.collection("users").get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> document in querySnapshot.docs) {
        Map<String, dynamic> data = document.data();
        users.add(data);
      }
      return users;
    } catch (e) {
      throw Exception("Error getting users list: $e");
    }
  }
}
