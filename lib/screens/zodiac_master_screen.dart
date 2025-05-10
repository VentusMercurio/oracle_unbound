import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/dummy_deck.dart';

class ZodiacMasterScreen extends StatefulWidget {
  const ZodiacMasterScreen({super.key});

  @override
  State<ZodiacMasterScreen> createState() => _ZodiacMasterScreenState();
}

class _ZodiacMasterScreenState extends State<ZodiacMasterScreen> {
  late List<TarotCard> playerHand;
  late List<TarotCard> aiHand;

  @override
  void initState() {
    super.initState();
    final fullDeck = generateDummyDeck()..shuffle();
    playerHand = fullDeck.sublist(0, 5);
    aiHand = fullDeck.sublist(5, 10);
  }

  Widget _buildCard(TarotCard card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Element: ${card.element.name}', style: const TextStyle(color: Colors.white60)),
          Text('Atk: ${card.attack}, PDef: ${card.physicalDefense}, MDef: ${card.magicDefense}',
              style: const TextStyle(color: Colors.white60)),
          Text('Directions: ${card.directions.join(', ')}',
              style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zodiac Master'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Player Hand', style: TextStyle(color: Colors.amber, fontSize: 20)),
            const SizedBox(height: 8),
            ...playerHand.map(_buildCard),
            const Divider(color: Colors.white38, height: 32),
            const Text('AI Hand', style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            const SizedBox(height: 8),
            ...aiHand.map(_buildCard),
          ],
        ),
      ),
    );
  }
}
