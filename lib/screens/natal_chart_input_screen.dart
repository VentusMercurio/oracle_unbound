// lib/screens/natal_chart_input_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date/time formatting, add to pubspec.yaml

// Import your AstrologyService and the global instance from main.dart
import '../services/astrology_service.dart';
import '../main.dart'; // Where 'astrologyService' is defined
import '../models/natal_chart_models.dart'; // To potentially navigate to a display screen

class NatalChartInputScreen extends StatefulWidget {
  const NatalChartInputScreen({super.key});

  @override
  State<NatalChartInputScreen> createState() => _NatalChartInputScreenState();
}

class _NatalChartInputScreenState extends State<NatalChartInputScreen> {
  // Controllers for text fields
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  // final _timezoneController = TextEditingController(); // For later

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  // For displaying results (optional, could navigate to new screen)
  String _results = "";

  @override
  void initState() {
    super.initState();
    // Pre-fill with some test data to speed up testing
    _dateController.text = "1990-07-15"; // YYYY-MM-DD
    _timeController.text = "14:30"; // HH:MM (24-hour)
    _latitudeController.text = "34.0522"; // Los Angeles Latitude
    _longitudeController.text = "-118.2437"; // Los Angeles Longitude
    // _timezoneController.text = "America/Los_Angeles"; // For later
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        // ignore: use_build_context_synchronously
        _timeController.text = picked.format(
          context,
        ); // Uses locale-specific format
      });
    }
  }

  Future<void> _calculateAndDisplayChart() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      setState(() {
        _results = "Please fill in all fields.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _results = "Calculating...";
    });

    try {
      // --- Parsing Date ---
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parseStrict(_dateController.text);
      } catch (e) {
        setState(() {
          _results = "Invalid Date Format. Use YYYY-MM-DD.";
          _isLoading = false;
        });
        return;
      }

      // --- Parsing Time ---
      // This is a bit tricky as TimeOfDay.format(context) can be locale specific.
      // For simplicity, we'll parse HH:MM. A more robust solution might be needed.
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
        setState(() {
          _results = "Invalid Time Format. Use HH:MM (24-hour).";
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
      // final String timezone = _timezoneController.text; // For later

      if (latitude == null || longitude == null) {
        setState(() {
          _results = "Invalid Latitude or Longitude.";
          _isLoading = false;
        });
        return;
      }

      print(
        "Input DateTime (Local): $birthDateTime, Lat: $latitude, Lon: $longitude",
      );

      NatalChartDetails?
      chartDetails = await astrologyService.calculateNatalChart(
        birthDateTime: birthDateTime, // This is local time
        latitude: latitude,
        longitude: longitude,
        // timezoneLocationName: timezone, // Pass this when ready for robust TZ
      );

      if (chartDetails != null) {
        StringBuffer sb = StringBuffer();
        sb.writeln("--- NATAL CHART DETAILS ---");
        sb.writeln("Birth (Local): $birthDateTime");
        sb.writeln("Birth (Used UTC): ${chartDetails.birthDateTimeUTC}");
        sb.writeln(
          "Lat: ${chartDetails.latitude}, Lon: ${chartDetails.longitude}",
        );
        sb.writeln("\n--- MAJOR POINTS ---");
        sb.writeln("${chartDetails.ascendant}");
        sb.writeln("${chartDetails.midheaven}");
        sb.writeln("\n--- PLANETS ---");
        for (var planet in chartDetails.planets) {
          sb.writeln(planet);
        }
        sb.writeln("\n--- HOUSE CUSPS (Placidus) ---");
        for (var cusp in chartDetails.houseCusps) {
          sb.writeln(cusp);
        }
        setState(() {
          _results = sb.toString();
        });
      } else {
        setState(() {
          _results =
              "Failed to calculate natal chart details. Check console for errors.";
        });
      }
    } catch (e, s) {
      print("Error in UI calculate: $e \n$s");
      setState(() {
        _results = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    // _timezoneController.dispose();
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
            // Date Field
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Birth Date (YYYY-MM-DD)',
                hintText: 'e.g., 1990-07-15',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),

            // Time Field
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Birth Time (HH:MM, 24-hour)',
                hintText: 'e.g., 14:30',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),

            // Latitude Field
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude (Decimal Degrees)',
                hintText: 'e.g., 34.0522',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 16),

            // Longitude Field
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude (Decimal Degrees)',
                hintText: 'e.g., -118.2437 (West is negative)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _calculateAndDisplayChart,
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
                      : const Text('Calculate Natal Chart'),
            ),
            const SizedBox(height: 24),

            // Display Results
            if (_results.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[800],
                child: Text(
                  _results,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ), // Monospace for better alignment
                ),
              ),
          ],
        ),
      ),
    );
  }
}
