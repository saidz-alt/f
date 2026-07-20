import 'package:flutter_test/flutter_test.dart';
import 'package:kabyle_duo/models/curriculum.dart';
import 'package:kabyle_duo/models/exercise.dart';
import 'package:kabyle_duo/models/learning_direction.dart';

Lesson _lesson() => const Lesson(
      id: 'l',
      titleFr: 'Test',
      titleKab: 'Test',
      icon: 'star',
      xpReward: 10,
      words: [
        WordPair(id: 'a', kab: 'itij', fr: 'soleil', emoji: '☀️'),
        WordPair(id: 'b', kab: 'aggur', fr: 'lune', emoji: '🌙'),
        WordPair(id: 'c', kab: 'itri', fr: 'étoile', emoji: '⭐'),
        WordPair(id: 'd', kab: 'aman', fr: 'eau', emoji: '💧'),
      ],
      phrases: [
        Phrase(
          id: 'p',
          kab: 'd aydi',
          fr: "c'est un chien",
          tokensKab: ['d', 'aydi'],
          tokensFr: ["c'est", 'un', 'chien'],
        ),
      ],
    );

void main() {
  group('ExerciseGenerator', () {
    test('produces exercises for every word plus each phrase', () {
      final ex = ExerciseGenerator(seed: 1)
          .generate(_lesson(), LearningDirection.kabyleToFrench);
      // 2 exercises per word (4 words) + 1 word-bank per phrase (1) = 9.
      expect(ex.length, 9);
      expect(ex.whereType<WordBankExercise>().length, 1);
    });

    test('Listen&Tap only appears when the target language is French', () {
      final kabToFr = ExerciseGenerator(seed: 2)
          .generate(_lesson(), LearningDirection.kabyleToFrench);
      final frToKab = ExerciseGenerator(seed: 2)
          .generate(_lesson(), LearningDirection.frenchToKabyle);

      expect(kabToFr.whereType<ListenTapExercise>(), isNotEmpty);
      // No Kabyle TTS -> no listen&tap when learning Kabyle.
      expect(frToKab.whereType<ListenTapExercise>(), isEmpty);
    });

    test('picture-match correctIndex points at the prompted word', () {
      final list = ExerciseGenerator(seed: 3)
          .generate(_lesson(), LearningDirection.kabyleToFrench)
          .whereType<PictureMatchExercise>();
      for (final pm in list) {
        expect(pm.correctIndex, inInclusiveRange(0, pm.emojis.length - 1));
        expect(pm.emojis.length, 4);
      }
    });

    test('word-bank correct tokens match the target direction', () {
      final wb = ExerciseGenerator(seed: 4)
          .generate(_lesson(), LearningDirection.frenchToKabyle)
          .whereType<WordBankExercise>()
          .first;
      // Learning Kabyle -> the answer tokens are the Kabyle ones.
      expect(wb.correctTokens, ['d', 'aydi']);
      // Every correct token exists in the shuffled bank.
      for (final t in wb.correctTokens) {
        expect(wb.bank.contains(t), isTrue);
      }
    });
  });
}
