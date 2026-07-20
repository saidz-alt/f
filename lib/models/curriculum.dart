import 'package:flutter/material.dart';

import 'learning_direction.dart';

/// ---------------------------------------------------------------------------
/// Data models for the bidirectional Kabyle (Taqbaylit) <-> French curriculum.
///
/// Design notes:
///  * Every learnable item stores BOTH languages (`kab` + `fr`). The exercise
///    engine (Stage 3) decides at runtime which side is the prompt and which is
///    the expected answer based on the active [LearningDirection]. This keeps
///    the content DRY — one JSON entry powers both course directions.
///  * A `tifinagh` field carries the optional Amazigh script rendering.
///  * `emoji` is the offline-friendly "picture" for picture-matching. An
///    optional `image` asset path is reserved for real illustrations later.
///
///  IMPORTANT: All Kabyle strings in `assets/curriculum/curriculum.json` are
///  provisional and must be validated by a fluent Taqbaylit speaker before a
///  public release. The schema and engine are final; only the words are draft.
/// ---------------------------------------------------------------------------

@immutable
class WordPair {
  final String id;
  final String kab;
  final String fr;
  final String? tifinagh;
  final String emoji;
  final String? image;

  const WordPair({
    required this.id,
    required this.kab,
    required this.fr,
    this.tifinagh,
    required this.emoji,
    this.image,
  });

  factory WordPair.fromJson(Map<String, dynamic> j) => WordPair(
        id: j['id'] as String,
        kab: j['kab'] as String,
        fr: j['fr'] as String,
        tifinagh: j['tifinagh'] as String?,
        emoji: (j['emoji'] as String?) ?? '❓',
        image: j['image'] as String?,
      );

  /// The word shown to the learner (their known language).
  String prompt(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? kab : fr;

  /// The word the learner must produce (their target language).
  String answer(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? fr : kab;

  /// Tifinagh only makes sense to surface when Kabyle is the answer side.
  String? answerScript(LearningDirection d) =>
      d == LearningDirection.frenchToKabyle ? tifinagh : null;
}

@immutable
class Phrase {
  final String id;
  final String kab;
  final String fr;
  final List<String> tokensKab;
  final List<String> tokensFr;

  const Phrase({
    required this.id,
    required this.kab,
    required this.fr,
    required this.tokensKab,
    required this.tokensFr,
  });

  factory Phrase.fromJson(Map<String, dynamic> j) => Phrase(
        id: j['id'] as String,
        kab: j['kab'] as String,
        fr: j['fr'] as String,
        tokensKab: (j['tokens_kab'] as List).cast<String>(),
        tokensFr: (j['tokens_fr'] as List).cast<String>(),
      );

  String answer(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? fr : kab;

  String prompt(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? kab : fr;

  /// Correctly-ordered tokens for the answer language (the target the learner
  /// assembles in the word-bank exercise).
  List<String> answerTokens(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? tokensFr : tokensKab;
}

@immutable
class Lesson {
  final String id;
  final String titleFr;
  final String titleKab;
  final String icon;
  final int xpReward;
  final List<WordPair> words;
  final List<Phrase> phrases;

  const Lesson({
    required this.id,
    required this.titleFr,
    required this.titleKab,
    required this.icon,
    required this.xpReward,
    required this.words,
    required this.phrases,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        titleFr: j['title_fr'] as String,
        titleKab: j['title_kab'] as String,
        icon: (j['icon'] as String?) ?? 'star',
        xpReward: (j['xp'] as int?) ?? 10,
        words: (j['words'] as List? ?? [])
            .map((e) => WordPair.fromJson(e as Map<String, dynamic>))
            .toList(),
        phrases: (j['phrases'] as List? ?? [])
            .map((e) => Phrase.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String title(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? titleKab : titleFr;
}

@immutable
class Unit {
  final String id;
  final String titleFr;
  final String titleKab;
  final String theme;
  final Color color;
  final List<Lesson> lessons;

  const Unit({
    required this.id,
    required this.titleFr,
    required this.titleKab,
    required this.theme,
    required this.color,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
        id: j['id'] as String,
        titleFr: j['title_fr'] as String,
        titleKab: j['title_kab'] as String,
        theme: (j['theme'] as String?) ?? 'olive',
        color: _parseHexColor(j['color'] as String?) ?? const Color(0xFF58CC02),
        lessons: (j['lessons'] as List? ?? [])
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String title(LearningDirection d) =>
      d == LearningDirection.kabyleToFrench ? titleKab : titleFr;
}

@immutable
class Curriculum {
  final int version;
  final List<Unit> units;

  const Curriculum({required this.version, required this.units});

  factory Curriculum.fromJson(Map<String, dynamic> j) => Curriculum(
        version: (j['version'] as int?) ?? 1,
        units: (j['units'] as List? ?? [])
            .map((e) => Unit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Flat, ordered list of every lesson across all units — handy for global
  /// progress math (e.g. "12 of 40 lessons complete").
  List<Lesson> get allLessons =>
      units.expand((u) => u.lessons).toList(growable: false);

  Lesson? lessonById(String id) {
    for (final u in units) {
      for (final l in u.lessons) {
        if (l.id == id) return l;
      }
    }
    return null;
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.replaceFirst('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}
