import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/chat.dart';

class ChatService {
  ChatService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ChatThread>> watchChats() {
    return _db
        .collection(Collections.chats)
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map((snap) {
      final chats = snap.docs.map(ChatThread.fromDoc).toList();
      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return chats;
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.messagePageSize)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<String> openDirectChat(String otherUid) async {
    final members = [_uid, otherUid]..sort();
    final existing = await _db
        .collection(Collections.chats)
        .where('type', isEqualTo: 'direct')
        .where('memberIds', isEqualTo: members)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final doc = await _db.collection(Collections.chats).add({
      'type': 'direct',
      'memberIds': members,
      'name': '',
      'photoUrl': '',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
      'companyId': '',
      'pinned': false,
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
    final doc = await _db.collection(Collections.chats).add({
      'type': 'group',
      'memberIds': members,
      'name': name,
      'photoUrl': '',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
      'companyId': companyId,
      'pinned': false,
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
  }) async {
    final chatRef = _db.collection(Collections.chats).doc(chatId);
    final messageRef = chatRef.collection(Collections.messages).doc();
    final preview = type == 'text'
        ? text
        : type == 'image'
            ? 'Photo'
            : type == 'audio'
                ? 'Voice message'
                : type == 'file'
                    ? 'Document'
                    : type;
    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': _uid,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'replyTo': replyTo,
      'deleted': false,
      'readBy': [_uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> markRead(String chatId, String messageId) async {
    await _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([_uid]),
    });
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) {
    return _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .doc(messageId)
        .update({
      'text': text,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) {
    return _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .doc(messageId)
        .update({
      'deleted': true,
      'text': '',
      'mediaUrl': '',
    });
  }
}
