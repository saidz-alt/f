import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_item.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shop', style: Theme.of(context).textTheme.headlineMedium),
                Row(
                  children: [
                    const Icon(Icons.diamond, color: AppColors.gemBlue),
                    const SizedBox(width: 4),
                    Text('${state.gems}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: kShopCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = kShopCatalog[index];
                final canAfford = state.gems >= item.cost;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.disabledGrey),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.gemBlue.withValues(alpha: 0.15),
                      child: Icon(_iconFor(item.effect), color: AppColors.gemBlue),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.description),
                    trailing: ElevatedButton(
                      onPressed: canAfford ? () => _purchase(context, item) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gemBlue,
                        minimumSize: const Size(96, 40),
                      ),
                      child: Text('${item.cost}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ShopItemEffect effect) {
    switch (effect) {
      case ShopItemEffect.refillHearts:
        return Icons.favorite;
      case ShopItemEffect.streakFreeze:
        return Icons.ac_unit;
      case ShopItemEffect.doubleXp:
        return Icons.bolt;
    }
  }

  void _purchase(BuildContext context, ShopItem item) {
    final state = context.read<GameStateProvider>();
    if (!state.spendGems(item.cost)) return;

    switch (item.effect) {
      case ShopItemEffect.refillHearts:
        state.refillHeartsInstantly();
        break;
      case ShopItemEffect.streakFreeze:
        state.grantStreakFreeze();
        break;
      case ShopItemEffect.doubleXp:
        state.activateDoubleXp(const Duration(minutes: 30));
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} purchased!')),
    );
  }
}
