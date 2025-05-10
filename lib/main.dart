// lib/main.dart
import 'package:flutter/material.dart';
import '/screens/splash_screen.dart';
import '/screens/sigil_generator.dart';
import '/screens/one_card_draw.dart'; // 👈 Add this import

void main() {
  runApp(const OracleUnboundApp());
}

class OracleUnboundApp extends StatelessWidget {
  const OracleUnboundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oracle Unbound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/draw': (context) => const SigilGeneratorScreen(),
        '/card': (context) => const OneCardDrawScreen(), // 👈 New route added
        // Future routes:
        // '/astrology': (context) => const AstrologyScreen(),
        // '/misc': (context) => const MiscScreen(),
      },
    );
  }
}
