import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AppFirebase {
  AppFirebase();

  Map<String, dynamic>? currentUserInfo;

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

  Future<void> deleteUserInfo() async {
    User? user = getCurrentUser();
    if(user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).delete();
    }
  }

  bool isLogged() {
    User? user = getCurrentUser();
    return user != null;
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception("Error during anonymous sign out: $e");
    }
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      User? user = getCurrentUser();
      if (user != null) {
        if (currentUserInfo == null) {
          DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();
          currentUserInfo = snapshot.data() as Map<String, dynamic>;
        }
        return currentUserInfo;
      }
      return null;
    } catch (e) {
      throw Exception("Error getting Display Name: $e");
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      List<dynamic> users = [];
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection("users").get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> document
          in querySnapshot.docs) {
        Map<String, dynamic> data = document.data();
        users.add(data);
      }
      return users;
    } catch (e) {
      throw Exception("Error getting users list: $e");
    }
  }


  Future<void> cleanUp() async {
    currentUserInfo = null;
  }
}
