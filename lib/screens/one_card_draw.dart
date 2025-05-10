import 'package:flutter/material.dart';

class OneCardDraw extends StatelessWidget {
  const OneCardDraw({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Card Draw'),
      ),
      body: const Center(
        child: Text(
          'Your card will appear here...',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
