/// The language the child already speaks — chosen at onboarding. This drives
/// BOTH the app's interface language and (derived) what they're learning.
enum UiLang { fr, kab }

extension UiLangInfo on UiLang {
  /// The language's own name, shown on the onboarding buttons.
  String get nativeName => this == UiLang.fr ? 'Français' : 'Taqbaylit';

  /// A flag/emoji marker for the onboarding buttons.
  String get flag => this == UiLang.fr ? '🇫🇷' : 'ⵣ';
}

/// The two bidirectional course directions the app supports.
enum LearningDirection { kabyleToFrench, frenchToKabyle }

extension LearningDirectionLabels on LearningDirection {
  String get sourceLanguage =>
      this == LearningDirection.kabyleToFrench ? 'Taqbaylit' : 'Français';

  String get targetLanguage =>
      this == LearningDirection.kabyleToFrench ? 'Français' : 'Taqbaylit';

  String get label => this == LearningDirection.kabyleToFrench
      ? 'Kabyle → French'
      : 'French → Kabyle';
}
