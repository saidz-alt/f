import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/curriculum.dart';
import '../models/learning_direction.dart';

enum LessonStatus { locked, unlocked, completed }

/// Tracks which lessons the learner has finished. Progress is stored
/// separately per [LearningDirection] — completing the Kabyle→French track
/// does not unlock the French→Kabyle track, and vice-versa.
///
/// Unlock rule (classic linear path): the first lesson of the whole course
/// is always available; every other lesson unlocks once the lesson before
/// it (in curriculum order) is completed.
class ProgressProvider extends ChangeNotifier {
  static const String _boxName = 'lessonProgress';

  late Box<dynamic> _box;
  bool _isReady = false;

  /// direction.name -> set of completed lesson ids
  final Map<String, Set<String>> _completed = {
    for (final d in LearningDirection.values) d.name: <String>{},
  };

  bool get isReady => _isReady;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    for (final d in LearningDirection.values) {
      final stored = (_box.get(d.name) as List?)?.cast<String>() ?? const [];
      _completed[d.name] = stored.toSet();
    }
    _isReady = true;
    notifyListeners();
  }

  bool isLessonComplete(String lessonId, LearningDirection direction) =>
      _completed[direction.name]!.contains(lessonId);

  void markLessonComplete(String lessonId, LearningDirection direction) {
    final set = _completed[direction.name]!;
    if (set.add(lessonId)) {
      _box.put(direction.name, set.toList());
      notifyListeners();
    }
  }

  int completedCount(LearningDirection direction) =>
      _completed[direction.name]!.length;

  /// Resolves the lock/unlock/completed state of a lesson given the full
  /// ordered lesson list for the active direction.
  LessonStatus statusFor(
    String lessonId,
    List<Lesson> orderedLessons,
    LearningDirection direction,
  ) {
    if (isLessonComplete(lessonId, direction)) return LessonStatus.completed;

    final index = orderedLessons.indexWhere((l) => l.id == lessonId);
    if (index <= 0) return LessonStatus.unlocked; // first lesson (or unknown)

    final previous = orderedLessons[index - 1];
    return isLessonComplete(previous.id, direction)
        ? LessonStatus.unlocked
        : LessonStatus.locked;
  }
}
