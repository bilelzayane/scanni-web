import 'pathology.dart';
import 'validation_status.dart';
import 'localized_text.dart';

class ScientificLexicon {
  final String id;
  final String? eCode;
  final String technicalCode;
  final String sourceType; // 'official' or 'ai_discovered'
  final ValidationStatus status;
  final String? createdAt;
  
  // Multilingual fields via Translations
  final LocalizedText name;
  final LocalizedText? genericName;
  final LocalizedText? description;
  final LocalizedText? unit;
  
  final List<Pathology> pathologies;

  const ScientificLexicon({
    required this.id,
    this.eCode,
    required this.technicalCode,
    this.sourceType = 'official',
    this.status = ValidationStatus.pending,
    this.createdAt,
    required this.name,
    this.genericName,
    this.description,
    this.unit,
    this.pathologies = const [],
  });

  factory ScientificLexicon.fromJson(Map<String, dynamic> json) {
    List<Pathology> parsedPathologies = [];
    if (json['lexicon_pathologies'] != null) {
      final lpList = json['lexicon_pathologies'] as List<dynamic>;
      for (var lp in lpList) {
        if (lp['pathologies'] != null) {
          parsedPathologies.add(
            Pathology.fromJson(lp['pathologies'] as Map<String, dynamic>),
          );
        }
      }
    }

    // Parse polymorphic translations list if it exists
    Map<String, Map<String, String>> translationMap = {};
    if (json['translations'] != null) {
      final tList = json['translations'] as List<dynamic>;
      for (var t in tList) {
        final tMap = t as Map<String, dynamic>;
        final lang = tMap['language_code'] as String;
        final field = tMap['field_name'] as String;
        final content = tMap['content'] as String;
        translationMap.putIfAbsent(lang, () => {})[field] = content;
      }
    }

    String getT(String lang, String field, {String? fallback}) {
      return translationMap[lang]?[field] ?? fallback ?? '';
    }

    return ScientificLexicon(
      id: json['id'] as String,
      eCode: json['e_code'] as String?,
      technicalCode: json['technical_code'] as String,
      sourceType: json['source_type'] as String? ?? 'official',
      status: ValidationStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: json['created_at'] as String?,
      name: LocalizedText(
        en: getT('en', 'name', fallback: json['technical_code'] as String),
        fr: getT('fr', 'name'),
        ar: getT('ar', 'name'),
        arTn: getT('ar_tn', 'name'),
      ),
      genericName: translationMap.values.any((m) => m.containsKey('generic_name')) ? LocalizedText(
        en: getT('en', 'generic_name'),
        fr: getT('fr', 'generic_name', fallback: getT('en', 'generic_name')),
        ar: getT('ar', 'generic_name', fallback: getT('en', 'generic_name')),
        arTn: getT('ar_tn', 'generic_name', fallback: getT('ar', 'generic_name')),
      ) : null,
      description: translationMap.values.any((m) => m.containsKey('description')) ? LocalizedText(
        en: getT('en', 'description'),
        fr: getT('fr', 'description', fallback: getT('en', 'description')),
        ar: getT('ar', 'description', fallback: getT('en', 'description')),
        arTn: getT('ar_tn', 'description', fallback: getT('ar', 'description')),
      ) : null,
      unit: translationMap.values.any((m) => m.containsKey('unit')) ? LocalizedText(
        en: getT('en', 'unit'),
        fr: getT('fr', 'unit', fallback: getT('en', 'unit')),
        ar: getT('ar', 'unit', fallback: getT('en', 'unit')),
        arTn: getT('ar_tn', 'unit', fallback: getT('ar', 'unit')),
      ) : null,
      pathologies: parsedPathologies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'e_code': eCode,
      'technical_code': technicalCode,
      'source_type': sourceType,
      'status': status.value,
      if (createdAt != null) 'created_at': createdAt,
      'name_en': name.en,
      'name_fr': name.fr,
      'name_ar': name.ar,
      'name_ar_tn': name.arTn,
      if (genericName != null) ...{
        'generic_name_en': genericName!.en,
        'generic_name_fr': genericName!.fr,
        'generic_name_ar': genericName!.ar,
        'generic_name_ar_tn': genericName!.arTn,
      },
      if (description != null) ...{
        'description_en': description!.en,
        'description_fr': description!.fr,
        'description_ar': description!.ar,
        'description_ar_tn': description!.arTn,
      },
      if (unit != null) ...{
        'unit_en': unit!.en,
        'unit_fr': unit!.fr,
        'unit_ar': unit!.ar,
        'unit_ar_tn': unit!.arTn,
      },
      'lexicon_pathologies': pathologies
          .map((p) => {'pathologies': p.toJson()})
          .toList(),
    };
  }

  ScientificLexicon copyWith({
    String? id,
    String? eCode,
    String? technicalCode,
    String? sourceType,
    ValidationStatus? status,
    String? createdAt,
    LocalizedText? name,
    LocalizedText? genericName,
    LocalizedText? description,
    LocalizedText? unit,
    List<Pathology>? pathologies,
  }) {
    return ScientificLexicon(
      id: id ?? this.id,
      eCode: eCode ?? this.eCode,
      technicalCode: technicalCode ?? this.technicalCode,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      pathologies: pathologies ?? this.pathologies,
    );
  }
}
