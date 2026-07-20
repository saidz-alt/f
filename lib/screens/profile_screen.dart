import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_direction.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text('Learning course', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.disabledGrey),
            ),
            child: Column(
              children: LearningDirection.values.map((direction) {
                return RadioListTile<LearningDirection>(
                  value: direction,
                  groupValue: state.direction,
                  activeColor: AppColors.primaryGreen,
                  title: Text(direction.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Learn ${direction.targetLanguage} from ${direction.sourceLanguage}'),
                  onChanged: (value) {
                    if (value != null) state.setDirection(value);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _StatRow(label: 'Total XP', value: '${state.xp}'),
          _StatRow(label: 'Level', value: '${state.level}'),
          _StatRow(label: 'Current streak', value: '${state.streakCount} days'),
          _StatRow(label: 'Gems', value: '${state.gems}'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
