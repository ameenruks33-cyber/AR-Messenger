import 'package:cloud_firestore/cloud_firestore.dart';

class StatusPost {
  const StatusPost({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.text,
    required this.createdAt,
    required this.expiresAt,
    this.companyOnly = false,
  });

  final String id;
  final String userId;
  final String displayName;
  final String photoUrl;
  final String text;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool companyOnly;

  factory StatusPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StatusPost(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      companyOnly: data['companyOnly'] as bool? ?? false,
    );
  }
}
