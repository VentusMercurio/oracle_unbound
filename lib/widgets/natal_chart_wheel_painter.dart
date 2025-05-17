// lib/widgets/natal_chart_wheel_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sweph/sweph.dart'; // For HeavenlyBody enum
import '../models/natal_chart_models.dart';

class NatalChartWheelPainter extends CustomPainter {
  final NatalChartDetails chartDetails;

  // ... (TextStyles and Glyph/Color Maps are THE SAME as your provided correct version)
  final TextStyle planetGlyphStyle = GoogleFonts.notoSans(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );
  final TextStyle zodiacGlyphStyle = GoogleFonts.notoSans(
    fontSize: 12,
    color: Colors.grey.shade400,
  );
  final TextStyle degreeTextStyle = GoogleFonts.roboto(
    fontSize: 9,
    color: Colors.grey.shade300,
  );
  final TextStyle angleLabelStyle = GoogleFonts.roboto(
    fontSize: 10,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  static const Map<int, String> planetGlyphChars = {
    0: '☉',
    1: '☽',
    2: '☿',
    3: '♀',
    4: '♂',
    5: '♃',
    6: '♄',
    7: '♅',
    8: '♆',
    9: '♇',
    11: '☊',
  };

  static Map<int, Color> getPlanetColors(BuildContext? context) {
    return {
      0: Colors.yellowAccent.shade400,
      1: Colors.grey.shade300,
      2: Colors.orange.shade300,
      3: Colors.pinkAccent.shade100,
      4: Colors.redAccent.shade200,
      5: Colors.blueAccent.shade100,
      6: Colors.brown.shade300,
    };
  }

  static const List<String> zodiacSignNames = [
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
  ];
  static const List<String> zodiacGlyphChars = [
    "♈",
    "♉",
    "♊",
    "♋",
    "♌",
    "♍",
    "♎",
    "♏",
    "♐",
    "♑",
    "♒",
    "♓",
  ];

  NatalChartWheelPainter({required this.chartDetails});

  void _drawText(
    Canvas canvas,
    Offset position,
    String text,
    TextStyle style, {
    TextAlign textAlign = TextAlign.center,
    double maxWidth = 200,
  }) {
    // ... (This helper method is THE SAME as your provided correct version)
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    final Offset centeredPosition;
    if (textAlign == TextAlign.center) {
      centeredPosition = Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      );
    } else if (textAlign == TextAlign.right) {
      centeredPosition = Offset(
        position.dx - textPainter.width,
        position.dy - textPainter.height / 2,
      );
    } else {
      centeredPosition = Offset(
        position.dx,
        position.dy - textPainter.height / 2,
      );
    }
    textPainter.paint(canvas, centeredPosition);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double chartRadius = math.min(centerX, centerY) * 0.95;
    final double zodiacGlyphRadius = chartRadius;
    final double zodiacBandOuterRadius = chartRadius * 0.92;
    final double zodiacBandInnerRadius = chartRadius * 0.80;
    final double houseNumberRadius = zodiacBandInnerRadius * 0.92;
    final double planetRingRadius = zodiacBandInnerRadius * 0.65;
    final double centerCircleRadius = zodiacBandInnerRadius * 0.15;

    final Paint linePaint = Paint()..style = PaintingStyle.stroke;
    final Map<int, Color> currentPlanetColors = getPlanetColors(null);

    // --- 1. Draw Outer Zodiac Ring & Sign Glyphs/Divisions ---

    // ✅ MODIFIED: Draw Zodiac Band with a SweepGradient
    final Rect zodiacRect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius:
          (zodiacBandOuterRadius + zodiacBandInnerRadius) /
          2, // Mid-radius of the band
    );

    final Paint gradientPaint =
        Paint()
          ..shader = SweepGradient(
            center:
                Alignment
                    .center, // Default, equivalent to Offset(centerX, centerY) in this context
            // Define your mystical/vibrant colors
            colors: [
              Colors.indigo.shade700,
              Colors.deepPurple.shade700,
              Colors.pinkAccent.shade400,
              Colors.purple.shade700,
              Colors.blue.shade800,
              Colors.indigo.shade700, // Loop back for smooth sweep
            ],
            // Define stops for color transitions (must match length of colors list)
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            // Optional: Rotate the gradient if needed
            // transform: const GradientRotation(math.pi / 2), // Example: rotate by 90 degrees
          ).createShader(
            zodiacRect,
          ); // Create shader based on the band's rectangle

