import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';

class LanguageSelector extends ConsumerStatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  ConsumerState<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends ConsumerState<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
      onSelected: (String language) async {
        if (language != widget.currentLanguage) {
          // Update user preference in database
          final userId = ref.read(profileRepositoryProvider).getCurrentUserId();
          if (userId != null) {
            await ref
                .read(profileRepositoryProvider)
                .updateUserLanguage(userId, language);
          }
          widget.onLanguageChanged(language);
        }
      },
      itemBuilder: (BuildContext context) => [
        _buildMenuItem(context, 'English', 'en', '🇬🇧'),
        _buildMenuItem(context, 'Français', 'fr', '🇫🇷'),
        _buildMenuItem(context, 'العربية', 'ar', '🇸🇦'),
        _buildMenuItem(context, 'العربية (تونس)', 'ar_tn', '🇹🇳'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    String label,
    String value,
    String flag,
  ) {
    final isSelected = widget.currentLanguage == value;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check, color: colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}

/// Helper to check if a language code requires RTL
bool isRTL(String languageCode) {
  return languageCode == 'ar' || languageCode == 'ar_tn';
}

/// Get localized text for common UI elements
Map<String, Map<String, String>> get commonTranslations => {
  'account': {'en': 'Account', 'fr': 'Compte', 'ar': 'حساب', 'ar_tn': 'حساب'},
  'my_activity': {
    'en': 'My Activity',
    'fr': 'Mon Activité',
    'ar': 'نشاطي',
    'ar_tn': 'نشاطي',
  },
  'contributions': {
    'en': 'Contributions',
    'fr': 'Contributions',
    'ar': 'المساهمات',
    'ar_tn': 'المساهمات',
  },
  'health_awareness': {
    'en': 'Health Awareness',
    'fr': 'Sensibilisation Santé',
    'ar': 'الوعي الصحي',
    'ar_tn': 'الوعي الصحي',
  },
  'pathologies_diet': {
    'en': 'Pathologies & Diet',
    'fr': 'Pathologies & Régime',
    'ar': 'الأمراض والحمية',
    'ar_tn': 'الأمراض والحمية',
  },
  'log_out': {
    'en': 'Log out',
    'fr': 'Déconnexion',
    'ar': 'تسجيل الخروج',
    'ar_tn': 'تسجيل الخروج',
  },
  'health_advocate': {
    'en': 'Health Advocate',
    'fr': 'Défenseur de la Santé',
    'ar': 'مدافع الصحة',
    'ar_tn': 'مدافع الصحة',
  },
};

String getTranslation(String key, String languageCode) {
  return commonTranslations[key]?[languageCode] ??
      commonTranslations[key]?['en'] ??
      key;
}
