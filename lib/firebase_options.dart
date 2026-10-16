// firebase_options.dart
//
// ESTE ARCHIVO ES UNA PLANTILLA, NO UNA CONFIGURACIÓN REAL.
//
// Normalmente este archivo NO se escribe a mano: lo genera automáticamente
// la CLI de FlutterFire con el comando:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ese comando pide iniciar sesión en Firebase, elegir (o crear) un proyecto
// en la consola (https://console.firebase.google.com) y selecciona las
// plataformas (Android, iOS, Web) que tendrá la app. Como resultado,
// sobrescribe este archivo con las credenciales reales del proyecto.
//
// Los valores de abajo son de relleno (no apuntan a ningún proyecto real)
// únicamente para que el proyecto compile y pueda revisarse en un editor
// antes de correr `flutterfire configure` con un proyecto propio.

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
          'DefaultFirebaseOptions no está configurado para esta plataforma. '
          'Corre `flutterfire configure` para generar la configuración real.',
        );
    }
  }

  // TODO: reemplazar con los valores reales generados por `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REEMPLAZAR-CON-TU-API-KEY-WEB',
    appId: 'REEMPLAZAR-CON-TU-APP-ID-WEB',
    messagingSenderId: 'REEMPLAZAR-CON-TU-SENDER-ID',
    projectId: 'clase23-firebase-demo',
    authDomain: 'clase23-firebase-demo.firebaseapp.com',
    storageBucket: 'clase23-firebase-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZAR-CON-TU-API-KEY-ANDROID',
    appId: 'REEMPLAZAR-CON-TU-APP-ID-ANDROID',
    messagingSenderId: 'REEMPLAZAR-CON-TU-SENDER-ID',
    projectId: 'clase23-firebase-demo',
    storageBucket: 'clase23-firebase-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZAR-CON-TU-API-KEY-IOS',
    appId: 'REEMPLAZAR-CON-TU-APP-ID-IOS',
    messagingSenderId: 'REEMPLAZAR-CON-TU-SENDER-ID',
    projectId: 'clase23-firebase-demo',
    storageBucket: 'clase23-firebase-demo.appspot.com',
    iosBundleId: 'com.esen.clase23FirebaseDemo',
  );
}
