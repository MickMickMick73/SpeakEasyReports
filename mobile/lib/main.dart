import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeakEasyApp());
}

class SpeakEasyApp extends StatefulWidget {
  const SpeakEasyApp({super.key});

  @override
  State<SpeakEasyApp> createState() => _SpeakEasyAppState();
}

class _SpeakEasyAppState extends State<SpeakEasyApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        if (!_state.ready) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.bg,
              body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          );
        }
        return MaterialApp(
          title: 'SpeakEasy Reports',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(dark: _state.settings.appearanceDark),
          home: SplashScreen(state: _state),
        );
      },
    );
  }
}