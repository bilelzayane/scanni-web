import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/ai_suggestion.dart';
import '../../../data/repositories/scan_repository.dart';

final aiSuggestionProvider = FutureProvider.family.autoDispose<AiSuggestion, String>((ref, id) async {
  final repo = ref.watch(scanRepositoryProvider);
  return await repo.getAiSuggestion(id);
});
