import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/guest_session_provider.dart';
import '../../../core/utils/url_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _currentLanguage = 'en';
  String _userName = 'Unknown User';
  List<Map<String, dynamic>> _pathologies = [];
  Set<String> _selectedPathologies = {};
  bool _isLoading = true;

  // Helper method to get specific icons for health conditions
  Widget _getHealthIcon(String technicalCode) {
    IconData iconData;
    Color iconColor = Colors.grey[600]!;

    switch (technicalCode.toLowerCase()) {
      case 'diabetic':
        iconData = Icons.water_drop;
        break;
      case 'hypertension':
        iconData = Icons.favorite;
        break;
      case 'celiac':
        iconData = Icons.no_food;
        break;
      case 'vegan_regime':
        iconData = Icons.eco;
        break;
      default:
        iconData = Icons.medical_information;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  bool get _isRTL => _currentLanguage == 'ar' || _currentLanguage == 'ar_tn';


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final db = Supabase.instance.client;
      print('DEBUG: Starting _loadUserData for user ${user.id}');

      // ── Step 1: Profile (needed to know langPref before fetching translations) ──
      final profileRaw =
          await db
                  .from('user_profiles')
                  .select('full_name, language_pref')
                  .eq('user_id', user.id)
                  .maybeSingle()
              as Map<String, dynamic>?;

      final langPref = profileRaw?['language_pref'] as String? ?? 'en';
      print('DEBUG: User language preference: $langPref');

      // ── Step 2: Fetch base tables + user selections in parallel ──
      final results = await Future.wait<dynamic>([
        db.from('pathologies').select('id, technical_code'), // [0]
        db
            .from('user_pathologies') // [1] - User selections
            .select('pathology_id')
            .eq('user_id', user.id),
      ]);

      final pathologies = (results[0] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final selectedPathRaw = (results[1] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      print('DEBUG: Pathologies count: ${pathologies.length}');
      print('DEBUG: Selected pathologies count: ${selectedPathRaw.length}');

      // ── Step 3: Fetch translations for pathologies ──
      final pathologyIds = pathologies.map((p) => p['id'] as String).toList();

      print('DEBUG: Pathology IDs to fetch translations for: $pathologyIds');

      // Fetch translations for both languages (preferred + en fallback) in one call each
      final langs = langPref == 'en' ? ['en'] : [langPref, 'en'];
      print('DEBUG: Language codes to fetch: $langs');

      final pathTranslations = pathologyIds.isEmpty
          ? <Map<String, dynamic>>[]
          : ((await db
                        .from('translations')
                        .select('parent_id, language_code, content')
                        .eq('parent_type', 'pathologies')
                        .inFilter('parent_id', pathologyIds)
                        .inFilter('language_code', langs))
                    as List<dynamic>)
                .cast<Map<String, dynamic>>();

      print('DEBUG: Pathology translations count: ${pathTranslations.length}');

      // ── Step 4: Build lookup Map<parentId, Map<langCode, content>> ──
      Map<String, Map<String, String>> buildLookup(
        List<Map<String, dynamic>> rows,
      ) {
        final map = <String, Map<String, String>>{};
        for (final row in rows) {
          final pid = row['parent_id'] as String;
          final lang = row['language_code'] as String;
          final text = row['content'] as String? ?? '';
          map.putIfAbsent(pid, () => {})[lang] = text;
        }
        return map;
      }

      final pathLookup = buildLookup(pathTranslations);

      // Helper: resolve best label with lang → en → technical_code fallback
      String resolveLabel(
        String id,
        String technicalCode,
        Map<String, Map<String, String>> lookup,
        String lang,
      ) {
        final byId = lookup[id];
        if (byId == null) {
          print(
            'DEBUG: No translation found for ID $id, using technical code: $technicalCode',
          );
          return technicalCode;
        }
        final result = byId[lang] ?? byId['en'] ?? technicalCode;
        print(
          'DEBUG: Resolved label for ID $id: $result (lang: $lang, byId: $byId)',
        );
        return result;
      }

      print('DEBUG: pathLookup: $pathLookup');

      // ── Step 5: Enrich each item with its resolved label ──
      final pathologiesWithLabel = pathologies.map((p) {
        final id = p['id'] as String;
        final code = p['technical_code'] as String;
        final label = resolveLabel(id, code, pathLookup, langPref);
        return <String, dynamic>{
          'id': id,
          'technical_code': code,
          'label': label,
        };
      }).toList();

      print(
        'DEBUG: Pathologies with label count: ${pathologiesWithLabel.length}',
      );
      print('DEBUG: Sample pathologies: $pathologiesWithLabel');

      // ── Step 6: Commit to state ──
      print('DEBUG: About to call setState, mounted=$mounted');
      if (mounted) {
        setState(() {
          if (profileRaw != null) {
            _userName = profileRaw['full_name'] as String? ?? 'Unknown User';
            _currentLanguage = langPref;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(localeProvider.notifier).setLocale(_currentLanguage);
            });
          }
          _pathologies = pathologiesWithLabel;
          _selectedPathologies = selectedPathRaw
              .map<String>((e) => e['pathology_id'] as String)
              .toSet();
          _isLoading = false;
          print(
            'DEBUG: setState completed - _pathologies length: ${_pathologies.length}',
          );
          print(
            'DEBUG: setState completed - _selectedPathologies: $_selectedPathologies',
          );
          print('DEBUG: setState completed - _isLoading: $_isLoading');
        });
      } else {
        print('DEBUG: Widget not mounted, skipping setState');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLanguage(String languageCode) async {
    setState(() {
      _currentLanguage = languageCode;
    });
    ref.read(localeProvider.notifier).setLocale(languageCode);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('user_profiles').upsert({
          'user_id': user.id,
          'language_pref': languageCode,
        });
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update language')));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onPathologyToggled(String pathologyId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final isSelected = _selectedPathologies.contains(pathologyId);
    setState(() {
      if (isSelected) {
        _selectedPathologies.remove(pathologyId);
      } else {
        _selectedPathologies.add(pathologyId);
      }
    });

    // Haptic feedback for better UX
    // Note: HapticFeedback is not available on all platforms, so we use try-catch
    try {
      // This would require importing 'package:flutter/services.dart'
      // HapticFeedback.lightImpact();
    } catch (e) {
      // Ignore haptic feedback errors
    }

    try {
      if (isSelected) {
        await Supabase.instance.client.from('user_pathologies').delete().match({
          'user_id': user.id,
          'pathology_id': pathologyId,
        });
      } else {
        await Supabase.instance.client.from('user_pathologies').insert({
          'user_id': user.id,
          'pathology_id': pathologyId,
        });
      }
    } catch (e) {
      // Revert UI on failure
      setState(() {
        if (isSelected) {
          _selectedPathologies.add(pathologyId);
        } else {
          _selectedPathologies.remove(pathologyId);
        }
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pathologies: $e')),
        );
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      clearAuthUrl();
      if (mounted) context.go('/auth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context);
        return Directionality(
          textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag indicator bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Language options
                _buildLanguageOption('en', l10n.english),
                _buildLanguageOption('fr', l10n.french),
                _buildLanguageOption('ar', l10n.arabic),
                _buildLanguageOption(
                  'ar_tn',
                  l10n.tunisianArabic,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName) {
    final isSelected = _currentLanguage == languageCode;
    return ListTile(
      title: Text(
        languageName,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () => _updateLanguage(languageCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    print('DEBUG: build() called - _isLoading: $_isLoading');
    print(
      'DEBUG: build() called - _pathologies length: ${_pathologies.length}',
    );
    print('DEBUG: build() called - _pathologies: $_pathologies');

    // Guest mode: show a login prompt instead of crashing
    final isGuest = ref.watch(isGuestProvider).value ?? false;
    if (isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.guestAccountTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.guestAccountSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(isGuestProvider.notifier).setGuest(false);
                      context.go('/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.guestAccountButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              l10n.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.account,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: AppTheme.primaryColor),
              onPressed: () => _showLanguageSelector(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    // Avatar and name
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Alert Preferences section
                    if (_pathologies.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.alertPreferences,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pathologies card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _pathologies.asMap().entries.map((entry) {
                            final index = entry.key;
                            final pathology = entry.value;
                            final pathologyId = pathology['id'] as String;
                            final isSelected = _selectedPathologies.contains(
                              pathologyId,
                            );
                            // Use the pre-resolved label from the translations join
                            final pathologyName =
                                (pathology['label'] as String? ?? '').isNotEmpty
                                ? pathology['label'] as String
                                : pathology['technical_code'] as String? ??
                                      pathologyId;
                            return Column(
                              children: [
                                // Add divider between items (but not after the last one)
                                if (index < _pathologies.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: Colors.grey,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      // Icon based on health condition
                                      _getHealthIcon(
                                        pathology['technical_code'] as String,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          pathologyName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Switch(
                                        value: isSelected,
                                        activeColor: AppTheme.primaryColor,
                                        onChanged: (_) =>
                                            _onPathologyToggled(pathologyId),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Logout button at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    label: Text(
                      l10n.logOut,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.5),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
