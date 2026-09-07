import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
      : _auth = authService ?? AuthService() {
    _sub = _auth.authStateChanges.listen(_onAuth);
  }

  final AuthService _auth;
  late final StreamSubscription<User?> _sub;
  User? _user;
  UserProfile? _profile;
  bool loading = true;
  String? verificationId;
  String? pendingPhone;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isSignedIn => _user != null;
  bool get needsProfile => _user != null && (_profile == null || _profile!.displayName.isEmpty);

  Future<void> _onAuth(User? user) async {
    _user = user;
    if (user == null) {
      _profile = null;
      loading = false;
      notifyListeners();
      return;
    }
    _profile = await _auth.loadProfile(user.uid);
    await _auth.setPresence(true);
    await _auth.saveFcmToken();
    loading = false;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) async {
    pendingPhone = phone;
    await _auth.sendOtp(
      phoneNumber: phone,
      onCodeSent: (id) {
        verificationId = id;
        notifyListeners();
      },
      onFailed: (error) {
        throw error;
      },
      onAutoVerified: (credential) async {
        await _auth.signInWithCredential(credential);
      },
    );
  }

  Future<void> verifyOtp(String code) async {
    final id = verificationId;
    if (id == null) {
      throw StateError('No OTP session. Request a new code.');
    }
    await _auth.verifyOtp(verificationId: id, smsCode: code);
  }

  Future<void> completeProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    await _auth.createProfile(displayName: displayName, photoUrl: photoUrl);
    if (_user != null) {
      _profile = await _auth.loadProfile(_user!.uid);
      await _auth.setPresence(true);
      await _auth.saveFcmToken();
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;
    _profile = await _auth.loadProfile(_user!.uid);
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
