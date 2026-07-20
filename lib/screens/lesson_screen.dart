import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_text.dart';
import '../models/curriculum.dart';
import '../models/exercise.dart';
import '../models/learning_direction.dart';
import '../services/audio_service.dart';
import '../services/game_state_provider.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/exercises/listen_tap_view.dart';
import '../widgets/exercises/picture_match_view.dart';
import '../widgets/exercises/text_input_view.dart';
import '../widgets/exercises/word_bank_view.dart';

/// Runs a single lesson end-to-end: a sequence of generated exercises with a
/// progress bar, live hearts, the green/red check-answer panel (with heart
/// deduction and wrong-answer requeue), out-of-hearts handling, and a
/// confetti completion screen that awards XP/gems and unlocks the next lesson.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Unit unit;

  const LessonScreen({super.key, required this.lesson, required this.unit});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

enum _Phase { answering, correct, wrong, finished, outOfHearts }

class _LessonScreenState extends State<LessonScreen> {
  late final AudioService _audio;
  late final LearningDirection _direction;
  late final ConfettiController _confetti;

  // Growing exercise list: a wrong answer appends the exercise again, which
  // also pushes the progress bar back (denominator grows). Lesson ends when
  // [_index] reaches the end.
  late List<Exercise> _exercises;
  int _index = 0;

  ExerciseAnswer? _answer; // current candidate from the active exercise widget
  _Phase _phase = _Phase.answering;
  bool _rewardsGranted = false;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _direction = context.read<GameStateProvider>().direction;
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _exercises =
        ExerciseGenerator().generate(widget.lesson, _direction).toList();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  double get _progress =>
      _exercises.isEmpty ? 1 : (_index / _exercises.length).clamp(0.0, 1.0);

  void _onAnswerChanged(ExerciseAnswer? answer) {
    setState(() => _answer = answer);
  }

  void _check() {
    final answer = _answer;
    if (answer == null) return;
    final game = context.read<GameStateProvider>();

    if (answer.isCorrect) {
      _audio.playCorrect();
      setState(() => _phase = _Phase.correct);
    } else {
      _audio.playWrong();
      game.loseHeart();
      // Requeue the missed exercise so it must eventually be answered right.
      _exercises.add(_exercises[_index]);
      setState(() {
        _phase = game.hearts <= 0 ? _Phase.outOfHearts : _Phase.wrong;
      });
    }
  }

  void _continue() {
    setState(() {
      _index++;
      _answer = null;
      if (_index >= _exercises.length) {
        _phase = _Phase.finished;
        _grantRewards();
        _confetti.play();
      } else {
        _phase = _Phase.answering;
      }
    });
  }

  void _grantRewards() {
    if (_rewardsGranted) return;
    _rewardsGranted = true;
    final game = context.read<GameStateProvider>();
    final progress = context.read<ProgressProvider>();
    game.addXp(widget.lesson.xpReward);
    game.addGems(5);
    game.recordActivityForToday();
    progress.markLessonComplete(widget.lesson.id, _direction);
  }

