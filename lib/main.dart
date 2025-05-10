import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/one_card_draw.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/draw': (context) => const OneCardDraw(),
      },
    );
  }
}
