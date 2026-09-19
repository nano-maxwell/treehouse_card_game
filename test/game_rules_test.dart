import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:treehouse_card_game/cardgame.dart';
import 'package:treehouse_card_game/playingcard.dart';

void main() {
  CardModel card(String name) => CardModel(name);

  List<CardModel> activePiles() => List<CardModel>.filled(
        9,
        card('two-of-clubs'),
      );

  group('card values', () {
    test('ace is low and king is high', () {
      expect(card('ace-of-spades').getValue(), 1);
      expect(card('king-of-hearts').getValue(), 13);
    });

    test('a cleared pile has no playable value', () {
      expect(card('playing-card').getValue(), 0);
    });
  });

  group('higher and lower guesses', () {
    test('higher is correct only for a higher revealed value', () {
      expect(
        isCorrectGuess(
          selectedCard: card('five-of-hearts'),
          revealedCard: card('eight-of-spades'),
          checkingHigher: true,
        ),
        isTrue,
      );
    });

    test('lower is correct only for a lower revealed value', () {
      expect(
        isCorrectGuess(
          selectedCard: card('queen-of-hearts'),
          revealedCard: card('nine-of-spades'),
          checkingHigher: false,
        ),
        isTrue,
      );
    });

    test('matching values are incorrect for both guesses', () {
      final selectedCard = card('queen-of-hearts');
      final revealedCard = card('queen-of-spades');

      expect(
        isCorrectGuess(
          selectedCard: selectedCard,
          revealedCard: revealedCard,
          checkingHigher: true,
        ),
        isFalse,
      );
      expect(
        isCorrectGuess(
          selectedCard: selectedCard,
          revealedCard: revealedCard,
          checkingHigher: false,
        ),
        isFalse,
      );
    });
  });

  group('end-of-turn status', () {
    test('loses when every pile has been cleared', () {
      final clearedPiles = List<CardModel>.filled(
        9,
        card('playing-card'),
      );

      expect(
        gameStatusForTurn(visibleCards: clearedPiles, deckIsEmpty: false),
        GameStatus.lost,
      );
    });

    test('wins when the deck is empty and a pile remains', () {
      expect(
        gameStatusForTurn(visibleCards: activePiles(), deckIsEmpty: true),
        GameStatus.won,
      );
    });

    test('continues while cards and playable piles remain', () {
      expect(
        gameStatusForTurn(visibleCards: activePiles(), deckIsEmpty: false),
        GameStatus.playing,
      );
    });
  });

  test('a new shuffled deck contains every card exactly once', () {
    final deck = shuffledDeck(random: math.Random(4));

    expect(deck, hasLength(52));
    expect(deck.map((card) => card.name).toSet(), hasLength(52));
    expect(deck.map((card) => card.name), containsAll(fullDeck));
  });
}
