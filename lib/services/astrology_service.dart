// lib/services/astrology_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';
import '../models/natal_chart_models.dart';

// ✅ ADD THIS IMPORT for package:timezone
import 'package:timezone/timezone.dart' as tz;
// Note: Ensure tz.initializeTimeZones(); has been called in main.dart

class AstrologyService {
  // ... (initState, isInitialized, dateTimeToJulianDay, _formatLongitude, _getHousePlacement, getPlanetPosition, etc. - keep them as they are) ...
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
    // Ensure this takes a UTC DateTime
    // final utcDateTime = dateTime.toUtc(); // Already expects UTC
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    int second = dateTime.second;
    double milliseconds = dateTime.millisecond / 1000.0;

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
    double normalizedLon = longitudeDegrees % 360.0;
    if (normalizedLon < 0) normalizedLon += 360.0;
    int signIndex = (normalizedLon / 30.0).floor();
    double degreeInSign = normalizedLon % 30.0;
    String formattedString =
        "${degreeInSign.toStringAsFixed(2)}° ${signs[signIndex]}";
    return {
      'sign': signs[signIndex],
      'degreeInSign': degreeInSign,
      'formattedString': formattedString,
    };
  }

  int _getHousePlacement(
    double planetLongitude,
    List<AstrologicalPoint> houseCusps,
  ) {
    if (houseCusps.isEmpty || houseCusps.length < 12) return 0;
    double planetLon = planetLongitude % 360.0;
    if (planetLon < 0) planetLon += 360.0;
    for (int i = 0; i < 12; i++) {
      double cusp1Lon = houseCusps[i].longitude % 360.0;
      if (cusp1Lon < 0) cusp1Lon += 360.0;
      double cusp2Lon = houseCusps[(i + 1) % 12].longitude % 360.0;
      if (cusp2Lon < 0) cusp2Lon += 360.0;
      if (cusp1Lon <= cusp2Lon) {
        if (planetLon >= cusp1Lon && planetLon < cusp2Lon) return i + 1;
      } else {
        if ((planetLon >= cusp1Lon && planetLon < 360.0) ||
            (planetLon >= 0.0 && planetLon < cusp2Lon))
          return i + 1;
      }
    }
    print(
      "Warning: Planet house placement fallback for lon $planetLon. Cusps: ${houseCusps.map((c) => c.longitude.toStringAsFixed(2)).toList()}",
    );
    return 12;
  }

  Future<Map<String, dynamic>?> getPlanetPosition(
    DateTime dateTime,
    HeavenlyBody planet,
  ) async {
    // ... (this method should be fine as is from previous version) ...
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
    // Ensure dateTime is UTC for Julian Day calculation
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
      );
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

  // ✅ MODIFIED: Added timezoneLocationName and timezone conversion logic
  Future<NatalChartDetails?> calculateNatalChart({
    required DateTime
    birthDateTime, // This is the LOCAL date and time from user input
    required double latitude,
    required double longitude,
    required String timezoneLocationName, // ✅ NEW PARAMETER
  }) async {
    if (!_isInitialized) {
      print("AstrologyService not initialized. Cannot calculate natal chart.");
      bool success = await initSweph();
      if (!success) {
        print("Initialization failed during calculateNatalChart.");
        return null;
      }
    }

    // --- 1. Convert Local Birth Time to ACCURATE UTC ---
    DateTime birthDateTimeUTC;
    try {
      // Ensure timezone database is initialized (should be done in main.dart)
      // tz.initializeTimeZones(); // No, this is tz_data.initializeTimeZones(); in main

      final location = tz.getLocation(timezoneLocationName);
      final tz.TZDateTime birthDateTimeInTZ = tz.TZDateTime(
        location,
        birthDateTime.year,
        birthDateTime.month,
        birthDateTime.day,
        birthDateTime.hour,
        birthDateTime.minute,
        birthDateTime.second, // Assuming seconds are 0 if not provided by user
        birthDateTime.millisecond, // Pass milliseconds too
      );
      birthDateTimeUTC = birthDateTimeInTZ.toUtc();
      print(
        "Input Local: $birthDateTime, Timezone: $timezoneLocationName -> Accurate UTC: $birthDateTimeUTC",
      );
    } catch (e, s) {
      print(
        "Error converting to TZDateTime for timezone '$timezoneLocationName': $e",
      );
      print(s);
      print(
        "Falling back to simple .toUtc() for birthDateTime. Results may be inaccurate for historical dates/DST.",
      );
      birthDateTimeUTC = birthDateTime.toUtc(); // Fallback, less accurate
    }

    print(
      "Calculating chart for UTC: $birthDateTimeUTC (Latitude: $latitude, Longitude: $longitude)",
    );
    double julianDayUT = dateTimeToJulianDay(
      birthDateTimeUTC,
    ); // Pass the accurate UTC here

    // --- 2. Calculate House Cusps, Ascendant, MC ---
    // ... (rest of this section remains the same as your correct version)
    HouseCuspData houseData;
    try {
      SwephFlag houseCalcFlags = SwephFlag(SwephFlag.SEFLG_SWIEPH.value);
      houseData = Sweph.swe_houses_ex(
        julianDayUT,
        houseCalcFlags,
        latitude,
        longitude,
        Hsys.P,
      );
    } catch (e, s) {
      print("Error calculating houses: $e");
      print(s);
      return null;
    }

    double ascLongitude = houseData.ascmc[AscmcIndex.SE_ASC.index];
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
    // ... (Planet calculation loop remains the same as your correct version)
    List<HeavenlyBody> bodiesToCalculate = [
      HeavenlyBody.SE_SUN,
      HeavenlyBody.SE_MOON,
      HeavenlyBody.SE_MERCURY,
      HeavenlyBody.SE_VENUS,
      HeavenlyBody.SE_MARS,
      HeavenlyBody.SE_JUPITER,
      HeavenlyBody.SE_SATURN,
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
