import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/curriculum.dart';
import 'screens/main_navigation.dart';
import 'services/audio_service.dart';
import 'services/curriculum_service.dart';
import 'services/game_state_provider.dart';
import 'services/progress_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // The curriculum is immutable content bundled with the app, so we load it
  // once at startup and inject it into the tree as a plain value.
  final curriculum = await CurriculumService().load();

  // Audio (TTS + SFX) initializes in the background; the UI never blocks on it.
  final audio = AudioService();
  unawaited(audio.init());

  runApp(KabyleDuoApp(curriculum: curriculum, audio: audio));
}

class KabyleDuoApp extends StatelessWidget {
  final Curriculum curriculum;
  final AudioService audio;
  const KabyleDuoApp({super.key, required this.curriculum, required this.audio});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Curriculum>.value(value: curriculum),
        Provider<AudioService>.value(value: audio),
        ChangeNotifierProvider<GameStateProvider>(
          create: (_) => GameStateProvider()..init(),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'KabyleDuo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppLoader(),
      ),
    );
  }
}

/// Blocks on both async stores (game state + lesson progress) opening their
/// Hive boxes before showing the tabbed shell, so no screen reads
/// uninitialized state.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final gameReady = context.select<GameStateProvider, bool>((g) => g.isReady);
    final progressReady =
        context.select<ProgressProvider, bool>((p) => p.isReady);

    if (!gameReady || !progressReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MainNavigation();
  }
}
