// File generated based on google-services.json for project hijama-f8e79
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBx_FiJ3UzxoPO8-jyTOYTIO1kc6mB24iw',
    appId: '1:270634952683:android:d1dfc035fccea03c565bae',
    messagingSenderId: '270634952683',
    projectId: 'hijama-f8e79',
    storageBucket: 'hijama-f8e79.firebasestorage.app',
  );

  // Placeholder — replace with real iOS config from GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBx_FiJ3UzxoPO8-jyTOYTIO1kc6mB24iw',
    appId: '1:270634952683:ios:placeholder',
    messagingSenderId: '270634952683',
    projectId: 'hijama-f8e79',
    storageBucket: 'hijama-f8e79.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.oubay.hijama',
  );

  // Placeholder — replace with real macOS config if needed
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBx_FiJ3UzxoPO8-jyTOYTIO1kc6mB24iw',
    appId: '1:270634952683:ios:placeholder',
    messagingSenderId: '270634952683',
    projectId: 'hijama-f8e79',
    storageBucket: 'hijama-f8e79.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.oubay.hijama',
  );

  // Placeholder — add web app config from Firebase Console if needed
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBx_FiJ3UzxoPO8-jyTOYTIO1kc6mB24iw',
    appId: '1:270634952683:web:placeholder',
    messagingSenderId: '270634952683',
    projectId: 'hijama-f8e79',
    storageBucket: 'hijama-f8e79.firebasestorage.app',
    authDomain: 'hijama-f8e79.firebaseapp.com',
  );
}
