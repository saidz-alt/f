import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_text.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();
    final last7 = state.lastNDaysActivity(7);
    final weekdayLabels = context.t.weekdayInitials;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(context.t.yourProgress,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: AppColors.streakOrange.withValues(alpha: 0.1),
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
                      Text(context.t.dayStreak(state.streakCount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(context.t
                          .streakFreezesAvailable(state.streakFreezes)),
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
                  Text(weekdayLabels[i], style: const TextStyle(fontSize: 12)),
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
            color: AppColors.xpGold.withValues(alpha: 0.12),
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
                      Text(context.t.totalXpValue(state.xp),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(context.t.levelN(state.level)),
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
