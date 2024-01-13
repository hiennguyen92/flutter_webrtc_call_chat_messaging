// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiN3V7VgOBJRVlsWgbP4nvm4DJ07Lcil0',
    appId: '1:773665512065:web:5c2510b50407a9d21a8b80',
    messagingSenderId: '773665512065',
    projectId: 'project-working-for-testing',
    authDomain: 'project-working-for-testing.firebaseapp.com',
    databaseURL: 'https://project-working-for-testing-default-rtdb.firebaseio.com',
    storageBucket: 'project-working-for-testing.appspot.com',
    measurementId: 'G-7T4Q9N7Q39',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBv5X-BDvO8km6lVG8gllj4bY6lJLDUguY',
    appId: '1:773665512065:android:2dcf6a0c607b57001a8b80',
    messagingSenderId: '773665512065',
    projectId: 'project-working-for-testing',
    databaseURL: 'https://project-working-for-testing-default-rtdb.firebaseio.com',
    storageBucket: 'project-working-for-testing.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAIKYJWeQJuRhUSDmPgNAV4LbX0iSNBdQA',
    appId: '1:773665512065:ios:1df44b32f7602cea1a8b80',
    messagingSenderId: '773665512065',
    projectId: 'project-working-for-testing',
    databaseURL: 'https://project-working-for-testing-default-rtdb.firebaseio.com',
    storageBucket: 'project-working-for-testing.appspot.com',
    iosBundleId: 'com.hiennv.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAIKYJWeQJuRhUSDmPgNAV4LbX0iSNBdQA',
    appId: '1:773665512065:ios:90d5474e66ff40301a8b80',
    messagingSenderId: '773665512065',
    projectId: 'project-working-for-testing',
    databaseURL: 'https://project-working-for-testing-default-rtdb.firebaseio.com',
    storageBucket: 'project-working-for-testing.appspot.com',
    iosBundleId: 'com.example.flutterWebrtcCallChatMessaging.RunnerTests',
  );
}
