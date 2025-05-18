// lib/screens/natal_chart_display_screen.dart
import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:sweph/sweph.dart'; // For HeavenlyBody.SE_SUN.value etc.
import 'package:intl/intl.dart'; // ✅ ADD THIS LINE
import '../models/natal_chart_models.dart';
import '../widgets/natal_chart_wheel_painter.dart'; // For chart drawing
// import '../widgets/video_background_scaffold.dart'; // Option for later

class NatalChartDisplayScreen extends StatefulWidget {
  final NatalChartDetails chartDetails;

  const NatalChartDisplayScreen({super.key, required this.chartDetails});

  @override
  State<NatalChartDisplayScreen> createState() =>
      _NatalChartDisplayScreenState();
}

class _NatalChartDisplayScreenState extends State<NatalChartDisplayScreen> {
  bool _isFetchingInterpretation = false;
  String? _sophiaInterpretation;

  // Using raw integer values from HeavenlyBody.SE_XXX.value for const map keys
  static const Map<int, String> _planetGlyphChars = {
    0: '☉', // HeavenlyBody.SE_SUN
    1: '☽', // HeavenlyBody.SE_MOON
    2: '☿', // HeavenlyBody.SE_MERCURY
    3: '♀', // HeavenlyBody.SE_VENUS
    4: '♂', // HeavenlyBody.SE_MARS
    5: '♃', // HeavenlyBody.SE_JUPITER
    6: '♄', // HeavenlyBody.SE_SATURN
    // Add others if needed and calculated:
    // 7: '♅', // Uranus
    // 8: '♆', // Neptune
    // 9: '♇', // Pluto
    // 11: '☊', // True Node
  };

  static const Map<int, Color> _planetGlyphColors = {
    0: Color(0xFFFFCA28), // Sun (e.g., Colors.amber.shade600)
    1: Color(0xFFB0BEC5), // Moon (e.g., Colors.blueGrey.shade200)
    2: Color(0xFFFFA726), // Mercury (e.g., Colors.orange.shade400)
    3: Color(0xFFF06292), // Venus (e.g., Colors.pinkAccent.shade200)
    4: Color(0xFFEF5350), // Mars (e.g., Colors.red.shade400)
    5: Color(0xFF42A5F5), // Jupiter (e.g., Colors.blue.shade300)
    6: Color(0xFF8D6E63), // Saturn (e.g., Colors.brown.shade400)
    // ... colors for other planets
  };

  Map<String, dynamic> _prepareDataForSophia(NatalChartDetails details) {
    List<Map<String, dynamic>> planetsData =
        details.planets.map((p) {
          return {
            "name": p.name,
            "sign": p.sign,
            "degree": double.parse(p.degreeInSign.toStringAsFixed(2)),
            "house": p.house,
            "isRetrograde": p.isRetrograde ?? false,
            "formatted": p.formattedPosition,
          };
        }).toList();

    return {
      "ascendant": {
        "sign": details.ascendant.sign,
        "degree": double.parse(
          details.ascendant.degreeInSign.toStringAsFixed(2),
        ),
        "formatted": details.ascendant.formattedPosition,
      },
      "midheaven": {
        "sign": details.midheaven.sign,
        "degree": double.parse(
          details.midheaven.degreeInSign.toStringAsFixed(2),
        ),
        "formatted": details.midheaven.formattedPosition,
      },
      "planets": planetsData,
    };
  }

