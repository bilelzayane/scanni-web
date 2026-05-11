import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logo.dart';
import '../../../domain/models/history.dart';
import '../../../domain/models/test_type.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/scan_repository.dart';
import '../history/history_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/widgets/pwa_install_banner.dart';
import '../../../core/providers/guest_session_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  Widget _buildSyncBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined,
              color: AppTheme.primaryDarkColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.guestModeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  l10n.guestModeSyncDesc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(isGuestProvider.notifier).setGuest(false);
              context.go('/auth');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.signIn,
              style: const TextStyle(
                color: AppTheme.primaryDarkColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = l10n.isRTL;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    final isGuest = ref.watch(isGuestProvider).value ?? false;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(
              start: 20,
              end: 20,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                if (isGuest) ...[
                  const SizedBox(height: 12),
                  _buildSyncBanner(context),
                ],
                const SizedBox(height: 24),
                _buildSearchBar(context),
                const PwaInstallBanner(),
                const SizedBox(height: 24),
                _buildHeroCard(context),
                const SizedBox(height: 24),
                _buildRecentScansSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScansSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (allScans) {
        final scans = allScans.take(3).toList();
        final isEmpty = scans.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.yourScans,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (!isEmpty)
                  GestureDetector(
                    onTap: () => context.push('/history'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.viewAll,
                          style: const TextStyle(
                            color: AppTheme.primaryDarkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          (Localizations.localeOf(context).languageCode == 'ar' ||
                                  Localizations.localeOf(context).languageCode == 'ar_tn')
                              ? Icons.arrow_back_ios
                              : Icons.arrow_forward_ios,
                          size: 14,
                          color: AppTheme.primaryDarkColor,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noScanHistory,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noScanHistorySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: scans.map((scan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentScanTile(
                      scan: scan,
                      translations: null, // Initial load doesn't need detailed translations
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error loading recent scans: $e')),
    );
  }
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
          decoration: const BoxDecoration(
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
      decoration: InputDecoration(
        hintText: l10n.homeSearchHint,
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

Widget _buildHeroCard(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: AppTheme.primaryGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppTheme.softShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white.withValues(alpha: 0.9),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.homeIngredientInfo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.homeScanToView,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeViewComposition,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.go('/scan'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeStartScanning,
                  style: const TextStyle(
                    color: AppTheme.primaryDarkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  (Localizations.localeOf(context).languageCode == 'ar' ||
                          Localizations.localeOf(context).languageCode ==
                              'ar_tn')
                      ? Icons.arrow_back_ios
                      : Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.primaryDarkColor,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecentScanTile extends StatelessWidget {
  final History scan;
  final Map<String, String>? translations;

  const _RecentScanTile({required this.scan, this.translations});

  String _getRelativeTime(String dateString, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.relativeToday;
    } else if (difference.inDays == 1) {
      return l10n.relativeYesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  IconData _getIcon() {
    return scan.testType == TestType.dishScan
        ? Icons.local_dining
        : Icons.list_alt;
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
          fontSize: 14,
          color: AppTheme.foregroundColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return const Text(
      'Unknown',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppTheme.mutedForegroundColor,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _getIcon();

    return GestureDetector(
      onTap: () => context.push('/result/${scan.id}?fromHome=true'),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          textDirection: Directionality.of(context),
          children: [
            // Image/Icon container (48x48)
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  const SizedBox(height: 2),
                  Text(
                    _getRelativeTime(scan.scanDate, context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              (Localizations.localeOf(context).languageCode == 'ar' ||
                      Localizations.localeOf(context).languageCode == 'ar_tn')
                  ? Icons.arrow_back_ios
                  : Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.mutedForegroundColor,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}
