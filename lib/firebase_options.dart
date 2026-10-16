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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDX3bVPXdh9j8wEgidzFr93Fc30owPee9c',
    appId: '1:462094267479:web:a71fea3400c15ac0d7df12',
    messagingSenderId: '462094267479',
    projectId: 'toktik-moviles',
    authDomain: 'toktik-moviles.firebaseapp.com',
    storageBucket: 'toktik-moviles.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX3bVPXdh9j8wEgidzFr93Fc30owPee9c',
    appId: '1:462094267479:web:a71fea3400c15ac0d7df12',
    messagingSenderId: '462094267479',
    projectId: 'toktik-moviles',
    storageBucket: 'toktik-moviles.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDX3bVPXdh9j8wEgidzFr93Fc30owPee9c',
    appId: '1:462094267479:web:a71fea3400c15ac0d7df12',
    messagingSenderId: '462094267479',
    projectId: 'toktik-moviles',
    storageBucket: 'toktik-moviles.firebasestorage.app',
  );
}
