import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../theme/app_theme.dart';

/// Word-bank builder: tap scattered word tiles to assemble the sentence in
/// the answer row; tap a placed tile to send it back. Tokens are tracked by
/// bank index so repeated words (e.g. "à") behave correctly.
class WordBankView extends StatefulWidget {
  final WordBankExercise exercise;
  final bool locked;
  final ValueChanged<ExerciseAnswer?> onChanged;

  const WordBankView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.onChanged,
  });

  @override
  State<WordBankView> createState() => _WordBankViewState();
}

class _WordBankViewState extends State<WordBankView> {
  final List<int> _placed = []; // ordered bank indices in the answer row

  List<String> get _assembled =>
      _placed.map((i) => widget.exercise.bank[i]).toList();

  bool get _isCorrect =>
      listEquals(_assembled, widget.exercise.correctTokens);

  void _notify() {
    widget.onChanged(_placed.isEmpty
        ? null
        : ExerciseAnswer(
            isCorrect: _isCorrect,
            correctText: widget.exercise.correctTokens.join(' '),
          ));
  }

  void _place(int bankIndex) {
    if (widget.locked || _placed.contains(bankIndex)) return;
    setState(() => _placed.add(bankIndex));
    _notify();
  }

  void _remove(int bankIndex) {
    if (widget.locked) return;
    setState(() => _placed.remove(bankIndex));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final answerColor = !widget.locked
        ? AppColors.disabledGrey
        : _isCorrect
            ? AppColors.primaryGreen
            : AppColors.heartRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Build the sentence',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('“${ex.promptSentence}”',
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 20),
        // Answer row.
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: answerColor, width: 2)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _placed
                .map((i) => _Tile(
                      label: ex.bank[i],
                      onTap: () => _remove(i),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Bank row (unused tiles).
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(ex.bank.length, (i) {
            final used = _placed.contains(i);
            return Opacity(
              opacity: used ? 0.25 : 1,
              child: _Tile(
                label: ex.bank[i],
                onTap: used ? null : () => _place(i),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Tile({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.disabledGrey, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x11000000), blurRadius: 3, offset: Offset(0, 2)),
          ],
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
