import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';

/// Picture-matching exercise: a target-language word (with a speaker button)
/// over a 2x2 grid of emoji cards. Tap the picture that matches the word.
class PictureMatchView extends StatefulWidget {
  final PictureMatchExercise exercise;
  final bool locked;
  final AudioService audio;
  final ValueChanged<ExerciseAnswer?> onChanged;

  const PictureMatchView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.audio,
    required this.onChanged,
  });

  @override
  State<PictureMatchView> createState() => _PictureMatchViewState();
}

class _PictureMatchViewState extends State<PictureMatchView> {
  int? _selected;

  void _select(int index) {
    if (widget.locked) return;
    setState(() => _selected = index);
    widget.onChanged(ExerciseAnswer(
      isCorrect: index == widget.exercise.correctIndex,
      correctText: widget.exercise.word,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which one is this?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            _SpeakerButton(
              onTap: () => widget.audio.speakWord(
                text: ex.word,
                isKabyle: ex.wordIsKabyle,
              ),
            ),
            const SizedBox(width: 12),
            Text(ex.word,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(ex.emojis.length, (i) {
            return _EmojiCard(
              emoji: ex.emojis[i],
              state: _cardState(i),
              onTap: () => _select(i),
            );
          }),
        ),
      ],
    );
  }

  _CardState _cardState(int index) {
    if (!widget.locked) {
      return _selected == index ? _CardState.selected : _CardState.neutral;
    }
    if (index == widget.exercise.correctIndex) return _CardState.correct;
    if (index == _selected) return _CardState.wrong;
    return _CardState.neutral;
  }
}

enum _CardState { neutral, selected, correct, wrong }

class _EmojiCard extends StatelessWidget {
  final String emoji;
  final _CardState state;
  final VoidCallback onTap;

  const _EmojiCard(
      {required this.emoji, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    late Color border;
    late Color fill;
    switch (state) {
      case _CardState.neutral:
        border = AppColors.disabledGrey;
        fill = Colors.white;
        break;
      case _CardState.selected:
        border = AppColors.gemBlue;
        fill = AppColors.gemBlue.withValues(alpha: 0.1);
        break;
      case _CardState.correct:
        border = AppColors.primaryGreen;
        fill = AppColors.primaryGreen.withValues(alpha: 0.12);
        break;
      case _CardState.wrong:
        border = AppColors.heartRed;
        fill = AppColors.heartRed.withValues(alpha: 0.12);
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2.5),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gemBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.volume_up, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
