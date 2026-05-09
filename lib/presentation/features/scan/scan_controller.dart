import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/history.dart';
import '../../../domain/models/test_type.dart';

class ScanState {
  final bool isAnalyzing;
  final String? error;
  final History? lastScan;

  const ScanState({this.isAnalyzing = false, this.error, this.lastScan});
}

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  Future<History?> processBarcode(String barcode) async {
    if (state.isAnalyzing) return null;
    state = const ScanState(isAnalyzing: true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Create a mock History object for barcode scan
      final result = History.withStringType(
        id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        testType: TestType.labelScan.value,
        scanDate: DateTime.now().toIso8601String(),
        details: [], // Will be populated by actual analysis
      );

      state = ScanState(isAnalyzing: false, lastScan: result);
      return result;
    } catch (e) {
      state = ScanState(isAnalyzing: false, error: e.toString());
      return null;
    }
  }

  Future<History?> processPhoto(String imagePath) async {
    if (state.isAnalyzing) return null;
    state = const ScanState(isAnalyzing: true);

    try {
      await Future.delayed(const Duration(seconds: 3));

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Create a mock History object for photo scan
      final result = History.withStringType(
        id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        testType: TestType.dishScan.value,
        scanDate: DateTime.now().toIso8601String(),
        details: [], // Will be populated by actual analysis
      );

      state = ScanState(isAnalyzing: false, lastScan: result);
      return result;
    } catch (e) {
      state = ScanState(isAnalyzing: false, error: e.toString());
      return null;
    }
  }

  void resetScan() {
    state = const ScanState(isAnalyzing: false, error: null, lastScan: null);
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

final cameraTriggerProvider = Provider<int>((ref) => 0);

class CameraTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

final cameraTriggerNotifierProvider =
    NotifierProvider<CameraTriggerNotifier, int>(CameraTriggerNotifier.new);
