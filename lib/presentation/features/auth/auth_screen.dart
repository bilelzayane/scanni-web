import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logo.dart';
import '../../../core/providers/guest_session_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/localization/app_localizations.dart';
import 'auth_controller.dart';
import '../../../core/utils/url_helper.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  String _selectedLanguage = 'en';
  bool _isLanguageInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLanguageInitialized) {
      final currentLocale = ref.read(localeProvider);
      _selectedLanguage = currentLocale.languageCode;
      _isLanguageInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    clearAuthUrl();
  }

  final Map<String, String> _languageNames = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
    'ar_tn': 'العربية (تونس)',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = l10n.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Consumer(
          builder: (context, ref, child) {
            ref.listen<AuthState>(authControllerProvider, (previous, next) {
              if (next.error != null && next.error != previous?.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(next.error!),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (!next.isLoading && previous?.isLoading == true && next.error == null) {
                context.go('/');
              }
            });
            
            final authState = ref.watch(authControllerProvider);
            
            return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Premium Language Selector (Top-Middle) ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(child: _buildPremiumLanguageSelector()),
              ),
            ),
            const SizedBox(height: 20),
            // ── Logo Area (Centered in Grey Zone) ───────────
            Expanded(
              flex: 1,
              child: Center(
                child: const Logo(
                  size: LogoSize.lg,
                  layout: LogoLayout.vertical,
                ),
              ),
            ),
            // ── Smaller White Container ──────────────────────
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Welcome Header ───────────────────────────────
                            Text(
                              l10n.loginWelcome,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.foregroundColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.loginSlogan,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.mutedForegroundColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // ── Google Sign-In button ─────────────────────
                            Center(
                              child: OutlinedButton(
                                onPressed: authState.isLoading ? null : () {
                                  ref.read(authControllerProvider.notifier).signInWithGoogle();
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/google_icon.svg',
                                      height: 24,
                                      width: 24,
                                    ),
                                      const SizedBox(width: 12),
                                      if (authState.isLoading)
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      else
                                        Text(
                                          l10n.signInWithGoogle,
                                          style: const TextStyle(
                                            color: AppTheme.foregroundColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                    ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Continue as Guest TextButton ──────────────
                            Center(
                              child: InkWell(
                                onTap: () {
                                  // Set guest flag and navigate to Home
                                  ref
                                      .read(isGuestProvider.notifier)
                                      .setGuest(true);
                                  context.go('/');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    l10n.continueAsGuest,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // ── Privacy Policy Link ────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to privacy policy
                        },
                        child: Text(
                          l10n.privacyPolicy,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Partner Logos ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/logos/poly.svg', height: 35),
                        const SizedBox(width: 20),
                        SvgPicture.asset(
                          'assets/logos/horizon_impact.svg',
                          height: 35,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumLanguageSelector() {
    return GestureDetector(
      onTap: () => _showLanguageBottomSheet(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _languageNames[_selectedLanguage] ?? 'English',
            style: const TextStyle(
              color: AppTheme.primaryDarkColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.primaryDarkColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ..._languageNames.entries.map((entry) {
              return ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(
                    color: entry.key == _selectedLanguage
                        ? AppTheme.primaryDarkColor
                        : Colors.grey[700],
                    fontWeight: entry.key == _selectedLanguage
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: entry.key == _selectedLanguage
                    ? const Icon(Icons.check, color: AppTheme.primaryDarkColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = entry.key;
                  });
                  ref.read(localeProvider.notifier).setLocale(entry.key);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