    gradientPaint.style = PaintingStyle.stroke;
    gradientPaint.strokeWidth =
        zodiacBandOuterRadius - zodiacBandInnerRadius; // Thickness of the band
    canvas.drawCircle(
      Offset(centerX, centerY),
      (zodiacBandOuterRadius + zodiacBandInnerRadius) / 2, // Draw at mid-radius
      gradientPaint,
    );
    // --- End of Gradient Zodiac Band ---

    // The rest of the drawing for zodiac divisions and glyphs remains the same,
    // but ensure their colors contrast well with the new gradient background.
    final double signAngleDegrees = 30.0;
    for (int i = 0; i < 12; i++) {
      final double lineAngleRad =
          math.pi /
          180 *
          (i * signAngleDegrees - 90 - chartDetails.ascendant.longitude);
      final double glyphAngleRad =
          math.pi /
          180 *
          (i * signAngleDegrees +
              signAngleDegrees / 2 -
              90 -
              chartDetails.ascendant.longitude);

      // Draw division line - make it lighter to show against gradient
      linePaint.color = Colors.white.withOpacity(
        0.3,
      ); // ✅ Light, semi-transparent line
      linePaint.strokeWidth = 0.8;
      canvas.drawLine(
        Offset(
          centerX + zodiacBandInnerRadius * math.cos(lineAngleRad),
          centerY + zodiacBandInnerRadius * math.sin(lineAngleRad),
        ),
        Offset(
          centerX + zodiacBandOuterRadius * math.cos(lineAngleRad),
          centerY + zodiacBandOuterRadius * math.sin(lineAngleRad),
        ),
        linePaint,
      );

      // Draw Zodiac Sign Glyph - ensure color contrasts with gradient
      _drawText(
        canvas,
        Offset(
          centerX +
              ((zodiacBandOuterRadius + zodiacBandInnerRadius) / 2) *
                  math.cos(glyphAngleRad), // Centered in the band
          centerY +
              ((zodiacBandOuterRadius + zodiacBandInnerRadius) / 2) *
                  math.sin(glyphAngleRad),
        ),
        zodiacGlyphChars[i],
        // ✅ Ensure glyph color is visible on gradient, e.g., brighter white
        zodiacGlyphStyle.copyWith(
          fontSize: (zodiacBandOuterRadius - zodiacBandInnerRadius) * 0.45,
          color: Colors.white.withOpacity(0.8),
        ),
      );
    }

    // --- 2. Draw House Cusp Lines & Numbers ---
    // (This section is THE SAME as your provided correct version)
    // ...
    linePaint.color = Colors.grey.shade600; // Reset color for house lines
    linePaint.strokeWidth = 0.7;
    for (int i = 0; i < 12; i++) {
      double cuspLongitude = chartDetails.houseCusps[i].longitude;
      double angleRad =
          math.pi /
          180 *
          (cuspLongitude - chartDetails.ascendant.longitude - 90);
      canvas.drawLine(
        Offset(
          centerX + centerCircleRadius * math.cos(angleRad),
          centerY + centerCircleRadius * math.sin(angleRad),
        ),
        Offset(
          centerX + zodiacBandInnerRadius * math.cos(angleRad),
          centerY + zodiacBandInnerRadius * math.sin(angleRad),
        ),
        linePaint,
      );

      double nextCuspLongitude =
          chartDetails.houseCusps[(i + 1) % 12].longitude;
      double midHouseAngleDeg = (cuspLongitude + nextCuspLongitude) / 2;
      if ((nextCuspLongitude < cuspLongitude) &&
          (cuspLongitude > 180 && nextCuspLongitude < 180)) {
        midHouseAngleDeg = (cuspLongitude + (nextCuspLongitude + 360)) / 2;
      }
      if (midHouseAngleDeg >= 360) midHouseAngleDeg -= 360;

      double midHouseAngleRad =
          math.pi /
          180 *
          (midHouseAngleDeg - chartDetails.ascendant.longitude - 90);
      _drawText(
        canvas,
        Offset(
          centerX + houseNumberRadius * math.cos(midHouseAngleRad),
          centerY + houseNumberRadius * math.sin(midHouseAngleRad),
        ),
        (i + 1).toString(),
        degreeTextStyle.copyWith(fontSize: 10, color: Colors.grey.shade500),
      );
    }

