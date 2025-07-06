import 'package:flutter/material.dart';
import 'package:treehouse_card_game/cardgame.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CardGame(),
    );
  }
}

