// lib/services/astrology_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math'; // For PI, sin, cos, atan2 if doing advanced house position logic manually

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart'; // Import the sweph package

// ✅ Import your new model classes
import '../models/natal_chart_models.dart'; // Adjust path if models are elsewhere

class AstrologyService {
  bool _isInitialized = false;
  String _ephePath = '';

  Future<bool> initSweph() async {
    if (_isInitialized) return true;

    try {
      print('Initializing Sweph (vm75/sweph.dart)...');
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      _ephePath = '${appDocDir.path}/ephe_vm75_sweph';
      final Directory epheDir = Directory(_ephePath);

      if (!await epheDir.exists()) {
        await epheDir.create(recursive: true);
        print('Created ephemeris directory: $_ephePath');
      }

      final List<String> epheFilesToCopy = [
        'sepl_18.se1',
        'semo_18.se1',
        'seas_18.se1',
      ];
      for (String filename in epheFilesToCopy) {
        final String assetPath = 'assets/ephe/$filename';
        final String localPath = '$_ephePath/$filename';
        final File localFile = File(localPath);
        if (!await localFile.exists()) {
          print('Copying $filename from app assets to $localPath...');
          final ByteData data = await rootBundle.load(assetPath);
          final List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await localFile.writeAsBytes(bytes, flush: true);
          print('Copied $filename.');
        } else {
          print('$filename already exists at $localPath.');
        }
      }

      print('Calling Sweph.init() with epheFilesPath: $_ephePath');
      await Sweph.init(epheFilesPath: _ephePath);
      print('Sweph.init() called.');

      Sweph.swe_set_ephe_path(_ephePath);
      print(
        'Sweph (vm75) C library ephemeris path explicitly set to: $_ephePath',
      );

      String version = Sweph.swe_version();
      print('Sweph (vm75) Library Version: $version');
      if (version.isEmpty) {
        print(
          'Warning: Sweph.swe_version() returned empty. Initialization may have failed despite Sweph.init().',
        );
        _isInitialized = false;
        return false;
      }

      _isInitialized = true;
      print('Sweph (vm75) initialized successfully.');
      return true;
    } catch (e, s) {
      print('Error initializing Sweph (vm75): $e');
      print('Stack trace: $s');
      _isInitialized = false;
      return false;
    }
  }

  bool get isInitialized => _isInitialized;

