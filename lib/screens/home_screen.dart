import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_text.dart';
import '../models/curriculum.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_badge.dart';
import 'lesson_screen.dart';
import 'path_view.dart';

/// Home tab: a persistent stat header (streak / hearts / gems) above the
/// winding lesson path. Tapping a lesson node launches the interactive
/// lesson flow (Stage 3).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();
    final curriculum = context.read<Curriculum>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatBadge(
                  icon: Icons.local_fire_department,
                  color: state.isStreakAtRisk
                      ? AppColors.disabledGrey
                      : AppColors.streakOrange,
                  value: '${state.streakCount}',
                  semanticLabel: context.t.streakSemantics(state.streakCount),
                ),
                StatBadge(
                  icon: Icons.favorite,
                  color: AppColors.heartRed,
                  value: '${state.hearts}',
                  semanticLabel: context.t.heartsSemantics(state.hearts),
                ),
                StatBadge(
                  icon: Icons.diamond,
                  color: AppColors.gemBlue,
                  value: '${state.gems}',
                  semanticLabel: context.t.gemsSemantics(state.gems),
                ),
              ],
            ),
          ),
          Expanded(
            child: PathView(
              curriculum: curriculum,
              onStartLesson: (lesson, unit) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LessonScreen(lesson: lesson, unit: unit),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
