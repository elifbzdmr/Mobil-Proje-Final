
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/mood_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama açılmadan önce local verileri yükleyelim.
  final moodProvider = MoodProvider();
  await moodProvider.initialize();

  runApp(
    ChangeNotifierProvider<MoodProvider>.value(
      value: moodProvider,
      child: const BiMuzikApp(),
    ),
  );
}

class BiMuzikApp extends StatelessWidget {
  const BiMuzikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<MoodProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );

    return MaterialApp(
      title: 'biMüzik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: Selector<MoodProvider, _AppGateStatus>(
        selector: (_, provider) {
          if (provider.isLoading) return _AppGateStatus.loading;
          if (!provider.hasProfile && provider.hasAnyAccount) {
            return _AppGateStatus.needsLogin;
          }
          if (!provider.hasProfile) return _AppGateStatus.needsProfile;
          if (!provider.isAuthenticated) return _AppGateStatus.needsLogin;
          return _AppGateStatus.ready;
        },
        builder: (context, status, _) {
          if (status == _AppGateStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (status == _AppGateStatus.needsProfile) {
            return const OnboardingScreen();
          }
          if (status == _AppGateStatus.needsLogin) {
            return const LoginScreen();
          }
          return const MainScaffold();
        },
      ),
    );
  }
}

enum _AppGateStatus { loading, needsProfile, needsLogin, ready }
