// lib/screens/three_card_spread_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Define your tarot deck (or import from a separate file)
const List<String> tarotDeck = [
  "The Fool",
  "The Magician",
  "The High Priestess",
  "The Empress",
  "The Emperor",
  "The Hierophant",
  "The Lovers",
  "The Chariot",
  "Strength",
  "The Hermit",
  "Wheel of Fortune",
  "Justice",
  "The Hanged Man",
  "Death",
  "Temperance",
  "The Devil",
  "The Tower",
  "The Star",
  "The Moon",
  "The Sun",
  "Judgement",
  "The World",
  "Ace of Wands",
  "Two of Wands",
  "Three of Wands",
  "Four of Wands",
  "Five of Wands",
  "Six of Wands",
  "Seven of Wands",
  "Eight of Wands",
  "Nine of Wands",
  "Ten of Wands",
  "Page of Wands",
  "Knight of Wands",
  "Queen of Wands",
  "King of Wands",
  "Ace of Cups",
  "Two of Cups",
  "Three of Cups",
  "Four of Cups",
  "Five of Cups",
  "Six of Cups",
  "Seven of Cups",
  "Eight of Cups",
  "Nine of Cups",
  "Ten of Cups",
  "Page of Cups",
  "Knight of Cups",
  "Queen of Cups",
  "King of Cups",
  "Ace of Swords",
  "Two of Swords",
  "Three of Swords",
  "Four of Swords",
  "Five of Swords",
  "Six of Swords",
  "Seven of Swords",
  "Eight of Swords",
  "Nine of Swords",
  "Ten of Swords",
  "Page of Swords",
  "Knight of Swords",
  "Queen of Swords",
  "King of Swords",
  "Ace of Pentacles",
  "Two of Pentacles",
  "Three of Pentacles",
  "Four of Pentacles",
  "Five of Pentacles",
  "Six of Pentacles",
  "Seven of Pentacles",
  "Eight of Pentacles",
  "Nine of Pentacles",
  "Ten of Pentacles",
  "Page of Pentacles",
  "Knight of Pentacles",
  "Queen of Pentacles",
  "King of Pentacles",
];

class ThreeCardSpreadScreen extends StatefulWidget {
  const ThreeCardSpreadScreen({super.key});

  @override
  State<ThreeCardSpreadScreen> createState() => _ThreeCardSpreadScreenState();
}

class _ThreeCardSpreadScreenState extends State<ThreeCardSpreadScreen> {
  final _questionController = TextEditingController();
  List<String> _drawnCards = [];
  String? _sophiaResponse;
  bool _isLoading = false;

  List<String> _drawThreeCards() {
    final List<String> shuffledDeck = List.from(tarotDeck);
    shuffledDeck.shuffle(Random());
    return shuffledDeck.sublist(0, 3);
  }

  Future<void> _handleSubmit() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your question for Sophia.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _drawnCards = []; // Clear previous cards
      _sophiaResponse = null; // Clear previous response
    });

    final List<String> drawn = _drawThreeCards();
    setState(() {
      _drawnCards = drawn;
    });

    final String prompt =
        'A querent asked: "${_questionController.text.trim()}". They drew the following three cards: 1) ${drawn[0]}, 2) ${drawn[1]}, 3) ${drawn[2]}. Please offer a poetic yet insightful three-card reading, addressing each card in order and then providing an overall summary or guidance based on the spread.';

    // ✅ IMPORTANT: Use your actual deployed Next.js API endpoint URL for the spread
    final String apiUrl = "https://spread-chi.vercel.app/api/spread";
    // Or if you have a custom domain: "https://your-custom-domain.com/api/spread"

    try {
      print("Sending prompt to Sophia: $prompt");
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": prompt,
            }), // Your Next.js API expects a 'message' field
          )
          .timeout(const Duration(seconds: 90)); // Increased timeout

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _sophiaResponse =
              responseData['reply'] ?? "Sophia's wisdom is currently veiled.";
        });
      } else {
        print(
          "Sophia API Error (Spread): ${response.statusCode} - ${response.body}",
        );
        setState(() {
          _sophiaResponse =
              "Sorry, Sophia is contemplating the cosmos (Error: ${response.statusCode}).";
        });
      }
    } catch (e, s) {
      print("Error calling Sophia API (Spread): $e\n$s");
      if (!mounted) return;
      setState(() {
        _sophiaResponse = "A cosmic disturbance interrupted our connection: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Consider using VideoBackgroundScaffold if you want a video here too
      // backgroundColor: Colors.black, // Assuming dark theme
      appBar: AppBar(
        title: Text(
          "Sophia's Three Card Spread",
          style: GoogleFonts.cinzel(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Pose your query to the Oracle...",
              style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter your question here...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent.withOpacity(0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent.withOpacity(0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: Colors.deepPurpleAccent,
                    width: 2.0,
                  ),
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Reveal the Oracle'),
            ),
            const SizedBox(height: 30),

            // Display Drawn Cards
            if (_drawnCards.isNotEmpty)
              Column(
                children: [
                  Text(
                    "Your cards:",
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        _drawnCards.map((card) {
                          return Expanded(
                            // To make cards take available space and wrap text
                            child: Card(
                              elevation: 4.0,
                              color: Colors.deepPurple.shade700.withOpacity(
                                0.7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  card,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),

            // Display Sophia's Response
            if (_sophiaResponse != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sophia Replies:",
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent.shade200,
                      ),
                    ),
                    Divider(
                      color: Colors.tealAccent.shade200.withOpacity(0.5),
                      height: 20,
                      thickness: 0.8,
                    ),
                    SelectableText(
                      _sophiaResponse!,
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
