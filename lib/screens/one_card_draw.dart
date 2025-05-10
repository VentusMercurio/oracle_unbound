import 'package:flutter/material.dart';

class OneCardDrawScreen extends StatelessWidget {
  const OneCardDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Card Draw'),
      ),
      body: const Center(
        child: Text(
          'This is the One Card Draw screen.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
