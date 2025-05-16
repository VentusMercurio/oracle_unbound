// lib/screens/natal_chart_input_screen.dart
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

// Import your other necessary files
import 'natal_chart_display_screen.dart';
import '../services/astrology_service.dart';
import '../main.dart'; // Where 'astrologyService' is defined
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

  bool _isLoading = false; // For the main calculate button
  bool _isFindingLocation = false; // For the find location button

  // ✅ IMPORTANT: REPLACE WITH YOUR ACTUAL TIMEZONEDB API KEY
  final String _timezonedbApiKey = "FMTI03MRT3QS";

  @override
  void initState() {
    super.initState();
    // Pre-fill with some test data to speed up testing
    _dateController.text = "1990-07-15";
    _timeController.text = "14:30";
    _locationStringController.text = "Los Angeles, CA, USA";
    // Pre-fill lat/lon/tz based on the pre-filled location for convenience during testing
    // These will be overwritten if "Find Location Details" is successful
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
      } catch (_) {
        /* Use DateTime.now() if parsing fails */
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDatePickerDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 10),
      ), // Allow up to 10 years in future
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

  // ✅ REVISED _findLocationDetails method for TimezoneDB
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

    try {
      List<Location> locations = await locationFromAddress(
        _locationStringController.text,
      );
      if (locations.isNotEmpty) {
        Location firstResult = locations.first;
        _latitudeController.text = firstResult.latitude.toStringAsFixed(4);
        _longitudeController.text = firstResult.longitude.toStringAsFixed(4);

        if (_timezonedbApiKey == "YOUR_TIMEZONEDB_API_KEY" ||
            _timezonedbApiKey.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'TimezoneDB API Key not set. Timezone may be incorrect or need manual entry.',
              ),
            ),
          );
          // Don't return, allow lat/lon to be set, user can manually enter timezone
          // _timezoneController.text = ""; // Optionally clear timezone if API key is missing
          setState(() {
            _isFindingLocation = false;
          });
          return; // Or proceed without timezone lookup
        }

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
              "Could not parse date/time for API timestamp, using current time as fallback: $e",
            );
          }
        }
        final int timestampForAPI =
            referenceDateTimeForAPI.toUtc().millisecondsSinceEpoch ~/ 1000;

        final Uri timezonedbApiUrl = Uri.parse(
          'http://api.timezonedb.com/v2.1/get-time-zone?key=$_timezonedbApiKey&format=json&by=position&lat=${firstResult.latitude}&lng=${firstResult.longitude}&time=$timestampForAPI',
        );

        print("Calling TimezoneDB API: ${timezonedbApiUrl.toString()}");
        final response = await http
            .get(timezonedbApiUrl)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("TimezoneDB API Response: $data");
          if (data['status'] == 'OK' && data['zoneName'] != null) {
            _timezoneController.text = data['zoneName'];
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location updated: Lat: ${firstResult.latitude.toStringAsFixed(2)}, Lon: ${firstResult.longitude.toStringAsFixed(2)}, TZ: ${data['zoneName']}',
                ),
              ),
            );
          } else {
            _timezoneController.text = ""; // Clear if API returns error
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
          _timezoneController.text = ""; // Clear on HTTP error
          print("TimezoneDB API Error Response: ${response.body}");
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
        // No locations found by geocoding
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location (city) not found via geocoding.'),
          ),
        );
      }
    } catch (e, s) {
      print("Error in _findLocationDetails: $e\n$s");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location details: $e')),
      );
    } finally {
      setState(() {
        _isFindingLocation = false;
      });
    }
  }

  Future<void> _calculateAndDisplayChart() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty ||
        _timezoneController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All fields (Date, Time, Lat, Lon, Timezone) are required.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parseStrict(_dateController.text);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Date Format. Use YYYY-MM-DD.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      TimeOfDay? parsedTime;
      final timeParts = _timeController.text.split(':');
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
        }
      }
      if (parsedTime == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Time Format. Use HH:MM (24-hour).'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Latitude or Longitude.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // Timezone already checked in the initial validation block by this point

      print(
        "Input DateTime (Local): $birthDateTime, Lat: $latitude, Lon: $longitude, TZ: $timezoneLocationName",
      );

      NatalChartDetails? chartDetails = await astrologyService
          .calculateNatalChart(
            birthDateTime: birthDateTime,
            latitude: latitude,
            longitude: longitude,
            timezoneLocationName: timezoneLocationName,
          );

      // setState(() { _isLoading = false; }); // Moved to finally block

      if (chartDetails != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NatalChartDisplayScreen(chartDetails: chartDetails),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to calculate natal chart details. Check console for errors from service.',
            ),
          ),
        );
      }
    } catch (e, s) {
      print("Error in UI _calculateAndDisplayChart: $e \n$s");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      }); // Ensure isLoading is always reset
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Natal Chart Input'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Date and Time Pickers
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Birth Date (YYYY-MM-DD)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Birth Time (HH:MM)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
              readOnly: true,
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 24),

            // Location Input Section
            Text(
              "Birth Location",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ), // Added color for dark theme
            const SizedBox(height: 8),
            TextField(
              controller: _locationStringController,
              decoration: const InputDecoration(
                labelText: 'Enter City, State/Country',
                hintText: 'e.g., New York, NY or Paris, France',
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _findLocationDetails(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isFindingLocation ? null : _findLocationDetails,
              child:
                  _isFindingLocation
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Find Location Details'),
            ),
            const SizedBox(height: 16),

            // Auto-filled or Manual Lat, Lon, TZ
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude (auto-filled or manual)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude (auto-filled or manual)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timezoneController,
              decoration: const InputDecoration(
                labelText: 'Timezone (IANA, auto-filled or manual)',
                hintText: 'e.g., America/New_York',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _calculateAndDisplayChart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Calculate Natal Chart',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
