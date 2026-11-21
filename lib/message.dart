class Message {
  const Message({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
  });
  final String id, text, authorUid, authorName;
  final DateTime? createdAt, editedAt;
}
