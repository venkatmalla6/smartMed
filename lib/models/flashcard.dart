import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 6)
class Flashcard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String deckId;

  @HiveField(2)
  final String front;

  @HiveField(3)
  final String back;

  @HiveField(4)
  final String topic;

  @HiveField(5)
  int interval; // Days until next review

  @HiveField(6)
  double easeFactor;

  @HiveField(7)
  int repetitions;

  @HiveField(8)
  DateTime nextReview;

  @HiveField(9)
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.topic,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    DateTime? nextReview,
    DateTime? createdAt,
  })  : nextReview = nextReview ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Flashcard.create({
    required String front,
    required String back,
    required String topic,
    String? deckId,
  }) {
    return Flashcard(
      id: const Uuid().v4(),
      deckId: deckId ?? topic,
      front: front,
      back: back,
      topic: topic,
    );
  }

  /// SM-2 Algorithm for Spaced Repetition
  /// [quality] is the user's score from 0-5:
  /// 5: perfect response
  /// 4: correct response after a hesitation
  /// 3: correct response recalled with serious difficulty
  /// 2: incorrect response; where the correct one seemed easy to recall
  /// 1: incorrect response; the correct one remembered
  /// 0: complete blackout.
  void updateSRS(int quality) {
    if (quality >= 3) {
      // Correct response
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    } else {
      // Incorrect response
      repetitions = 0;
      interval = 1;
    }

    // Update ease factor: EF' = f(EF, q)
    // EF' := EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    // Set next review date
    nextReview = DateTime.now().add(Duration(days: interval));
    save(); // Save to Hive
  }

  bool get isDue => DateTime.now().isAfter(nextReview);
}
