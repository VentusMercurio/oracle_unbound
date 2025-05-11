import 'package:flutter/material.dart';
import 'dart:math';

class OneCardDraw extends StatefulWidget {
  const OneCardDraw({super.key});

  @override
  State<OneCardDraw> createState() => _OneCardDrawState();
}

class _OneCardDrawState extends State<OneCardDraw> {
  final List<String> tarotDeck = [
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress', 'The Emperor',
    'The Hierophant', 'The Lovers', 'The Chariot', 'Strength', 'The Hermit',
    'Wheel of Fortune', 'Justice', 'The Hanged Man', 'Death', 'Temperance',
    'The Devil', 'The Tower', 'The Star', 'The Moon', 'The Sun', 'Judgement', 'The World',
    'Ace of Wands', 'Two of Wands', 'Three of Wands', 'Four of Wands', 'Five of Wands',
    'Six of Wands', 'Seven of Wands', 'Eight of Wands', 'Nine of Wands', 'Ten of Wands',
    'Page of Wands', 'Knight of Wands', 'Queen of Wands', 'King of Wands',
    'Ace of Cups', 'Two of Cups', 'Three of Cups', 'Four of Cups', 'Five of Cups',
    'Six of Cups', 'Seven of Cups', 'Eight of Cups', 'Nine of Cups', 'Ten of Cups',
    'Page of Cups', 'Knight of Cups', 'Queen of Cups', 'King of Cups',
    'Ace of Swords', 'Two of Swords', 'Three of Swords', 'Four of Swords', 'Five of Swords',
    'Six of Swords', 'Seven of Swords', 'Eight of Swords', 'Nine of Swords', 'Ten of Swords',
    'Page of Swords', 'Knight of Swords', 'Queen of Swords', 'King of Swords',
    'Ace of Pentacles', 'Two of Pentacles', 'Three of Pentacles', 'Four of Pentacles',
    'Five of Pentacles', 'Six of Pentacles', 'Seven of Pentacles', 'Eight of Pentacles',
    'Nine of Pentacles', 'Ten of Pentacles', 'Page of Pentacles', 'Knight of Pentacles',
    'Queen of Pentacles', 'King of Pentacles'
  ];

  String? drawnCard;

  void drawCard() {
    final random = Random();
    final index = random.nextInt(tarotDeck.length);
    setState(() {
      drawnCard = tarotDeck[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Card Draw'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: drawCard,
              child: const Text('Draw Card'),
            ),
            const SizedBox(height: 20),
            if (drawnCard != null)
              Text(
                drawnCard!,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
