import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/history.dart';
import '../../../data/repositories/scan_repository.dart';
import '../../../data/repositories/auth_repository.dart';

final historyProvider = FutureProvider.autoDispose<List<History>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  final repo = ref.watch(scanRepositoryProvider);
  final userId = user?.id ?? 'guest';
  return repo.getFullUserHistory(userId, limit: 20, offset: 0);
});
