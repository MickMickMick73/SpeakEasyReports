import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/splash/splash_bg.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    'SpeakEasy Reports',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Voice-powered inspection reports. Record, narrate, and deliver professional summaries to your clients.',
                    style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Colors.white24,
                    minHeight: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}