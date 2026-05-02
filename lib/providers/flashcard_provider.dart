import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/hive_service.dart';
import '../services/groq_service.dart';

class FlashcardProvider with ChangeNotifier {
  List<Flashcard> _flashcards = [];
  bool _isLoading = false;

  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;

  FlashcardProvider() {
    loadFlashcards();
  }

  void loadFlashcards() {
    _flashcards = HiveService.getAllFlashcards();
    notifyListeners();
  }

  List<Flashcard> getDueCards() {
    return _flashcards.where((c) => c.isDue).toList();
  }

  Map<String, List<Flashcard>> getDecks() {
    final Map<String, List<Flashcard>> decks = {};
    for (final card in _flashcards) {
      if (!decks.containsKey(card.topic)) {
        decks[card.topic] = [];
      }
      decks[card.topic]!.add(card);
    }
    return decks;
  }

  int getDueCount(String topic) {
    return _flashcards.where((c) => c.topic == topic && c.isDue).length;
  }

  Future<void> generateFlashcardsFromTopic(String topic) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCards = await GroqService().generateTopicFlashcards(topic);
      for (final card in newCards) {
        await HiveService.addFlashcard(card);
      }
      loadFlashcards();
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateFlashcardsFromText(String text, String topic) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCards = await GroqService().generateFlashcards(text, topic: topic);
      for (final card in newCards) {
        await HiveService.addFlashcard(card);
      }
      loadFlashcards();
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reviewCard(Flashcard card, int quality) async {
    card.updateSRS(quality);
    await HiveService.addFlashcard(card); // Update in Hive
    loadFlashcards();
  }

  Future<void> deleteDeck(String topic) async {
    final cardsToDelete = _flashcards.where((c) => c.topic == topic).toList();
    for (final card in cardsToDelete) {
      await HiveService.deleteFlashcard(card.id);
    }
    loadFlashcards();
  }

  Future<void> deleteFlashcard(String id) async {
    await HiveService.deleteFlashcard(id);
    loadFlashcards();
  }
}
