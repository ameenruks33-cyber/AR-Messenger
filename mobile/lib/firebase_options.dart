import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform ${defaultTargetPlatform.name}');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAEsADGqY9Kt79Rk_j4K1-PYzzbSxRzU2g',
    appId: '1:851451981724:web:41455b4930260567112259',
    messagingSenderId: '851451981724',
    projectId: 'ar-messenger-app',
    authDomain: 'ar-messenger-app.firebaseapp.com',
    storageBucket: 'ar-messenger-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2MoF0TxCIUBRxMyR7TmpeHYj0qpMzKoc',
    appId: '1:851451981724:android:1135433025e67ef1112259',
    messagingSenderId: '851451981724',
    projectId: 'ar-messenger-app',
    storageBucket: 'ar-messenger-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIaaW1P-78VNVPTQMSKROJxsESLkfTG-I',
    appId: '1:851451981724:ios:379ec5464c18abe9112259',
    messagingSenderId: '851451981724',
    projectId: 'ar-messenger-app',
    storageBucket: 'ar-messenger-app.firebasestorage.app',
    iosBundleId: 'com.armessenger.arMessenger',
  );
}
