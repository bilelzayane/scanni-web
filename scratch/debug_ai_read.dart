import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/core/constants/env.dart';
import '../lib/domain/models/ai_suggestion.dart';
import '../lib/domain/models/history.dart';

void main() async {
  print('--- DEBUG: AI READ TEST ---');
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    print('WARNING: No user currently connected. Checking for public data or specific ID...');
    // Testing with a specific ID if available
    const testId = 'replace-with-a-real-id'; 
    final data = await client.from('ai_suggestions').select().limit(1);
    if (data.isNotEmpty) {
      print('FOUND DATA: ${data.length} records found in ai_suggestions.');
      final first = data[0];
      final suggestion = AiSuggestion.fromJson(first);
      print('SUCCESS: Parsed suggestion "${suggestion.scanInfo.titleSuggested}"');
      final history = History.fromAiSuggestion(suggestion);
      print('SUCCESS: Mapped to History object with ${history.details.length} ingredients.');
    } else {
      print('EMPTY: No records found in ai_suggestions table.');
    }
  } else {
    print('USER CONNECTED: ${user.email} (${user.id})');
    final data = await client
        .from('ai_suggestions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    print('FETCHED: ${data.length} records for user ${user.id}');
    for (final row in data) {
      final suggestion = AiSuggestion.fromJson(row);
      print('- [${suggestion.id}] ${suggestion.scanInfo.titleSuggested}');
    }
  }
  
  print('--- DEBUG: TEST COMPLETE ---');
}
