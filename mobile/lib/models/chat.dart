import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    required this.type,
    required this.memberIds,
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdBy,
    required this.companyId,
    this.pinned = false,
  });

  final String id;
  final String type;
  final List<String> memberIds;
  final String name;
  final String photoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String createdBy;
  final String companyId;
  final bool pinned;

  bool get isGroup => type == 'group';

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatThread(
      id: doc.id,
      type: data['type'] as String? ?? 'direct',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      pinned: data['pinned'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.createdAt,
    this.replyTo,
    this.editedAt,
    this.deleted = false,
    this.readBy = const [],
  });

  final String id;
  final String senderId;
  final String type;
  final String text;
  final String mediaUrl;
  final DateTime createdAt;
  final String? replyTo;
  final DateTime? editedAt;
  final bool deleted;
  final List<String> readBy;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      text: data['text'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyTo: data['replyTo'] as String?,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      deleted: data['deleted'] as bool? ?? false,
      readBy: List<String>.from(data['readBy'] ?? const []),
    );
  }
}
