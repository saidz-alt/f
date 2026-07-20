import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';

/// Listen & Tap: a big play button speaks the target word (French TTS), and
/// the learner taps the matching written option. Auto-plays once on appear.
class ListenTapView extends StatefulWidget {
  final ListenTapExercise exercise;
  final bool locked;
  final AudioService audio;
  final ValueChanged<ExerciseAnswer?> onChanged;

  const ListenTapView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.audio,
    required this.onChanged,
  });

  @override
  State<ListenTapView> createState() => _ListenTapViewState();
}

class _ListenTapViewState extends State<ListenTapView> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  void _play() {
    // Listen&Tap is only generated when the target language is French, so the
    // spoken text is always French here.
    widget.audio.speakWord(text: widget.exercise.spokenText, isKabyle: false);
  }

  void _select(int index) {
    if (widget.locked) return;
    setState(() => _selected = index);
    widget.onChanged(ExerciseAnswer(
      isCorrect: index == widget.exercise.correctIndex,
      correctText: widget.exercise.options[widget.exercise.correctIndex],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tap what you hear',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _play,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.gemBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.volume_up, color: Colors.white, size: 56),
            ),
          ),
        ),
        const SizedBox(height: 28),
        ...List.generate(ex.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              label: ex.options[i],
              state: _tileState(i),
              onTap: () => _select(i),
            ),
          );
        }),
      ],
    );
  }

  _TileState _tileState(int index) {
    if (!widget.locked) {
      return _selected == index ? _TileState.selected : _TileState.neutral;
    }
    if (index == widget.exercise.correctIndex) return _TileState.correct;
    if (index == _selected) return _TileState.wrong;
    return _TileState.neutral;
  }
}

enum _TileState { neutral, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final _TileState state;
  final VoidCallback onTap;

  const _OptionTile(
      {required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    late Color border;
    late Color fill;
    switch (state) {
      case _TileState.neutral:
        border = AppColors.disabledGrey;
        fill = Colors.white;
        break;
      case _TileState.selected:
        border = AppColors.gemBlue;
        fill = AppColors.gemBlue.withValues(alpha: 0.1);
        break;
      case _TileState.correct:
        border = AppColors.primaryGreen;
        fill = AppColors.primaryGreen.withValues(alpha: 0.12);
        break;
      case _TileState.wrong:
        border = AppColors.heartRed;
        fill = AppColors.heartRed.withValues(alpha: 0.12);
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2.5),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
