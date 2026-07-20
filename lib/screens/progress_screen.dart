import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();
    final last7 = state.lastNDaysActivity(7);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Your progress', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: AppColors.streakOrange.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: AppColors.streakOrange, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${state.streakCount}-day streak',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${state.streakFreezes} streak freeze(s) available'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = last7[i];
              return Column(
                children: [
                  Text(_weekdayLabels[i], style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: active ? AppColors.primaryGreen : AppColors.disabledGrey,
                    child: Icon(
                      active ? Icons.check : Icons.circle,
                      size: active ? 16 : 8,
                      color: active ? Colors.white : Colors.black26,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: AppColors.xpGold.withOpacity(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.xpGold, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${state.xp} total XP',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Level ${state.level}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
