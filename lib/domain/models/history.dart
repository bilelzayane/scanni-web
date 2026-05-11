import 'test_type.dart';
import 'ai_suggestion.dart';

class History {
  final String id;
  final String userId;
  final String sessionId;
  final TestType testType;
  final String? imageUrl;
  final String scanDate;
  final String? name;
  final List<IngredientDetected> details;

  const History({
    required this.id,
    required this.userId,
    this.sessionId = '', // Default empty string for backward compatibility
    required this.testType,
    this.imageUrl,
    required this.scanDate,
    this.name,
    this.details = const [],
  });

  // Backward-compatible constructor that accepts String for testType
  factory History.withStringType({
    required String id,
    required String userId,
    String sessionId = '',
    required String testType,
    String? imageUrl,
    required String scanDate,
    String? name,
    List<IngredientDetected> details = const [],
  }) {
    return History(
      id: id,
      userId: userId,
      sessionId: sessionId,
      testType: TestType.fromString(testType),
      imageUrl: imageUrl,
      scanDate: scanDate,
      name: name,
      details: details,
    );
  }

  factory History.fromJson(Map<String, dynamic> json) {
    List<IngredientDetected> details = [];
    if (json['payload'] != null && json['payload']['ingredients_detected'] != null) {
      final ingredientsJson = json['payload']['ingredients_detected'] as List<dynamic>;
      details = ingredientsJson
          .map((e) => IngredientDetected.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['history_details'] != null) {
      // Compatibility with old format if needed, though most should come from payload now
      final ingredientsJson = json['history_details'] as List<dynamic>;
      details = ingredientsJson
          .map((e) => IngredientDetected.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return History(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      testType: TestType.fromString(json['test_type'] as String? ?? 'scientific'),
      imageUrl: json['image_url'] as String?,
      scanDate: json['scan_date'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      name: json['name'] as String?,
      details: details,
    );
  }

  factory History.fromAiSuggestion(AiSuggestion suggestion) {
    // Extract test_type from payload if available
    final payload = suggestion.payload;
    final scanInfo = payload?['scan_info'] as Map<String, dynamic>?;
    final testTypeStr = scanInfo?['test_type'] as String? ?? 'label_scan';

    return History(
      id: suggestion.id,
      userId: suggestion.userId ?? '',
      sessionId: '',
      testType: TestType.fromString(testTypeStr),
      imageUrl: suggestion.imageUrl,
      scanDate: suggestion.createdAt.toIso8601String(),
      name: suggestion.scanInfo.titleSuggested,
      details: suggestion.ingredientsDetected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'test_type': testType.value,
      'image_url': imageUrl,
      'scan_date': scanDate,
      'name': name,
      // We don't necessarily need to serialize details here if they are stored in the payload column in DB
    };
  }

  History copyWith({
    String? id,
    String? userId,
    String? sessionId,
    TestType? testType,
    String? imageUrl,
    String? scanDate,
    String? name,
    List<IngredientDetected>? details,
  }) {
    return History(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      testType: testType ?? this.testType,
      imageUrl: imageUrl ?? this.imageUrl,
      scanDate: scanDate ?? this.scanDate,
      name: name ?? this.name,
      details: details ?? this.details,
    );
  }
}
