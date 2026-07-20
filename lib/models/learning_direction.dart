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
