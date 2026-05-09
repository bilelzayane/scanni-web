import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/env.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(Env.geminiApiKey);
});

class AiService {
  final String apiKey;
  late final GenerativeModel _model;

  AiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<String> analyzeProduct(Uint8List imageBytes) async {
    // Return empty result if API key is not set
    if (apiKey.isEmpty) {
      print('DEBUG: AiService - API key NOT SET. Returning empty analysis.');
      return '{}';
    }

    final prompt = """
Analyze the provided image(s) following the "Neutral Scientific Analyzer" specifications.
Return ONLY a valid JSON object.

STRICT RULES:
1. BRAND NEUTRALITY: Strictly ignore logos, commercial names, and marketing claims.
2. SCIENTIFIC NEUTRALITY: Describe what the ingredient IS and its FUNCTION. No health scores or "good/bad" labels.
3. TRACEABILITY (LAW 54): Objective extraction only. Use "is_estimated: true" for guessed data.
4. MULTILINGUAL: Accurate names/descriptions in: FR, EN, AR, and AR_TN (Arabic script).

JSON STRUCTURE:
{
  "scan_info": {
    "title_suggested": "Generic name only",
    "analysis_timestamp": "ISO8601"
  },
  "ingredients_detected": [
    {
      "technical_code": "E-code (e.g., 'E150c') or 'l_name' (e.g., 'l_sugar')",
      "quantity": null,
      "unit": "g, ml, or null",
      "is_estimated": false,
      "priority_score": 5,
      "translations": {
        "fr": { "name": "...", "description": "Rôle technique" },
        "en": { "name": "...", "description": "Technical role" },
        "ar": { "name": "...", "description": "الدور التقني" },
        "ar_tn": { "name": "...", "description": "وصف بالدارجة" }
      }
    }
  ]
}

PRIORITY_SCORE LOGIC (for internal sorting, integer 1-10):
- 10-8: High priority / sensitive items (e.g., added sugars, high sodium, saturated fats, controversial additives).
- 7-4: Secondary ingredients or technical additives with functional roles.
- 3-1: Neutral or base ingredients (e.g., water, natural fibers).

SPECIFIC HANDLING:
- Additives: technical_code MUST be the E-code (e.g., "E150c"). Description = scientific role only.
- Quantities: If not visible on packaging, set to null and is_estimated to true.
- Raw dishes: Decompose into base components.
""";

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    try {
      final response = await _model.generateContent(content);
      return response.text ?? '{}';
    } catch (e) {
      print('DEBUG: AiService.analyzeProduct - ERROR: $e');
      rethrow;
    }
  }
}
