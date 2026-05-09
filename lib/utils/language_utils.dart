import 'dart:ui';

/// Utility function to detect the phone's locale and default to English
/// Supported languages: en, fr, ar, ar_tn
String getInitialLanguage() {
  final locale = PlatformDispatcher.instance.locale;
  final languageCode = locale.languageCode;

  // Map supported locales
  switch (languageCode) {
    case 'fr':
      return 'fr';
    case 'ar':
      // Check for Tunisia specifically for ar_tn
      final countryCode = locale.countryCode?.toLowerCase();
      if (countryCode == 'tn') {
        return 'ar_tn';
      }
      return 'ar';
    case 'en':
    default:
      return 'en'; // Default to English
  }
}
