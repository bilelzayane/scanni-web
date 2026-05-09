import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/history.dart';
import '../../../domain/models/scientific_lexicon.dart';
import '../../../domain/models/scientific_fact.dart';
import '../../../domain/models/user_watchlist.dart';
import '../../../domain/models/ai_suggestion.dart';
import 'dart:typed_data';
import '../services/local_scan_service.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return SupabaseScanRepository(
    Supabase.instance.client,
    LocalScanService(),
  );
});

abstract class ScanRepository {
  Future<void> deleteScan(String id);

  // New methods for History Detail screen
  Future<History?> getHistoryById(String id);
  Future<List<ScientificLexicon>> getScientificLexicon(
    List<String> ingredientIds,
  );
  Future<List<ScientificFact>> getScientificFacts(List<String> ingredientIds);
  Future<List<UserWatchlist>> getUserWatchlist(String userId);

  // Method for paginated history with joins
  Future<List<History>> getFullUserHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  });

  // New method to fetch translations for multiple ingredients
  Future<Map<String, Map<String, String>>> getIngredientTranslations(
    List<String> ingredientIds,
    String languageCode,
  );

  // New method to fetch user pathologies for safety logic
  Future<List<String>> getUserPathologyIds(String userId);

  // AI-powered scan methods
  Future<AiSuggestion> getAiSuggestion(String id);
  Future<String?> uploadImage(String userId, List<int> bytes);
  Future<AiSuggestion> saveAiSuggestion(
    String userId,
    Map<String, dynamic> payload, {
    String? imageUrl,
  });
  Future<void> updateAiSuggestionTitle(String id, String newTitle);
  
  // Guest mode sync
  Future<void> syncGuestScans(String userId);
}

class SupabaseScanRepository implements ScanRepository {
  final SupabaseClient _client;
  final LocalScanService _localService;

  SupabaseScanRepository(this._client, this._localService);

  @override
  Future<void> deleteScan(String id) async {
    if (id.startsWith('local_')) {
      await _localService.deleteScan(id);
    } else {
      await _client.from('ai_suggestions').delete().eq('id', id);
    }
  }

  @override
  Future<History?> getHistoryById(String id) async {
    print('DEBUG: getHistoryById - id: $id');
    try {
      AiSuggestion? suggestion;
      if (id.startsWith('local_')) {
        suggestion = await _localService.getScanById(id);
      } else {
        final data = await _client
            .from('ai_suggestions')
            .select()
            .eq('id', id)
            .single();
        suggestion = AiSuggestion.fromJson(data);
      }
      
      if (suggestion == null) return null;
      return History.fromAiSuggestion(suggestion);
    } catch (e) {
      print('DEBUG: getHistoryById - error: $e');
      return null;
    }
  }

  @override
  Future<List<ScientificLexicon>> getScientificLexicon(
    List<String> ingredientIds,
  ) async {
    if (ingredientIds.isEmpty) return [];
    // Using technical_code instead of id (UUID) to support string-based AI suggestions
    final data = await _client
        .from('scientific_lexicon')
        .select()
        .inFilter('technical_code', ingredientIds);
    return (data as List<dynamic>)
        .map((e) => ScientificLexicon.fromJson(e))
        .toList();
  }

  @override
  Future<List<ScientificFact>> getScientificFacts(
    List<String> ingredientIds,
  ) async {
    if (ingredientIds.isEmpty) return [];
    try {
      // Use technical_code from the joined scientific_lexicon table
      final data = await _client
          .from('scientific_facts')
          .select('*, scientific_lexicon!inner(technical_code)')
          .inFilter('scientific_lexicon.technical_code', ingredientIds);
      
      return (data as List<dynamic>)
          .map((e) => ScientificFact.fromJson(e))
          .toList();
    } catch (e) {
      print('DEBUG: getScientificFacts - fallback search by ingredient_id: $e');
      // Fallback: if scientific_lexicon join fails, try direct but it might fail on UUID type
      try {
        final data = await _client
            .from('scientific_facts')
            .select()
            .inFilter('ingredient_id', ingredientIds);
        return (data as List<dynamic>)
            .map((e) => ScientificFact.fromJson(e))
            .toList();
      } catch (innerError) {
        return [];
      }
    }
  }

  @override
  Future<List<UserWatchlist>> getUserWatchlist(String userId) async {
    final data = await _client
        .from('user_watchlist')
        .select()
        .eq('user_id', userId);
    return (data as List<dynamic>)
        .map((e) => UserWatchlist.fromJson(e))
        .toList();
  }

