import 'package:flutter/material.dart';
import 'package:treehouse_card_game/flipcardwidget.dart';
import 'package:treehouse_card_game/playingcard.dart';

const Color darkerPurple = Color.fromARGB(255, 85, 105, 220);
const Color bgPurple = Color.fromARGB(255, 144, 157, 255);

const List<String> fullDeck = [
  "ace-of-spades",
  "two-of-spades",
  "three-of-spades",
  "four-of-spades",
  "five-of-spades",
  "six-of-spades",
  "seven-of-spades",
  "eight-of-spades",
  "nine-of-spades",
  "ten-of-spades",
  "jack-of-spades",
  "queen-of-spades",
  "king-of-spades",
  "ace-of-hearts",
  "two-of-hearts",
  "three-of-hearts",
  "four-of-hearts",
  "five-of-hearts",
  "six-of-hearts",
  "seven-of-hearts",
  "eight-of-hearts",
  "nine-of-hearts",
  "ten-of-hearts",
  "jack-of-hearts",
  "queen-of-hearts",
  "king-of-hearts",
  "ace-of-diamonds",
  "two-of-diamonds",
  "three-of-diamonds",
  "four-of-diamonds",
  "five-of-diamonds",
  "six-of-diamonds",
  "seven-of-diamonds",
  "eight-of-diamonds",
  "nine-of-diamonds",
  "ten-of-diamonds",
  "jack-of-diamonds",
  "queen-of-diamonds",
  "king-of-diamonds",
  "ace-of-clubs",
  "two-of-clubs",
  "three-of-clubs",
  "four-of-clubs",
  "five-of-clubs",
  "six-of-clubs",
  "seven-of-clubs",
  "eight-of-clubs",
  "nine-of-clubs",
  "ten-of-clubs",
  "jack-of-clubs",
  "queen-of-clubs",
  "king-of-clubs"
];

Map<String, int> cardValues = {
  "ace": 1,
  "two": 2,
  "three": 3,
  "four": 4,
  "five": 5,
  "six": 6,
  "seven": 7,
  "eight": 8,
  "nine": 9,
  "ten": 10,
  "jack": 11,
  "queen": 12,
  "king": 13,
};

class CardGame extends StatefulWidget {
  const CardGame({super.key});

  @override
  State<CardGame> createState() => _CardGameState();
}

class _CardGameState extends State<CardGame> {
  List<CardModel> visibleCards = [];
  late List<CardModel> cardDeck;
  int? tappedIndex;
  FlipCardController controller = FlipCardController();
  late CardModel nextCard;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    cardDeck = fullDeck.map((name) => CardModel(name)).toList()..shuffle();

