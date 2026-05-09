import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/ai_suggestion.dart';

class LocalScanService {
  static const String _storageKey = 'guest_scans';

  Future<void> saveScan(Map<String, dynamic> payload, {String? imageUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList(_storageKey) ?? [];
    
    final newScan = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'guest',
      'payload': payload,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    scansJson.add(json.encode(newScan));
    await prefs.setStringList(_storageKey, scansJson);
  }

  Future<List<AiSuggestion>> getScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList(_storageKey) ?? [];
    
    return scansJson.map((s) => AiSuggestion.fromJson(json.decode(s))).toList();
  }

  Future<AiSuggestion?> getScanById(String id) async {
    final scans = await getScans();
    try {
      return scans.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList(_storageKey) ?? [];
    
    final updatedScans = scansJson.where((s) {
      final decoded = json.decode(s);
      return decoded['id'] != id;
    }).toList();

    await prefs.setStringList(_storageKey, updatedScans);
  }

  Future<void> updateTitle(String id, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList(_storageKey) ?? [];
    
    final updatedScans = scansJson.map((s) {
      final decoded = json.decode(s) as Map<String, dynamic>;
      if (decoded['id'] == id) {
        final payload = Map<String, dynamic>.from(decoded['payload'] as Map);
        final scanInfo = Map<String, dynamic>.from(payload['scan_info'] as Map);
        scanInfo['title_suggested'] = newTitle;
        payload['scan_info'] = scanInfo;
        decoded['payload'] = payload;
      }
      return json.encode(decoded);
    }).toList();

    await prefs.setStringList(_storageKey, updatedScans);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
