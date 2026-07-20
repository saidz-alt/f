import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_text.dart';
import '../models/learning_direction.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();
    final t = context.t;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.profileTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 24),
          // Interface language — changing it re-localizes the whole app AND
          // flips what the child is learning (the other language).
          Text(t.appLanguage, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.disabledGrey),
            ),
            child: RadioGroup<UiLang>(
              groupValue: state.uiLang,
              onChanged: (value) {
                if (value != null) state.setUiLang(value);
              },
              child: Column(
                children: UiLang.values.map((lang) {
                  return RadioListTile<UiLang>(
                    value: lang,
                    activeColor: AppColors.primaryGreen,
                    secondary:
                        Text(lang.flag, style: const TextStyle(fontSize: 26)),
                    title: Text(lang.nativeName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t.youSpeakSubtitle(lang)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _StatRow(label: t.statTotalXp, value: '${state.xp}'),
          _StatRow(label: t.statLevel, value: '${state.level}'),
          _StatRow(label: t.statStreak, value: t.daysUnit(state.streakCount)),
          _StatRow(label: t.statGems, value: '${state.gems}'),
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
