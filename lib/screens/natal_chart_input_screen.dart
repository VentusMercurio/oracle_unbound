// lib/screens/natal_chart_input_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts

import '../widgets/video_background_scaffold.dart'; // Your reusable video background
import 'natal_chart_display_screen.dart';
import '../services/astrology_service.dart';
import '../main.dart';
import '../models/natal_chart_models.dart';

class NatalChartInputScreen extends StatefulWidget {
  const NatalChartInputScreen({super.key});

  @override
  State<NatalChartInputScreen> createState() => _NatalChartInputScreenState();
}

class _NatalChartInputScreenState extends State<NatalChartInputScreen> {
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationStringController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _timezoneController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  bool _isFindingLocation = false;

  // ✅ REMEMBER TO REPLACE WITH YOUR ACTUAL TIMEZONEDB API KEY
  final String _timezonedbApiKey = "FMTI03MRT3QS";

  @override
  void initState() {
    super.initState();
    _dateController.text = "1990-07-15";
    _timeController.text = "14:30";
    _locationStringController.text = "Los Angeles, CA, USA";
    _latitudeController.text = "34.0522";
    _longitudeController.text = "-118.2437";
    _timezoneController.text = "America/Los_Angeles";
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDatePickerDate = DateTime.now();
    if (_dateController.text.isNotEmpty) {
      try {
        initialDatePickerDate = DateFormat(
          'yyyy-MM-dd',
        ).parseStrict(_dateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDatePickerDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTimePickerTime = TimeOfDay.now();
    if (_timeController.text.isNotEmpty) {
      final parts = _timeController.text.split(':');
      if (parts.length == 2) {
        initialTimePickerTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 12,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? initialTimePickerTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _findLocationDetails() async {
    if (_locationStringController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location to search.')),
      );
      return;
    }
    setState(() {
      _isFindingLocation = true;
    });
    print(
      "LOC_FIND: isFindingLocation set to true for location: ${_locationStringController.text}",
    );

    try {
      print("LOC_FIND: Calling locationFromAddress...");
      List<Location> locations = await locationFromAddress(
        _locationStringController.text,
      );
      print(
        "LOC_FIND: locationFromAddress returned. Found ${locations.length} locations.",
      );

      if (locations.isNotEmpty) {
        Location firstResult = locations.first;
        _latitudeController.text = firstResult.latitude.toStringAsFixed(4);
        _longitudeController.text = firstResult.longitude.toStringAsFixed(4);
        print(
          "LOC_FIND: Lat/Lon updated: ${firstResult.latitude}, ${firstResult.longitude}",
        );

        // ✅ CORRECTED CHECK:
        // Since _timezonedbApiKey is set with your actual key,
        // we just need to ensure it's not an empty string (which it won't be if set).
        // The placeholder check is no longer strictly necessary IF you always replace the placeholder.
        // However, to be super safe and match the *intent* of a placeholder check:
        const String expectedPlaceholderIfNotSet =
            "YOUR_TIMEZONEDB_API_KEY"; // A common placeholder string

        if (_timezonedbApiKey == expectedPlaceholderIfNotSet ||
            _timezonedbApiKey.isEmpty) {
          print(
            "LOC_FIND: API Key IS the placeholder or empty. Current key: '$_timezonedbApiKey'",
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'TimezoneDB API Key is still a placeholder or empty. Please set your actual key in the code.',
              ),
            ),
          );
          setState(() {
            _isFindingLocation = false;
          });
          return;
        }
        // If we reach here, the API key is not the placeholder and not empty.

        DateTime referenceDateTimeForAPI = DateTime.now();
        if (_dateController.text.isNotEmpty &&
            _timeController.text.isNotEmpty) {
          try {
            final parsedDate = DateFormat(
              'yyyy-MM-dd',
            ).parseStrict(_dateController.text);
            final timeParts = _timeController.text.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            referenceDateTimeForAPI = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              hour,
              minute,
            );
          } catch (e) {
            print(
              "LOC_FIND: Could not parse date/time for API timestamp, using current time as fallback: $e",
            );
          }
        }
        final int timestampForAPI =
            referenceDateTimeForAPI.toUtc().millisecondsSinceEpoch ~/ 1000;

        final Uri timezonedbApiUrl = Uri.parse(
          'http://api.timezonedb.com/v2.1/get-time-zone?key=$_timezonedbApiKey&format=json&by=position&lat=${firstResult.latitude}&lng=${firstResult.longitude}&time=$timestampForAPI',
        );

        print(
          "LOC_FIND: Calling TimezoneDB API: ${timezonedbApiUrl.toString()}",
        );
        final response = await http
            .get(timezonedbApiUrl)
            .timeout(const Duration(seconds: 10));
        print(
          "LOC_FIND: TimezoneDB API response status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("LOC_FIND: TimezoneDB API Response: $data");
          if (data['status'] == 'OK' && data['zoneName'] != null) {
            _timezoneController.text = data['zoneName'];
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location updated: TZ: ${data['zoneName']}'),
              ),
            );
          } else {
            _timezoneController.text = "";
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Timezone lookup failed (TimezoneDB): ${data['message'] ?? 'Unknown API error'}',
                ),
              ),
            );
          }
        } else {
          _timezoneController.text = "";
          print("LOC_FIND: TimezoneDB API Error Response: ${response.body}");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'TimezoneDB API request failed: ${response.statusCode}',
              ),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location (city) not found via geocoding.'),
          ),
        );
      }
    } catch (e, s) {
      print("LOC_FIND: Error in _findLocationDetails: $e\n$s");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location details: $e')),
      );
    } finally {
      print("LOC_FIND: Finally block. Setting isFindingLocation to false.");
      if (!mounted) return;
      setState(() {
        _isFindingLocation = false;
      });
    }
  }

  Future<void> _calculateAndDisplayChart() async {
    print("CALC_CHART: Button pressed. Validating fields...");
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty ||
        _timezoneController.text.isEmpty) {
      print("CALC_CHART: Validation failed - some fields empty.");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }
    print("CALC_CHART: Validation passed.");
    setState(() {
      _isLoading = true;
    });
    print("CALC_CHART: isLoading set to true. Parsing inputs...");

    try {
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parseStrict(_dateController.text);
      } catch (e) {
        /* ... error handling as before ... */
        print("CALC_CHART: Date parsing error.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ... (inside _calculateAndDisplayChart, after date parsing) ...
      TimeOfDay? parsedTime;
      String timeToParse = _timeController.text.trim(); // Trim whitespace
      print(
        "CALC_CHART: Attempting to parse time: '$timeToParse'",
      ); // Print what we're parsing

      final timeParts = timeToParse.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          parsedTime = TimeOfDay(hour: hour, minute: minute);
          print("CALC_CHART: Time parsed successfully: $parsedTime");
        } else {
          print(
            "CALC_CHART: Time parts parsed but hour/minute out of range or not numbers. Hour: $hour, Minute: $minute",
          );
        }
      } else {
        print(
          "CALC_CHART: Time string '$timeToParse' not in HH:MM format (parts count: ${timeParts.length})",
        );
      }

      if (parsedTime == null) {
        print(
          "CALC_CHART: Final parsedTime is null. Time parsing error.",
        ); // This log matches your output
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid Time Format. Please use the picker or HH:MM (24-hour).',
            ),
          ),
        );
        // setState(() {_isLoading = false;}); // This will be handled by finally
        return; // Return here to ensure isLoading is reset in finally
      }
      print("CALC_CHART: Date and Time fully parsed.");
      // ... rest of the method
      final DateTime birthDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      final double? latitude = double.tryParse(_latitudeController.text);
      final double? longitude = double.tryParse(_longitudeController.text);
      final String timezoneLocationName = _timezoneController.text.trim();

      if (latitude == null || longitude == null) {
        /* ... error handling ... */
        print("CALC_CHART: Lat/Lon parsing error.");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print(
        "CALC_CHART: Input DateTime (Local): $birthDateTime, Lat: $latitude, Lon: $longitude, TZ: $timezoneLocationName",
      );
      print("CALC_CHART: Calling astrologyService.calculateNatalChart...");

      NatalChartDetails? chartDetails = await astrologyService
          .calculateNatalChart(
            birthDateTime: birthDateTime,
            latitude: latitude,
            longitude: longitude,
            timezoneLocationName: timezoneLocationName,
          );
      print(
        "CALC_CHART: astrologyService.calculateNatalChart returned. ChartDetails is null: ${chartDetails == null}",
      );

      if (chartDetails != null) {
        print(
          "CALC_CHART: chartDetails received. Navigating to display screen...",
        );
        if (!mounted) {
          print("CALC_CHART: Not mounted, cannot navigate.");
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NatalChartDisplayScreen(chartDetails: chartDetails),
          ),
        );
        print("CALC_CHART: Navigation to display screen attempted.");
      } else {
        print("CALC_CHART: chartDetails is null. Showing error SnackBar.");
        if (!mounted) {
          print("CALC_CHART: Not mounted, cannot show SnackBar.");
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to calculate natal chart details. Check console for errors from service.',
            ),
          ),
        );
      }
    } catch (e, s) {
      print("CALC_CHART: Error caught in _calculateAndDisplayChart: $e \n$s");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      print("CALC_CHART: Finally block. Setting isLoading to false.");
      if (!mounted)
        return; // Ensure widget is still mounted before calling setState
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _locationStringController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  // Helper method for styled TextFields
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? icon,
    VoidCallback? onIconTap,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    bool isLocationSearch = false,
    ValueChanged<String>? onSubmitted,
    bool readOnlyOverride = true,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.lato(
        color: Colors.white.withOpacity(0.9),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.lato(
          color: Colors.deepPurpleAccent.withOpacity(0.8),
          fontSize: 14,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.lato(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
        suffixIcon:
            icon != null
                ? IconButton(
                  icon: Icon(
                    icon,
                    color: Colors.deepPurpleAccent.withOpacity(0.8),
                  ),
                  onPressed: onIconTap,
                )
                : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: Colors.deepPurpleAccent,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4), // More transparency for video
      ),
      keyboardType: keyboardType,
      readOnly: isLocationSearch ? false : readOnlyOverride,
      onTap: isLocationSearch ? null : onTap,
      onSubmitted: onSubmitted,
      textInputAction:
          onSubmitted != null ? TextInputAction.search : TextInputAction.done,
    );
  }

  @override
  Widget build(BuildContext context) {
    return VideoBackgroundScaffold(
      videoAssetPath:
          'assets/videos/asteroid.mp4', // Ensure this video exists and is declared
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24.0,
                  70.0,
                  24.0,
                  24.0,
                ), // Adjusted padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Text(
                        'Enter Birth Details',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: 30, // Slightly larger
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // Brighter white for title
                          shadows: [
                            const Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(1.5, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildStyledTextField(
                      controller: _dateController,
                      labelText: 'Birth Date (YYYY-MM-DD)',
                      icon: Icons.calendar_today,
                      onIconTap: () => _selectDate(context),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 18),
                    _buildStyledTextField(
                      controller: _timeController,
                      labelText: 'Birth Time (HH:MM)',
                      icon: Icons.access_time,
                      onIconTap: () => _selectTime(context),
                      onTap: () => _selectTime(context),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "Birth Location",
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStyledTextField(
                      controller: _locationStringController,
                      labelText: 'Enter City, State/Country',
                      hintText: 'e.g., Tokyo, Japan',
                      isLocationSearch: true,
                      onSubmitted: (_) => _findLocationDetails(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent.withOpacity(
                          0.75,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed:
                          _isFindingLocation ? null : _findLocationDetails,
                      child:
                          _isFindingLocation
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Find Location Details',
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    ),
                    const SizedBox(height: 20),
                    _buildStyledTextField(
                      controller: _latitudeController,
                      labelText: 'Latitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      readOnlyOverride: false,
                    ),
                    const SizedBox(height: 18),
                    _buildStyledTextField(
                      controller: _longitudeController,
                      labelText: 'Longitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      readOnlyOverride: false,
                    ),
                    const SizedBox(height: 18),
                    _buildStyledTextField(
                      controller: _timezoneController,
                      labelText: 'Timezone (IANA)',
                      hintText: 'e.g., America/New_York',
                      keyboardType: TextInputType.text,
                      readOnlyOverride: false,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700.withOpacity(
                          0.9,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: _isLoading ? null : _calculateAndDisplayChart,
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Calculate Natal Chart',
                                style: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Back Button
              Positioned(
                top: 15.0, // Adjusted for better spacing from status bar
                left: 15.0,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ), // Changed icon and color
                  iconSize: 26.0,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.35),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      // Check if it can pop
                      Navigator.of(context).pop();
                    } else {
                      // Optionally, navigate to splash if it's the first screen in this flow
                      // Navigator.of(context).pushReplacementNamed('/');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
