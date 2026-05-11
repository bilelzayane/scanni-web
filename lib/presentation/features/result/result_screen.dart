import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/theme/app_theme.dart';
import '../history/history_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'ai_result_controller.dart';
import '../../../data/repositories/scan_repository.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/ai_suggestion.dart';
import '../../../domain/models/test_type.dart';

// Using ResultData from result_controller.dart

class ResultScreen extends ConsumerStatefulWidget {
  final String id;

  const ResultScreen({super.key, required this.id});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final Set<String> _expandedQuantitativeItems = {};
  final Set<String> _expandedTechnicalItems = {};
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleQuantitativeExpansion(String ingredientId) {
    setState(() {
      if (_expandedQuantitativeItems.contains(ingredientId)) {
        _expandedQuantitativeItems.remove(ingredientId);
      } else {
        _expandedQuantitativeItems.add(ingredientId);
      }
    });
  }

  void _toggleTechnicalExpansion(String lexiconId) {
    setState(() {
      if (_expandedTechnicalItems.contains(lexiconId)) {
        _expandedTechnicalItems.remove(lexiconId);
      } else {
        _expandedTechnicalItems.add(lexiconId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final suggestionAsync = ref.watch(aiSuggestionProvider(widget.id));
    final l10n = AppLocalizations.of(context);

    return Directionality(
      textDirection: l10n.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: suggestionAsync.when(
          data: (suggestion) {
            // Sort ingredients by priorityScore descending
            final sortedIngredients = List<IngredientDetected>.from(suggestion.ingredientsDetected)
              ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

            // Set name controller text if empty
            if (_nameController.text.isEmpty) {
              _nameController.text = suggestion.scanInfo.titleSuggested;
            }

            return Stack(
              children: [
                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 80, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section 1: Quantitative Analysis
                            _buildQuantitativeAnalysis(
                              sortedIngredients
                                  .where((i) => i.quantity != null)
                                  .toList(),
                              locale,
                            ),
                            const SizedBox(height: 16),
                            // Section 2: Technical Composition
                            _buildTechnicalComposition(
                              sortedIngredients
                                  .where((i) => i.quantity == null)
                                  .toList(),
                              locale,
                            ),
                            const SizedBox(height: 20),
                            // Footer button
                            GestureDetector(
                              onTap: () => context.go('/scan'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.center_focus_strong,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(
                      context,
                      ref,
                      suggestion,
                      locale,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('${l10n.errorLoadingDetails}: $e'),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => ref.refresh(aiSuggestionProvider(widget.id)),
                      child: Text(l10n.retry),
                    ),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(l10n.goHome),
                    ),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AiSuggestion suggestion,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context);
    final isRTL = l10n.isRTL;

    // Get relative date
    final date = suggestion.createdAt;
    final now = DateTime.now();
    final difference = now.difference(date);
    String relativeDate;
    if (difference.inDays == 0) {
      relativeDate = l10n.relativeToday;
    } else if (difference.inDays == 1) {
      relativeDate = l10n.relativeYesterday;
    } else {
      relativeDate = intl.DateFormat('MMM d, y').format(date);
    }

    // Determine icon (Default to list_alt)
    IconData iconData = Icons.list_alt;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      textDirection: (Localizations.localeOf(context).languageCode == 'ar' ||
              Localizations.localeOf(context).languageCode == 'ar_tn')
          ? TextDirection.rtl
          : TextDirection.ltr,
      children: [
        // Back button (Leading)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            final fromHome = GoRouterState.of(context).uri.queryParameters['fromHome'] == 'true';
            if (fromHome) {
              context.go('/');
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        // Product Identity (Center) - Editable
        Expanded(
          child: GestureDetector(
            onTap: () => _showEditTitleDialog(context, ref, suggestion),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    (suggestion.payload?['scan_info']?['test_type'] == 'dish_scan')
                        ? Icons.local_dining
                        : Icons.list_alt,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              suggestion.scanInfo.titleSuggested,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: Colors.grey),
                        ],
                      ),
                      Text(
                        relativeDate,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Delete button (Trailing)
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmationDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showEditTitleDialog(
    BuildContext context,
    WidgetRef ref,
    AiSuggestion suggestion,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: suggestion.scanInfo.titleSuggested);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.editTitle),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: l10n.enterNewTitle),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newTitle = controller.text.trim();
                  if (newTitle.isNotEmpty) {
                    try {
                      await ref
                          .read(scanRepositoryProvider)
                          .updateAiSuggestionTitle(widget.id, newTitle);
                      ref.invalidate(aiSuggestionProvider(widget.id));
                      ref.invalidate(historyProvider);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10n.errorLoadingDetails}: $e')),
                        );
                      }
                    }
                  }
                },
                 child: Text(l10n.save),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.areYouSureDelete),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(scanRepositoryProvider).deleteScan(widget.id);
                    ref.invalidate(historyProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.go('/history');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10n.errorLoadingDetails}: $e')),
                      );
                    }
                  }
                },
                 child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildQuantitativeAnalysis(
    List<IngredientDetected> ingredients,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context);
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
          if (ingredients.isEmpty)
            Text(
              l10n.noQuantitativeData,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            ...ingredients.map((ing) {
              final quantity = ing.quantity ?? 0;
              final unit = ing.unit?.replaceAll('unit_', '') ?? '';
              final name = ing.getName(locale.languageCode);
              final description = ing.getDescription(locale.languageCode);
              final progress = _getGaugePercentage(ing.technicalCode, quantity);
              final isExpanded = _expandedQuantitativeItems.contains(ing.technicalCode);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleQuantitativeExpansion(ing.technicalCode),
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
    List<IngredientDetected> ingredients,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
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
          if (ingredients.isEmpty)
            Text(
              l10n.noQuantitativeData, // Using quantitative as fallback or adding specific
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            ...ingredients.map((ing) {
              final name = ing.getName(locale.languageCode);
              final description = ing.getDescription(locale.languageCode);

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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  double _getGaugePercentage(String code, double value) {
    final c = code.toLowerCase();
    if (c.contains('milk')) return 0.8;
    if (c.contains('sugar')) return 0.2;
    if (c.contains('e120')) return 0.05;
    if (c.contains('salt') || c.contains('sodium')) return 0.15;
    return 0.1;
  }
}