  @override
  Future<List<History>> getFullUserHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    print(
      'DEBUG: getFullUserHistory - userId: $userId, limit: $limit, offset: $offset',
    );
    try {
      List<AiSuggestion> suggestions = [];
      
      if (userId == 'guest' || userId.isEmpty) {
        suggestions = await _localService.getScans();
        // Sort and apply pagination locally for simplicity
        suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (offset < suggestions.length) {
          final end = (offset + limit < suggestions.length) ? offset + limit : suggestions.length;
          suggestions = suggestions.sublist(offset, end);
        } else {
          suggestions = [];
        }
      } else {
        final data = await _client
            .from('ai_suggestions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        suggestions = (data as List).map((e) => AiSuggestion.fromJson(e)).toList();
      }
      
      print('DEBUG: getFullUserHistory - fetched ${suggestions.length} records');
      
      return suggestions.map((s) => History.fromAiSuggestion(s)).toList();
    } catch (e) {
      print('DEBUG: getFullUserHistory - error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, Map<String, String>>> getIngredientTranslations(
    List<String> ingredientIds,
    String languageCode,
  ) async {
    if (ingredientIds.isEmpty) return {};

    // Fetch translations for the given ingredients and language
    final data = await _client
        .from('translations')
        .select('parent_id, field_name, content')
        .eq('parent_type', 'scientific_lexicon')
        .eq('language_code', languageCode)
        .inFilter('parent_id', ingredientIds);

    // Build a map: parent_id -> field_name -> content
    final Map<String, Map<String, String>> translationMap = {};
    for (final row in data as List<dynamic>) {
      final rowMap = row as Map<String, dynamic>;
      final parentId = rowMap['parent_id'] as String;
      final fieldName = rowMap['field_name'] as String;
      final content = rowMap['content'] as String;

      translationMap.putIfAbsent(parentId, () => {})[fieldName] = content;
    }

    return translationMap;
  }

  @override
  Future<List<String>> getUserPathologyIds(String userId) async {
    final data = await _client
        .from('user_pathologies')
        .select('pathology_id')
        .eq('user_id', userId);
    return (data as List<dynamic>)
        .map((e) => e['pathology_id'] as String)
        .toList();
  }

  @override
  Future<AiSuggestion> getAiSuggestion(String id) async {
    if (id.startsWith('local_')) {
      final suggestion = await _localService.getScanById(id);
      if (suggestion == null) throw Exception('Local scan not found');
      return suggestion;
    }
    final data = await _client
        .from('ai_suggestions')
        .select()
        .eq('id', id)
        .single();
    return AiSuggestion.fromJson(data);
  }

  @override
  Future<String?> uploadImage(String userId, List<int> bytes) async {
    if (userId == 'guest' || userId.isEmpty) {
      // For guest, we could store images locally, but for now we skip upload
      print('DEBUG: uploadImage - skipping for guest');
      return null;
    }
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';

      await _client.storage.from('product-scans').uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      return _client.storage.from('product-scans').getPublicUrl(path);
    } catch (e) {
      print('DEBUG: uploadImage - ERROR: $e. Scan will proceed without image URL.');
      return null;
    }
  }

  @override
  Future<AiSuggestion> saveAiSuggestion(
    String userId,
    Map<String, dynamic> payload, {
    String? imageUrl,
  }) async {
    if (userId == 'guest' || userId.isEmpty) {
      await _localService.saveScan(payload, imageUrl: imageUrl);
      // Return a temporary AiSuggestion object
      return AiSuggestion(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'guest',
        payload: payload,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        scanInfo: ScanInfo.fromJson(payload['scan_info'] as Map<String, dynamic>),
        ingredientsDetected: (payload['ingredients_detected'] as List)
            .map((e) => IngredientDetected.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final data = {
      'user_id': userId,
      'payload': payload,
      'image_url': imageUrl,
    };

    final response = await _client
        .from('ai_suggestions')
        .insert(data)
        .select()
        .single();
    return AiSuggestion.fromJson(response);
  }

  @override
  Future<void> updateAiSuggestionTitle(String id, String newTitle) async {
    if (id.startsWith('local_')) {
      await _localService.updateTitle(id, newTitle);
      return;
    }
    // We need to update the JSONB payload
    final existing = await _client
        .from('ai_suggestions')
        .select('payload')
        .eq('id', id)
        .single();

    final payload = Map<String, dynamic>.from(existing['payload'] as Map);
    final scanInfo = Map<String, dynamic>.from(payload['scan_info'] as Map);
    scanInfo['title_suggested'] = newTitle;
    payload['scan_info'] = scanInfo;

    await _client
        .from('ai_suggestions')
        .update({'payload': payload})
        .eq('id', id);
  }

  @override
  Future<void> syncGuestScans(String userId) async {
    final guestScans = await _localService.getScans();
    if (guestScans.isEmpty) return;

    for (final scan in guestScans) {
      final data = {
        'user_id': userId,
        'payload': scan.payload,
        'image_url': scan.imageUrl,
        'created_at': scan.createdAt.toIso8601String(),
      };
      
      await _client.from('ai_suggestions').insert(data);
    }

    await _localService.clearAll();
  }
}
