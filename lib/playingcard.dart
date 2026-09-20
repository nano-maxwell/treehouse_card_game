import 'package:flutter/material.dart';
import 'package:treehouse_card_game/cardgame.dart';

const double playingCardAspectRatio = 0.72;

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
  int? getValue() {
    return cardValues[widget.cardName.split('-')[0]] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.isDimmed
            ? widget.cardName == 'playing-card'
                ? 0.4
                : 1
            : 0.4,
        duration: const Duration(milliseconds: 175),
        curve: Curves.easeIn,
        child: AnimatedScale(
          scale: widget.isSelected ? 1.15 : 1,
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeIn,
          child: CardArtwork(
            cardName: widget.cardName,
            height: 110,
          ),
        ),
      ),
    );
  }
}

class CardArtwork extends StatelessWidget {
  final String cardName;
  final double? height;
  final double? width;

  const CardArtwork({
    super.key,
    required this.cardName,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Center(
        child: AspectRatio(
          aspectRatio: playingCardAspectRatio,
          child: cardName == 'playing-card'
              ? const _CardBack()
              : _CardFace(cardName: cardName),
        ),
      ),
    );
  }
}

class CardDeckArtwork extends StatelessWidget {
  final double height;

  const CardDeckArtwork({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = height * 0.9;
    return SizedBox(
      height: height,
      width: cardHeight * 0.79,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          for (var layer = 4; layer >= 1; layer--)
            Positioned(
              top: layer * height * 0.021,
              child: Container(
                height: cardHeight,
                width: cardHeight * 0.72,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFD5D5D5),
                    Colors.white,
                    (4 - layer) / 5,
                  ),
                  borderRadius: BorderRadius.circular(cardHeight * 0.075),
                ),
              ),
            ),
          Positioned(
            top: 0,
            child: CardArtwork(height: cardHeight, cardName: 'playing-card'),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String cardName;

  const _CardFace({required this.cardName});

  static const _rankLabels = <String, String>{
    'ace': 'A',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'jack': 'J',
    'queen': 'Q',
    'king': 'K',
  };

  static const _suitLabels = <String, String>{
    'clubs': '♣',
    'diamonds': '♦',
    'hearts': '♥',
    'spades': '♠',
  };

  @override
  Widget build(BuildContext context) {
    final parts = cardName.split('-of-');
    final rank = _rankLabels[parts.first] ?? parts.first;
    final suitName = parts.length == 2 ? parts.last : 'spades';
    final suit = _suitLabels[suitName] ?? '♠';
    final isRed = suitName == 'hearts' || suitName == 'diamonds';
    final color = isRed ? const Color(0xFFFF4D55) : const Color(0xFF30323A);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        Widget corner() => Text(
              rank,
              style: TextStyle(
                color: color,
                fontSize: width * 0.24,
                height: 0.82,
                fontWeight: FontWeight.w800,
                letterSpacing: -width * 0.01,
              ),
            );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(width * 0.11),
            border: Border.all(
              color: const Color(0xFFE3E3E0),
              width: width * 0.01,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x22000000),
                blurRadius: width * 0.04,
                offset: Offset(0, width * 0.02),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: width * 0.075,
                top: width * 0.08,
                child: corner(),
              ),
              Center(
                child: Text(
                  suit,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.52,
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                right: width * 0.075,
                bottom: width * 0.08,
                child: Transform.rotate(
                  angle: 3.141592653589793,
                  child: corner(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(width * 0.11),
            border: Border.all(color: Colors.white, width: width * 0.02),
            boxShadow: [
              BoxShadow(
                color: const Color(0x22000000),
                blurRadius: width * 0.04,
                offset: Offset(0, width * 0.02),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _CardBackPainter(),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const red = Color(0xFFFF4D55);
    final paint = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.075,
        size.height * 0.05,
        size.width * 0.85,
        size.height * 0.9,
      ),
      Radius.circular(size.width * 0.1),
    );
    paint.strokeWidth = size.width * 0.045;
    canvas.drawRRect(outer, paint);

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.095,
        size.width * 0.72,
        size.height * 0.81,
      ),
      Radius.circular(size.width * 0.065),
    );
    paint.strokeWidth = size.width * 0.023;
    canvas.drawRRect(inner, paint);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.19;
    final motif = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.42, center.dy - radius * 0.42)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.42, center.dy + radius * 0.42)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.42, center.dy + radius * 0.42)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.42, center.dy - radius * 0.42)
      ..close();
    paint.strokeWidth = size.width * 0.035;
    canvas.drawPath(motif, paint);

    final diamond = Path()
      ..moveTo(center.dx, center.dy - radius * 0.52)
      ..lineTo(center.dx + radius * 0.38, center.dy)
      ..lineTo(center.dx, center.dy + radius * 0.52)
      ..lineTo(center.dx - radius * 0.38, center.dy)
      ..close();
    canvas.drawPath(diamond, paint);

    paint.strokeWidth = size.width * 0.025;
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.19),
      Offset(size.width * 0.62, size.height * 0.19),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.81),
      Offset(size.width * 0.62, size.height * 0.81),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
