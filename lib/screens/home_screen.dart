import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_badge.dart';

/// Home tab. Stage 1 shows the live gamification stats plus two demo
/// actions that exercise the state store end-to-end; Stage 2 replaces
/// the center section with the real snake-path lesson map.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();

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
                  semanticLabel: '${state.streakCount} day streak',
                ),
                StatBadge(
                  icon: Icons.favorite,
                  color: AppColors.heartRed,
                  value: '${state.hearts}',
                  semanticLabel: '${state.hearts} hearts remaining',
                ),
                StatBadge(
                  icon: Icons.diamond,
                  color: AppColors.gemBlue,
                  value: '${state.gems}',
                  semanticLabel: '${state.gems} gems',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${state.level}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.levelProgress,
                    minHeight: 12,
                    backgroundColor: AppColors.disabledGrey,
                    valueColor: const AlwaysStoppedAnimation(AppColors.xpGold),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${state.xpIntoCurrentLevel} / 100 XP'
                    '${state.hasDoubleXp ? "  •  2x active" : ""}'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.route, size: 72, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    const Text(
                      'The lesson path arrives in Stage 2.\n'
                      'Use the buttons below to exercise the gamification engine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        state.addXp(10);
                        state.recordActivityForToday();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Simulate correct answer (+10 XP)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.hearts > 0 ? () => state.loseHeart() : null,
                      icon: const Icon(Icons.close, color: AppColors.heartRed),
                      label: const Text('Simulate wrong answer (-1 heart)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.heartRed,
                        side: const BorderSide(color: AppColors.heartRed),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (state.hearts == 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.nextHeartRefillAt != null
                            ? 'Out of hearts! Next heart at '
                                '${TimeOfDay.fromDateTime(state.nextHeartRefillAt!).format(context)}'
                            : 'Out of hearts!',
                        style: const TextStyle(
                          color: AppColors.heartRed,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
