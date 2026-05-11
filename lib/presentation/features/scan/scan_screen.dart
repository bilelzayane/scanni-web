import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_app/core/localization/app_localizations.dart';
import 'package:flutter_app/presentation/core/theme/app_theme.dart';
import 'package:flutter_app/presentation/features/scan/scan_controller.dart';
import 'package:flutter_app/data/repositories/scan_repository.dart';
import 'package:flutter_app/data/repositories/auth_repository.dart';
import 'package:flutter_app/core/services/ai_service.dart';
import 'package:flutter_app/presentation/features/history/history_controller.dart';
import 'package:flutter_app/domain/models/ai_suggestion.dart';
import 'package:flutter_app/domain/models/history.dart';
import 'package:flutter_app/domain/models/scientific_lexicon.dart';
import 'package:flutter_app/domain/models/scientific_fact.dart';
import 'package:flutter_app/domain/models/test_type.dart';

// ─── Detail Data Model for Drawer ─────────────────────────────────────────────
class _DetailData {
  final History? history;
  final List<IngredientDetected> historyDetails;
  final List<ScientificLexicon> scientificLexicon;
  final List<ScientificFact> scientificFacts;
  final Set<String> watchlistIds;

  _DetailData({
    required this.history,
    required this.historyDetails,
    required this.scientificLexicon,
    required this.scientificFacts,
    required this.watchlistIds,
  });
}

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final GlobalKey _boundaryKey = GlobalKey();

  bool _isProcessing = false;
  bool _showResults = false;
  bool _flashEnabled = false;
  Timer? _autoDetectTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    _resetScanState();
  }

  void _resetScanState() {
    _cameraController.start();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _showResults = false;
        _flashEnabled = false;
      });
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(scanControllerProvider.notifier).resetScan();
    });
  }

  @override
  void dispose() {
    _autoDetectTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });

    if (kIsWeb) {
      _toggleWebTorch(_flashEnabled);
    } else {
      _cameraController.toggleTorch();
    }
  }

  Future<void> _toggleWebTorch(bool enabled) async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        print('DEBUG: Web Torch - mediaDevices not supported');
        return;
      }

      final devices = await mediaDevices.enumerateDevices();
      final videoDevices = devices.where((device) => device.kind == 'videoinput').toList();
      
      if (videoDevices.isNotEmpty) {
        final stream = await mediaDevices.getUserMedia({'video': {'facingMode': 'environment'}});
        final tracks = stream.getVideoTracks();
        if (tracks.isNotEmpty) {
          final track = tracks.first;
          final constraints = {'advanced': [{'torch': enabled}]};
          await (track as dynamic).applyConstraints(constraints);
          print('DEBUG: Web Torch - Applied constraints: $constraints');
        }
      }
    } catch (e) {
      print('DEBUG: Web Torch - Error: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessing) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        await _processImage(bytes);
      }
    } catch (e) {
      print('DEBUG: _pickImage ERROR: $e');
    }
  }

  Future<void> _processImage(Uint8List bytes) async {
    if (!mounted || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. AI Analysis (Gemini)
      final aiService = ref.read(aiServiceProvider);
      final aiResponseJson = await aiService.analyzeProduct(bytes);
      final Map<String, dynamic> payload = json.decode(aiResponseJson);
      print('DEBUG: ScanScreen - Parsed AI Payload: $payload');

      // Check if analysis actually returned anything
      if (payload.isEmpty ||
          (payload['ingredients_detected'] as List?)?.isEmpty == true) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showNoResultDrawer();
        }
        return;
      }

      // 2. Supabase Integration
      final authRepo = ref.read(authRepositoryProvider);
      final scanRepo = ref.read(scanRepositoryProvider);
      final userId = authRepo.currentUser?.id;
      final effectiveUserId = userId ?? 'guest';

      // Upload image
      final imageUrl = await scanRepo.uploadImage(effectiveUserId, bytes);

      // Save suggestion
      final suggestion = await scanRepo.saveAiSuggestion(
        effectiveUserId,
        payload,
        imageUrl: imageUrl,
      );

      // Convert to History for UI
      final result = History.fromAiSuggestion(suggestion);

      // Refresh history list
      ref.invalidate(historyProvider);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _showResults = true;
      });
      _showResultDrawer(result);
    } catch (e) {
      print('DEBUG: _processImage - ERROR: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showNoResultDrawer();
      }
    }
  }

  Future<void> _handleCapture() async {
    if (!mounted || _isProcessing) return;

    try {
      // For Web, ImagePicker.pickImage(source: ImageSource.camera) is the most reliable way 
      // to get a high-quality photo that Gemini can analyze.
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();
      await _processImage(bytes);
    } catch (e) {
      print('DEBUG: _handleCapture - ERROR: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showNoResultDrawer();
      }
    }
  }

  void _simulateVisualDetection() {
    // For visual detection, we still use the boundary capture
    _handleCapture();
  }

  // ─── No Result Drawer ──────────────────────────────────────────────────
  void _showNoResultDrawer() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.analysisImpossible,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.analysisImpossibleDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanState();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Drawer (Visual Recognition) ────────────────────────────────────
  void _showResultDrawer(History result) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) => _ResultDrawerSheet(
        scanResult: result,
        onScanAnother: () {
          Navigator.pop(sheetContext);
          _resetScanState();
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showResults = false;
          _isProcessing = false;
        });
      }
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanState = ref.watch(scanControllerProvider);

    ref.listen(cameraTriggerNotifierProvider, (previous, next) {
      print(
        'DEBUG: Trigger received - previous: $previous, next: $next, _isProcessing: $_isProcessing, _showResults: $_showResults',
      );
      if (next > (previous ?? 0)) {
        if (mounted && !_isProcessing) {
          print('DEBUG: Starting visual detection');
          _simulateVisualDetection();
        } else {
          print(
            'DEBUG: Detection skipped - mounted: $mounted, _isProcessing: $_isProcessing',
          );
        }
      }
    });

    final isLoading = scanState.isAnalyzing || _isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen camera ────────────────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                errorBuilder: (context, error) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.center_focus_strong,
                            color: Colors.red,
                            size: 50,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${l10n.cameraError}: ${error.errorCode}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                placeholderBuilder: (context) {
                  return Container(color: Colors.black);
                },
              ),
            ),
          ),

          // ── Dark gradient overlay (top) for status bar legibility ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Flash toggle button (top right) ─────────────────────────
          Positioned(
            top: 50,
            right: 16,
            child: GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _flashEnabled ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // ── Viewfinder frame ────────────────────────────────────────
          Center(
            child: SizedBox(
              height: 240,
              width: MediaQuery.of(context).size.width * 0.75,
              child: CustomPaint(painter: _CornerFramePainter()),
            ),
          ),

          // ── Floating instruction text ───────────────────────────────
          Positioned(
            bottom: 160,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.scanInstruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.analyzingInProgress,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerRadius = 20.0;
    final segmentLength = 25.0;
    final path = Path();

    // Top-left corner
    path.moveTo(0, segmentLength + cornerRadius);
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(segmentLength + cornerRadius, 0);

    // Top-right corner
    path.moveTo(size.width - segmentLength - cornerRadius, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(size.width, segmentLength + cornerRadius);

    // Bottom-right corner
    path.moveTo(size.width, size.height - segmentLength - cornerRadius);
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(size.width - segmentLength - cornerRadius, size.height);

    // Bottom-left corner
    path.moveTo(segmentLength + cornerRadius, size.height);
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(0, size.height - segmentLength - cornerRadius);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── New Result Drawer Sheet (DraggableScrollableSheet) ─────────────────────
class _ResultDrawerSheet extends ConsumerStatefulWidget {
  final History scanResult;
  final VoidCallback onScanAnother;

  const _ResultDrawerSheet({
    required this.scanResult,
    required this.onScanAnother,
  });

  @override
  ConsumerState<_ResultDrawerSheet> createState() => _ResultDrawerSheetState();
}

class _ResultDrawerSheetState extends ConsumerState<_ResultDrawerSheet> {
  final Set<int> _expandedQuantitativeIndices = {};
  final Set<int> _expandedTechnicalIndices = {};
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _nameController = TextEditingController();

  Future<_DetailData>? _dataFuture;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      if (_sheetController.size <= 0.02) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final l10n = AppLocalizations.of(context);
      _nameController.text = widget.scanResult.name ?? l10n.analysisImpossible;
      _isInitialized = true;
      _dataFuture = _fetchData();
    }
  }

  Future<_DetailData> _fetchData() async {
    final repo = ref.read(scanRepositoryProvider);
    final history = await repo.getHistoryById(widget.scanResult.id);

    if (history == null) {
      return _DetailData(
        history: widget.scanResult,
        historyDetails: widget.scanResult.details,
        scientificLexicon: [],
        scientificFacts: [],
        watchlistIds: {},
      );
    }

    // Use history.details directly (already joined from Supabase)
    final historyDetails = history.details;

    // Get ingredient IDs for fetching scientific data
    final ingredientIds = historyDetails
        .map((d) => d.technicalCode)
        .toList();
    final scientificLexicon = await repo.getScientificLexicon(ingredientIds);
    final scientificFacts = await repo.getScientificFacts(ingredientIds);

    // Update title controller if we got a better name from DB
    if (history.name != null && history.name != _nameController.text) {
      _nameController.text = history.name!;
    }

    return _DetailData(
      history: history,
      historyDetails: historyDetails,
      scientificLexicon: scientificLexicon,
      scientificFacts: scientificFacts,
      watchlistIds: {},
    );
  }

  Future<void> _showEditTitleDialog(BuildContext context) async {
    final controller = TextEditingController(text: _nameController.text);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).editTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).enterNewTitle,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                try {
                  await ref
                      .read(scanRepositoryProvider)
                      .updateAiSuggestionTitle(widget.scanResult.id, newTitle);
                  if (mounted) {
                    setState(() {
                      _nameController.text = newTitle;
                    });
                  }
                  ref.invalidate(historyProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating title: $e')),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(AppLocalizations.of(context).areYouSureDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(scanRepositoryProvider)
                    .deleteScan(widget.scanResult.id);
                ref.invalidate(historyProvider);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close drawer
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting scan: $e')),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeDate(BuildContext context, String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      // Reset times to compare only dates
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final compareDate = DateTime(date.year, date.month, date.day);

      final l10n = AppLocalizations.of(context);

      if (compareDate == today) {
        return l10n.relativeToday;
      } else if (compareDate == yesterday) {
        return l10n.relativeYesterday;
      } else {
        return intl.DateFormat.yMMMd(
          Localizations.localeOf(context).languageCode,
        ).format(date);
      }
    } catch (e) {
      print('DEBUG: _getRelativeDate ERROR: $e');
      return 'Today';
    }
  }

  void _toggleQuantitativeExpansion(int index) {
    setState(() {
      if (_expandedQuantitativeIndices.contains(index)) {
        _expandedQuantitativeIndices.remove(index);
      } else {
        _expandedQuantitativeIndices.add(index);
      }
    });
  }

  void _toggleTechnicalExpansion(int index) {
    setState(() {
      if (_expandedTechnicalIndices.contains(index)) {
        _expandedTechnicalIndices.remove(index);
      } else {
        _expandedTechnicalIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.6,
      minChildSize: 0.0,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.0, 0.4, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Grabber handle
              GestureDetector(
                onTap: () {
                  _sheetController.animateTo(
                    0.95,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header - Synchronized with ResultScreen
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.scanResult.testType == TestType.dishScan
                            ? Icons.local_dining
                            : Icons.list_alt,
                        size: 24,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Identity - Editable
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditTitleDialog(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _nameController.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.foregroundColor,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action: Delete
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: () => _showDeleteConfirmationDialog(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: FutureBuilder<_DetailData>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final detailData =
                        snapshot.data ??
                        _DetailData(
                          history: null,
                          historyDetails: [],
                          scientificLexicon: [],
                          scientificFacts: [],
                          watchlistIds: {},
                        );

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Quantitative Analysis
                        _buildQuantitativeAnalysis(
                          context,
                          detailData.scientificLexicon,
                          detailData.scientificFacts,
                          detailData.watchlistIds,
                          _expandedQuantitativeIndices,
                          _toggleQuantitativeExpansion,
                          detailData.historyDetails,
                        ),
                        const SizedBox(height: 16),
                        // Technical Composition
                        _buildTechnicalComposition(
                          context,
                          detailData.scientificLexicon,
                          detailData.scientificFacts,
                          detailData.watchlistIds,
                          _expandedTechnicalIndices,
                          _toggleTechnicalExpansion,
                          detailData.historyDetails,
                        ),
                        const SizedBox(height: 20),
                        // Footer button
                        GestureDetector(
                          onTap: widget.onScanAnother,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.center_focus_strong,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  l10n.newScanButton,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 120),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantitativeAnalysis(
    BuildContext context,
    List<ScientificLexicon> scientificLexicon,
    List<ScientificFact> scientificFacts,
    Set<String> watchlistIds,
    Set<int> expandedIndices,
    Function(int) onToggle,
    List<IngredientDetected> historyDetails,
  ) {
    final l10n = AppLocalizations.of(context);
    // Filter for ingredients with quantity and sort by priorityScore DESC
    final filteredDetails = historyDetails
        .where((d) => d.quantity != null)
        .toList();
    filteredDetails.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    final locale = Localizations.localeOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quantitativeAnalysis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.foregroundColor,
            ),
          ),
          const SizedBox(height: 12),
          if (filteredDetails.isEmpty)
            Text(
              l10n.noQuantitativeDataDetected,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            ...filteredDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final detail = entry.value;
              final quantity = detail.quantity ?? 0;
              final unit = detail.unit ?? '';
              final name = _getIngredientName(detail);
              final description = detail.getDescription(locale.languageCode);
              final progress = _getGaugePercentage(
                detail.technicalCode,
                quantity,
              );
              final isExpanded = expandedIndices.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => onToggle(index),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.foregroundColor,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${quantity.toStringAsFixed(2)} $unit',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.foregroundColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 8,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueGrey[400]!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded && description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTechnicalComposition(
    BuildContext context,
    List<ScientificLexicon> scientificLexicon,
    List<ScientificFact> scientificFacts,
    Set<String> watchlistIds,
    Set<int> expandedIndices,
    Function(int) onToggle,
    List<IngredientDetected> historyDetails,
  ) {
    final l10n = AppLocalizations.of(context);
    // Filter for ingredients without quantity and sort by priorityScore DESC
    final filteredDetails = historyDetails
        .where((d) => d.quantity == null)
        .toList();
    filteredDetails.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    final locale = Localizations.localeOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.technicalComposition,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.foregroundColor,
            ),
          ),
          const SizedBox(height: 12),
          if (filteredDetails.isEmpty)
            Text(
              l10n.noQuantitativeDataDetected, // Re-using this or could add more specific if needed
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            ...filteredDetails.asMap().entries.map((entry) {
              final detail = entry.value;
              final name = _getIngredientName(detail);
              final description = detail.getDescription(locale.languageCode);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toLowerCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.foregroundColor,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getIngredientName(IngredientDetected detail) {
    return detail.getName(Localizations.localeOf(context).languageCode);
  }

  double _getGaugePercentage(String technicalCode, double value) {
    // Return specific gauge percentages for ingredient data
    switch (technicalCode) {
      case 'ing_milk':
        return 0.50;
      case 'ing_sugar':
        return 0.20;
      case 'ing_e120':
        return 0.05;
      case 'ing_wheat_flour':
        return 0.30;
      case 'ing_palm_oil':
        return 0.10;
      case 'ing_cocoa_flavor':
        return 0.02;
      case 'ing_sodium_chloride':
        return 1.00;
      case 'ing_e551':
        return 0.01;
      case 'ing_cocoa':
        return 0.08;
      case 'ing_e407':
        return 0.03;
      case 'ing_e621':
        return 0.02;
      case 'ing_vitamin_d':
        return 0.15;
      default:
        return (value / 1000).clamp(0.0, 1.0);
    }
  }

  String _getQuantitativeFact(String technicalCode) {
    switch (technicalCode) {
      case 'ing_milk':
        return 'Rich in calcium and protein';
      case 'ing_sugar':
        return 'High sugar intake risk';
      case 'ing_e120':
        return 'Red food coloring additive';
      case 'ing_wheat_flour':
        return 'Contains gluten';
      case 'ing_palm_oil':
        return 'Fat used for texture';
      case 'ing_cocoa_flavor':
        return 'Artificial flavor additive';
      case 'ing_sodium_chloride':
        return 'Basic salt used in food';
      case 'ing_e551':
        return 'Prevents clumping';
      case 'ing_cocoa':
        return 'Chocolate flavor source';
      case 'ing_e407':
        return 'Used to maintain texture and prevent separation';
      case 'ing_e621':
        return 'Enhances taste (MSG)';
      case 'ing_vitamin_d':
        return 'Fortification for bone health';
      default:
        return '';
    }
  }

  String _getQuantitativeSource(String technicalCode) {
    switch (technicalCode) {
      case 'ing_milk':
        return 'Source: NT 14.01';
      case 'ing_sugar':
        return 'Source: WHO';
      case 'ing_e120':
        return 'Source: EU Regulation';
      case 'ing_wheat_flour':
        return 'Source: Codex Alimentarius';
      case 'ing_palm_oil':
        return 'Source: EFSA';
      case 'ing_cocoa_flavor':
        return 'Source: EU Regulation';
      case 'ing_sodium_chloride':
        return 'Source: NT 16.02';
      case 'ing_e551':
        return 'Source: EU Regulation';
      case 'ing_cocoa':
        return 'Source: Codex Alimentarius';
      case 'ing_e407':
        return 'Source: EU Food Regulation';
      case 'ing_e621':
        return 'Source: WHO / FAO';
      case 'ing_vitamin_d':
        return 'Source: Nutrition Standards';
      default:
        return '';
    }
  }
}
