import 'package:flutter/material.dart';

/// Small pill used in the top bar / cards to show a stat (hearts, gems,
/// streak) with an icon, a color, and a value.
class StatBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String? semanticLabel;

  const StatBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
