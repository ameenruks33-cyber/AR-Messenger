import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/status_post.dart';
import '../models/user_profile.dart';

class StatusService {
  StatusService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<StatusPost>> watchActive() {
    return _db
        .collection(Collections.statuses)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map(StatusPost.fromDoc)
          .where((post) => post.expiresAt.isAfter(now))
          .toList();
    });
  }

  Future<void> postText({
    required UserProfile profile,
    required String text,
    bool companyOnly = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    await _db.collection(Collections.statuses).add({
      'userId': uid,
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'text': text.trim(),
      'type': 'text',
      'companyOnly': companyOnly,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }
}
