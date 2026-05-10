import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/logo.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../../domain/models/history.dart';
import '../../../domain/models/test_type.dart';
import '../../../core/providers/guest_session_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/scan_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import 'history_controller.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_svg/flutter_svg.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;
  List<History> _allScans = [];
  int _currentOffset = 0;
  static const int _pageSize = 10;
  bool _hasMore = true;
  Map<String, Map<String, String>> _historyTranslations = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data every time the screen is shown to avoid stale 0-result data
    _loadInitial();
  }

  void _loadInitial() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      // Guest mode: show empty history
      setState(() {
        _allScans = [];
        _currentOffset = 0;
        _hasMore = false;
      });
      return;
    }

    final repo = ref.read(scanRepositoryProvider);
    try {
      final scans = await repo.getFullUserHistory(
        user.id,
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _allScans = scans;
        _currentOffset = scans.length;
        _hasMore = scans.length >= _pageSize;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() {
        _isLoadingMore = false;
      });
      return;
    }

    final repo = ref.read(scanRepositoryProvider);
    try {
      final newScans = await repo.getFullUserHistory(
        user.id,
        limit: _pageSize,
        offset: _currentOffset,
      );

      setState(() {
        _allScans.addAll(newScans);
        _currentOffset = _currentOffset + newScans.length;
        _hasMore = newScans.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    // TODO: Reset pagination and filter results
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final isGuest = user == null;
    final l10n = AppLocalizations.of(context);
    final isRTL = l10n.isRTL;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(historyProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    // Style de padding réutilisable pour le bas (pour la Navbar flottante)
    const double bottomPadding = 110.0;


    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: historyAsync.when(
            data: (scans) {
              if (scans.isEmpty) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          MediaQuery.of(context).padding.top + 16,
                          20,
                          8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context),
                            if (isGuest) ...[
                              const SizedBox(height: 12),
                              _buildSyncBanner(context),
                            ],
                            const SizedBox(height: 16),
                            _buildSearchBar(context),
                            const SizedBox(height: 16),
                            _buildPageHeader(context),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(child: _buildEmptyState(context)),
                  ],
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 16,
                        20,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          if (isGuest) ...[
                            const SizedBox(height: 12),
                            _buildSyncBanner(context),
                          ],
                          const SizedBox(height: 16),
                          _buildSearchBar(context),
                          const SizedBox(height: 16),
                          _buildPageHeader(context),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                      top: 16,
                      bottom: bottomPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final displayScans = isGuest ? scans.take(3).toList() : scans;
                        
                        if (index < displayScans.length) {
                          return _ScanListItem(
                            scan: displayScans[index],
                            translations: _historyTranslations[displayScans[index].id],
                          );
                        }
                        
                        if (isGuest && index == displayScans.length) {
                          return _buildGuestLimitPrompt(context);
                        }
                        
                        return const SizedBox();
                      }, childCount: isGuest ? (scans.length > 3 ? 4 : scans.length) : scans.length),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.center_focus_strong,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noScanHistory,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              // Wait 100ms to avoid provider build exception
              Future.delayed(const Duration(milliseconds: 100), () {
                context.go('/scan');
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Text(
                l10n.homeStartScanning,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSyncBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryDarkColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Sign in to sync your scans across devices',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/auth'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestLimitPrompt(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock_outlined, color: AppTheme.primaryDarkColor, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an account to save unlimited scans and access them from any device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDarkColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Sign Up to See Full History'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primaryDarkColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.guestHistoryTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.guestHistorySubtitle,
                style: const TextStyle(
                  color: AppTheme.mutedForegroundColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(isGuestProvider.notifier).setGuest(false);
                  context.go('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDarkColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.guestHistoryButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Logo(size: LogoSize.sm, layout: LogoLayout.horizontal),
        GestureDetector(
          onTap: () => context.push('/account'),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(
              Icons.account_circle,
              size: 28,
              color: AppTheme.primaryDarkColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.searchHistoryHint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historySubtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.historyTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ScanListItem extends StatelessWidget {
  final History scan;
  final Map<String, String>? translations;

  const _ScanListItem({required this.scan, this.translations});

  String _getRelativeDate(String dateString, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);
    final locale = Localizations.localeOf(context);

    if (difference.inDays == 0) {
      return l10n.relativeToday;
    } else if (difference.inDays == 1) {
      return l10n.relativeYesterday;
    } else {
      // Format date as yMMMd with locale (e.g., "May 9, 2026")
      return intl.DateFormat.yMMMd(locale.toString()).format(date);
    }
  }

  Widget _buildTitle(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    // Prefer scan.name (from ai_suggestions.scan_info.title_suggested)
    final name = (scan.name != null && scan.name!.isNotEmpty) 
        ? scan.name 
        : translations?['${lang}_name'];

    if (name != null && name.isNotEmpty && name != 'Unknown') {
      return Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return const Text(
      'Unknown',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppTheme.mutedForegroundColor,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  IconData _getIcon() {
    // Use uniform analytics icon as requested; do not use image_url
    return Icons.analytics;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/result/${scan.id}'),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          textDirection: Directionality.of(context),
          children: [
            // Dynamic icon based on test type
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  const SizedBox(height: 4),
                  Text(
                    _getRelativeDate(scan.scanDate, context),
                    style: const TextStyle(
                      color: AppTheme.mutedForegroundColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              (Localizations.localeOf(context).languageCode == 'ar' ||
                      Localizations.localeOf(context).languageCode == 'ar_tn')
                  ? Icons.arrow_back_ios
                  : Icons.arrow_forward_ios,
              size: 18,
              color: AppTheme.mutedForegroundColor,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}
