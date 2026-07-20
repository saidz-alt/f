import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/answer_check.dart';

/// Text-input exercise: show the prompt word (+ emoji) and let the child type
/// the translation. Correctness uses the forgiving [AnswerCheck] so missing
/// accents / special letters and small typos still pass.
class TextInputView extends StatefulWidget {
  final TextInputExercise exercise;
  final bool locked;
  final AudioService audio;
  final ValueChanged<ExerciseAnswer?> onChanged;

  const TextInputView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.audio,
    required this.onChanged,
  });

  @override
  State<TextInputView> createState() => _TextInputViewState();
}

class _TextInputViewState extends State<TextInputView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final trimmed = value.trim();
    widget.onChanged(trimmed.isEmpty
        ? null
        : ExerciseAnswer(
            isCorrect: AnswerCheck.isAcceptable(widget.exercise.expected, trimmed),
            correctText: widget.exercise.expected,
          ));
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type the translation',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(ex.promptEmoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(ex.promptWord,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          enabled: !widget.locked,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: _onTextChanged,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: 'Your answer…',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.disabledGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.disabledGrey),
            ),
          ),
        ),
        if (ex.answerIsKabyle) ...[
          const SizedBox(height: 10),
          const Text(
            'Tip: accents and special letters are optional.',
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
