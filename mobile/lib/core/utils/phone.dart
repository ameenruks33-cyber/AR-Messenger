import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';

String normalizePhoneNumber(String input) {
  var raw = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (raw.isEmpty) return raw;

  if (raw.startsWith('00')) {
    raw = '+${raw.substring(2)}';
  }

  if (!raw.startsWith('+')) {
    if (raw.startsWith('971')) {
      raw = '+$raw';
    } else {
      if (raw.startsWith('0')) {
        raw = raw.substring(1);
      }
      raw = '${AppConstants.defaultCountryCode}$raw';
    }
  }

  if (raw.startsWith('+9710')) {
    raw = '+971${raw.substring(5)}';
  }

  return raw;
}

String phoneToAuthEmail(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return '$digits@users.armessenger.app';
}

String phoneFromAuthEmail(String? email) {
  const suffix = '@users.armessenger.app';
  if (email == null || !email.endsWith(suffix)) return '';
  final digits = email.substring(0, email.length - suffix.length);
  if (digits.length < 8) return '';
  return '+$digits';
}

String pinToAuthPassword(String phone, String pin) {
  final digest = sha256.convert(utf8.encode('ar-messenger|$phone|$pin'));
  return 'Pin${digest.toString().substring(0, 24)}!';
}

String authErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('wrong-pin') || text.contains('wrong-password') || text.contains('email-already-in-use')) {
    return 'Wrong PIN. Enter the 6-digit PIN you created for this number.';
  }
  if (text.contains('weak-password')) {
    return 'Use a 6-digit PIN.';
  }
  if (text.contains('invalid-phone-number')) {
    return 'That phone number is not valid. Use +9715XXXXXXXX without a leading 0.';
  }
  if (text.contains('too-many-requests')) {
    return 'Too many attempts. Wait a few minutes and try again.';
  }
  if (text.contains('operation-not-allowed')) {
    return 'Email/PIN sign-in is not enabled in Firebase.';
  }
  if (text.contains('network-request-failed')) {
    return 'No internet. Check your connection and try again.';
  }
  if (text.contains('permission-denied') || text.contains('PERMISSION_DENIED')) {
    return 'Could not save your profile. Close the app, open it again, and tap Continue.';
  }
  return text.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
}
