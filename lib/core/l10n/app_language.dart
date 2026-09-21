enum AppLanguage {
  en,
  hi;

  String get storageValue => name;

  String get pickerLabel => switch (this) {
        AppLanguage.en => 'English',
        AppLanguage.hi => 'Hindi',
      };

  static AppLanguage fromStorage(String? raw) {
    if (raw == AppLanguage.hi.storageValue) return AppLanguage.hi;
    return AppLanguage.en;
  }
}
