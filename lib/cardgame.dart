import 'package:flutter/material.dart';
import 'package:treehouse_card_game/flipcardwidget.dart';
import 'package:treehouse_card_game/playingcard.dart';
import 'package:flutter/scheduler.dart' show TickerCanceled;

const Color darkerPurple = Color.fromARGB(255, 85, 105, 220);
const Color bgPurple = Color.fromARGB(255, 144, 157, 255);

const List<String> fullDeck = [
  'ace-of-spades',
  'two-of-spades',
  'three-of-spades',
  'four-of-spades',
  'five-of-spades',
  'six-of-spades',
  'seven-of-spades',
  'eight-of-spades',
  'nine-of-spades',
  'ten-of-spades',
  'jack-of-spades',
  'queen-of-spades',
  'king-of-spades',
  'ace-of-hearts',
  'two-of-hearts',
  'three-of-hearts',
  'four-of-hearts',
  'five-of-hearts',
  'six-of-hearts',
  'seven-of-hearts',
  'eight-of-hearts',
  'nine-of-hearts',
  'ten-of-hearts',
  'jack-of-hearts',
  'queen-of-hearts',
  'king-of-hearts',
  'ace-of-diamonds',
  'two-of-diamonds',
  'three-of-diamonds',
  'four-of-diamonds',
  'five-of-diamonds',
  'six-of-diamonds',
  'seven-of-diamonds',
  'eight-of-diamonds',
  'nine-of-diamonds',
  'ten-of-diamonds',
  'jack-of-diamonds',
  'queen-of-diamonds',
  'king-of-diamonds',
  'ace-of-clubs',
  'two-of-clubs',
  'three-of-clubs',
  'four-of-clubs',
  'five-of-clubs',
  'six-of-clubs',
  'seven-of-clubs',
  'eight-of-clubs',
  'nine-of-clubs',
  'ten-of-clubs',
  'jack-of-clubs',
  'queen-of-clubs',
  'king-of-clubs',
];

const Map<String, int> cardValues = {
  'ace': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'jack': 11,
  'queen': 12,
  'king': 13,
};

enum GameStatus {
  playing,
  won,
  lost,
}

class CardGame extends StatefulWidget {
  const CardGame({super.key});

  @override
  State<CardGame> createState() => _CardGameState();
}

class _CardGameState extends State<CardGame> {
  List<CardModel> visibleCards = [];
  late List<CardModel> cardDeck;

  int? tappedIndex;
  final FlipCardController controller = FlipCardController();

  CardModel? nextCard;
  bool isAnimating = false;
  GameStatus gameStatus = GameStatus.playing;

  int roundId = 0;

  int get cardsRemaining {
    return cardDeck.length + (nextCard == null ? 0 : 1);
  }

  String get gameStatusText {
    switch (gameStatus) {
      case GameStatus.playing:
        return 'Cards Remaining: $cardsRemaining';
      case GameStatus.won:
        return 'Game complete!';
      case GameStatus.lost:
        return 'Game over!';
    }
  }

