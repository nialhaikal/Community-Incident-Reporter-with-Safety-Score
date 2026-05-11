import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGPJ48EdFJRe2F1SXEBusyjJEprb5bOek',
    appId: '1:266655269440:android:1bf2d624031b4fbb34d5a5',
    messagingSenderId: '266655269440',
    projectId: 'safezone-cb78f',
    storageBucket: 'safezone-cb78f.firebasestorage.app',
  );
}
