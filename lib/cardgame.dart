import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:treehouse_card_game/playingcard.dart';

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

class _CardGameState extends State<CardGame> with TickerProviderStateMixin {
  List<CardModel> visibleCards = [];
  late List<CardModel> cardDeck;

  int? tappedIndex;
  final _DeckCardController controller = _DeckCardController();
  final GlobalKey _deckCardKey = GlobalKey();
  final List<GlobalKey> _pileKeys = List.generate(9, (_) => GlobalKey());

  CardModel? nextCard;
  bool isAnimating = false;
  GameStatus gameStatus = GameStatus.playing;

  int roundId = 0;
  late final AnimationController _feedbackController;
  int? _wrongPileIndex;
  bool _hideDeckFace = false;
  final Set<int> _landingPileIndices = {};

  int get cardsRemaining {
    return cardDeck.length + (nextCard == null ? 0 : 1);
  }

  double get gameProgress {
    final drawableCards = fullDeck.length - visibleCards.length;
    return ((drawableCards - cardsRemaining) / drawableCards).clamp(0.0, 1.0);
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

  String get instructionText {
    if (gameStatus == GameStatus.won) {
      return 'You made it through the deck.';
    }
    if (gameStatus == GameStatus.lost) {
      return 'All nine piles have been cleared.';
    }
    if (isAnimating) {
      return 'Revealing the next card...';
    }
    if (tappedIndex == null) {
      return 'Choose a card pile.';
    }
    return 'Will the next card be higher or lower?';
  }

  @override
  void initState() {
    super.initState();

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    _dealNewGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheCardImages(context);
      }
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
    _wrongPileIndex = null;
    _hideDeckFace = false;
    _landingPileIndices.clear();
    _feedbackController.reset();
    controller.reset();
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
    final selectedCard = visibleCards[selectedIndex];
    final guessedCorrectly = checkingHigher
        ? selectedCard.getValue() < revealedCard.getValue()
        : selectedCard.getValue() > revealedCard.getValue();
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    setState(() {
      isAnimating = true;
    });

    if (!reduceMotion) {
      await controller.reveal();
      await Future<void>.delayed(const Duration(milliseconds: 240));
    }

    if (!mounted || activeRoundId != roundId) {
      return;
    }

    if (guessedCorrectly) {
      if (reduceMotion) {
        setState(() {
          visibleCards[selectedIndex] = revealedCard;
        });
      } else {
        setState(() {
          _hideDeckFace = true;
        });

        await _animateCardToPile(
          pileIndex: selectedIndex,
          card: revealedCard,
          activeRoundId: activeRoundId,
          onArrive: () {
            setState(() {
              visibleCards[selectedIndex] = revealedCard;
            });
          },
        );
      }

      if (!mounted || activeRoundId != roundId) {
        return;
      }

      controller.reset();
      HapticFeedback.lightImpact();

      setState(() {
        _hideDeckFace = false;
        if (!reduceMotion) {
          _landingPileIndices.add(selectedIndex);
        }
        _finishTurn();
      });

      if (!reduceMotion) {
        _clearLandingAnimationAfterDelay(selectedIndex, activeRoundId);
      }
      _queueResultDialog(activeRoundId);
    } else {
      if (!reduceMotion) {
        await _animateIncorrectGuess(selectedIndex);
      }

      if (!mounted || activeRoundId != roundId) {
        return;
      }

      controller.reset();
      _feedbackController.reset();
      HapticFeedback.mediumImpact();

      setState(() {
        _wrongPileIndex = null;
        visibleCards[selectedIndex] = CardModel('playing-card');
        _finishTurn();
      });
      _queueResultDialog(activeRoundId);
    }
  }

  void _finishTurn() {
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
  }

  Future<void> _animateIncorrectGuess(int pileIndex) async {
    setState(() {
      _wrongPileIndex = pileIndex;
    });

    try {
      await _feedbackController.forward(from: 0).orCancel;
    } on TickerCanceled {
      // The game was disposed while feedback was playing.
    }
  }

