import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/phone.dart';
import '../models/user_profile.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithPhonePin({
    required String phoneNumber,
    required String pin,
  }) async {
    final email = phoneToAuthEmail(phoneNumber);
    final password = pinToAuthPassword(phoneNumber, pin);
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      final unknownAccount = error.code == 'user-not-found' ||
          error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'INVALID_LOGIN_CREDENTIALS';
      if (!unknownAccount) rethrow;
      try {
        return await _auth.createUserWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use') {
          throw FirebaseAuthException(
            code: 'wrong-pin',
            message: 'Wrong PIN for this number.',
          );
        }
        rethrow;
      }
    }
  }

  Future<UserProfile?> loadProfile(String uid) async {
    final doc = await _db.collection(Collections.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection(Collections.users).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  Future<void> createProfile({
    required String displayName,
    required String photoUrl,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final resolvedPhone = [
      phone,
      phoneFromAuthEmail(user.email),
      user.phoneNumber,
    ].whereType<String>().firstWhere((value) => value.length >= 8, orElse: () => '');
    if (resolvedPhone.length < 8) {
      throw StateError('Missing phone number. Go back and enter your mobile number again.');
    }

    final existing = await _db.collection(Collections.users).doc(user.uid).get();
    if (existing.exists) {
      await _db.collection(Collections.users).doc(user.uid).update({
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      return;
    }

    final profile = UserProfile(
      id: user.uid,
      phone: resolvedPhone,
      displayName: displayName,
      photoUrl: photoUrl,
      about: 'Available',
      role: 'employee',
      companyId: '',
      employeeId: '',
      isOnline: true,
    );

    await _db.collection(Collections.users).doc(user.uid).set(profile.toCreateMap());
  }

  Future<void> setPresence(bool online) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.collection(Collections.users).doc(user.uid);
    final existing = await ref.get();
    if (!existing.exists) return;
    await ref.set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.collection(Collections.users).doc(user.uid);
    final existing = await ref.get();
    if (!existing.exists) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ref.set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await setPresence(false);
    await _auth.signOut();
  }
}
