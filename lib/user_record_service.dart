import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRecordService {
  Future<void> saveUserRecord(
    User user, {
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role.trim(),
      'registrationDateTime': FieldValue.serverTimestamp(),
    });
  }
}
