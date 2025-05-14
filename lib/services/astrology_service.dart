// lib/services/astrology_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart'; // Import the new package

class AstrologyService {
  bool _isInitialized = false;
  String _ephePath = '';

  Future<bool> initSweph() async {
    if (_isInitialized) return true;

    try {
      print('Initializing Sweph (vm75/sweph.dart)...');
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      // Using a directory name that indicates it's for this specific package version/source
      _ephePath = '${appDocDir.path}/ephe_vm75_sweph';
      final Directory epheDir = Directory(_ephePath);

      if (!await epheDir.exists()) {
        await epheDir.create(recursive: true);
        print('Created ephemeris directory: $_ephePath');
      }

      final List<String> epheFilesToCopy = ['sepl_18.se1', 'semo_18.se1', 'seas_18.se1'];
      for (String filename in epheFilesToCopy) {
        final String assetPath = 'assets/ephe/$filename';
        final String localPath = '$_ephePath/$filename';
        final File localFile = File(localPath);
        if (!await localFile.exists()) {
          print('Copying $filename from app assets to $localPath...');
          final ByteData data = await rootBundle.load(assetPath);
          final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await localFile.writeAsBytes(bytes, flush: true);
          print('Copied $filename.');
        } else {
          print('$filename already exists at $localPath.');
        }
      }

      // According to vm75/sweph.dart, Sweph.init() should be called.
      // It handles loading the native library (WASM or FFI).
      // We provide epheFilesPath so it knows where our manually copied files are.
      // If epheAssets is empty, it shouldn't try to load/copy from package assets.
      print('Calling Sweph.init() with epheFilesPath: $_ephePath');
      await Sweph.init(
          epheFilesPath: _ephePath // Tells Sweph where ephemeris files are located
          // We are not using modulePath as sweph.dart doc says for ffi-plugin it should be null
          // and Sweph.init handles it.
          // We are not using epheAssets or assetLoader as we copy files manually.
          );
      print('Sweph.init() called.');

      // After Sweph.init(), we then tell the *underlying Swiss Ephemeris C library*
      // the exact path to use for ephemeris files. Sweph.init might set up an internal
      // default path, but this ensures it uses our specific copied location.
      Sweph.swe_set_ephe_path(_ephePath);
      print('Sweph (vm75) C library ephemeris path explicitly set to: $_ephePath');

      String version = Sweph.swe_version();
      print('Sweph (vm75) Library Version: $version');
      if (version.isEmpty) {
        print('Warning: Sweph.swe_version() returned empty. Initialization may have failed despite Sweph.init().');
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

    if (month <= 2) { year -= 1; month += 12; }
    int a = year ~/ 100;
    int b = 2 - a + (a ~/ 4);
    double jdDay = (365.25 * (year + 4716)).floorToDouble() +
                   (30.6001 * (month + 1)).floorToDouble() +
                   day + b - 1524.5;
    double jdFraction = (hour + (minute / 60.0) + (second / 3600.0) + (milliseconds / 3600.0)) / 24.0;
    return jdDay + jdFraction;
  }

  Future<Map<String, dynamic>?> getPlanetPosition(DateTime dateTime, HeavenlyBody planet) async {
    if (!_isInitialized) {
      print('Sweph (vm75) not initialized in getPlanetPosition. Attempting to initialize...');
      bool success = await initSweph();
      if (!success) {
        print('Failed to initialize Sweph (vm75) in getPlanetPosition. Cannot calculate.');
        return null;
      }
    }

    double julianDayUT = dateTimeToJulianDay(dateTime);

    // Define flags:
    // SEFLG_SWIEPH (use Swiss Ephemeris files) is value 2.
    // SEFLG_SPEED (calculate speed) is value 256.
    // The SwephFlag constructor takes an int. We combine flags using bitwise OR.
    final SwephFlag calculationFlags = SwephFlag(SwephFlag.SEFLG_SWIEPH.value | SwephFlag.SEFLG_SPEED.value);

    try {
      CoordinatesWithSpeed positionData = Sweph.swe_calc_ut(
        julianDayUT,
        planet, // Pass the HeavenlyBody enum value directly
        calculationFlags, // Pass the SwephFlag object
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
      print('Error in getPlanetPosition for ${planet.toString()}: $e');
      print('Stack trace: $s');
      if (e.toString().toLowerCase().contains("ephemeris file") && e.toString().toLowerCase().contains("not found")) {
         print("Ensure the ephemeris file for planet is in $_ephePath and accessible by the Sweph C library.");
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSunPosition(DateTime dateTime) async {
    return getPlanetPosition(dateTime, HeavenlyBody.SE_SUN);
  }

  Future<Map<String, dynamic>?> getMoonPosition(DateTime dateTime) async {
    return getPlanetPosition(dateTime, HeavenlyBody.SE_MOON);
  }

  // You can add more:
  // Future<Map<String, dynamic>?> getMercuryPosition(DateTime dateTime) async {
  //   return getPlanetPosition(dateTime, HeavenlyBody.SE_MERCURY);
  // }
}