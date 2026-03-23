// File generated from Firebase project tavli-2da6a.
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
    apiKey: 'AIzaSyBxUTmwtMAIHKS2-59bEDHynTkaaLpetTM',
    appId: '1:378522388821:android:ecd15e4a0418f6353887dc',
    messagingSenderId: '378522388821',
    projectId: 'tavli-2da6a',
    storageBucket: 'tavli-2da6a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbPq7M8fo8PKezS6nonosdvOEFk-eJq_Y',
    appId: '1:378522388821:ios:11c38d2e47115a2d3887dc',
    messagingSenderId: '378522388821',
    projectId: 'tavli-2da6a',
    storageBucket: 'tavli-2da6a.firebasestorage.app',
    iosBundleId: 'com.tavli.tavli',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDbPq7M8fo8PKezS6nonosdvOEFk-eJq_Y',
    appId: '1:378522388821:ios:11c38d2e47115a2d3887dc',
    messagingSenderId: '378522388821',
    projectId: 'tavli-2da6a',
    storageBucket: 'tavli-2da6a.firebasestorage.app',
    iosBundleId: 'com.tavli.tavli',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDa-gTDSbI86VSN6GDhr4MZXeBlnc7fYuc',
    appId: '1:378522388821:web:b5680c99655d51123887dc',
    messagingSenderId: '378522388821',
    projectId: 'tavli-2da6a',
    storageBucket: 'tavli-2da6a.firebasestorage.app',
    authDomain: 'tavli-2da6a.firebaseapp.com',
    measurementId: 'G-7MB93WY7FH',
  );
}
