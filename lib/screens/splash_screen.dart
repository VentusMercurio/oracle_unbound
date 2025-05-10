import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                  label: 'Astrology',
                  onTap: () {
                    // Future: Navigator.pushNamed(context, '/astrology');
                  },
                ),
                const SizedBox(height: 12),
                FeatureButton(
                  label: 'Misc',
                  onTap: () {
                    // Future: Navigator.pushNamed(context, '/misc');
                  },
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
                  Navigator.pushNamed(context, '/card'); // 🔮 Now routes to OneCardDrawScreen
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
