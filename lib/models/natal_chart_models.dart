// lib/models/natal_chart_models.dart
import 'package:sweph/sweph.dart'; // For HeavenlyBody enum

class AstrologicalPoint {
  final String name; // e.g., "Sun", "Moon", "Ascendant", "MC", "1st House Cusp"
  final HeavenlyBody? heavenlyBody; // Null for Asc, MC, Cusps
  final double longitude; // 0-359.99 degrees
  final String sign;
  final double degreeInSign;
  final String formattedPosition; // e.g., "15°30' Aries" or "15.50 Aries"
  final int?
  house; // Which house the point (if it's a planet) is in. Null for cusps.
  final bool? isRetrograde; // Null for non-planets

  AstrologicalPoint({
    required this.name,
    this.heavenlyBody,
    required this.longitude,
    required this.sign,
    required this.degreeInSign,
    required this.formattedPosition,
    this.house,
    this.isRetrograde,
  });

  @override
  String toString() {
    return '$name: $formattedPosition' +
        (house != null ? ' (House $house)' : '') +
        (isRetrograde == true ? ' Rx' : '');
  }
}

class NatalChartDetails {
  final DateTime birthDateTimeUTC;
  final double latitude;
  final double longitude;
  final AstrologicalPoint ascendant;
  final AstrologicalPoint midheaven;
  final List<AstrologicalPoint>
  houseCusps; // List of 12 AstrologicalPoint objects for cusps
  final List<AstrologicalPoint>
  planets; // List of AstrologicalPoint objects for planets

  NatalChartDetails({
    required this.birthDateTimeUTC,
    required this.latitude,
    required this.longitude,
    required this.ascendant,
    required this.midheaven,
    required this.houseCusps,
    required this.planets,
  });
}
