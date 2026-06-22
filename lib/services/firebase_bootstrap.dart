import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static bool _isEnabled = false;

  static bool get isEnabled => _isEnabled;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isEnabled = !_usesPlaceholderConfig;
    } catch (_) {
      _isEnabled = false;
    }
  }

  static bool get _usesPlaceholderConfig {
    final options = DefaultFirebaseOptions.currentPlatform;
    return options.apiKey == 'TODO' ||
        options.appId == 'TODO' ||
        options.projectId == 'TODO';
  }
}
