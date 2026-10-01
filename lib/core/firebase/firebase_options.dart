import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Client config for Firebase project `gemworld-9c899`, taken from
/// `android/app/google-services.json` and the iOS `GoogleService-Info.plist`.
///
/// Push is only configured for Android and iOS; [currentPlatform] is `null`
/// elsewhere so web and desktop builds skip Firebase entirely.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOYtHNMBr31gzkY5pd7-y1906kQfFKE-4',
    appId: '1:1033527417367:android:283b66ae3fdd8ed21b5a52',
    messagingSenderId: '1033527417367',
    projectId: 'gemworld-9c899',
    storageBucket: 'gemworld-9c899.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCf_xmZUPRE8zReCU8jo6Us7XC25ANYEmY',
    appId: '1:1033527417367:ios:2b3cdd8774dfdee11b5a52',
    messagingSenderId: '1033527417367',
    projectId: 'gemworld-9c899',
    storageBucket: 'gemworld-9c899.firebasestorage.app',
    iosBundleId: 'gemworld-notifications-IOS',
  );
}
