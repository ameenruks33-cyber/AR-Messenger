import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/chat.dart';

class ChatService {
  ChatService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection(Collections.chats);

  Stream<List<ChatThread>> watchChats() {
    return _chats.where('memberIds', arrayContains: _uid).snapshots().map((snap) {
      final chats = snap.docs.map(ChatThread.fromDoc).toList();
      chats.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return chats;
    });
  }

  Stream<ChatThread?> watchThread(String chatId) {
    return _chats.doc(chatId).snapshots().map((doc) => doc.exists ? ChatThread.fromDoc(doc) : null);
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection(Collections.messages)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).where((m) => !m.isExpired).toList());
  }

  Future<ChatThread?> byId(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return ChatThread.fromDoc(doc);
  }

  Future<String> openDirectChat(String otherUid) async {
    final members = [_uid, otherUid]..sort();
    final existing = await _chats
        .where('type', isEqualTo: 'direct')
        .where('memberIds', isEqualTo: members)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final doc = await _chats.add({
      'type': 'direct',
      'memberIds': members,
      'name': '',
      'photoUrl': '',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
      'companyId': '',
      'pinned': false,
      'pinnedMessageId': '',
      'disappearingHours': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String companyId = '',
  }) async {
    final members = {...memberIds, _uid}.toList();
    final doc = await _chats.add({
      'type': 'group',
      'memberIds': members,
      'name': name,
      'photoUrl': '',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
      'companyId': companyId,
      'pinned': false,
      'pinnedMessageId': '',
      'disappearingHours': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> sendMessage({
    required String chatId,
    required String type,
    String text = '',
    String mediaUrl = '',
    String? replyTo,
    double? latitude,
    double? longitude,
    int disappearingHours = 0,
  }) async {
    final chatRef = _chats.doc(chatId);
    final messageRef = chatRef.collection(Collections.messages).doc();
    final preview = switch (type) {
      'text' => text,
      'image' => 'Photo',
      'video' => 'Video',
      'audio' => 'Voice message',
      'file' => 'Document',
      'location' => 'Location',
      'live_location' => 'Live location',
      'contact' => 'Contact',
      _ => type,
    };
    final data = <String, dynamic>{
      'senderId': _uid,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'replyTo': replyTo,
      'deleted': false,
      'readBy': [_uid],
      'starredBy': <String>[],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (latitude != null && longitude != null) {
      data['latitude'] = latitude;
      data['longitude'] = longitude;
    }
    if (disappearingHours > 0) {
      data['expiresAt'] = Timestamp.fromDate(DateTime.now().add(Duration(hours: disappearingHours)));
    }
    final batch = _db.batch();
    batch.set(messageRef, data);
    batch.update(chatRef, {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> markRead(String chatId, String messageId) async {
    await _chats.doc(chatId).collection(Collections.messages).doc(messageId).update({
      'readBy': FieldValue.arrayUnion([_uid]),
    });
  }

  Future<void> editMessage({required String chatId, required String messageId, required String text}) {
    return _chats.doc(chatId).collection(Collections.messages).doc(messageId).update({
      'text': text,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage({required String chatId, required String messageId}) {
    return _chats.doc(chatId).collection(Collections.messages).doc(messageId).update({
      'deleted': true,
      'text': '',
      'mediaUrl': '',
    });
  }

  Future<void> toggleStar({required String chatId, required String messageId, required bool starred}) {
    return _chats.doc(chatId).collection(Collections.messages).doc(messageId).update({
      'starredBy': starred ? FieldValue.arrayUnion([_uid]) : FieldValue.arrayRemove([_uid]),
    });
  }

  Future<void> react({required String chatId, required String messageId, required String emoji}) {
    return _chats.doc(chatId).collection(Collections.messages).doc(messageId).update({
      'reactions.$_uid': emoji,
    });
  }

  Future<void> pinChat(String chatId, bool pinned) {
    return _chats.doc(chatId).update({'pinned': pinned});
  }

  Future<void> pinMessage(String chatId, String messageId) {
    return _chats.doc(chatId).update({'pinnedMessageId': messageId});
  }

  Future<void> setDisappearing(String chatId, int hours) {
    return _chats.doc(chatId).update({'disappearingHours': hours});
  }

  Future<void> setTyping(String chatId, bool typing) {
    return _chats.doc(chatId).update({
      'typingUid': typing ? _uid : '',
      'typingAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ChatMessage>> latestMessages(String chatId) async {
    final snap = await _chats
        .doc(chatId)
        .collection(Collections.messages)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .get();
    return snap.docs.map(ChatMessage.fromDoc).where((m) => !m.isExpired).toList();
  }

  Future<void> logCall({required String otherUid, required String kind}) {
    return _db.collection(Collections.calls).add({
      'callerId': _uid,
      'calleeId': otherUid,
      'kind': kind,
      'status': 'started',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
