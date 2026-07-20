import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/curriculum.dart';
import '../models/learning_direction.dart';
import '../services/game_state_provider.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../theme/lesson_icons.dart';
import '../widgets/lesson_node.dart';

/// The scrolling, winding "learning path" of circular lesson nodes grouped
/// under unit banners. Callers supply what happens when a lesson is tapped
/// (Stage 3 wires this to the interactive lesson screen).
class PathView extends StatelessWidget {
  final Curriculum curriculum;
  final void Function(Lesson lesson, Unit unit) onStartLesson;

  const PathView({
    super.key,
    required this.curriculum,
    required this.onStartLesson,
  });

  /// Horizontal winding factors (-1..1), cycled across the flat lesson list
  /// to produce the characteristic Duolingo S-curve.
  static const List<double> _wind = [0.0, 0.55, 0.85, 0.55, 0.0, -0.55, -0.85, -0.55];

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final direction = context.select<GameStateProvider, LearningDirection>(
      (g) => g.direction,
    );
    final orderedLessons = curriculum.allLessons;

    // Index of the first not-yet-completed lesson = the "current" one.
    final currentIndex = orderedLessons.indexWhere(
      (l) => !progress.isLessonComplete(l.id, direction),
    );

    var globalIndex = -1;
    final children = <Widget>[];

    for (final unit in curriculum.units) {
      children.add(_UnitBanner(unit: unit, direction: direction));
      for (final lesson in unit.lessons) {
        globalIndex++;
        final factor = _wind[globalIndex % _wind.length];
        final status = progress.statusFor(lesson.id, orderedLessons, direction);
        final isCurrent = globalIndex == currentIndex;

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Align(
              alignment: Alignment(factor, 0),
              child: LessonNode(
                icon: lessonIconFor(lesson.icon),
                color: unit.color,
                status: status,
                isCurrent: isCurrent,
                onTap: () => _showLessonIntro(context, lesson, unit, direction),
              ),
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(height: 32));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: children,
    );
  }

  void _showLessonIntro(
    BuildContext context,
    Lesson lesson,
    Unit unit,
    LearningDirection direction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => LessonIntroSheet(
        lesson: lesson,
        unit: unit,
        direction: direction,
        onStart: () {
          Navigator.of(sheetContext).pop();
          onStartLesson(lesson, unit);
        },
      ),
    );
  }
}

class _UnitBanner extends StatelessWidget {
  final Unit unit;
  final LearningDirection direction;

  const _UnitBanner({required this.unit, required this.direction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: unit.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(unitThemeIcon(unit.theme), color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.title(direction),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${unit.lessons.length} lessons',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown when a lesson node is tapped: a preview of the words
/// to be learned plus a big "Start" button.
class LessonIntroSheet extends StatelessWidget {
  final Lesson lesson;
  final Unit unit;
  final LearningDirection direction;
  final VoidCallback onStart;

  const LessonIntroSheet({
    super.key,
    required this.lesson,
    required this.unit,
    required this.direction,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.disabledGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: unit.color,
                child: Icon(lessonIconFor(lesson.icon), color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                lesson.title(direction),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Text('You will learn:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lesson.words.take(6).map((w) {
                return Chip(
                  avatar: Text(w.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text(w.prompt(direction)),
                  backgroundColor: unit.color.withValues(alpha: 0.12),
                  side: BorderSide(color: unit.color.withValues(alpha: 0.4)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(backgroundColor: unit.color),
                child: const Text('START LESSON'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
