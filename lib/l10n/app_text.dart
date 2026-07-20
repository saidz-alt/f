import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/learning_direction.dart';
import '../services/game_state_provider.dart';

/// Bilingual UI text for the whole app, selected by the child's [UiLang].
///
/// Every string exists in French (`fr`) and Kabyle/Taqbaylit (`kab`). The
/// French is authoritative. The KABYLE UI STRINGS ARE BEST-EFFORT AND SHOULD
/// BE REVIEWED BY A FLUENT TAQBAYLIT SPEAKER before public release — the
/// localization system itself is final; only the wording may need polish.
class AppText {
  final UiLang lang;
  const AppText(this.lang);

  String _p(String fr, String kab) => lang == UiLang.fr ? fr : kab;

  // The name of the language the learner is studying (their target).
  String get targetLanguageName => _p('kabyle', 'tafṛansist');

  // -- Bottom navigation --------------------------------------------------
  String get navHome => _p('Accueil', 'Axxam');
  String get navProgress => _p('Progrès', 'Asnerni');
  String get navShop => _p('Boutique', 'Taḥanut');
  String get navProfile => _p('Profil', 'Amaɣnu');

  // -- Home ---------------------------------------------------------------
  String levelN(int n) => _p('Niveau $n', 'Aswir $n');
  String xpOutOf(int a) => '$a / 100 XP';
  String get doubleXpActive => _p('2x actif', '2x yermed');
  String streakSemantics(int n) => _p('série de $n jours', '$n wussan');
  String heartsSemantics(int n) => _p('$n cœurs', '$n ulawen');
  String gemsSemantics(int n) => _p('$n gemmes', '$n yiḥbuben');

  // -- Progress -----------------------------------------------------------
  String get yourProgress => _p('Ta progression', 'Asnerni-k');
  String dayStreak(int n) => _p('Série de $n jours', 'Talɣwact n $n wussan');
  String streakFreezesAvailable(int n) =>
      _p('$n protection(s) de série', '$n imester n talɣwact');
  String totalXpValue(int n) => _p('$n XP au total', '$n XP s wakk');

  // -- Shop ---------------------------------------------------------------
  String get shopTitle => _p('Boutique', 'Taḥanut');
  String get heartRefill => _p('Recharge de cœurs', 'Ččar ulawen');
  String get heartRefillDesc =>
      _p('Restaure tous tes cœurs.', 'Err-d akk ulawen-ik.');
  String get streakFreeze => _p('Gel de série', 'Amester n talɣwact');
  String get streakFreezeDesc => _p(
      'Protège ta série pendant un jour manqué.',
      'Iḥerrez wussan-ik ma tzegleḍ yiwen wass.');
  String get doubleXp => _p('XP double (30 min)', 'XP sin iberdan (30 min)');
  String get doubleXpDesc => _p(
      "Gagne le double d'XP pendant 30 minutes.",
      'Rbeḥ XP sin iberdan i 30 n tesdatin.');
  String purchased(String name) => _p('$name acheté !', '$name yețwaɣ!');

  // -- Profile ------------------------------------------------------------
  String get profileTitle => _p('Profil', 'Amaɣnu');
  String get appLanguage => _p('Langue', 'Tutlayt');
  String youSpeakSubtitle(UiLang l) => l == UiLang.fr
      ? _p('Tu parles français', 'Tessawaleḍ tafṛansist')
      : _p('Tu parles kabyle', 'Tessawaleḍ taqbaylit');
  String get statTotalXp => _p('XP total', 'XP s wakk');
  String get statLevel => _p('Niveau', 'Aswir');
  String get statStreak => _p('Série actuelle', 'Talɣwact tamirant');
  String get statGems => _p('Gemmes', 'Iḥbuben');
  String daysUnit(int n) => _p('$n jours', '$n wussan');

  // -- Path ---------------------------------------------------------------
  String lessonsCount(int n) => _p('$n leçons', '$n timsirin');
  String get youWillLearn => _p('Tu vas apprendre :', 'Ad telmeḍ:');
  String get startLesson => _p('COMMENCER', 'BDU TAMSIRT');
  String get startBubble => _p('GO', 'BDU');

  // -- Exercises ----------------------------------------------------------
  String get whichOneIsThis => _p('Lequel est-ce ?', 'D acu-t wa?');
  String get tapWhatYouHear =>
      _p('Touche ce que tu entends', 'Sit ɣef wayen tesliḍ');
  String get buildTheSentence => _p('Construis la phrase', 'Bnu tafyirt');
  String get typeTheTranslation => _p('Écris la traduction', 'Aru asuqqel');
  String get yourAnswerHint => _p('Ta réponse…', 'Tiririt-ik…');
  String get accentsTip => _p('Astuce : les accents sont optionnels.',
      'Tikt,: accents ur ilaqen ara.');

  // -- Check panel / lesson flow -----------------------------------------
  String get check => _p('VÉRIFIER', 'SENQED');
  String get continue_ => _p('CONTINUER', 'KEMMEL');
  String get correctAnswer => _p('Bonne réponse :', 'Tiririt tameɣtut:');
  String get lessonComplete => _p('Leçon terminée !', 'Tfukk tmsirt!');
  String get quitLessonTitle =>
      _p('Quitter la leçon ?', 'Ad tffɣeḍ seg tmsirt?');
  String get quitLessonBody => _p(
      "Ta progression dans cette leçon ne sera pas sauvegardée.",
      "Asnerni-k deg tmsirt-a ur yețwaḥraz ara.");
  String get stay => _p('RESTER', 'QQIM');
  String get quit => _p('QUITTER', 'FFEƔ');
  String get quitLessonButton =>
      _p('QUITTER LA LEÇON', 'FFEƔ SEG TMSIRT');
  String get outOfHearts => _p('Tu n\'as plus de cœurs !', 'Ulac-ik ulawen!');
  String refillForGems(int n) =>
      _p('Recharger pour $n gemmes', 'Ččar s $n yiḥbuben');

  List<String> get praises => lang == UiLang.fr
      ? const ['Excellent !', 'Bravo !', 'Super !', 'Génial !', 'Parfait !']
      : const ['Igerrez!', 'Ayyuz!', 'Yelha!', 'D ayen!', 'Ilha!'];

  List<String> get weekdayInitials => lang == UiLang.fr
      ? const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
      : const ['L', 'T', 'L', 'L', 'Ǧ', 'S', 'Ḥ'];

  // -- Onboarding (shown before a language is chosen, so kept bilingual) --
  String get onboardingTitle => 'Kabylingo';
  String get onboardingPromptFr => 'Choisis ta langue';
  String get onboardingPromptKab => 'Fren tutlayt-ik';
}

/// `context.t` gives the current localized text and rebuilds on language change.
extension AppTextX on BuildContext {
  AppText get t => AppText(watch<GameStateProvider>().uiLang);
}
