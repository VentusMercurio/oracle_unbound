// lib/screens/splash_screen.dart
import 'dart:math'; // For Random
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/video_background_scaffold.dart';
// Import the routeObserver from main.dart or wherever you define it
// Assuming main.dart is in the parent directory of lib or accessible
import '../../main.dart'; // Adjust path if your main.dart is elsewhere

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with RouteAware {
  //  Tambahkan RouteAware
  final List<String> _videoAssets = [
    'assets/videos/intro.mp4',
    'assets/videos/pink_nebula.mp4',
    'assets/videos/red_nebula.mp4',
    // Add more video paths as needed
  ];

  String? _currentVideoPath;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Select an initial video.
    // No need to call _changeVideo here if didPush will handle it.
    if (_videoAssets.isNotEmpty) {
      _currentVideoPath = _videoAssets[_random.nextInt(_videoAssets.length)];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes.
    // Use ModalRoute.of(context) as PageRoute<dynamic>
    // or ensure your routeObserver is correctly typed if issues arise.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Check if route is a PageRoute
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); //  Jangan lupa unsubscribe
    super.dispose();
  }

  // Called when the current route has been pushed.
  @override
  void didPush() {
    super.didPush();
    // This can be a good place for initial video selection if you want it
    // to potentially change even on the very first load vs. initState.
    // Or if you want to ensure it runs after dependencies are fully resolved.
    _selectNewVideo();
    print("SplashScreen: didPush - Video: $_currentVideoPath");
  }

  // Called when the top route has been popped off, and the current route shows up.
  @override
  void didPopNext() {
    super.didPopNext();
    // This is when the user returns to this screen.
    _selectNewVideo();
    print("SplashScreen: didPopNext - Video: $_currentVideoPath");
  }

  void _selectNewVideo() {
    if (_videoAssets.isEmpty) return;
    if (_videoAssets.length == 1) {
      if (mounted) {
        setState(() {
          _currentVideoPath = _videoAssets.first;
        });
      }
      return;
    }

    String? previousVideoPath = _currentVideoPath;
    String newVideoPath;

    do {
      newVideoPath = _videoAssets[_random.nextInt(_videoAssets.length)];
    } while (newVideoPath ==
        previousVideoPath); // Ensure it's a different video

    if (mounted) {
      setState(() {
        _currentVideoPath = newVideoPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> featureButtons = [
      {'label': 'Natal Chart', 'route': '/natal_input'},
      {'label': 'Sigil Engine', 'route': '/draw'},
      {'label': 'Three Card Draw', 'route': '/three_card_spread'},
      {'label': 'Zodiac Master', 'route': '/zodiac'},
    ];

    // Fallback video if something goes wrong or list is initially empty
    String videoToPlay =
        _currentVideoPath ??
        (_videoAssets.isNotEmpty
            ? _videoAssets.first
            : 'assets/videos/intro.mp4');

    return VideoBackgroundScaffold(
      videoAssetPath: videoToPlay,
      // Ensure your VideoBackgroundScaffold handles looping correctly internally
      // and re-initializes the player if videoAssetPath changes.
      child: Row(
        // ... your existing UI ...
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

// FeatureButton class remains the same
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
