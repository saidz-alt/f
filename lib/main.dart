import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/main_navigation.dart';
import 'services/game_state_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const KabyleDuoApp());
}

class KabyleDuoApp extends StatelessWidget {
  const KabyleDuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameStateProvider>(
      create: (_) => GameStateProvider()..init(),
      child: MaterialApp(
        title: 'KabyleDuo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppLoader(),
      ),
    );
  }
}

/// Blocks on the Hive box opening in [GameStateProvider.init] before
/// showing the tabbed shell, so no screen ever reads uninitialized state.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameStateProvider>();
    if (!state.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MainNavigation();
  }
}
