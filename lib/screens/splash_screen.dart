// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
// ✅ Import your AstrologyService and the global instance from main.dart
import '../services/astrology_service.dart'; // Adjust path if your services folder is elsewhere
import '../main.dart';                       // This is where 'astrologyService' instance is defined

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // ✅ Method to perform the astrology test calculations
  Future<void> _performAstrologyTest() async {
    print("SplashScreen: Astrology Test button tapped.");

    if (!astrologyService.isInitialized) {
      print("SplashScreen: AstrologyService is not initialized. Test cannot run.");
      // Optionally, you could try to call astrologyService.initSweph() here again,
      // but it should have been initialized in main.dart.
      // This usually indicates a problem during the initial startup.
      return;
    }

    print("SplashScreen: --- Testing Astrology Calculations ---");
    DateTime testDateTime = DateTime.now(); // Use current date and time for the test

    print("SplashScreen: Calculating for: $testDateTime (local), which is ${testDateTime.toUtc()} (UTC)");

    Map<String, dynamic>? sunInfo = await astrologyService.getSunPosition(testDateTime);
    if (sunInfo != null) {
      print('SplashScreen: --- Sun Position ---');
      print('  Longitude: ${sunInfo['longitude']?.toStringAsFixed(4)}°');
      print('  Latitude: ${sunInfo['latitude']?.toStringAsFixed(4)}°');
      print('  Distance (AU): ${sunInfo['distance_au']?.toStringAsFixed(4)}');
      print('  Speed Longitude (°/day): ${sunInfo['speed_longitude_per_day']?.toStringAsFixed(4)}');
      // You can add more fields here if needed, e.g., speeds for lat/dist
      print('  Julian Day (UT) used for calc: ${sunInfo['julian_day_ut']}');
    } else {
      print('SplashScreen: Failed to get Sun position for $testDateTime.');
    }

    Map<String, dynamic>? moonInfo = await astrologyService.getMoonPosition(testDateTime);
    if (moonInfo != null) {
      print('SplashScreen: --- Moon Position ---');
      print('  Longitude: ${moonInfo['longitude']?.toStringAsFixed(4)}°');
      print('  Latitude: ${moonInfo['latitude']?.toStringAsFixed(4)}°');
      print('  Distance (AU): ${moonInfo['distance_au']?.toStringAsFixed(4)}');
      print('  Speed Longitude (°/day): ${moonInfo['speed_longitude_per_day']?.toStringAsFixed(4)}');
      print('  Julian Day (UT) used for calc: ${moonInfo['julian_day_ut']}');
    } else {
      print('SplashScreen: Failed to get Moon position for $testDateTime.');
    }
    print("SplashScreen: --- End Astrology Test ---");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Row(
        children: [
          // 🔹 Side tab with feature buttons
          Container(
            width: 120,
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
                  label: 'Astrology Test', // ✅ Changed label for clarity
                  onTap: () {
                    _performAstrologyTest(); // ✅ Call the test method
                    // Future: Navigator.pushNamed(context, '/astrology_input_screen');
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Misc',
                  onTap: () {
                    // Future: Navigator.pushNamed(context, '/misc');
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Zodiac Master',
                  onTap: () => Navigator.pushNamed(context, '/zodiac'),
                ),
              ],
            ),
          ),

          // 🔸 Main content
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: Colors.deepPurpleAccent,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/card');
                },
                child: const Text(
                  'Enter the Oracle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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

  const FeatureButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}