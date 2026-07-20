import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_direction.dart';
import '../services/game_state_provider.dart';
import '../theme/app_theme.dart';

/// First-run screen: the child taps the language they speak. Because no
/// language is chosen yet, the prompt is shown in BOTH languages. The choice
/// sets the whole app's interface language and (derived) what they learn.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              // App icon / mascot.
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 132,
                  height: 132,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choukrilingo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Bilingual prompt (no language chosen yet).
              const Text(
                'Choisis ta langue\nFren tutlayt-ik',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _LanguageButton(
                lang: UiLang.fr,
                subtitle: 'Je parle français',
                onTap: () => _choose(context, UiLang.fr),
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                lang: UiLang.kab,
                subtitle: 'Ttmeslayeɣ taqbaylit',
                onTap: () => _choose(context, UiLang.kab),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _choose(BuildContext context, UiLang lang) {
    context.read<GameStateProvider>().completeOnboarding(lang);
  }
}

class _LanguageButton extends StatelessWidget {
  final UiLang lang;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.lang,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.nativeName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.primaryGreen, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
