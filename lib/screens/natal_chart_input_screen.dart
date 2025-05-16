// lib/screens/natal_chart_input_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _timezoneController =
      TextEditingController(); // ✅ NEW: Controller for timezone

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  String _results = "";

  @override
  void initState() {
    super.initState();
    _dateController.text = "1990-07-15";
    _timeController.text = "14:30";
    _latitudeController.text = "34.0522";
    _longitudeController.text = "-118.2437";
    _timezoneController.text =
        "America/Los_Angeles"; // ✅ NEW: Pre-fill timezone (IANA format)
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
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _calculateAndDisplayChart() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty ||
        _timezoneController.text.isEmpty) {
      // ✅ MODIFIED: Check timezone field
      setState(() {
        _results = "Please fill in all fields, including Timezone.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _results = "Calculating...";
    });

    try {
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

      TimeOfDay? parsedTime;
      final timeParts = _timeController.text.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minutePart =
            timeParts[1].split(
              ' ',
            )[0]; // Handle cases like "14:30 AM/PM" if picker adds it
        final minute = int.tryParse(minutePart);
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
          _results = "Invalid Time Format. Use HH:MM (24-hour) or picker.";
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
      final String timezoneLocationName =
          _timezoneController.text.trim(); // ✅ NEW: Get timezone string

      if (latitude == null || longitude == null) {
        setState(() {
          _results = "Invalid Latitude or Longitude.";
          _isLoading = false;
        });
        return;
      }
      if (timezoneLocationName.isEmpty) {
        // ✅ NEW: Basic check for timezone
        setState(() {
          _results = "Timezone cannot be empty.";
          _isLoading = false;
        });
        return;
      }

      print(
        "Input DateTime (Local): $birthDateTime, Lat: $latitude, Lon: $longitude, TZ: $timezoneLocationName",
      );

      NatalChartDetails? chartDetails = await astrologyService
          .calculateNatalChart(
            birthDateTime: birthDateTime,
            latitude: latitude,
            longitude: longitude,
            timezoneLocationName:
                timezoneLocationName, // ✅ MODIFIED: Pass timezone
          );

      if (chartDetails != null) {
        StringBuffer sb = StringBuffer();
        sb.writeln("--- NATAL CHART DETAILS ---");
        sb.writeln(
          "Birth (Local Input): ${DateFormat('yyyy-MM-dd HH:mm').format(birthDateTime)} (TZ: $timezoneLocationName)",
        );
        sb.writeln(
          "Birth (Calculated UTC): ${DateFormat('yyyy-MM-dd HH:mm:ss').format(chartDetails.birthDateTimeUTC)} UTC",
        );
        sb.writeln(
          "Lat: ${chartDetails.latitude.toStringAsFixed(4)}, Lon: ${chartDetails.longitude.toStringAsFixed(4)}",
        );
        sb.writeln("\n--- MAJOR POINTS ---");
        sb.writeln(chartDetails.ascendant);
        sb.writeln(chartDetails.midheaven);
        sb.writeln("\n--- PLANETS ---");
        for (var planet in chartDetails.planets) {
          sb.writeln(planet);
        }
        sb.writeln("\n--- HOUSE CUSPS (Placidus) ---");
        int cuspNum = 1;
        for (var cusp in chartDetails.houseCusps) {
          sb.writeln("${cuspNum++}. ${cusp.formattedPosition}");
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
    _timezoneController.dispose(); // ✅ NEW: Dispose timezone controller
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Birth Time (HH:MM, 24-hour)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude (e.g., 34.0522)',
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
                labelText: 'Longitude (e.g., -118.2437)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 16), // ✅ NEW SPACING
            // ✅ NEW: Timezone Field
            TextField(
              controller: _timezoneController,
              decoration: const InputDecoration(
                labelText: 'Timezone (e.g., America/Los_Angeles)',
                hintText: 'IANA Timezone Name',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),

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

            if (_results.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[800], // Consider a theme-appropriate color
                child: SelectableText(
                  // ✅ MODIFIED: Made results selectable for easier copy-pasting
                  _results,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
