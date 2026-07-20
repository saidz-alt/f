import 'package:flutter/material.dart';

/// Maps the curriculum's `icon` string keys to Material icons, so the JSON
/// stays free of Dart/Flutter specifics. Unknown keys fall back to a star.
IconData lessonIconFor(String key) {
  switch (key) {
    case 'wave':
      return Icons.waving_hand;
    case 'family':
      return Icons.family_restroom;
    case 'numbers':
      return Icons.pin;
    case 'colors':
      return Icons.palette;
    case 'nature':
      return Icons.park; // olive/tree motif for Kabyle landscape
    case 'animals':
      return Icons.pets;
    case 'food':
      return Icons.restaurant;
    case 'body':
      return Icons.accessibility_new;
    case 'star':
    default:
      return Icons.star;
  }
}

/// A soft background motif icon per unit theme, evoking Kabyle culture:
/// olive branches, traditional silver jewelry, mint tea, greetings.
IconData unitThemeIcon(String theme) {
  switch (theme) {
    case 'olive':
      return Icons.park;
    case 'jewelry':
      return Icons.diamond;
    case 'tea':
      return Icons.emoji_food_beverage;
    case 'greeting':
      return Icons.waving_hand;
    default:
      return Icons.auto_awesome;
  }
}
