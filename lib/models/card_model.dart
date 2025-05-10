import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ElementType { fire, water, air, earth, light, dark, none }

class TarotCard {
  final String id;
  final String name;
  final ElementType element;
  final int attack;
  final int physicalDefense;
  final int magicDefense;
  final List<String> directions; // eg: ['N', 'E', 'SW']
  final bool isMajorArcana;

  TarotCard({
    required this.name,
    required this.element,
    required this.attack,
    required this.physicalDefense,
    required this.magicDefense,
    required this.directions,
    this.isMajorArcana = false,
  }) : id = const Uuid().v4();
}
