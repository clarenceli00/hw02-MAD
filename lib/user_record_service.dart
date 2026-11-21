import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRecord {
  const UserRecord({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.registeredAt,
  });
  final String uid, firstName, lastName, role;
  final DateTime? registeredAt;
  String get fullName => '$firstName $lastName';
  bool get isComplete =>
      [uid, firstName, lastName, role].every((s) => s.trim().isNotEmpty) &&
      registeredAt != null;
}

class UserRecordService {
  Future<UserRecord?> getUserRecord(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null) return null;
    String field(String key) => data[key] is String ? data[key] as String : '';
    return UserRecord(
      uid: field('uid'),
      firstName: field('firstName'),
      lastName: field('lastName'),
      role: field('role'),
      registeredAt: data['registrationDateTime'] is Timestamp
          ? (data['registrationDateTime'] as Timestamp).toDate()
          : null,
    );
  }

  Future<void> saveUserRecord(
    User user, {
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      transaction.set(reference, {
        'uid': user.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'role': role.trim(),
        'registrationDateTime':
            existing.data()?['registrationDateTime'] is Timestamp
            ? existing.data()!['registrationDateTime']
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
