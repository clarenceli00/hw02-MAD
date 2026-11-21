import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String newMessageId() => _db.collection('messages').doc().id;

  /// CREATE — uid-owned, server-timestamped
  Future<void> postMessage({
    required String messageId,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    if (text.trim().isEmpty) throw ArgumentError('Message cannot be empty.');
    final reference = _db.collection('messages').doc(messageId);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        if (existing.data()?['authorUid'] != authorUid ||
            existing.data()?['text'] != text.trim()) {
          throw StateError('This message ID belongs to a different post.');
        }
        return;
      }
      transaction.set(reference, {
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// READ (live) — the board renders from this stream
  Stream<List<Message>> messageBoard() {
    return _db
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            String field(String key) =>
                data[key] is String ? data[key] as String : '';
            DateTime? date(String key) => data[key] is Timestamp
                ? (data[key] as Timestamp).toDate()
                : null;
            return Message(
              id: doc.id,
              text: field('text'),
              authorUid: field('authorUid'),
              authorName: field('authorName'),
              createdAt: date('createdAt'),
              editedAt: date('editedAt'),
            );
          }).toList(),
        );
  }

  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    await _db.collection('messages').doc(messageId).update({
      'text': newText.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage({required String messageId}) async {
    await _db.collection('messages').doc(messageId).delete();
  }
}
