// lib/screens/natal_chart_display_screen.dart
import 'package:flutter/material.dart';
import '../models/natal_chart_models.dart';
// import '../widgets/video_background_scaffold.dart'; // ✅ REMOVE or comment out if no video
import '../widgets/natal_chart_wheel_painter.dart'; // ✅ Make sure this is imported

class NatalChartDisplayScreen extends StatelessWidget {
  final NatalChartDetails chartDetails;

  const NatalChartDisplayScreen({super.key, required this.chartDetails});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double chartSize = screenWidth * 0.85;

    // ✅ Return a normal Scaffold if no video background is desired here
    return Scaffold(
      backgroundColor: Colors.black, // Or your desired background color
      appBar: AppBar(
        title: const Text('Your Natal Chart'),
        backgroundColor: Colors.deepPurple.withOpacity(0.7), // Or theme default
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Birth: ${chartDetails.birthDateTimeUTC.toLocal()} (Local Est.)",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), // Added color
            ),
            Text(
              "Location: Lat ${chartDetails.latitude.toStringAsFixed(2)}, Lon ${chartDetails.longitude.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ), // Added color
            ),
            const SizedBox(height: 20),

            Container(
              height: chartSize,
              width: chartSize,
              alignment:
                  Alignment
                      .center, // Center the CustomPaint if container is larger
              child: CustomPaint(
                painter: NatalChartWheelPainter(chartDetails: chartDetails),
                size: Size(
                  chartSize,
                  chartSize,
                ), // Explicitly give size to CustomPaint
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle("Major Points"),
            Text(
              chartDetails.ascendant.toString(),
              style: const TextStyle(color: Colors.white),
            ), // Added color
            Text(
              chartDetails.midheaven.toString(),
              style: const TextStyle(color: Colors.white),
            ), // Added color
            const SizedBox(height: 16),

            _buildSectionTitle("Planets"),
            ...chartDetails.planets.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  p.toString(),
                  style: const TextStyle(color: Colors.white),
                ), // Added color
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle("House Cusps (Placidus)"),
            ...chartDetails.houseCusps.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  c.toString(),
                  style: const TextStyle(color: Colors.white),
                ), // Added color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}