  void _clearLandingAnimationAfterDelay(int pileIndex, int activeRoundId) {
    Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
      if (!mounted || activeRoundId != roundId) {
        return;
      }

      setState(() {
        _landingPileIndices.remove(pileIndex);
      });
    });
  }

  Rect? _rectForKey(GlobalKey key, RenderBox overlayBox) {
    final keyContext = key.currentContext;
    if (keyContext == null) {
      return null;
    }

    final renderObject = keyContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final topLeft = renderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final bottomRight = renderObject.localToGlobal(
      renderObject.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  Future<void> _animateCardToPile({
    required int pileIndex,
    required CardModel card,
    required int activeRoundId,
    required VoidCallback onArrive,
  }) async {
    final overlay = Overlay.of(context);
    final overlayRenderObject = overlay.context.findRenderObject();

    if (overlayRenderObject is! RenderBox) {
      onArrive();
      return;
    }

    final startRect = _rectForKey(_deckCardKey, overlayRenderObject);
    final endRect = _rectForKey(_pileKeys[pileIndex], overlayRenderObject);

    if (startRect == null || endRect == null) {
      onArrive();
      return;
    }

    final flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final flightAnimation = CurvedAnimation(
      parent: flightController,
      curve: Curves.easeInOutCubic,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: flightAnimation,
          builder: (context, child) {
            final progress = flightAnimation.value;
            final inverseProgress = 1 - progress;
            final start = startRect.center;
            final end = endRect.center;
            final controlPoint = Offset(
              (start.dx + end.dx) / 2,
              math.min(start.dy, end.dy) - 70,
            );

            final position = start * (inverseProgress * inverseProgress) +
                controlPoint * (2 * inverseProgress * progress) +
                end * (progress * progress);
            final size = Size.lerp(
              startRect.size,
              endRect.size,
              progress,
            )!;

            return Positioned(
              left: position.dx - size.width / 2,
              top: position.dy - size.height / 2,
              width: size.width,
              height: size.height,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: 0.05 * math.sin(math.pi * progress),
                  child: Image.asset(
                    'assets/${card.name}.png',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);

    try {
      await flightController.forward().orCancel;

      if (mounted && activeRoundId == roundId) {
        onArrive();
      }
    } on TickerCanceled {
      // The game was disposed while the card was moving.
    } finally {
      entry.remove();
      flightController.dispose();
    }
  }

  Future<void> _showLeaveConfirmationDialog() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 225, 225, 225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Are you sure you want to leave the game?',
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
              Navigator.of(dialogContext).pop(false);
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
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!mounted || shouldLeave != true) {
      return;
    }

    Navigator.of(context).maybePop();
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

  void _showHowToPlayDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 245, 245, 250),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: darkerPurple),
            SizedBox(width: 10),
            Text(
              'How to play',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '1. Choose one of the nine card piles.\n\n'
          '2. Guess whether the next card will be higher or lower.\n\n'
          '3. A correct card replaces the selected card. An incorrect guess '
          'clears that pile.\n\n'
          'Aces are low, kings are high, and matching values count as an '
          'incorrect guess. Clear the deck before losing all nine piles to win.',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            height: 1.3,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: darkerPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _queueResultDialog(int activeRoundId) {
    if (gameStatus == GameStatus.playing) {
      return;
    }

    final result = gameStatus;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || roundId != activeRoundId || gameStatus != result) {
        return;
      }

      _showResultDialog(result);
    });
  }

  void _showResultDialog(GameStatus result) {
    final won = result == GameStatus.won;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(255, 245, 245, 250),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            won ? Icons.emoji_events_rounded : Icons.refresh_rounded,
            color: darkerPurple,
            size: 48,
          ),
          title: Text(
            won ? 'You won!' : 'Game over',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            won
                ? 'You successfully made it through the entire deck.'
                : 'All nine piles were cleared before the deck ran out.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: darkerPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await Future<void>.delayed(Duration.zero);
                if (!mounted) {
                  return;
                }

                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Home'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: darkerPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(_dealNewGame);
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play again'),
            ),
          ],
        ),
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
    final feedbackProgress =
        _wrongPileIndex == index ? _feedbackController.value : 0.0;
    final shakeOffset =
        math.sin(feedbackProgress * math.pi * 8) * (1 - feedbackProgress) * 10;
    final feedbackScale = 1 - (feedbackProgress * 0.14);
    final feedbackOpacity = 1 - feedbackProgress;
    final isSelected = tappedIndex == index;
    final isLanding = _landingPileIndices.contains(index);

    return SizedBox(
      key: _pileKeys[index],
      height: cardSize,
      width: cardSize,
      child: Transform.translate(
        offset: Offset(shakeOffset, 0),
        child: Transform.scale(
          scale: feedbackScale,
          child: Opacity(
            opacity: feedbackOpacity,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${card.name}-$isLanding'),
              tween: Tween<double>(
                begin: isLanding ? 0.88 : 1,
                end: 1,
              ),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: PlayingCard(
                cardName: card.name,
                isSelected: isSelected,
                isDimmed: tappedIndex == null || isSelected,
                onTap: () {
                  if (gameStatus == GameStatus.playing &&
                      card.name != 'playing-card') {
                    _handleCardTap(index);
                  }
                },
              ),
            ),
          ),
        ),
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
        const SizedBox(height: 14),
        buildRow(3),
        const SizedBox(height: 14),
        buildRow(6),
      ],
    );
  }

  Widget _buildDeck() {
    final deckCardOpacity = _wrongPileIndex != null
        ? 1 - _feedbackController.value
        : (_hideDeckFace ? 0.0 : 1.0);

    return Stack(
      alignment: const Alignment(0, -1),
      children: [
        Image.asset(
          'assets/card-deck.png',
          height: 125,
        ),
        if (nextCard != null)
          SizedBox(
            key: _deckCardKey,
            height: 110,
            width: 110,
            child: Opacity(
              opacity: deckCardOpacity,
              child: _DeckCardWidget(
                card: nextCard,
                controller: controller,
              ),
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
    final selectedCard = gameStatus == GameStatus.playing && tappedIndex != null
        ? visibleCards[tappedIndex!]
        : null;

    return Scaffold(
      backgroundColor: bgPurple,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Home',
                                onPressed: isAnimating
                                    ? null
                                    : () {
                                        _showLeaveConfirmationDialog();
                                      },
                                icon: const Icon(
                                  Icons.home_rounded,
                                  size: 30,
                                ),
                                color: Colors.white,
                                disabledColor: Colors.white38,
                              ),
                              IconButton(
                                tooltip: 'Start over',
                                onPressed: isAnimating
                                    ? null
                                    : () {
                                        _showResetConfirmationDialog(context);
                                      },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 30,
                                ),
                                color: Colors.white,
                                disabledColor: Colors.white38,
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'How to play',
                            onPressed: isAnimating
                                ? null
                                : () {
                                    _showHowToPlayDialog(context);
                                  },
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              size: 32,
                            ),
                            color: Colors.white,
                            disabledColor: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Treehouse Card Game',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        instructionText,
                        key: ValueKey(instructionText),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCardGrid(110),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    _buildDeck(),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1).animate(
                              animation,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        gameStatusText,
                        key: ValueKey(gameStatusText),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: '${(gameProgress * 100).round()} percent complete',
                      value: '$cardsRemaining cards remaining',
                      child: SizedBox(
                        width: 270,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: gameProgress),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckCardController {
  _DeckCardWidgetState? _state;

  Future<void> reveal() {
    return _state?.reveal() ?? Future<void>.value();
  }

  void reset() {
    _state?.reset();
  }
}

class _DeckCardWidget extends StatefulWidget {
  final CardModel? card;
  final _DeckCardController controller;

  const _DeckCardWidget({
    required this.card,
    required this.controller,
  });

  @override
  State<_DeckCardWidget> createState() => _DeckCardWidgetState();
}

class _DeckCardWidgetState extends State<_DeckCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant _DeckCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._state == this) {
        oldWidget.controller._state = null;
      }
      widget.controller._state = this;
    }
  }

  Future<void> reveal() async {
    if (_controller.isAnimating) {
      return;
    }

    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // The card was disposed while revealing.
    }
  }

  void reset() {
    if (mounted) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final showBack = angle < math.pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0025)
          ..rotateY(angle);

        final face = Image.asset(
          widget.card == null
              ? 'assets/playing-card.png'
              : 'assets/${widget.card!.name}.png',
          height: 110,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: showBack
              ? Image.asset(
                  'assets/playing-card.png',
                  height: 110,
                  fit: BoxFit.contain,
                )
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: face,
                ),
        );
      },
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
    final isDisabled = selectedCard == null || selectedCard!.getValue() == 13;

    return SizedBox(
      height: 56,
      width: 130,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkerPurple,
          disabledBackgroundColor: const Color.fromARGB(102, 85, 105, 220),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Higher',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
    final isDisabled = selectedCard == null || selectedCard!.getValue() == 1;

    return SizedBox(
      height: 56,
      width: 130,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkerPurple,
          disabledBackgroundColor: const Color.fromARGB(102, 85, 105, 220),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Lower',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
