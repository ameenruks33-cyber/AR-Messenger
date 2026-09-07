import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/constants/app_constants.dart';
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

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) {
    return _auth.signInWithCredential(credential);
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
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
      phone: user.phoneNumber ?? '',
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
