import 'package:flutter/material.dart';

import '../services/progress_provider.dart';
import '../theme/app_theme.dart';

/// A single circular lesson node on the learning path, styled with the
/// Duolingo-style "3D" pressed-button look (a darker plate under a lighter
/// cap). Renders differently for locked / unlocked / completed states.
class LessonNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final LessonStatus status;
  final bool isCurrent;
  final String startLabel;
  final VoidCallback? onTap;

  const LessonNode({
    super.key,
    required this.icon,
    required this.color,
    required this.status,
    required this.isCurrent,
    required this.startLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = status == LessonStatus.locked;
    final completed = status == LessonStatus.completed;

    final capColor = locked
        ? AppColors.disabledGrey
        : completed
            ? AppColors.xpGold
            : color;
    final plateColor = locked
        ? const Color(0xFFBDBDBD)
        : completed
            ? const Color(0xFFE0A800)
            : _darken(color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCurrent && !locked) ...[
          _StartBubble(color: color, label: startLabel),
          const SizedBox(height: 6),
        ],
        Semantics(
          button: true,
          enabled: !locked,
          label: locked
              ? 'Locked lesson'
              : completed
                  ? 'Completed lesson'
                  : 'Start lesson',
          child: GestureDetector(
            onTap: locked ? null : onTap,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bottom plate (the "3D" depth).
                  Positioned(
                    top: 8,
                    child: Container(
                      width: 72,
                      height: 68,
                      decoration: BoxDecoration(
                        color: plateColor,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  // Top cap.
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 72,
                      height: 64,
                      decoration: BoxDecoration(
                        color: capColor,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          if (isCurrent && !locked)
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        completed
                            ? Icons.check
                            : locked
                                ? Icons.lock
                                : icon,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Color _darken(Color c, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// The little "START" call-out that bounces above the current lesson.
class _StartBubble extends StatelessWidget {
  final Color color;
  final String label;
  const _StartBubble({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
