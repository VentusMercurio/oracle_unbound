// lib/widgets/natal_chart_wheel_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/natal_chart_models.dart'; // Your data models
import 'package:sweph/sweph.dart'; // ✅ ADD THIS IMPORT

class NatalChartWheelPainter extends CustomPainter {
  final NatalChartDetails chartDetails;
  // Add glyphs map later: final Map<HeavenlyBody, String> planetGlyphs;

  NatalChartWheelPainter({
    required this.chartDetails /*, required this.planetGlyphs */,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius =
        math.min(centerX, centerY) * 0.9; // 90% of available space
    final Paint paint = Paint();

    // --- 1. Draw Outer Zodiac Ring (Simplified) ---
    paint.color = Colors.blueGrey.shade800;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 20.0; // Width of the zodiac band
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // --- 2. Draw Zodiac Sign Divisions & Labels (Simplified) ---
    final double signAngle = 30.0; // 360 / 12
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final signs = [
      "Ari",
      "Tau",
      "Gem",
      "Can",
      "Leo",
      "Vir",
      "Lib",
      "Sco",
      "Sag",
      "Cap",
      "Aqu",
      "Pis",
    ]; // Abbreviations

    for (int i = 0; i < 12; i++) {
      final double startAngleRad =
          math.pi /
          180 *
          (i * signAngle -
              90 -
              chartDetails
                  .ascendant
                  .longitude); // Offset by ASC for Aries on left
      final double endAngleRad =
          math.pi /
          180 *
          ((i + 1) * signAngle - 90 - chartDetails.ascendant.longitude);

      // Draw division line
      paint.color = Colors.grey.shade600;
      paint.strokeWidth = 1.0;
      canvas.drawLine(
        Offset(
          centerX + (radius - 10) * math.cos(startAngleRad),
          centerY + (radius - 10) * math.sin(startAngleRad),
        ),
        Offset(
          centerX + (radius + 10) * math.cos(startAngleRad),
          centerY + (radius + 10) * math.sin(startAngleRad),
        ),
        paint,
      );

      // Draw sign label (very basic positioning)
      final double midAngleRad = (startAngleRad + endAngleRad) / 2;
      textPainter.text = TextSpan(
        text: signs[i],
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX + (radius) * math.cos(midAngleRad) - textPainter.width / 2,
          centerY + (radius) * math.sin(midAngleRad) - textPainter.height / 2,
        ),
      );
    }

    // --- 3. Draw House Cusp Lines ---
    // ASC is cusp 1. In Placidus, cusp 1 longitude = Ascendant longitude.
    // Aries is 0 degrees. Standard chart wheels often put Aries at the 9 o'clock position (left).
    // So, 0 degrees on our canvas wheel should correspond to the Ascendant's longitude.
    // Angle for drawing = (Point Longitude - Ascendant Longitude)
    // Convert to radians and adjust for canvas coordinates (0 rad is right, positive is CCW).

    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 1.0;
    for (int i = 0; i < 12; i++) {
      double cuspLongitude = chartDetails.houseCusps[i].longitude;
      // Angle relative to Ascendant, converted to radians for drawing
      // -90 degrees or -PI/2 to make 0 degrees (Aries point if ASC=0) point left
      double angleRad =
          math.pi /
          180 *
          (cuspLongitude - chartDetails.ascendant.longitude - 90);

      double innerRadius = radius * 0.3; // Inner circle for house lines
      canvas.drawLine(
        Offset(
          centerX + innerRadius * math.cos(angleRad),
          centerY + innerRadius * math.sin(angleRad),
        ),
        Offset(
          centerX + (radius - 10) * math.cos(angleRad),
          centerY + (radius - 10) * math.sin(angleRad),
        ), // End at inner edge of zodiac band
        paint,
      );
      // Add house numbers later
    }

    // --- 4. Draw ASC/MC Lines (thicker) ---
    paint.color = Colors.white;
    paint.strokeWidth = 2.0;
    // ASC-DSC Line (Horizontal)
    double ascAngleRad =
        math.pi /
        180 *
        (chartDetails.ascendant.longitude -
            chartDetails.ascendant.longitude -
            90); // Should be -PI/2
    canvas.drawLine(
      Offset(
        centerX + radius * math.cos(ascAngleRad),
        centerY + radius * math.sin(ascAngleRad),
      ),
      Offset(
        centerX + radius * math.cos(ascAngleRad + math.pi),
        centerY + radius * math.sin(ascAngleRad + math.pi),
      ),
      paint,
    );
    // MC-IC Line (Vertical-ish)
    double mcAngleRad =
        math.pi /
        180 *
        (chartDetails.midheaven.longitude -
            chartDetails.ascendant.longitude -
            90);
    canvas.drawLine(
      Offset(
        centerX + radius * math.cos(mcAngleRad),
        centerY + radius * math.sin(mcAngleRad),
      ),
      Offset(
        centerX + radius * math.cos(mcAngleRad + math.pi),
        centerY + radius * math.sin(mcAngleRad + math.pi),
      ),
      paint,
    );

    // --- 5. Draw Planets (Simplified - just dots for now) ---
    // Later, replace dots with actual glyphs (TextPainter with symbol font or SVG)
    final Map<HeavenlyBody, Color> planetColors = {
      HeavenlyBody.SE_SUN: Colors.yellowAccent,
      HeavenlyBody.SE_MOON: Colors.grey.shade300,
      HeavenlyBody.SE_MERCURY: Colors.orange,
      HeavenlyBody.SE_VENUS: Colors.pinkAccent,
      HeavenlyBody.SE_MARS: Colors.redAccent,
      HeavenlyBody.SE_JUPITER: Colors.blueAccent,
      HeavenlyBody.SE_SATURN: Colors.brown.shade400,
    };

    for (var planetPoint in chartDetails.planets) {
      if (planetPoint.heavenlyBody == null) continue;

      double planetLongitude = planetPoint.longitude;
      double angleRad =
          math.pi /
          180 *
          (planetLongitude - chartDetails.ascendant.longitude - 90);

      // Position planets somewhere within the house band
      // This needs refinement based on house system and visual preference
      double planetRadius = radius * 0.65; // Example: 65% of the way out

      paint.color = planetColors[planetPoint.heavenlyBody!] ?? Colors.white;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          centerX + planetRadius * math.cos(angleRad),
          centerY + planetRadius * math.sin(angleRad),
        ),
        5,
        paint,
      ); // Draw a 5-pixel dot
    }
  }

  @override
  bool shouldRepaint(covariant NatalChartWheelPainter oldDelegate) {
    return oldDelegate.chartDetails != chartDetails;
  }
}
