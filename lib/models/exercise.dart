import 'dart:math';

import 'curriculum.dart';
import 'learning_direction.dart';

/// The four interactive exercise kinds. Modeled as a sealed hierarchy so the
/// lesson screen can switch over them exhaustively.
sealed class Exercise {
  const Exercise();
}

/// Show a target-language word; the learner taps the matching picture (emoji).
class PictureMatchExercise extends Exercise {
  final String word; // word in the language being learned
  final bool wordIsKabyle; // whether [word] should be spoken as Kabyle
  final List<String> emojis; // option pictures
  final int correctIndex;

  const PictureMatchExercise({
    required this.word,
    required this.wordIsKabyle,
    required this.emojis,
    required this.correctIndex,
  });
}

/// Play audio; the learner taps the matching written form.
class ListenTapExercise extends Exercise {
  final String spokenText; // text to be spoken (target language, French only)
  final List<String> options; // written options (target language)
  final int correctIndex;

  const ListenTapExercise({
    required this.spokenText,
    required this.options,
    required this.correctIndex,
  });
}

/// Assemble the target-language sentence by tapping scattered word tiles.
class WordBankExercise extends Exercise {
  final String promptSentence; // shown in the known language
  final List<String> correctTokens; // ordered target-language tokens
  final List<String> bank; // shuffled tokens (+ distractors)

  const WordBankExercise({
    required this.promptSentence,
    required this.correctTokens,
    required this.bank,
  });
}

/// Type the translation. Checked with the forgiving [AnswerCheck] algorithm.
class TextInputExercise extends Exercise {
  final String promptWord; // shown in the known language
  final String promptEmoji;
  final String expected; // accepted target-language answer
  final bool answerIsKabyle;

  const TextInputExercise({
    required this.promptWord,
    required this.promptEmoji,
    required this.expected,
    required this.answerIsKabyle,
  });
}

/// A candidate answer reported by an exercise widget to the lesson screen.
/// `null` from an exercise means "not answerable yet" (Check stays disabled).
class ExerciseAnswer {
  final bool isCorrect;

  /// Human-readable correct answer, shown in the red "incorrect" sheet.
  final String correctText;

  const ExerciseAnswer({required this.isCorrect, required this.correctText});
}

/// Builds a varied, ordered exercise set for one lesson in one direction.
///
/// Adaptation rule: Listen&Tap requires the ANSWER language to be audible.
/// French has TTS; Kabyle does not (until native recordings ship), so
/// Listen&Tap is only generated when the learner's target is French
/// (Kabyle→French). In the other direction it's swapped for extra
/// picture-match / text-input so the lesson stays full and playable.
class ExerciseGenerator {
  final Random _rng;
  ExerciseGenerator({int? seed}) : _rng = Random(seed);

  List<Exercise> generate(Lesson lesson, LearningDirection direction) {
    final words = lesson.words;
    if (words.isEmpty) return const [];

    final targetIsFrench = direction == LearningDirection.kabyleToFrench;
    final answerIsKabyle = direction == LearningDirection.frenchToKabyle;
    final exercises = <Exercise>[];

    for (var i = 0; i < words.length; i++) {
      final word = words[i];

      // 1) Every word gets a picture-match (introduces / reinforces meaning).
      exercises.add(_pictureMatch(word, words, direction));

      // 2) Alternate a second modality per word.
      final secondKind = i % 2;
      if (secondKind == 0 && targetIsFrench) {
        // Listen & Tap (French audio available).
        exercises.add(_listenTap(word, words, direction));
      } else {
        // Type the translation.
        exercises.add(_textInput(word, direction, answerIsKabyle));
      }
    }

    // 3) Phrases power the sentence exercises. Each gets a word-bank plus a
    //    second modality so phrase-only lessons stay varied: Listen & Tap when
    //    the target is French (audio available), otherwise a short text-input.
    final phrases = lesson.phrases;
    for (var i = 0; i < phrases.length; i++) {
      final phrase = phrases[i];
      exercises.add(_wordBank(phrase, direction));

      if (targetIsFrench) {
        exercises.add(_phraseListenTap(phrase, phrases, direction));
      } else if (phrase.answerTokens(direction).length <= 2) {
        exercises.add(_phraseTextInput(phrase, direction, answerIsKabyle));
      }
    }

    exercises.shuffle(_rng);
    return exercises;
  }

  PictureMatchExercise _pictureMatch(
    WordPair word,
    List<WordPair> pool,
    LearningDirection direction,
  ) {
    final distractors = _pickDistractors(word, pool, 3);
    final options = [word, ...distractors]..shuffle(_rng);
    return PictureMatchExercise(
      word: word.answer(direction),
      wordIsKabyle: direction == LearningDirection.frenchToKabyle,
      emojis: options.map((w) => w.emoji).toList(),
      correctIndex: options.indexOf(word),
    );
  }

  ListenTapExercise _listenTap(
    WordPair word,
    List<WordPair> pool,
    LearningDirection direction,
  ) {
    final distractors = _pickDistractors(word, pool, 3);
    final options = [word, ...distractors]..shuffle(_rng);
    return ListenTapExercise(
      spokenText: word.answer(direction),
      options: options.map((w) => w.answer(direction)).toList(),
      correctIndex: options.indexOf(word),
    );
  }

  TextInputExercise _textInput(
    WordPair word,
    LearningDirection direction,
    bool answerIsKabyle,
  ) {
    return TextInputExercise(
      promptWord: word.prompt(direction),
      promptEmoji: word.emoji,
      expected: word.answer(direction),
      answerIsKabyle: answerIsKabyle,
    );
  }

  WordBankExercise _wordBank(Phrase phrase, LearningDirection direction) {
    final correct = phrase.answerTokens(direction);
    // Add one or two distractor tiles from the opposite token set to make it
    // non-trivial, then shuffle the whole bank.
    final otherTokens = direction == LearningDirection.kabyleToFrench
        ? phrase.tokensKab
        : phrase.tokensFr;
    final distractors = otherTokens.take(1).toList();
    final bank = [...correct, ...distractors]..shuffle(_rng);
    return WordBankExercise(
      promptSentence: phrase.prompt(direction),
      correctTokens: correct,
      bank: bank,
    );
  }

  ListenTapExercise _phraseListenTap(
    Phrase phrase,
    List<Phrase> pool,
    LearningDirection direction,
  ) {
    final others = pool.where((p) => p.id != phrase.id).toList()..shuffle(_rng);
    final distractors = others.take(3).toList();
    final options = [phrase, ...distractors]..shuffle(_rng);
    return ListenTapExercise(
      spokenText: phrase.answer(direction),
      options: options.map((p) => p.answer(direction)).toList(),
      correctIndex: options.indexOf(phrase),
    );
  }

  TextInputExercise _phraseTextInput(
    Phrase phrase,
    LearningDirection direction,
    bool answerIsKabyle,
  ) {
    return TextInputExercise(
      promptWord: phrase.prompt(direction),
      promptEmoji: '💬',
      expected: phrase.answer(direction),
      answerIsKabyle: answerIsKabyle,
    );
  }

  List<WordPair> _pickDistractors(WordPair correct, List<WordPair> pool, int n) {
    final others = pool.where((w) => w.id != correct.id).toList()..shuffle(_rng);
    if (others.length >= n) return others.take(n).toList();
    // Small lesson: pad by repeating (kept distinct enough by emoji variety).
    final result = <WordPair>[...others];
    var i = 0;
    while (result.length < n && others.isNotEmpty) {
      result.add(others[i % others.length]);
      i++;
    }
    return result;
  }
}
