import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';

class UserService {
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<UserProfile>> contacts() {
    return _db.collection(Collections.users).snapshots().map((snap) {
      return snap.docs.map(UserProfile.fromDoc).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    });
  }

  Future<UserProfile?> byId(String uid) async {
    final doc = await _db.collection(Collections.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<UserProfile?> byPhone(String phone) async {
    final snap = await _db
        .collection(Collections.users)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserProfile.fromDoc(snap.docs.first);
  }

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
}
