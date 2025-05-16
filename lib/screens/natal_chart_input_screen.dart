// lib/screens/natal_chart_input_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ Import the new display screen
import 'natal_chart_display_screen.dart';

import '../services/astrology_service.dart';
import '../main.dart'; // Where 'astrologyService' is defined
// NatalChartDetails is now imported via natal_chart_display_screen.dart if it imports natal_chart_models.dart
// or directly if you keep the import here:
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
  final _timezoneController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  // String _results = ""; // ✅ REMOVED - We navigate instead

  @override
  void initState() {
    super.initState();
    // Pre-fill with some test data to speed up testing
    _dateController.text = "1990-07-15"; // YYYY-MM-DD
    _timeController.text = "14:30"; // HH:MM (24-hour)
    _latitudeController.text = "34.0522"; // Los Angeles Latitude
    _longitudeController.text = "-118.2437"; // Los Angeles Longitude
    _timezoneController.text = "America/Los_Angeles";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Allow dates up to 1 year in future
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
        // Use a consistent format for parsing later
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _calculateAndDisplayChart() async {
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty ||
        _timezoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields, including Timezone.'),
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
        final minute = int.tryParse(
          timeParts[1],
        ); // Assuming HH:MM format from _selectTime
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
      if (timezoneLocationName.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timezone cannot be empty.')),
        );
        setState(() {
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
            timezoneLocationName: timezoneLocationName,
          );

      setState(() {
        _isLoading = false;
      });

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
              'Failed to calculate natal chart details. Check console for errors.',
            ),
          ),
        );
      }
    } catch (e, s) {
      print("Error in UI _calculateAndDisplayChart: $e \n$s");
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
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
        backgroundColor:
            Colors.deepPurple, // Or Theme.of(context).colorScheme.primary
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
              readOnly: true, // Make it read-only if using picker exclusively
              onTap: () => _selectDate(context), // Also open picker on tap
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
              readOnly: true, // Make it read-only if using picker exclusively
              onTap: () => _selectTime(context), // Also open picker on tap
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
            const SizedBox(height: 16),
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
            // The old _results display Container is removed from here
          ],
        ),
      ),
    );
  }
}
