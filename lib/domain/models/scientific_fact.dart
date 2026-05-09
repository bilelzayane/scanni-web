import 'localized_text.dart';

class ScientificFact {
  final String id;
  final String ingredientId;
  final LocalizedText? legalReference;
  final LocalizedText factContent;
  final String updatedAt;

  const ScientificFact({
    required this.id,
    required this.ingredientId,
    this.legalReference,
    required this.factContent,
    required this.updatedAt,
  });

  factory ScientificFact.fromJson(Map<String, dynamic> json) {
    return ScientificFact(
      id: json['id'] as String,
      ingredientId: json['ingredient_id'] as String,
      legalReference: json['legal_reference_en'] != null ? LocalizedText(
        en: json['legal_reference_en'] as String? ?? '',
        fr: json['legal_reference_fr'] as String? ?? '',
        ar: json['legal_reference_ar'] as String? ?? '',
        arTn: json['legal_reference_ar_tn'] as String? ?? '',
      ) : null,
      factContent: LocalizedText(
        en: json['fact_content_en'] as String? ?? '',
        fr: json['fact_content_fr'] as String? ?? '',
        ar: json['fact_content_ar'] as String? ?? '',
        arTn: json['fact_content_ar_tn'] as String? ?? '',
      ),
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient_id': ingredientId,
      if (legalReference != null) ...{
        'legal_reference_en': legalReference!.en,
        'legal_reference_fr': legalReference!.fr,
        'legal_reference_ar': legalReference!.ar,
        'legal_reference_ar_tn': legalReference!.arTn,
      },
      'fact_content_en': factContent.en,
      'fact_content_fr': factContent.fr,
      'fact_content_ar': factContent.ar,
      'fact_content_ar_tn': factContent.arTn,
      'updated_at': updatedAt,
    };
  }
}
