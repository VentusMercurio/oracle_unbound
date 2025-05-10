import 'dart:math';
import 'card_model.dart';

final _rand = Random();

/// Returns a list of 78 dummy Tarot cards with randomized attributes
List<TarotCard> generateDummyDeck() {
  const minorSuits = ['Wands', 'Cups', 'Swords', 'Pentacles'];
  const elements = {
    'Wands': ElementType.fire,
    'Cups': ElementType.water,
    'Swords': ElementType.air,
    'Pentacles': ElementType.earth,
  };

  final List<TarotCard> deck = [];

  // Minor Arcana: 2–10
  for (var suit in minorSuits) {
    for (int value = 2; value <= 10; value++) {
      deck.add(TarotCard(
        name: '$value of $suit',
        element: elements[suit]!,
        attack: _weightedValue(value, 2, 5),
        physicalDefense: _weightedValue(value, 2, 5),
        magicDefense: _weightedValue(value, 2, 5),
        directions: _randomDirections(value),
      ));
    }
  }

  // Court Cards
  const courts = ['Page', 'Knight', 'Queen', 'King'];
  for (var suit in minorSuits) {
    for (var rank in courts) {
      deck.add(TarotCard(
        name: '$rank of $suit',
        element: elements[suit]!,
        attack: _rand.nextInt(3) + 5,
        physicalDefense: _rand.nextInt(3) + 5,
        magicDefense: _rand.nextInt(3) + 5,
        directions: _randomDirections(6),
      ));
    }
  }

  // Major Arcana
  const majors = [
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress',
    'The Emperor', 'The Hierophant', 'The Lovers', 'The Chariot',
    'Strength', 'The Hermit', 'Wheel of Fortune', 'Justice', 'The Hanged Man',
    'Death', 'Temperance', 'The Devil', 'The Tower', 'The Star', 'The Moon',
    'The Sun', 'Judgement', 'The World'
  ];

  for (var name in majors) {
    deck.add(TarotCard(
      name: name,
      element: ElementType.none,
      attack: _rand.nextInt(5) + 5,
      physicalDefense: _rand.nextInt(5) + 5,
      magicDefense: _rand.nextInt(5) + 5,
      directions: _randomDirections(8),
      isMajorArcana: true,
    ));
  }

  return deck;
}

/// Generates a weighted stat based on card value (higher value = stronger)
int _weightedValue(int cardValue, int min, int max) {
  final bias = (cardValue - 1) / 10.0;
  return min + (_rand.nextDouble() * (max - min) * bias).round();
}

/// Returns a random list of cardinal/intercardinal directions (2 to 8)
List<String> _randomDirections(int cardValue) {
  final allDirections = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final numDirections = 2 + _rand.nextInt(min(cardValue, 7));
  allDirections.shuffle(_rand);
  return allDirections.take(numDirections).toList();
}
