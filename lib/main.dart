import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const FastCutApp());
}

class FastCutApp extends StatelessWidget {
  const FastCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastCut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
      ),
      home: const SplashScreen(),
    );
  }
}