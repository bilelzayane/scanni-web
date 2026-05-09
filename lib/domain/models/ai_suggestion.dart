import 'localized_text.dart';

class AiSuggestion {
  final String id;
  final String? userId;
  final String? imageUrl;
  final DateTime createdAt;
  final ScanInfo scanInfo;
  final List<IngredientDetected> ingredientsDetected;
  final Map<String, dynamic>? payload;

  AiSuggestion({
    required this.id,
    this.userId,
    this.imageUrl,
    required this.createdAt,
    required this.scanInfo,
    required this.ingredientsDetected,
    this.payload,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    print('DEBUG: AiSuggestion.fromJson - ID: ${json['id']}');
    final payload = json['payload'] as Map<String, dynamic>;
    final scanInfoJson = payload['scan_info'] as Map<String, dynamic>;
    final ingredientsJson = payload['ingredients_detected'] as List<dynamic>;

    print('DEBUG: AiSuggestion.fromJson - Title: ${scanInfoJson['title_suggested']}');
    print('DEBUG: AiSuggestion.fromJson - Ingredients count: ${ingredientsJson.length}');

    return AiSuggestion(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      scanInfo: ScanInfo.fromJson(scanInfoJson),
      ingredientsDetected: ingredientsJson
          .map((e) => IngredientDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      payload: payload,
    );
  }
}

class ScanInfo {
  final String titleSuggested;
  final DateTime? timestamp;

  ScanInfo({
    required this.titleSuggested,
    this.timestamp,
  });

  factory ScanInfo.fromJson(Map<String, dynamic> json) {
    return ScanInfo(
      titleSuggested: json['title_suggested'] as String? ?? 'Analyse',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
    );
  }
}

class IngredientDetected {
  final String technicalCode;
  final double? quantity;
  final String? unit;
  final bool isEstimated;
  final int priorityScore;
  final bool isModerate;
  final Map<String, IngredientTranslation> translations;

  IngredientDetected({
    required this.technicalCode,
    this.quantity,
    this.unit,
    required this.isEstimated,
    this.priorityScore = 0,
    this.isModerate = false,
    required this.translations,
  });

  factory IngredientDetected.fromJson(Map<String, dynamic> json) {
    final transMap = json['translations'] as Map<String, dynamic>;
    final translations = transMap.map(
      (key, value) => MapEntry(
        key,
        IngredientTranslation.fromJson(value as Map<String, dynamic>),
      ),
    );

    return IngredientDetected(
      technicalCode: json['technical_code'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isEstimated: json['is_estimated'] as bool? ?? false,
      priorityScore: json['priority_score'] as int? ?? 0,
      isModerate: json['is_moderate'] as bool? ?? false,
      translations: translations,
    );
  }

  String getName(String locale) {
    // Handle ar_tn -> ar fallback
    if (locale == 'ar_tn') {
      return translations['ar_tn']?.name ?? translations['ar']?.name ?? translations['fr']?.name ?? technicalCode;
    }
    return translations[locale]?.name ?? translations['en']?.name ?? technicalCode;
  }

  String getDescription(String locale) {
    if (locale == 'ar_tn') {
      return translations['ar_tn']?.description ?? translations['ar']?.description ?? translations['fr']?.description ?? '';
    }
    return translations[locale]?.description ?? translations['en']?.description ?? '';
  }
}

class IngredientTranslation {
  final String name;
  final String description;

  IngredientTranslation({
    required this.name,
    required this.description,
  });

  factory IngredientTranslation.fromJson(Map<String, dynamic> json) {
    return IngredientTranslation(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
