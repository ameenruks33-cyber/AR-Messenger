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

String authErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('invalid-phone-number')) {
    return 'That phone number is not valid. Use +9715XXXXXXXX without a leading 0.';
  }
  if (text.contains('too-many-requests')) {
    return 'Too many attempts. Wait a few minutes and try again.';
  }
  if (text.contains('operation-not-allowed')) {
    return 'Phone sign-in is not enabled yet. Try again in a minute.';
  }
  if (text.contains('quota-exceeded')) {
    return 'SMS limit reached. Try again later.';
  }
  if (text.contains('app-not-authorized') || text.contains('missing-client-identifier')) {
    return 'This app install is not authorized for OTP. Reinstall the latest APK from the website.';
  }
  if (text.contains('captcha-check-failed') || text.contains('recaptcha')) {
    return 'Google could not verify the app. Complete the browser check if it opens, then retry.';
  }
  if (text.contains('otp-timeout') || text.contains('session-expired')) {
    return 'Firebase did not send an OTP. Check your number and internet, then retry.';
  }
  return text.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
}
