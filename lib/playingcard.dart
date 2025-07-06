import 'package:flutter/material.dart';
import 'main.dart';

class CardModel {
  final String name;

  CardModel(this.name);

  int getValue() {
    final rank = name.split("-")[0]; // e.g. "ace"
    return cardValues[rank] ?? 0;
  }
}

class PlayingCard extends StatefulWidget {
  final String cardName;
  final bool isDrawn;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const PlayingCard({
    super.key,
    required this.cardName,
    this.isDrawn = false,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  State<PlayingCard> createState() => _PlayingCardState();
}

class _PlayingCardState extends State<PlayingCard> {
  int? getValue(){
    return cardValues[widget.cardName.split('-')[0]] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.isDimmed ? widget.cardName == 'playing-card' ? 0.4 : 1 : 0.4,
        duration: const Duration(milliseconds: 175),
        curve: Curves.easeIn,
        child: AnimatedScale(
          scale: widget.isSelected ? 1.15 : 1,
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeIn,
          child: Image.asset(
            'assets/${widget.cardName}.png',
            fit: BoxFit.contain,
            height: 110,
          ),
        ),
      ),
    );
  }
}