  Future<void> _getSophiaInterpretation() async {
    setState(() {
      _isFetchingInterpretation = true;
      _sophiaInterpretation = null;
    });

    final Map<String, dynamic> requestData = _prepareDataForSophia(
      widget.chartDetails,
    );

    // ✅ CRITICAL: Replace with your actual deployed Next.js API endpoint URL
    final String apiUrl =
        "https://spread-git-main-ventus-mercurios-projects.vercel.app/api/sophia-natal-chart";

    if (apiUrl.contains("YOUR_NEXTJS_SOPHIA_NATAL_CHART_API_ENDPOINT")) {
      // Safety check
      setState(() {
        _sophiaInterpretation =
            "API Endpoint URL not configured in Flutter app.";
        _isFetchingInterpretation = false;
      });
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _sophiaInterpretation =
              responseData['reply'] ??
              "No interpretation content received from Sophia.";
        });
      } else {
        print("Sophia API Error: ${response.statusCode} - ${response.body}");
        setState(() {
          _sophiaInterpretation =
              "Sophia is contemplating the cosmos (Error: ${response.statusCode}). Details: ${response.body.length > 150 ? response.body.substring(0, 150) + "..." : response.body}";
        });
      }
    } catch (e, s) {
      print("Error calling Sophia API: $e\n$s");
      if (!mounted) return;
      setState(() {
        _sophiaInterpretation =
            "A cosmic disturbance interrupted our connection to Sophia: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isFetchingInterpretation = false;
      });
    }
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool noPadding = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: noPadding ? 0 : 20.0, bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  Widget _buildPointDisplay(BuildContext context, AstrologicalPoint point) {
    String glyphString = "";
    Color glyphColor = Colors.white;

    if (point.heavenlyBody != null &&
        _planetGlyphChars.containsKey(point.heavenlyBody!.value)) {
      glyphString = "${_planetGlyphChars[point.heavenlyBody!.value]!} ";
      glyphColor =
          _planetGlyphColors[point.heavenlyBody!.value] ?? Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Colors.white),
          children: <TextSpan>[
            if (glyphString.isNotEmpty)
              TextSpan(
                text: glyphString,
                style: GoogleFonts.notoSans(fontSize: 16, color: glyphColor),
              ),
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
    final double chartSize = screenWidth * 0.60;

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
            _buildSectionTitle(context, "Birth Details", noPadding: true),
            Text(
              "Date & Time: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.chartDetails.birthDateTimeUTC.toLocal())} (Local Est.)",
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "Location: Lat ${widget.chartDetails.latitude.toStringAsFixed(4)}, Lon ${widget.chartDetails.longitude.toStringAsFixed(4)}",
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 24),

            Center(
              child: Container(
                height: chartSize,
                width: chartSize,
                child: CustomPaint(
                  painter: NatalChartWheelPainter(
                    chartDetails: widget.chartDetails,
                  ),
                  size: Size(chartSize, chartSize),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, "Key Points"),
            _buildPointDisplay(context, widget.chartDetails.ascendant),
            _buildPointDisplay(context, widget.chartDetails.midheaven),

            _buildSectionTitle(context, "Planets"),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.chartDetails.planets.length,
              itemBuilder: (ctx, index) {
                return _buildPointDisplay(
                  context,
                  widget.chartDetails.planets[index],
                );
              },
            ),

            ExpansionTile(
              title: _buildSectionTitle(
                context,
                "House Cusps (Placidus)",
                noPadding: true,
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              iconColor: Colors.deepPurpleAccent,
              collapsedIconColor: Colors.grey.shade400,
              initiallyExpanded: false,
              children:
                  widget.chartDetails.houseCusps.asMap().entries.map((entry) {
                    int idx = entry.key;
                    AstrologicalPoint cusp = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        "${idx + 1}. ${cusp.formattedPosition}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade700.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    _isFetchingInterpretation ? null : _getSophiaInterpretation,
                child:
                    _isFetchingInterpretation
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text("Get Sophia's Insight"),
              ),
            ),
            const SizedBox(height: 16),
            if (_sophiaInterpretation != null)
              Card(
                color: Colors.black.withOpacity(
                  0.4,
                ), // Even more subtle background for text card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.tealAccent.withOpacity(0.3),
                  ), // Subtle border
                ),
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sophia's Insight:",
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.tealAccent.shade100,
                        ),
                      ),
                      Divider(
                        color: Colors.tealAccent.shade100.withOpacity(0.5),
                        height: 20,
                        thickness: 0.5,
                      ),
                      SelectableText(
                        _sophiaInterpretation!,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.6,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
