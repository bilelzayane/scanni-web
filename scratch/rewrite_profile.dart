import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/locale_provider.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _currentLanguage = 'en';
  String _userName = 'Unknown User';
  int _scansCount = 0;
  List<Map<String, dynamic>> _pathologies = [];
  Set<String> _selectedPathologies = {};
  bool _isLoading = true;

  Map<String, Map<String, String>> get _translations => {
    'account': {'en': 'Account', 'fr': 'Compte', 'ar': 'حساب', 'ar_tn': 'حساب'},
    'personal_health_profile': {
      'en': 'Personal Health Profile',
      'fr': 'Profil de Santé Personnel',
      'ar': 'الملف الصحي الشخصي',
      'ar_tn': 'الملف الصحي الشخصي',
    },
    'total_scans': {
      'en': 'Total Scans',
      'fr': 'Scans Totaux',
      'ar': 'إجمالي عمليات المسح',
      'ar_tn': 'سكانارات الكل',
    },
    'log_out': {
      'en': 'Log out',
      'fr': 'Déconnexion',
      'ar': 'تسجيل الخروج',
      'ar_tn': 'تسجيل الخروج',
    },
    'celiac': {
      'en': 'Celiac',
      'fr': 'Cœliaque',
      'ar': 'الداء البطني',
      'ar_tn': 'الداء البطني',
    },
    'diabetic': {
      'en': 'Diabetic',
      'fr': 'Diabétique',
      'ar': 'سكري',
      'ar_tn': 'سكري',
    },
    'hypertension': {
      'en': 'Hypertension',
      'fr': 'Hypertension',
      'ar': 'ارتفاع ضغط الدم',
      'ar_tn': 'ارتفاع ضغط الدم',
    },
    'diabetes_t2': {
      'en': 'Diabetes Type 2',
      'fr': 'Diabète Type 2',
      'ar': 'السكري صنف 2',
      'ar_tn': 'السكري صنف 2',
    },
    'languages': {
      'en': 'Languages',
      'fr': 'Langues',
      'ar': 'اللغات',
      'ar_tn': 'اللغات',
    },
    'english': {
      'en': 'English',
      'fr': 'Anglais',
      'ar': 'الإنجليزية',
      'ar_tn': 'English',
    },
    'french': {
      'en': 'French',
      'fr': 'Français',
      'ar': 'الفرنسية',
      'ar_tn': 'Français',
    },
    'arabic': {
      'en': 'Arabic',
      'fr': 'Arabe',
      'ar': 'العربية',
      'ar_tn': 'العربية',
    },
    'tunisian_arabic': {
      'en': 'Tunisian Arabic',
      'fr': 'Arabe Tunisien',
      'ar': 'العربية التونسية',
      'ar_tn': 'العربية التونسية',
    },
  };

  bool get _isRTL => _currentLanguage == 'ar' || _currentLanguage == 'ar_tn';

  String _getTranslation(String key) {
    return _translations[key]?[_currentLanguage] ??
        _translations[key]?['en'] ??
        key;
  }

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
      final futures = await Future.wait<dynamic>([
        Supabase.instance.client.from('user_profiles').select('full_name, language_pref').eq('user_id', user.id).maybeSingle(),
        Supabase.instance.client.from('history').select('id').eq('user_id', user.id).count(CountOption.exact),
        Supabase.instance.client.from('pathologies').select('id, technical_code'),
        Supabase.instance.client.from('user_watchlist').select('pathology_id').eq('user_id', user.id),
      ]);

      final profile = futures[0] as Map<String, dynamic>?;
      final countResponse = futures[1] as PostgrestResponse; // wait, select().count() returns a PostgrestResponse with count
      final pData = futures[2] as List<dynamic>;
      final wData = futures[3] as List<dynamic>;

      if (mounted) {
        setState(() {
          if (profile != null) {
            _userName = profile['full_name'] ?? 'Unknown User';
            _currentLanguage = profile['language_pref'] ?? 'en';
            // Sync Riverpod locale state without notifying prematurely
            WidgetsBinding.instance.addPostFrameCallback((_) {
               ref.read(localeProvider.notifier).setLocale(_currentLanguage);
            });
          }
          _scansCount = countResponse.count ?? 0;
          _pathologies = List<Map<String, dynamic>>.from(pData);
          _selectedPathologies = wData.map<String>((e) => e['pathology_id'] as String).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update language')));
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

    try {
      if (isSelected) {
        await Supabase.instance.client.from('user_watchlist').delete().match({
          'user_id': user.id,
          'pathology_id': pathologyId,
        });
      } else {
        await Supabase.instance.client.from('user_watchlist').insert({
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update watchlist')));
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/auth');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
                _buildLanguageOption('en', _getTranslation('english')),
                _buildLanguageOption('fr', _getTranslation('french')),
                _buildLanguageOption('ar', _getTranslation('arabic')),
                _buildLanguageOption(
                  'ar_tn',
                  _getTranslation('tunisian_arabic'),
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
              _isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _getTranslation('account'),
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
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
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
                    const SizedBox(height: 8),
                    Text(
                      '${_getTranslation('total_scans')}: $_scansCount',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Personal Health Profile section
                    if (_pathologies.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getTranslation('personal_health_profile'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Health profile card
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
                            final technicalCode = pathology['technical_code'] as String;
                            final isSelected = _selectedPathologies.contains(pathologyId);
                            final pathologyName = _getTranslation(technicalCode);

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _onPathologyToggled(pathologyId),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: _isRTL
                                          ? [
                                              Switch(
                                                value: isSelected,
                                                onChanged: (_) => _onPathologyToggled(pathologyId),
                                                activeColor: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  pathologyName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ]
                                          : [
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
                                                onChanged: (_) => _onPathologyToggled(pathologyId),
                                                activeColor: AppTheme.primaryColor,
                                              ),
                                            ],
                                    ),
                                  ),
                                ),
                                if (index < _pathologies.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: Colors.grey,
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
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: _logout,
                    child: Text(
                      _getTranslation('log_out'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
