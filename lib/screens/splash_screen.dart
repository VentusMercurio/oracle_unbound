// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Import google_fonts

// We can remove the 'mysticalFontFamily' constant now or keep it for other Text widgets if desired.

class SplashScreen extends StatefulWidget {
  // ... (rest of StatefulWidget setup is the same) ...
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  final List<Map<String, dynamic>> _featureButtons = [
    {'label': 'Natal Chart', 'route': '/natal_input'},
    {'label': 'Sigil Engine', 'route': '/draw'},
    {'label': 'One Card Draw', 'route': '/card'},
    {'label': 'Zodiac Master', 'route': '/zodiac'},
  ];

  @override
  void initState() {
    super.initState();
    // ... (video controller initialization is the same) ...
    _videoController = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {
              _videoInitialized = true;
            });
            _videoController.play();
            _videoController.setLooping(true);
            _videoController.setVolume(0.0);
          })
          .catchError((error) {
            if (!mounted) return;
            print("Error initializing video player: $error");
            setState(() {
              _videoInitialized = false;
            });
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_videoInitialized)
            FittedBox(
              /* ... video player part ... */
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),

          Row(
            children: [
              Container(
                width: 150,
                color: Colors.pinkAccent.withOpacity(0.35),
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      _featureButtons.map((buttonData) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: FeatureButton(
                            // Will update FeatureButton too
                            label: buttonData['label'],
                            onTap: () {
                              if (buttonData['route'] != null) {
                                Navigator.pushNamed(
                                  context,
                                  buttonData['route'],
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        // ✅ Use GoogleFonts for the title
                        'The Oracle Unbound',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          // Or GoogleFonts.yourChosenFont()
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
                        // ✅ Use GoogleFonts for the button text
                        child: Text(
                          'Enter the Oracle',
                          style: GoogleFonts.cinzel(
                            // Or GoogleFonts.yourChosenFont()
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .normal, // Cinzel is often bold by nature
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
        backgroundColor: Colors.deepPurple.withOpacity(0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        minimumSize: const Size(120, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        // ✅ Use GoogleFonts for the feature button text
        textStyle: GoogleFonts.cinzel(
          // Or GoogleFonts.yourChosenFont()
          fontSize: 13,
          // fontWeight: FontWeight.w500, // Adjust weight if needed
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
