import 'localized_text.dart';

class Pathology {
  final String id;
  final String technicalCode;
  final LocalizedText name;

  const Pathology({
    required this.id,
    required this.technicalCode,
    required this.name,
  });

  factory Pathology.fromJson(Map<String, dynamic> json) {
    return Pathology(
      id: json['id'] as String,
      technicalCode: json['technical_code'] as String,
      name: LocalizedText(
        en: json['name_en'] as String? ?? json['technical_code'] as String,
        fr: json['name_fr'] as String? ?? json['technical_code'] as String,
        ar: json['name_ar'] as String? ?? json['technical_code'] as String,
        arTn:
            json['name_ar_tn'] as String? ??
            json['name_ar'] as String? ??
            json['technical_code'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technical_code': technicalCode,
      'name_en': name.en,
      'name_fr': name.fr,
      'name_ar': name.ar,
      'name_ar_tn': name.arTn,
    };
  }

  Pathology copyWith({String? id, String? technicalCode, LocalizedText? name}) {
    return Pathology(
      id: id ?? this.id,
      technicalCode: technicalCode ?? this.technicalCode,
      name: name ?? this.name,
    );
  }
}
