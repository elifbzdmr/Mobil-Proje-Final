import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1p9YTw9Sgi-U1uxtuniXvlDOxO15p_3Q',
    appId: '1:445335067524:android:f079ce9a6204829c509bd1',
    messagingSenderId: '445335067524',
    projectId: 'mobil-proje-final',
    storageBucket: 'mobil-proje-final.firebasestorage.app',
  );
}
