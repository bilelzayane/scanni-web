import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _isVisible = false;
  bool _isIos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInstallationStatus();
    });
  }

  void _checkInstallationStatus() {
    // Check if already in standalone mode
    final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches ||
        (html.window.navigator.asTest?['standalone'] ?? false);

    if (isStandalone) {
      setState(() => _isVisible = false);
      return;
    }

    // Check user agent for iOS
    final ua = html.window.navigator.userAgent.toLowerCase();
    _isIos = ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');

    // Only show on mobile devices
    final isMobile = ua.contains('mobile') || ua.contains('android') || _isIos;

    if (isMobile) {
      setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isRTL = l10n.isRTL;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.install_mobile, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pwaInstallTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.pwaInstallSubtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _isVisible = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isIos) 
                  const Icon(Icons.ios_share, color: Colors.white, size: 18)
                else
                  const Icon(Icons.add_to_home_screen, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _isIos ? l10n.pwaInstallActionIos : l10n.pwaInstallActionAndroid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on html.Navigator {
  dynamic get asTest => this;
}
