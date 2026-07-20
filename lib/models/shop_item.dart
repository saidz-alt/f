enum ShopItemEffect { refillHearts, streakFreeze, doubleXp }

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final ShopItemEffect effect;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effect,
  });
}

/// The Stage 1 gem shop catalog. Cosmetic items (avatar outfits, path
/// themes, etc.) are added once Stage 2's asset pipeline exists.
const List<ShopItem> kShopCatalog = [
  ShopItem(
    id: 'refill_hearts',
    name: 'Heart Refill',
    description: 'Instantly restore all your hearts.',
    cost: 350,
    effect: ShopItemEffect.refillHearts,
  ),
  ShopItem(
    id: 'streak_freeze',
    name: 'Streak Freeze',
    description: 'Protects your streak through one missed day.',
    cost: 200,
    effect: ShopItemEffect.streakFreeze,
  ),
  ShopItem(
    id: 'double_xp',
    name: 'Double XP (30 min)',
    description: 'Earn double XP on every correct answer for 30 minutes.',
    cost: 300,
    effect: ShopItemEffect.doubleXp,
  ),
];
