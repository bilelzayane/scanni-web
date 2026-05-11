import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/presentation/core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _isVisible = false;
  bool _isIOS = false;
  bool _isAndroid = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkInstallation();
    }
  }

  void _checkInstallation() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    _isIOS = userAgent.contains('iphone') || userAgent.contains('ipad');
    _isAndroid = userAgent.contains('android');

    // Only show on mobile
    if (!_isIOS && !_isAndroid) return;

    // Check if already in standalone mode (installed)
    final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches ||
                        (html.window.navigator as dynamic).standalone == true;

    if (!isStandalone) {
      // Show after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isVisible = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Positioned(
      bottom: 100, // Above bottom nav
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset('assets/logos/icon_app.svg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.pwaInstallTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isIOS ? l10n.pwaInstallActionIos : l10n.pwaInstallActionAndroid,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _isVisible = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
