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
    this.pinnedMessageId = '',
    this.disappearingHours = 0,
    this.typingUid = '',
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
  final String pinnedMessageId;
  final int disappearingHours;
  final String typingUid;

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
      pinnedMessageId: data['pinnedMessageId'] as String? ?? '',
      disappearingHours: (data['disappearingHours'] as num?)?.toInt() ?? 0,
      typingUid: data['typingUid'] as String? ?? '',
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
    this.starredBy = const [],
    this.reactions = const {},
    this.latitude,
    this.longitude,
    this.expiresAt,
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
  final List<String> starredBy;
  final Map<String, String> reactions;
  final double? latitude;
  final double? longitude;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final reactionRaw = data['reactions'];
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
      starredBy: List<String>.from(data['starredBy'] ?? const []),
      reactions: reactionRaw is Map
          ? reactionRaw.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const {},
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