  @override
  void initState() {
    super.initState();
    _dealNewGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheCardImages(context);
      }
    });
  }

  void _dealNewGame() {
    cardDeck = fullDeck.map((name) => CardModel(name)).toList()..shuffle();

    visibleCards = List.generate(
      9,
      (_) => cardDeck.removeAt(0),
    );

    nextCard = cardDeck.removeAt(0);
    tappedIndex = null;
    isAnimating = false;
    gameStatus = GameStatus.playing;
    roundId++;
  }

  void _handleCardTap(int index) {
    if (isAnimating || gameStatus != GameStatus.playing) {
      return;
    }

    setState(() {
      tappedIndex = index == tappedIndex ? null : index;
    });
  }

  Future<void> _handleGuess({required bool checkingHigher}) async {
    final selectedIndex = tappedIndex;
    final revealedCard = nextCard;

    if (isAnimating ||
        gameStatus != GameStatus.playing ||
        selectedIndex == null ||
        revealedCard == null) {
      return;
    }

    final activeRoundId = roundId;

    setState(() {
      isAnimating = true;
    });

    await controller.flipCard();

    if (!mounted || activeRoundId != roundId) {
      return;
    }

    setState(() {
      final selectedCard = visibleCards[selectedIndex];

      final guessedCorrectly = checkingHigher
          ? selectedCard.getValue() < revealedCard.getValue()
          : selectedCard.getValue() > revealedCard.getValue();

      visibleCards[selectedIndex] =
          guessedCorrectly ? revealedCard : CardModel('playing-card');

      tappedIndex = null;

      final noPlayableCards = visibleCards.every(
        (card) => card.name == 'playing-card',
      );

      if (noPlayableCards) {
        gameStatus = GameStatus.lost;
        nextCard = null;
      } else if (cardDeck.isEmpty) {
        gameStatus = GameStatus.won;
        nextCard = null;
      } else {
        nextCard = cardDeck.removeAt(0);
      }

      isAnimating = false;
    });
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: darkerPurple,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
              setState(_dealNewGame);
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _precacheCardImages(BuildContext context) {
    for (final cardName in fullDeck) {
      precacheImage(
        AssetImage('assets/$cardName.png'),
        context,
      );
    }

    precacheImage(
      const AssetImage('assets/playing-card.png'),
      context,
    );
  }

  Widget _buildCard(int index, double cardSize) {
    final card = visibleCards[index];

    return SizedBox(
      height: cardSize,
      width: cardSize,
      child: PlayingCard(
        cardName: card.name,
        isSelected: tappedIndex == index,
        isDimmed: tappedIndex == null || tappedIndex == index,
        onTap: () {
          if (gameStatus == GameStatus.playing &&
              card.name != 'playing-card') {
            _handleCardTap(index);
          }
        },
      ),
    );
  }

  Widget _buildCardGrid(double cardSize) {
    Widget buildRow(int firstIndex) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCard(firstIndex, cardSize),
          const SizedBox(width: 5),
          _buildCard(firstIndex + 1, cardSize),
          const SizedBox(width: 5),
          _buildCard(firstIndex + 2, cardSize),
        ],
      );
    }

    return Column(
      children: [
        buildRow(0),
        const SizedBox(height: 30),
        buildRow(3),
        const SizedBox(height: 30),
        buildRow(6),
      ],
    );
  }

  Widget _buildDeck() {
    return Stack(
      alignment: const Alignment(0, -1),
      children: [
        Image.asset(
          'assets/card-deck.png',
          height: 125,
        ),
        if (nextCard != null)
          FlipCardWidget(
            front: Image.asset(
              'assets/${nextCard!.name}.png',
              height: 110,
            ),
            controller: controller,
            back: Image.asset(
              'assets/playing-card.png',
              height: 110,
            ),
          )
        else
          const SizedBox(
            height: 110,
            width: 110,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard =
        gameStatus == GameStatus.playing && tappedIndex != null
            ? visibleCards[tappedIndex!]
            : null;

    return Scaffold(
      backgroundColor: bgPurple,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 16.0;
            const totalCardSpacing = 10.0;

            final cardSize = ((constraints.maxWidth -
                        horizontalPadding * 2 -
                        totalCardSpacing) /
                    3)
                .clamp(0.0, 110.0)
                .toDouble();

            final minimumHeight = (constraints.maxHeight - 32)
                .clamp(0.0, double.infinity)
                .toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minimumHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: isAnimating
                                ? null
                                : () {
                                    _showResetConfirmationDialog(context);
                                  },
                            child: AnimatedOpacity(
                              opacity: isAnimating ? 0.4 : 1,
                              duration: const Duration(milliseconds: 100),
                              child: const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 35,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: Icon(
                                Icons.help_outline_rounded,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCardGrid(cardSize),
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HigherButton(
                          selectedCard: selectedCard,
                          onPressed: () {
                            _handleGuess(checkingHigher: true);
                          },
                        ),
                        const SizedBox(width: 15),
                        LowerButton(
                          selectedCard: selectedCard,
                          onPressed: () {
                            _handleGuess(checkingHigher: false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    _buildDeck(),
                    const SizedBox(height: 30),
                    Text(
                      gameStatusText,
                      textAlign: TextAlign.center,
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
          },
        ),
      ),
    );
  }
}

class HigherButton extends StatelessWidget {
  final CardModel? selectedCard;
  final VoidCallback onPressed;

  const HigherButton({
    super.key,
    required this.selectedCard,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        selectedCard == null || selectedCard!.getValue() == 13;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          width: 130,
          decoration: const BoxDecoration(
            color: darkerPurple,
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
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
      ),
    );
  }
}

class LowerButton extends StatelessWidget {
  final CardModel? selectedCard;
  final VoidCallback onPressed;

  const LowerButton({
    super.key,
    required this.selectedCard,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        selectedCard == null || selectedCard!.getValue() == 1;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          width: 130,
          decoration: const BoxDecoration(
            color: darkerPurple,
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
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
      ),
    );
  }
}