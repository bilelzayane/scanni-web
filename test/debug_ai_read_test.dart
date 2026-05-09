import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/core/constants/env.dart';
import 'package:flutter_app/domain/models/ai_suggestion.dart';
import 'package:flutter_app/domain/models/history.dart';

void main() {
  test('Debug AI Read Test', () async {
    print('--- DEBUG: AI READ TEST ---');
    
    // We can't easily initialize real Supabase in a unit test without mocks or proper setup
    // but we can test the parsing logic with sample data
    
    final sampleJson = {
      'id': 'test-uuid-123',
      'user_id': 'user-uuid-456',
      'image_url': 'https://example.com/image.jpg',
      'created_at': DateTime.now().toIso8601String(),
      'payload': {
        'scan_info': {
          'title_suggested': 'Analyse Technique Test',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'ingredients_detected': [
          {
            'technical_code': 'l_sugar',
            'quantity': 10.5,
            'unit': 'g',
            'is_estimated': true,
            'translations': {
              'fr': {'name': 'Sucre', 'description': 'Description du sucre'},
              'en': {'name': 'Sugar', 'description': 'Sugar description'},
            }
          }
        ]
      }
    };

    print('TESTING: Parsing AiSuggestion from sample JSON...');
    final suggestion = AiSuggestion.fromJson(sampleJson);
    expect(suggestion.id, 'test-uuid-123');
    expect(suggestion.scanInfo.titleSuggested, 'Analyse Technique Test');
    print('SUCCESS: AiSuggestion parsed.');

    print('TESTING: Mapping AiSuggestion to History...');
    final history = History.fromAiSuggestion(suggestion);
    expect(history.id, suggestion.id);
    expect(history.name, suggestion.scanInfo.titleSuggested);
    expect(history.details.length, 1);
    expect(history.details[0].ingredient?.name.fr, 'Sucre');
    print('SUCCESS: History mapped correctly.');
    
    print('--- DEBUG: TEST COMPLETE ---');
  });
}
