// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/video_background_scaffold.dart'; // ✅ Import the reusable widget

// const String mysticalFontFamily = 'serif'; // No longer needed if using GoogleFonts directly

class SplashScreen extends StatelessWidget {
  // ✅ Can be StatelessWidget now!
  const SplashScreen({super.key});

  // No need for initState, dispose, or _videoController here anymore.

  @override
  Widget build(BuildContext context) {
    // Define your buttons here or pass them in if this widget becomes more generic
    final List<Map<String, dynamic>> featureButtons = [
      {'label': 'Natal Chart', 'route': '/natal_input'},
      {'label': 'Sigil Engine', 'route': '/draw'},
      {'label': 'One Card Draw', 'route': '/card'},
      {'label': 'Zodiac Master', 'route': '/zodiac'},
    ];

    return VideoBackgroundScaffold(
      // ✅ Use the reusable widget
      videoAssetPath: 'assets/videos/intro.mp4', // ✅ Pass your video path
      child: Row(
        // This Row is now the child of VideoBackgroundScaffold
        children: [
          // 🔹 Side tab with feature buttons
          Container(
            width: 150,
            color: Colors.pinkAccent.withOpacity(0.35),
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  featureButtons.map((buttonData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FeatureButton(
                        label: buttonData['label'],
                        onTap: () {
                          if (buttonData['route'] != null) {
                            Navigator.pushNamed(context, buttonData['route']);
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),

          // 🔸 Main content (Title and Primary Action Button)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'The Oracle Unbound',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      shadows: const [
                        Shadow(
                          blurRadius: 12.0,
                          color: Colors.black87,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent.withOpacity(
                        0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 8.0,
                      shadowColor: Colors.purpleAccent,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/card');
                    },
                    child: Text(
                      'Enter the Oracle',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
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

// FeatureButton class remains the same (or can be moved to a common widgets file)
class FeatureButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FeatureButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.withOpacity(0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        minimumSize: const Size(120, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.cinzel(fontSize: 13),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
