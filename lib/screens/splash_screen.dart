// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
// Import your AstrologyService and the global instance from main.dart
import '../services/astrology_service.dart'; // Adjust path if your services folder is elsewhere
import '../main.dart'; // This is where 'astrologyService' instance is defined

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Method to perform the astrology test calculations (Sun/Moon for current time)
  Future<void> _performAstrologyTest() async {
    print("SplashScreen: Astrology Test button tapped.");

    if (!astrologyService.isInitialized) {
      print(
        "SplashScreen: AstrologyService is not initialized. Test cannot run.",
      );
      return;
    }

    print("SplashScreen: --- Testing Quick Sun/Moon Calculations ---");
    DateTime testDateTime = DateTime.now();

    print(
      "SplashScreen: Calculating for: $testDateTime (local), which is ${testDateTime.toUtc()} (UTC)",
    );

    Map<String, dynamic>? sunInfo = await astrologyService.getSunPosition(
      testDateTime,
    );
    if (sunInfo != null) {
      print('SplashScreen: --- Sun Position (Quick Test) ---');
      print('  Longitude: ${sunInfo['longitude']?.toStringAsFixed(4)}°');
      // ... other sun info if desired ...
    } else {
      print('SplashScreen: Failed to get Sun position (Quick Test).');
    }

    Map<String, dynamic>? moonInfo = await astrologyService.getMoonPosition(
      testDateTime,
    );
    if (moonInfo != null) {
      print('SplashScreen: --- Moon Position (Quick Test) ---');
      print('  Longitude: ${moonInfo['longitude']?.toStringAsFixed(4)}°');
      // ... other moon info if desired ...
    } else {
      print('SplashScreen: Failed to get Moon position (Quick Test).');
    }
    print("SplashScreen: --- End Quick Sun/Moon Test ---");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Row(
        children: [
          // 🔹 Side tab with feature buttons
          Container(
            width:
                120, // Adjusted width slightly for potentially longer button text
            color: Colors.deepPurple.shade800,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FeatureButton(
                  label: 'Sigil Engine',
                  onTap: () => Navigator.pushNamed(context, '/draw'),
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Natal Chart', // ✅ NEW/REPURPOSED BUTTON
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/natal_input',
                    ); // ✅ Navigate to input screen
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Astrology Test', // ✅ Kept your quick test button
                  onTap: () {
                    _performAstrologyTest(); // Calls the local sun/moon test
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Misc', // Example, if you have other features
                  onTap: () {
                    // Future: Navigator.pushNamed(context, '/misc');
                    print("Misc button tapped - no route defined yet.");
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Zodiac Master',
                  onTap: () => Navigator.pushNamed(context, '/zodiac'),
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label:
                      'One Card Draw', // ✅ Added this back, assuming it's linked to '/card'
                  onTap: () => Navigator.pushNamed(context, '/card'),
                ),
              ],
            ),
          ),

          // 🔸 Main content (Enter the Oracle button now removed, assuming features are on side)
          // If you still want the "Enter the Oracle" button to go to a specific screen (e.g. '/card'),
          // you can add it back here. For now, I'm assuming the side buttons are the primary navigation.
          Expanded(
            child: Center(
              child: Column(
                // Added a Column for centering text or future elements
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Oracle Unbound',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // You could add an image or more descriptive text here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FeatureButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(
          100,
          40,
        ), // Ensure buttons have a decent tap area
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
        ), // Slightly smaller for more text
        textAlign: TextAlign.center,
      ),
    );
  }
}