  void _refillWithGems() {
    final game = context.read<GameStateProvider>();
    if (game.spendGems(350)) {
      game.refillHeartsInstantly();
      setState(() => _phase = _Phase.answering);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.finished) return _buildFinished(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: _buildExercise(),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hearts = context.select<GameStateProvider, int>((g) => g.hearts);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black45),
            onPressed: () => _confirmQuit(context),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 14,
                backgroundColor: AppColors.disabledGrey,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.favorite, color: AppColors.heartRed, size: 22),
          const SizedBox(width: 4),
          Text('$hearts',
              style: const TextStyle(
                  color: AppColors.heartRed, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExercise() {
    final ex = _exercises[_index];
    final locked = _phase != _Phase.answering;
    // A unique key per queue position resets exercise widget state on advance.
    final key = ValueKey('ex_$_index');
    return switch (ex) {
      PictureMatchExercise() => PictureMatchView(
          key: key,
          exercise: ex,
          locked: locked,
          audio: _audio,
          onChanged: _onAnswerChanged,
        ),
      ListenTapExercise() => ListenTapView(
          key: key,
          exercise: ex,
          locked: locked,
          audio: _audio,
          onChanged: _onAnswerChanged,
        ),
      WordBankExercise() => WordBankView(
          key: key,
          exercise: ex,
          locked: locked,
          onChanged: _onAnswerChanged,
        ),
      TextInputExercise() => TextInputView(
          key: key,
          exercise: ex,
          locked: locked,
          audio: _audio,
          onChanged: _onAnswerChanged,
        ),
    };
  }

  Widget _buildBottomBar(BuildContext context) {
    switch (_phase) {
      case _Phase.answering:
        return _BottomPanel(
          color: Colors.white,
          child: ElevatedButton(
            onPressed: _answer == null ? null : _check,
            child: Text(context.t.check),
          ),
        );
      case _Phase.correct:
        return _FeedbackPanel(
          isCorrect: true,
          message: _praise(context),
          continueLabel: context.t.continue_,
          onContinue: _continue,
        );
      case _Phase.wrong:
        return _FeedbackPanel(
          isCorrect: false,
          message: context.t.correctAnswer,
          correctText: _answer?.correctText,
          continueLabel: context.t.continue_,
          onContinue: _continue,
        );
      case _Phase.outOfHearts:
        return _OutOfHeartsPanel(
          canRefill: context.select<GameStateProvider, int>((g) => g.gems) >= 350,
          title: context.t.outOfHearts,
          refillLabel: context.t.refillForGems(350),
          quitLabel: context.t.quitLessonButton,
          onRefill: _refillWithGems,
          onQuit: () => Navigator.of(context).pop(),
        );
      case _Phase.finished:
        return const SizedBox.shrink();
    }
  }

  String _praise(BuildContext context) {
    final options = context.t.praises;
    return options[_index % options.length];
  }

  Widget _buildFinished(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text('🎉', style: TextStyle(fontSize: 88)),
                  const SizedBox(height: 12),
                  Text(context.t.lessonComplete,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RewardChip(
                        icon: Icons.star,
                        color: AppColors.xpGold,
                        label: '+${widget.lesson.xpReward} XP',
                      ),
                      const SizedBox(width: 16),
                      const _RewardChip(
                        icon: Icons.diamond,
                        color: AppColors.gemBlue,
                        label: '+5',
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.t.continue_),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            gravity: 0.25,
            colors: const [
              AppColors.primaryGreen,
              AppColors.xpGold,
              AppColors.gemBlue,
              AppColors.streakOrange,
            ],
          ),
        ],
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t.quitLessonTitle),
        content: Text(context.t.quitLessonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t.stay),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(context.t.quit),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final Color color;
  final Widget child;
  const _BottomPanel({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String? correctText;
  final String continueLabel;
  final VoidCallback onContinue;

  const _FeedbackPanel({
    required this.isCorrect,
    required this.message,
    this.correctText,
    required this.continueLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final base = isCorrect ? AppColors.primaryGreen : AppColors.heartRed;
    return _BottomPanel(
      color: base.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: base),
              const SizedBox(width: 8),
              Text(message,
                  style: TextStyle(
                      color: base, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          if (!isCorrect && correctText != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(correctText!,
                  style: TextStyle(
                      color: base, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(backgroundColor: base),
              child: Text(continueLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutOfHeartsPanel extends StatelessWidget {
  final bool canRefill;
  final String title;
  final String refillLabel;
  final String quitLabel;
  final VoidCallback onRefill;
  final VoidCallback onQuit;

  const _OutOfHeartsPanel({
    required this.canRefill,
    required this.title,
    required this.refillLabel,
    required this.quitLabel,
    required this.onRefill,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return _BottomPanel(
      color: AppColors.heartRed.withValues(alpha: 0.12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.heart_broken, color: AppColors.heartRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.heartRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canRefill)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRefill,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.gemBlue),
                icon: const Icon(Icons.diamond),
                label: Text(refillLabel),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onQuit,
              child: Text(quitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RewardChip(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
