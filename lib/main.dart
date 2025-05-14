// lib/main.dart
import 'package:flutter/material.dart';
import 'services/astrology_service.dart'; // 👈 Import your AstrologyService
import 'screens/splash_screen.dart';     // 👈 Ensure correct path if screens are in lib/screens/
import 'screens/sigil_generator.dart';  // 👈 Ensure correct path
import 'screens/one_card_draw.dart';     // 👈 Ensure correct path
import 'screens/zodiac_master_screen.dart'; // 👈 Ensure correct path

// ✅ Create a global instance of your AstrologyService
// This makes it accessible throughout your app.
// For larger apps, you might consider a service locator like GetIt or Provider.
final AstrologyService astrologyService = AstrologyService();

void main() async { // ✅ Changed to async to allow await for initialization
  // ✅ CRUCIAL: Ensure Flutter bindings are initialized before using plugins
  // or doing async operations before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  print("Oracle Unbound: Main - Initializing AstrologyService...");
  bool initSuccess = await astrologyService.initSweph(); // ✅ Await the initialization

  if (initSuccess) {
    print("Oracle Unbound: Main - AstrologyService initialized successfully.");
  } else {
    print("Oracle Unbound: Main - AstrologyService FAILED to initialize. Astrology features may not work.");
    // In a production app, you might want to show an error to the user
    // or disable features that depend on this service.
  }

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
            backgroundColor: Colors.deepPurpleAccent, // Ensure this provides enough contrast or consider foregroundColor: Colors.white
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        // Assuming your screen files are directly in a 'screens' folder under 'lib'
        // If they are in 'lib/screens/', the paths like '/screens/splash_screen.dart' are correct for imports,
        // but the routes are just string keys.
        '/': (context) => const SplashScreen(),
        '/draw': (context) => const SigilGeneratorScreen(),
        '/card': (context) => const OneCardDraw(),
        '/zodiac': (context) => const ZodiacMasterScreen(),
        // Example for a future natal chart screen:
        // '/natal_chart_input': (context) => const NatalChartInputScreen(),
      },
    );
  }
}