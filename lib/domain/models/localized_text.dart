/// LocalizedText class for multilingual support
/// Supports English (en), French (fr), Arabic (ar), and Tunisian Arabic (ar_tn)
class LocalizedText {
  final String en; // English - default language
  final String fr; // French
  final String ar; // Arabic
  final String arTn; // Tunisian Arabic

  const LocalizedText({
    required this.en,
    required this.fr,
    required this.ar,
    required this.arTn,
  });

  /// Get text for a specific language code, defaults to English
  String get(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      case 'ar_tn':
        return arTn;
      case 'en':
      default:
        return en;
    }
  }

  /// Create from a map (useful for JSON serialization)
  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      en: json['en'] as String? ?? '',
      fr: json['fr'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
      arTn: json['ar_tn'] as String? ?? '',
    );
  }

  /// Convert to map (useful for JSON serialization)
  Map<String, dynamic> toJson() {
    return {
      'en': en,
      'fr': fr,
      'ar': ar,
      'ar_tn': arTn,
    };
  }

  /// Copy with method for immutability
  LocalizedText copyWith({
    String? en,
    String? fr,
    String? ar,
    String? arTn,
  }) {
    return LocalizedText(
      en: en ?? this.en,
      fr: fr ?? this.fr,
      ar: ar ?? this.ar,
      arTn: arTn ?? this.arTn,
    );
  }
}