    // --- 3. Draw ASC/MC Lines (thicker) ---
    // (This section is THE SAME as your provided correct version)
    // ...
    linePaint.color = Colors.white.withOpacity(0.9);
    linePaint.strokeWidth = 1.5;
    double ascPlotAngleRad = math.pi / 180 * (-90);
    canvas.drawLine(
      Offset(
        centerX + zodiacBandOuterRadius * math.cos(ascPlotAngleRad),
        centerY + zodiacBandOuterRadius * math.sin(ascPlotAngleRad),
      ),
      Offset(
        centerX - zodiacBandOuterRadius * math.cos(ascPlotAngleRad),
        centerY - zodiacBandOuterRadius * math.sin(ascPlotAngleRad),
      ),
      linePaint,
    );
    _drawText(
      canvas,
      Offset(
        centerX + (zodiacBandOuterRadius + 12) * math.cos(ascPlotAngleRad),
        centerY + (zodiacBandOuterRadius + 12) * math.sin(ascPlotAngleRad),
      ),
      "ASC",
      angleLabelStyle,
    );

    double mcPlotAngleRad =
        math.pi /
        180 *
        (chartDetails.midheaven.longitude -
            chartDetails.ascendant.longitude -
            90);
    canvas.drawLine(
      Offset(
        centerX + zodiacBandOuterRadius * math.cos(mcPlotAngleRad),
        centerY + zodiacBandOuterRadius * math.sin(mcPlotAngleRad),
      ),
      Offset(
        centerX - zodiacBandOuterRadius * math.cos(mcPlotAngleRad),
        centerY - zodiacBandOuterRadius * math.sin(mcPlotAngleRad),
      ),
      linePaint,
    );
    _drawText(
      canvas,
      Offset(
        centerX + (zodiacBandOuterRadius + 12) * math.cos(mcPlotAngleRad),
        centerY + (zodiacBandOuterRadius + 12) * math.sin(mcPlotAngleRad),
      ),
      "MC",
      angleLabelStyle,
    );

    // --- 4. Draw Planets with Glyphs, Degrees, and Rx ---
    // (This section is THE SAME as your provided correct version)
    // ...
    for (var planetPoint in chartDetails.planets) {
      if (planetPoint.heavenlyBody == null ||
          planetGlyphChars[planetPoint.heavenlyBody!.value] == null)
        continue;

      String glyph = planetGlyphChars[planetPoint.heavenlyBody!.value]!;
      double planetLongitude = planetPoint.longitude;
      double angleRad =
          math.pi /
          180 *
          (planetLongitude - chartDetails.ascendant.longitude - 90);

      Color planetColor =
          currentPlanetColors[planetPoint.heavenlyBody!.value] ?? Colors.white;

      _drawText(
        canvas,
        Offset(
          centerX + planetRingRadius * math.cos(angleRad),
          centerY + planetRingRadius * math.sin(angleRad),
        ),
        glyph,
        planetGlyphStyle.copyWith(color: planetColor),
      );

      String degreeSignGlyph =
          zodiacGlyphChars[zodiacSignNames.indexOf(planetPoint.sign)];
      String degreeRetroText =
          "${planetPoint.degreeInSign.floor()}°$degreeSignGlyph${planetPoint.isRetrograde == true ? " Rx" : ""}";
      _drawText(
        canvas,
        Offset(
          centerX +
              (planetRingRadius + planetGlyphStyle.fontSize! * 1.1) *
                  math.cos(angleRad),
          centerY +
              (planetRingRadius + planetGlyphStyle.fontSize! * 1.1) *
                  math.sin(angleRad),
        ),
        degreeRetroText,
        degreeTextStyle,
      );
    }

    // --- 5. Draw Center Circle ---
    // (This section is THE SAME as your provided correct version)
    // ...
    linePaint.style = PaintingStyle.fill;
    linePaint.color = Colors.black; // Assuming your chart background is black
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);
    linePaint.style = PaintingStyle.stroke;
    linePaint.color = Colors.grey.shade800;
    linePaint.strokeWidth = 1.0;
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);
  }

  @override
  bool shouldRepaint(covariant NatalChartWheelPainter oldDelegate) {
    return oldDelegate.chartDetails != chartDetails;
  }
}