  double dateTimeToJulianDay(DateTime dateTime) {
    final utcDateTime = dateTime.toUtc();
    int year = utcDateTime.year;
    int month = utcDateTime.month;
    int day = utcDateTime.day;
    int hour = utcDateTime.hour;
    int minute = utcDateTime.minute;
    int second = utcDateTime.second;
    double milliseconds = utcDateTime.millisecond / 1000.0;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int a = year ~/ 100;
    int b = 2 - a + (a ~/ 4);
    double jdDay =
        (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
    double jdFraction =
        (hour + (minute / 60.0) + (second / 3600.0) + (milliseconds / 3600.0)) /
        24.0;
    return jdDay + jdFraction;
  }

  // ✅ ADDED: Helper function to format longitude into Sign, Degree, and Formatted String
  Map<String, dynamic> _formatLongitude(double longitudeDegrees) {
    final signs = [
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

    // Normalize longitude to be 0 <= lon < 360
    double normalizedLon = longitudeDegrees % 360.0;
    if (normalizedLon < 0) {
      normalizedLon += 360.0;
    }

    int signIndex = (normalizedLon / 30.0).floor();
    double degreeInSign = normalizedLon % 30.0;

    int degPart = degreeInSign.floor();
    double minDecimal = (degreeInSign - degPart) * 60.0;
    int minPart = minDecimal.floor();
    // String formattedString = "${degPart.toString().padLeft(2, ' ')}° ${minPart.toString().padLeft(2, '0')}' ${signs[signIndex]}";
    String formattedString =
        "${degreeInSign.toStringAsFixed(2)}° ${signs[signIndex]}"; // Simpler decimal format

    return {
      'sign': signs[signIndex],
      'degreeInSign':
          degreeInSign, // Could return degPart for just whole degrees
      'formattedString': formattedString,
    };
  }

  // ✅ ADDED: Function to determine house placement (can be improved for edge cases/precision)
  int _getHousePlacement(
    double planetLongitude,
    List<AstrologicalPoint> houseCusps,
  ) {
    if (houseCusps.isEmpty || houseCusps.length < 12)
      return 0; // Should not happen

    double planetLon = planetLongitude % 360.0;
    if (planetLon < 0) planetLon += 360.0;

    for (int i = 0; i < 12; i++) {
      double cusp1Lon = houseCusps[i].longitude % 360.0;
      if (cusp1Lon < 0) cusp1Lon += 360.0;

      double cusp2Lon = houseCusps[(i + 1) % 12].longitude % 360.0;
      if (cusp2Lon < 0) cusp2Lon += 360.0;

      // Handle wrap-around (e.g., 12th house cusp might be 330°, 1st house cusp 20°)
      if (cusp1Lon <= cusp2Lon) {
        // Normal case, e.g. cusp1=30, cusp2=60
        if (planetLon >= cusp1Lon && planetLon < cusp2Lon) {
          return i + 1;
        }
      } else {
        // Wrap-around case, e.g. cusp1=330 (12th), cusp2=20 (1st)
        if ((planetLon >= cusp1Lon && planetLon < 360.0) ||
            (planetLon >= 0.0 && planetLon < cusp2Lon)) {
          return i + 1;
        }
      }
    }
    // Fallback, should ideally not be reached if cusps are correctly ordered
    // This can happen if planet longitude is exactly on a cusp, depending on strict inequality.
    // For simplicity, defaulting to 12th if no other house is found.
    print(
      "Warning: Planet house placement fallback for lon $planetLon. Cusps: ${houseCusps.map((c) => c.longitude.toStringAsFixed(2)).toList()}",
    );
    return 12;
  }

  // Existing method, no changes needed here other than type hint for planet
  Future<Map<String, dynamic>?> getPlanetPosition(
    DateTime dateTime,
    HeavenlyBody planet,
  ) async {
    if (!_isInitialized) {
      print(
        'Sweph (vm75) not initialized in getPlanetPosition. Attempting to initialize...',
      );
      bool success = await initSweph();
      if (!success) {
        print(
          'Failed to initialize Sweph (vm75) in getPlanetPosition. Cannot calculate.',
        );
        return null;
      }
    }
    double julianDayUT = dateTimeToJulianDay(dateTime.toUtc());
    final SwephFlag calculationFlags = SwephFlag(
      SwephFlag.SEFLG_SWIEPH.value | SwephFlag.SEFLG_SPEED.value,
    );
    try {
      CoordinatesWithSpeed positionData = Sweph.swe_calc_ut(
        julianDayUT,
        planet,
        calculationFlags,
      );
      return {
        'longitude': positionData.longitude,
        'latitude': positionData.latitude,
        'distance_au': positionData.distance,
        'speed_longitude_per_day': positionData.speedInLongitude,
        'speed_latitude_per_day': positionData.speedInLatitude,
        'speed_distance_per_day': positionData.speedInDistance,
        'julian_day_ut': julianDayUT,
      };
    } catch (e, s) {
      print(
        'Error in getPlanetPosition for ${Sweph.swe_get_planet_name(planet)}: $e',
      ); // Use Sweph.swe_get_planet_name
      print('Stack trace: $s');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSunPosition(DateTime dateTime) async {
    return getPlanetPosition(dateTime, HeavenlyBody.SE_SUN);
  }

  Future<Map<String, dynamic>?> getMoonPosition(DateTime dateTime) async {
    return getPlanetPosition(dateTime, HeavenlyBody.SE_MOON);
  }

  // ✅ NEW METHOD: Calculate Full Natal Chart Details
  Future<NatalChartDetails?> calculateNatalChart({
    required DateTime birthDateTime, // User's local birth date and time
    required double latitude,
    required double longitude,
    // required String timezoneLocationName, // For later robust TZ conversion
  }) async {
    if (!_isInitialized) {
      print("AstrologyService not initialized. Cannot calculate natal chart.");
      bool success = await initSweph();
      if (!success) {
        print("Initialization failed during calculateNatalChart.");
        return null;
      }
    }

    // --- 1. Convert Local Birth Time to UTC ---
    // TEMPORARY: Using simple .toUtc(). For production, use 'package:timezone'.
    DateTime birthDateTimeUTC = birthDateTime.toUtc();
    print(
      "Calculating chart for UTC: $birthDateTimeUTC (Latitude: $latitude, Longitude: $longitude)",
    );

    double julianDayUT = dateTimeToJulianDay(birthDateTimeUTC);

    // --- 2. Calculate House Cusps, Ascendant, MC ---
    HouseCuspData houseData;
    try {
      // Standard flags for houses: Swiss Ephemeris, geocentric.
      // Topocentric (SEFLG_TOPOCTR) might be used by some for houses/angles, but geocentric is common.
      SwephFlag houseCalcFlags = SwephFlag(
        SwephFlag.SEFLG_SWIEPH.value,
      ); // Default geo
      houseData = Sweph.swe_houses_ex(
        julianDayUT,
        houseCalcFlags,
        latitude,
        longitude,
        Hsys.P,
      ); // Hsys.P for Placidus
    } catch (e, s) {
      print("Error calculating houses: $e");
      print(s);
      return null;
    }

    double ascLongitude =
        houseData.ascmc[AscmcIndex.SE_ASC.index]; // Use enum index for safety
    double mcLongitude = houseData.ascmc[AscmcIndex.SE_MC.index];

    var ascFormatted = _formatLongitude(ascLongitude);
    AstrologicalPoint ascendant = AstrologicalPoint(
      name: "Ascendant",
      longitude: ascLongitude,
      sign: ascFormatted['sign'],
      degreeInSign: ascFormatted['degreeInSign'],
      formattedPosition: ascFormatted['formattedString'],
    );

    var mcFormatted = _formatLongitude(mcLongitude);
    AstrologicalPoint midheaven = AstrologicalPoint(
      name: "Midheaven",
      longitude: mcLongitude,
      sign: mcFormatted['sign'],
      degreeInSign: mcFormatted['degreeInSign'],
      formattedPosition: mcFormatted['formattedString'],
    );

    List<AstrologicalPoint> houseCusps = [];
    // houseData.cusps array contains 13 doubles for Placidus. cusps[0] is house 1, cusps[1] is house 2, ..., cusps[11] is house 12.
    // cusps[12] is not used or is identical to cusps[0] for some systems. We need 12 cusps.
    for (int i = 0; i < 12; i++) {
      double cuspLongitude = houseData.cusps[i];
      var cuspFormatted = _formatLongitude(cuspLongitude);
      houseCusps.add(
        AstrologicalPoint(
          name: "${i + 1} House Cusp",
          longitude: cuspLongitude,
          sign: cuspFormatted['sign'],
          degreeInSign: cuspFormatted['degreeInSign'],
          formattedPosition: cuspFormatted['formattedString'],
        ),
      );
    }

    // --- 3. Calculate Planet Positions ---
    List<HeavenlyBody> bodiesToCalculate = [
      HeavenlyBody.SE_SUN, HeavenlyBody.SE_MOON, HeavenlyBody.SE_MERCURY,
      HeavenlyBody.SE_VENUS, HeavenlyBody.SE_MARS, HeavenlyBody.SE_JUPITER,
      HeavenlyBody.SE_SATURN,
      // You can add Uranus, Neptune, Pluto, True Node later:
      // HeavenlyBody.SE_URANUS, HeavenlyBody.SE_NEPTUNE, HeavenlyBody.SE_PLUTO,
      // HeavenlyBody.SE_TRUE_NODE,
    ];

    List<AstrologicalPoint> planets = [];
    final SwephFlag planetCalcFlags = SwephFlag(
      SwephFlag.SEFLG_SWIEPH.value | SwephFlag.SEFLG_SPEED.value,
    );

    for (HeavenlyBody body in bodiesToCalculate) {
      try {
        CoordinatesWithSpeed positionData = Sweph.swe_calc_ut(
          julianDayUT,
          body,
          planetCalcFlags,
        );
        var planetFormatted = _formatLongitude(positionData.longitude);
        bool isRetrograde = positionData.speedInLongitude < 0;
        int houseNumber = _getHousePlacement(
          positionData.longitude,
          houseCusps,
        );

        planets.add(
          AstrologicalPoint(
            name: Sweph.swe_get_planet_name(body),
            heavenlyBody: body,
            longitude: positionData.longitude,
            sign: planetFormatted['sign'],
            degreeInSign: planetFormatted['degreeInSign'],
            formattedPosition: planetFormatted['formattedString'],
            house: houseNumber,
            isRetrograde: isRetrograde,
          ),
        );
      } catch (e, s) {
        print("Error calculating ${Sweph.swe_get_planet_name(body)}: $e");
        print(s);
        // Add a placeholder to maintain list structure if a planet calculation fails
        var errorFormatted = _formatLongitude(0);
        planets.add(
          AstrologicalPoint(
            name: "${Sweph.swe_get_planet_name(body)} (Error)",
            heavenlyBody: body,
            longitude: 0,
            sign: errorFormatted['sign'],
            degreeInSign: errorFormatted['degreeInSign'],
            formattedPosition: "Error",
            house: 0,
            isRetrograde: false,
          ),
        );
      }
    }

    return NatalChartDetails(
      birthDateTimeUTC: birthDateTimeUTC,
      latitude: latitude,
      longitude: longitude,
      ascendant: ascendant,
      midheaven: midheaven,
      houseCusps: houseCusps,
      planets: planets,
    );
  }
}
