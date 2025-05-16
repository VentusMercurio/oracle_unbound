// lib/screens/natal_chart_display_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming you might want to use custom fonts here too
import '../models/natal_chart_models.dart';
import '../widgets/natal_chart_wheel_painter.dart';
// import '../widgets/video_background_scaffold.dart'; // Keeping it commented out for now

class NatalChartDisplayScreen extends StatelessWidget {
  final NatalChartDetails chartDetails;

  const NatalChartDisplayScreen({super.key, required this.chartDetails});

  // Helper for building section titles, with an option for no top padding
  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool noPadding = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: noPadding ? 0 : 20.0,
        bottom: 10.0,
      ), // Adjusted padding
      child: Text(
        title,
        style: GoogleFonts.cinzel(
          // Example: Using Cinzel for section titles
          fontSize: 18, // Adjusted size
          fontWeight: FontWeight.w600,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  // Helper widget for displaying an AstrologicalPoint consistently
  Widget _buildPointDisplay(BuildContext context, AstrologicalPoint point) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Increased vertical padding slightly
      child: RichText(
        text: TextSpan(
          // Use a base style that inherits from the theme but allows overrides
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: "${point.name}: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: point.formattedPosition),
            if (point.house != null)
              TextSpan(
                text: " (H${point.house})",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            if (point.isRetrograde == true)
              const TextSpan(
                text: " Rx",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double chartSize = screenWidth * 0.60; // Chart is 60% of screen width

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Your Natal Chart',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.withOpacity(0.7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Birth Details Section
            _buildSectionTitle(
              context,
              "Birth Details",
              noPadding: true,
            ), // First title, no top padding
            Text(
              "Date & Time: ${chartDetails.birthDateTimeUTC.toLocal()} (Local Est.)", // More descriptive
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "Location: Lat ${chartDetails.latitude.toStringAsFixed(4)}, Lon ${chartDetails.longitude.toStringAsFixed(4)}", // Increased precision
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 24), // Increased spacing
            // Chart Wheel
            Center(
              child: Container(
                height: chartSize,
                width: chartSize,
                // decoration: BoxDecoration( // Optional: Border for debugging painter area
                //   border: Border.all(color: Colors.grey.shade700),
                // ),
                child: CustomPaint(
                  painter: NatalChartWheelPainter(chartDetails: chartDetails),
                  size: Size(chartSize, chartSize),
                ),
              ),
            ),
            const SizedBox(height: 24), // Increased spacing
            // Textual Data Sections
            _buildSectionTitle(context, "Key Points"),
            _buildPointDisplay(context, chartDetails.ascendant),
            _buildPointDisplay(context, chartDetails.midheaven),

            _buildSectionTitle(context, "Planets"),
            // Using ListView.builder isn't strictly necessary if the number of planets is fixed and small,
            // a simple map like before is fine. But this is also okay.
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chartDetails.planets.length,
              itemBuilder: (ctx, index) {
                return _buildPointDisplay(context, chartDetails.planets[index]);
              },
            ),

            // House Cusps as an ExpansionTile
            ExpansionTile(
              title: _buildSectionTitle(
                context,
                "House Cusps (Placidus)",
                noPadding: true,
              ),
              tilePadding:
                  EdgeInsets
                      .zero, // Remove default padding for ExpansionTile title
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              iconColor: Colors.deepPurpleAccent, // Match title color
              collapsedIconColor: Colors.grey.shade400,
              initiallyExpanded: false, // Start collapsed
              children:
                  chartDetails.houseCusps.asMap().entries.map((entry) {
                    int idx = entry.key;
                    AstrologicalPoint cusp = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        // Use cusp.name directly if it's already "1 House Cusp", or format as needed
                        "${idx + 1}. ${cusp.formattedPosition}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20), // Some padding at the bottom
          ],
        ),
      ),
    );
  }
}