    for (int i = 0; i < 9; i++) {
      visibleCards.add(cardDeck.removeAt(0));
    }
    nextCard = cardDeck.removeAt(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheCardImages(context);
    });
  }

  void _handleCardTap(int index) {
    if (isAnimating) return;

    setState(() {
      tappedIndex = index == tappedIndex ? null : index;
    });
  }

  CardModel drawCard() {
    return cardDeck.removeAt(0);
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 225, 225, 225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Are you sure you want to start over?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'Your progress from this game will not be saved.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: darkerPurple
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkerPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                visibleCards = [];
                cardDeck = fullDeck.map((name) => CardModel(name)).toList()
                  ..shuffle();

                for (int i = 0; i < 9; i++) {
                  visibleCards.add(cardDeck.removeAt(0));
                }

                nextCard = cardDeck.removeAt(0);

                controller = FlipCardController();
              });

              Navigator.of(context).pop();
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  void addNewCard(int index, CardModel newCard, bool checkingHigher) {
    setState(() {
      if (checkingHigher &&
          visibleCards[index].getValue() < newCard.getValue()) {
        visibleCards[index] = newCard;
      } else if (!checkingHigher &&
          visibleCards[index].getValue() > newCard.getValue()) {
        visibleCards[index] = newCard;
      } else {
        visibleCards[index] = CardModel('playing-card');
      }
      tappedIndex = null;
    });
  }

  void _precacheCardImages(BuildContext context) {
    for (String cardName in fullDeck) {
      precacheImage(AssetImage('assets/$cardName.png'), context);
    }
    precacheImage(const AssetImage('assets/playing-card.png'), context);
  }

  Widget _buildCard(int index) {
    final card = visibleCards[index];
    return Container(
      height: 110,
      width: 110,
      child: PlayingCard(
          cardName: card.name,
          isSelected: tappedIndex == index,
          isDimmed: tappedIndex == null || tappedIndex == index,
          onTap: () {
            if (card.name != 'playing-card') {
              _handleCardTap(index);
            }
          }),
    );
  }

  Widget _buildCardGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(0),
            const SizedBox(width: 5),
            _buildCard(1),
            const SizedBox(width: 5),
            _buildCard(2),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(3),
            const SizedBox(width: 5),
            _buildCard(4),
            const SizedBox(width: 5),
            _buildCard(5),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(6),
            const SizedBox(width: 5),
            _buildCard(7),
            const SizedBox(width: 5),
            _buildCard(8),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bgPurple,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        onTap: () {
                          _showResetConfirmationDialog(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 14.0),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        )),
                    GestureDetector(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 14.0),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        )),
                  ],
                ),
              ),
            ),
            _buildCardGrid(),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HigherButton(
                  selectedCard:
                      tappedIndex != null ? visibleCards[tappedIndex!] : null,
                  onPressed: () async {
                    if (isAnimating || tappedIndex == null) return;

                    setState(() {
                      isAnimating = true;
                    });

                    await controller.flipCard();

                    addNewCard(tappedIndex!, nextCard, true);
                    setState(() {
                      nextCard = drawCard();
                      isAnimating = false;
                    });
                  },
                ),
                const SizedBox(width: 15),
                LowerButton(
                  selectedCard:
                      tappedIndex != null ? visibleCards[tappedIndex!] : null,
                  onPressed: () async {
                    if (isAnimating || tappedIndex == null) return;

                    setState(() {
                      isAnimating = true;
                    });

                    await controller.flipCard();

                    addNewCard(tappedIndex!, nextCard, false);
                    setState(() {
                      nextCard = drawCard();
                      isAnimating = false;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 35),
            // Image.asset('assets/card-deck.png', height: 125),
            Stack(
              alignment: const Alignment(0, -1),
              children: [
                Image.asset(
                  'assets/card-deck.png',
                  height: 125,
                ),
                FlipCardWidget(
                  front: Image.asset(
                    'assets/${nextCard.name}.png',
                    height: 110,
                  ),
                  controller: controller,
                  back: Image.asset(
                    'assets/playing-card.png',
                    height: 110,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Cards Remaining: ${cardDeck.length + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HigherButton extends StatefulWidget {
  final CardModel? selectedCard;
  final VoidCallback onPressed;

  const HigherButton(
      {super.key, required this.selectedCard, required this.onPressed});

  @override
  State<HigherButton> createState() => _HigherButtonState();
}

class _HigherButtonState extends State<HigherButton> {
  @override
  Widget build(BuildContext context) {
    final isDisabled =
        widget.selectedCard == null || widget.selectedCard!.getValue() == 13;

    return GestureDetector(
        onTap: () {
          if (widget.selectedCard != null &&
              widget.selectedCard!.getValue() < 13) {
            widget.onPressed();
          }
        },
        child: AnimatedOpacity(
          opacity: widget.selectedCard != null && !isDisabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 56,
            width: 130,
            decoration: const BoxDecoration(
              color: darkerPurple,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Center(
              child: Text(
                'Higher',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ));
  }
}

class LowerButton extends StatefulWidget {
  final CardModel? selectedCard;
  final VoidCallback onPressed;

  const LowerButton(
      {super.key, required this.selectedCard, required this.onPressed});

  @override
  State<LowerButton> createState() => _LowerButtonState();
}

class _LowerButtonState extends State<LowerButton> {
  @override
  Widget build(BuildContext context) {
    final isDisabled =
        widget.selectedCard == null || widget.selectedCard!.getValue() == 1;

    return GestureDetector(
        onTap: () {
          if (widget.selectedCard != null &&
              widget.selectedCard!.getValue() > 1) {
            widget.onPressed();
          }
        },
        child: AnimatedOpacity(
          opacity: widget.selectedCard != null && !isDisabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 56,
            width: 130,
            decoration: const BoxDecoration(
              color: darkerPurple,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Center(
              child: Text(
                'Lower',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ));
  }
}
