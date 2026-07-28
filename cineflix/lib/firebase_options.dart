// GABARIT - ce fichier sera écrasé automatiquement.
//
// Lancez `flutterfire configure` à la racine du projet : l'outil régénère
// ce fichier avec les vraies clés de VOTRE projet Firebase.
// Tant que ce n'est pas fait, l'application affiche un écran d'explication
// au lieu de planter (voir main.dart).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDGhp29_RmwkvTTcbJsj1OBbKX7wi60nU',
    appId: '1:464572347881:web:14539db2b4d89ab6dfc778',
    messagingSenderId: '464572347881',
    projectId: 'cineflix-ipssi',
    authDomain: 'cineflix-ipssi.firebaseapp.com',
    storageBucket: 'cineflix-ipssi.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'A_REMPLACER_PAR_FLUTTERFIRE',
    appId: 'A_REMPLACER_PAR_FLUTTERFIRE',
    messagingSenderId: 'A_REMPLACER_PAR_FLUTTERFIRE',
    projectId: 'A_REMPLACER_PAR_FLUTTERFIRE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'A_REMPLACER_PAR_FLUTTERFIRE',
    appId: 'A_REMPLACER_PAR_FLUTTERFIRE',
    messagingSenderId: 'A_REMPLACER_PAR_FLUTTERFIRE',
    projectId: 'A_REMPLACER_PAR_FLUTTERFIRE',
    iosBundleId: 'com.example.cineflix',
  );
}
