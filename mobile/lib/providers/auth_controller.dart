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
  StreamSubscription<UserProfile?>? _profileSub;
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
      await _profileSub?.cancel();
      _profileSub = null;
      _profile = null;
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      _profile = await _auth.loadProfile(user.uid).timeout(const Duration(seconds: 8));
    } catch (_) {
      _profile = _profile;
    }
    loading = false;
    notifyListeners();
    await _profileSub?.cancel();
    _profileSub = _auth.watchProfile(user.uid).listen((profile) {
      _profile = profile;
      notifyListeners();
    });
    unawaited(_auth.setPresence(true));
    unawaited(_auth.saveFcmToken());
  }

  Future<void> sendOtp(String phone) async {
    pendingPhone = phone;
    notifyListeners();
  }

  void clearPendingPhone() {
    pendingPhone = null;
    notifyListeners();
  }

  Future<void> verifyOtp(String code) async {
    final phone = pendingPhone;
    if (phone == null || phone.isEmpty) {
      throw StateError('Enter your mobile number first.');
    }
    if (code.length != 6) {
      throw StateError('Enter a 6-digit PIN.');
    }
    final credential = await _auth
        .signInWithPhonePin(phoneNumber: phone, pin: code)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw StateError('Sign-in timed out. Check internet and try again.'),
        );
    _user = credential.user;
    if (_user != null) {
      try {
        _profile = await _auth.loadProfile(_user!.uid).timeout(const Duration(seconds: 8));
      } catch (_) {
        _profile = null;
      }
      loading = false;
      notifyListeners();
      unawaited(_auth.setPresence(true));
      unawaited(_auth.saveFcmToken());
    }
  }

  Future<void> completeProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    await _auth.createProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      phone: pendingPhone,
    );
    if (_user != null) {
      try {
        _profile = await _auth.loadProfile(_user!.uid).timeout(const Duration(seconds: 8));
      } catch (_) {
        _profile = null;
      }
      notifyListeners();
      unawaited(_auth.setPresence(true));
      unawaited(_auth.saveFcmToken());
    }
  }

  Future<void> applyWorkspaceUpdate(String companyId) async {
    if (_user == null) return;
    if ((_profile?.companyId ?? '').isEmpty && companyId.isNotEmpty) {
      await _auth.joinCompany(companyId);
    }
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;
    _profile = await _auth.loadProfile(_user!.uid);
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _profileSub?.cancel();
    _sub.cancel();
    super.dispose();
  }
}
