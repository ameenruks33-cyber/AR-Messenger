import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsController extends ChangeNotifier {
  PrefsController() {
    _load();
  }

  SharedPreferences? _prefs;
  ThemeMode themeMode = ThemeMode.light;
  bool amoled = false;
  String lastSeen = 'everyone';
  String profilePhoto = 'everyone';
  bool readReceipts = true;
  bool notifications = true;
  String disappearingDefault = 'off';
  String chatPin = '';
  Set<String> lockedChats = {};

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final theme = _prefs?.getString('theme') ?? 'light';
    themeMode = theme == 'dark' || theme == 'amoled' ? ThemeMode.dark : ThemeMode.light;
    amoled = theme == 'amoled';
    lastSeen = _prefs?.getString('lastSeen') ?? 'everyone';
    profilePhoto = _prefs?.getString('profilePhoto') ?? 'everyone';
    readReceipts = _prefs?.getBool('readReceipts') ?? true;
    notifications = _prefs?.getBool('notifications') ?? true;
    disappearingDefault = _prefs?.getString('disappearing') ?? 'off';
    chatPin = _prefs?.getString('chatPin') ?? '';
    lockedChats = (_prefs?.getStringList('lockedChats') ?? const []).toSet();
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    await _prefs?.setString('theme', value);
    themeMode = value == 'light' ? ThemeMode.light : ThemeMode.dark;
    amoled = value == 'amoled';
    notifyListeners();
  }

  Future<void> setLastSeen(String value) async {
    lastSeen = value;
    await _prefs?.setString('lastSeen', value);
    notifyListeners();
  }

  Future<void> setProfilePhoto(String value) async {
    profilePhoto = value;
    await _prefs?.setString('profilePhoto', value);
    notifyListeners();
  }

  Future<void> setReadReceipts(bool value) async {
    readReceipts = value;
    await _prefs?.setBool('readReceipts', value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    notifications = value;
    await _prefs?.setBool('notifications', value);
    notifyListeners();
  }

  Future<void> setDisappearing(String value) async {
    disappearingDefault = value;
    await _prefs?.setString('disappearing', value);
    notifyListeners();
  }

  Future<void> setChatPin(String value) async {
    chatPin = value;
    await _prefs?.setString('chatPin', value);
    notifyListeners();
  }

  Future<void> toggleLock(String chatId) async {
    if (lockedChats.contains(chatId)) {
      lockedChats.remove(chatId);
    } else {
      lockedChats.add(chatId);
    }
    await _prefs?.setStringList('lockedChats', lockedChats.toList());
    notifyListeners();
  }

  bool isLocked(String chatId) => lockedChats.contains(chatId);
}
