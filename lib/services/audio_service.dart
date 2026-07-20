import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/learning_direction.dart';

/// Central audio manager for the app.
///
/// Pronunciation strategy (important, and deliberate):
///  * FRENCH is spoken with the device Text-To-Speech engine (`fr-FR`),
///    which is present on essentially all Android devices and web browsers.
///  * KABYLE (Taqbaylit) has NO TTS voice in any mainstream engine. Speaking
///    it through an Arabic/Berber-adjacent voice would teach children WRONG
///    pronunciation, so we never do that. Kabyle audio is played only from a
///    real bundled recording (`assets/audio/kab/<key>.mp3`) when one exists;
///    otherwise Kabyle is presented silently (text + Tifinagh). Drop in
///    native-speaker recordings later and they light up automatically.
///
/// UI feedback sounds (correct/wrong) are short synthesized tones bundled as
/// assets, so they work fully offline with no network and no TTS dependency.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  bool _ttsReady = false;
  Set<String> _ttsLanguages = <String>{};

  Future<void> init() async {
    try {
      final langs = await _tts.getLanguages;
      if (langs is List) {
        _ttsLanguages =
            langs.map((e) => e.toString().toLowerCase()).toSet();
      }
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45); // slower — clearer for children
      await _tts.setPitch(1.05);
      _ttsReady = true;
    } catch (e) {
      // TTS unavailable on this device/platform — degrade gracefully.
      _ttsReady = false;
      debugPrint('AudioService: TTS init failed: $e');
    }
  }

  bool get isFrenchTtsAvailable =>
      _ttsReady &&
      _ttsLanguages.any((l) => l.startsWith('fr'));

  // ---------------------------------------------------------------------
  // Word pronunciation
  // ---------------------------------------------------------------------

  /// Speaks [text] in the given language. For French this uses TTS; for
  /// Kabyle it plays a bundled recording keyed by [audioKey] if present, and
  /// otherwise stays silent (returns without error).
  Future<void> speakWord({
    required String text,
    required bool isKabyle,
    String? audioKey,
  }) async {
    if (isKabyle) {
      await _playKabyleClip(audioKey);
      return;
    }
    await _speakFrench(text);
  }

  Future<void> _speakFrench(String text) async {
    if (!isFrenchTtsAvailable) return;
    try {
      final locale =
          _ttsLanguages.contains('fr-fr') ? 'fr-FR' : 'fr';
      await _tts.setLanguage(locale);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('AudioService: French TTS failed: $e');
    }
  }

  Future<void> _playKabyleClip(String? audioKey) async {
    if (audioKey == null) return;
    try {
      // Only attempts to play; if the asset isn't bundled this throws and we
      // simply stay silent. Recordings go under assets/audio/kab/.
      await _voicePlayer.play(AssetSource('audio/kab/$audioKey.mp3'));
    } catch (_) {
      // No recording available yet — silent by design.
    }
  }

  /// Convenience: speak whichever language is the current answer/target.
  Future<void> speakAnswerLanguage(String text, LearningDirection direction) {
    final targetIsKabyle = direction == LearningDirection.frenchToKabyle;
    return speakWord(text: text, isKabyle: targetIsKabyle);
  }

  // ---------------------------------------------------------------------
  // Feedback sounds
  // ---------------------------------------------------------------------

  Future<void> playCorrect() async {
    HapticFeedback.mediumImpact();
    await _playSfx('audio/sfx/correct.wav');
  }

  Future<void> playWrong() async {
    HapticFeedback.heavyImpact();
    await _playSfx('audio/sfx/wrong.wav');
  }

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('AudioService: SFX failed ($assetPath): $e');
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _sfxPlayer.dispose();
    await _voicePlayer.dispose();
  }
}
