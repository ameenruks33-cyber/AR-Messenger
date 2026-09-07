import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = _storage.ref('users/$uid/profile.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadSelfie(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = _uuid.v4();
    final ref = _storage.ref('attendance/$uid/$id.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadChatMedia({
    required String chatId,
    required File file,
    required String contentType,
    required String extension,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = _uuid.v4();
    final ref = _storage.ref('chats/$chatId/$uid/$id.$extension');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
