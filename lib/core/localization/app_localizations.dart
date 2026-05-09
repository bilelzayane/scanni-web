import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'guestHistoryTitle': 'Sign in to see history',
      'guestHistorySubtitle':
          'Your scan history is only available for registered users.',
      'guestHistoryButton': 'Go to Login',
      'guestAccountTitle': 'Guest Mode',
      'guestAccountSubtitle':
          'Sign in to sync your history and customize your profile.',
      'guestAccountButton': 'Go to Login',
      'loginSlogan': 'Scan, Understand, Protect yourself',
      'signInWithGoogle': 'Sign in with Google',
      'continueAsGuest': 'Continue as Guest',
      'privacyPolicy': 'Privacy Policy',
      'historyTitle': 'Your scans',
      'historySubtitle': 'View your scan history',
      'searchHistoryHint': 'Search in your history...',
      'noScanHistory': 'No scan history available',
      'homeSearchHint': 'Search for an ingredient (ex: E120)...',
      'homeIngredientInfo': 'Ingredient information',
      'homeScanToView': 'Scan to view ingredients',
      'homeViewComposition': 'View detailed ingredient composition',
      'homeStartScanning': 'Start scanning',
      'yourScans': 'Your scans',
      'loginWelcome': 'Welcome to Scanni',
      'relativeToday': 'Today',
      'relativeYesterday': 'Yesterday',
      'viewAll': 'View all',
      'endOfHistory': 'No more history',
      'aiDisclaimer': 'AI Generated - Awaiting scientific validation',
      'newScanButton': 'Launch a new scan',
      'account': 'Account',
      'alert_preferences': 'Alert Preferences',
      'log_out': 'Log out',
      'celiac': 'Celiac',
      'diabetic': 'Diabetic',
      'hypertension': 'Hypertension',
      'diabetes_t2': 'Diabetes Type 2',
      'languages': 'Languages',
      'english': 'English',
      'french': 'French',
      'arabic': 'Arabic',
      'tunisian_arabic': 'Tunisian Arabic',
      'my_activity': 'My Activity',
      'contributions': 'Contributions',
      'health_awareness': 'Health Awareness',
      'pathologies_diet': 'Pathologies & Diet',
      'health_advocate': 'Health Advocate',
      'editTitle': 'Edit Title',
      'confirmDelete': 'Confirm Delete',
      'areYouSureDelete': 'Are you sure you want to delete this scan?',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'noQuantitativeData': 'No quantitative data available',
      'technicalComposition': 'Technical Composition',
      'quantitativeAnalysis': 'Quantitative Analysis',
      'scanFailed': 'Scan failed',
      'enterNewTitle': 'Enter new title',
      'analysisImpossible': 'Analysis Impossible',
      'analysisImpossibleDesc': 'We could not identify the ingredients. This may be due to a blurry image or an unrecognized product.',
      'retry': 'Retry',
    },
    'fr': {
      'guestHistoryTitle': "Connectez-vous pour voir l'historique",
      'guestHistorySubtitle':
          'Votre historique de scan est disponible uniquement pour les utilisateurs inscrits.',
      'guestHistoryButton': 'Se connecter',
      'guestAccountTitle': 'Mode Invité',
      'guestAccountSubtitle':
          'Connectez-vous pour synchroniser votre historique et personnaliser votre profil.',
      'guestAccountButton': 'Se connecter',
      'loginSlogan': 'Scanner, Comprendre, Se protéger',
      'signInWithGoogle': 'Se connecter avec Google',
      'continueAsGuest': 'Continuer en tant qu\'invité',
      'privacyPolicy': 'Politique de confidentialité',
      'historyTitle': 'Vos scans',
      'historySubtitle': 'Consultez votre historique de scans',
      'searchHistoryHint': 'Chercher dans l\'historique...',
      'noScanHistory': 'Aucun historique de scan',
      'homeSearchHint': 'Chercher un ingrédient (ex: E120)...',
      'homeIngredientInfo': 'Infos ingrédients',
      'homeScanToView': 'Scanner pour voir les ingrédients',
      'homeViewComposition': 'Voir la composition détaillée des ingrédients.',
      'homeStartScanning': 'Lancer le scan',
      'yourScans': 'Vos scans',
      'loginWelcome': 'Bienvenue sur Scanni',
      'relativeToday': "Aujourd'hui",
      'relativeYesterday': 'Hier',
      'viewAll': 'Voir tout',
      'endOfHistory': 'Fin de l\'historique',
      'aiDisclaimer': 'Généré par IA - En attente de validation scientifique',
      'newScanButton': 'Lancer un nouveau scan',
      'account': 'Compte',
      'alert_preferences': 'Mes Préférences d\'Alerte',
      'log_out': 'Déconnexion',
      'celiac': 'Cœliaque',
      'diabetic': 'Diabétique',
      'hypertension': 'Hypertension',
      'diabetes_t2': 'Diabète Type 2',
      'languages': 'Langues',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'Arabe',
      'tunisian_arabic': 'Arabe Tunisien',
      'my_activity': 'Mon Activité',
      'contributions': 'Contributions',
      'health_awareness': 'Sensibilisation Santé',
      'pathologies_diet': 'Pathologies & Régime',
      'health_advocate': 'Défenseur de la Santé',
      'editTitle': 'Modifier le titre',
      'confirmDelete': 'Confirmer la suppression',
      'areYouSureDelete': 'Êtes-vous sûr de vouloir supprimer ce scan ?',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'noQuantitativeData': 'Aucune donnée quantitative disponible',
      'technicalComposition': 'Composition technique',
      'quantitativeAnalysis': 'Analyse quantitative',
      'scanFailed': 'Le scan a échoué',
      'enterNewTitle': 'Entrez un nouveau titre',
      'analysisImpossible': 'Analyse Impossible',
      'analysisImpossibleDesc': "Nous n'avons pas pu identifier les ingrédients. Cela peut être dû à une image floue ou un produit non reconnu.",
      'retry': 'Réessayer',
    },
    'ar': {
      'guestHistoryTitle': 'تسجيل الدخول لرؤية السجل',
      'guestHistorySubtitle':
          'سجل المسح الخاص بك متاح فقط للمستخدمين المسجلين.',
      'guestHistoryButton': 'الذهاب إلى تسجيل الدخول',
      'guestAccountTitle': 'وضع الزائر',
      'guestAccountSubtitle': 'سجل الدخول لمزامنة سجلك وتخصيص ملفك الشخصي.',
      'guestAccountButton': 'الذهاب إلى تسجيل الدخول',
      'loginSlogan': 'افحص، افهم، احمِ نفسك',
      'signInWithGoogle': 'تسجيل الدخول بـ Google',
      'continueAsGuest': 'المتابعة كزائر',
      'privacyPolicy': 'سياسة الخصوصية',
      'historyTitle': 'مسحاتك',
      'historySubtitle': 'عرض سجل المسح الخاص بك',
      'searchHistoryHint': 'ابحث في سجلك...',
      'noScanHistory': 'لا يوجد سجل مسح',
      'homeSearchHint': 'ابحث عن مكون (مثال: E120)...',
      'homeIngredientInfo': 'معلومات المكونات',
      'homeScanToView': 'اسحب لرؤية المكونات',
      'homeViewComposition': 'عرض تركيبة المكونات بالتفصيل.',
      'homeStartScanning': 'ابدأ المسح',
      'yourScans': 'مسحاتك',
      'loginWelcome': 'مرحباً بكم في Scanni',
      'relativeToday': 'اليوم',
      'relativeYesterday': 'أمس',
      'viewAll': 'عرض الكل',
      'endOfHistory': 'نهاية السجل',
      'aiDisclaimer':
          'تم إنشاؤه بواسطة الذكاء الاصطناعي - في انتظار التحقق العلمي',
      'newScanButton': 'إطلاق مسح جديد',
      'account': 'حساب',
      'alert_preferences': 'تفضيلات التنبيهات',
      'log_out': 'تسجيل الخروج',
      'celiac': 'الداء البطني',
      'diabetic': 'سكري',
      'hypertension': 'ارتفاع ضغط الدم',
      'diabetes_t2': 'السكري صنف 2',
      'languages': 'اللغات',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
      'tunisian_arabic': 'العربية التونسية',
      'my_activity': 'نشاطي',
      'contributions': 'المساهمات',
      'health_awareness': 'الوعي الصحي',
      'pathologies_diet': 'الأمراض والحمية',
      'health_advocate': 'مدافع الصحة',
      'editTitle': 'تعديل العنوان',
      'confirmDelete': 'تأكيد الحذف',
      'areYouSureDelete': 'هل أنت متأكد أنك تريد حذف هذا المسح؟',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'noQuantitativeData': 'لا توجد بيانات كمية متاحة',
      'technicalComposition': 'التركيبة التقنية',
      'quantitativeAnalysis': 'التحليل الكمي',
      'scanFailed': 'فشل المسح',
      'enterNewTitle': 'أدخل عنواناً جديداً',
      'analysisImpossible': 'التحليل مستحيل',
      'analysisImpossibleDesc': 'لم نتمكن من تحديد المكونات. قد يكون ذلك بسبب صورة غير واضحة أو منتج غير معروف.',
      'retry': 'إعادة المحاولة',
    },
    'ar_tn': {
      'guestHistoryTitle': 'ادخل باش تشوف السجل متاعك',
      'guestHistorySubtitle': 'السجل متاعك ما يظهر كان كيف تبدأ مسجل عندنا.',
      'guestHistoryButton': 'امشي للـ Connexion',
      'guestAccountTitle': 'وضع الزائر (Guest)',
      'guestAccountSubtitle':
          'ادخل باش تسجل التاريخ متاعك وتعدل البروفيل متاعك.',
      'guestAccountButton': 'امشي للـ Connexion',
      'loginSlogan': 'اسكاني، افهم، واحمِي روحك',
      'signInWithGoogle': 'ادخل بـ Google',
      'continueAsGuest': 'كمل كـ Guest',
      'privacyPolicy': 'سياسة الخصوصية',
      'historyTitle': 'المسحات متاعك',
      'historySubtitle': 'شوف السجل متاعك',
      'searchHistoryHint': 'لوّج في الـ historique متاعك...',
      'noScanHistory': 'ما ثمة حتى سكان قديم',
      'homeSearchHint': 'لوّج على composant (مثال E120)...',
      'homeIngredientInfo': 'Info mta3 ingrédients',
      'homeScanToView': 'اسكاني باش تشوف المكونات',
      'homeViewComposition': 'شوف الـ composition détaillée متاع المكونات.',
      'homeStartScanning': 'ابدا اسكاني',
      'yourScans': 'المسحات متاعك',
      'loginWelcome': 'مرحبا بيك في Scanni',
      'relativeToday': 'اليوم',
      'relativeYesterday': 'البارح',
      'viewAll': 'شوف الكل',
      'endOfHistory': 'وفى الـ historique',
      'aiDisclaimer': 'تم إنشاؤه بواسطة الذكاء الاصطناعي - في انتظار التحقق العلمي',
      'newScanButton': 'ابدأ سكان جديد',
      'account': 'حساب',
      'alert_preferences': 'تفضيلات التنبيهات',
      'log_out': 'تسجيل الخروج',
      'celiac': 'الداء البطني',
      'diabetic': 'سكري',
      'hypertension': 'ارتفاع ضغط الدم',
      'diabetes_t2': 'السكري صنف 2',
      'languages': 'اللغات',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'tunisian_arabic': 'العربية التونسية',
      'my_activity': 'نشاطي',
      'contributions': 'المساهمات',
      'health_awareness': 'الوعي الصحي',
      'pathologies_diet': 'الأمراض والحمية',
      'health_advocate': 'مدافع الصحة',
      'editTitle': 'بدل العنوان',
      'confirmDelete': 'ثبت في الحذف',
      'areYouSureDelete': 'تحب بالرسمي تفسخ السكان هذا؟',
      'cancel': 'أبطل',
      'save': 'سجل',
      'delete': 'فسخ',
      'noQuantitativeData': 'ما ثماش بيانات كمية',
      'technicalComposition': 'التركيبة التقنية',
      'quantitativeAnalysis': 'التحليل الكمي',
      'scanFailed': 'السكان ما خطفش',
      'enterNewTitle': 'اكتب عنوان جديد',
      'analysisImpossible': 'تحليل مستحيل',
      'analysisImpossibleDesc': 'ما نجمناش نعرفوا المكونات. ينجم يكون من تصويرة موش واضحة، وإلا المنتج موش معروف.',
      'retry': 'عاود مرة أخرى',
    },
  };

  String get guestHistoryTitle =>
      _localizedValues[locale.languageCode]?['guestHistoryTitle'] ??
      _localizedValues['en']!['guestHistoryTitle']!;
  String get guestHistorySubtitle =>
      _localizedValues[locale.languageCode]?['guestHistorySubtitle'] ??
      _localizedValues['en']!['guestHistorySubtitle']!;
  String get guestHistoryButton =>
      _localizedValues[locale.languageCode]?['guestHistoryButton'] ??
      _localizedValues['en']!['guestHistoryButton']!;
  String get guestAccountTitle =>
      _localizedValues[locale.languageCode]?['guestAccountTitle'] ??
      _localizedValues['en']!['guestAccountTitle']!;
  String get guestAccountSubtitle =>
      _localizedValues[locale.languageCode]?['guestAccountSubtitle'] ??
      _localizedValues['en']!['guestAccountSubtitle']!;
  String get guestAccountButton =>
      _localizedValues[locale.languageCode]?['guestAccountButton'] ??
      _localizedValues['en']!['guestAccountButton']!;
  String get loginSlogan =>
      _localizedValues[locale.languageCode]?['loginSlogan'] ??
      _localizedValues['en']!['loginSlogan']!;
  String get signInWithGoogle =>
      _localizedValues[locale.languageCode]?['signInWithGoogle'] ??
      _localizedValues['en']!['signInWithGoogle']!;
  String get continueAsGuest =>
      _localizedValues[locale.languageCode]?['continueAsGuest'] ??
      _localizedValues['en']!['continueAsGuest']!;
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]?['privacyPolicy'] ??
      _localizedValues['en']!['privacyPolicy']!;
  String get historyTitle =>
      _localizedValues[locale.languageCode]?['historyTitle'] ??
      _localizedValues['en']!['historyTitle']!;
  String get historySubtitle =>
      _localizedValues[locale.languageCode]?['historySubtitle'] ??
      _localizedValues['en']!['historySubtitle']!;
  String get searchHistoryHint =>
      _localizedValues[locale.languageCode]?['searchHistoryHint'] ??
      _localizedValues['en']!['searchHistoryHint']!;
  String get noScanHistory =>
      _localizedValues[locale.languageCode]?['noScanHistory'] ??
      _localizedValues['en']!['noScanHistory']!;
  String get homeSearchHint =>
      _localizedValues[locale.languageCode]?['homeSearchHint'] ??
      _localizedValues['en']!['homeSearchHint']!;
  String get homeIngredientInfo =>
      _localizedValues[locale.languageCode]?['homeIngredientInfo'] ??
      _localizedValues['en']!['homeIngredientInfo']!;
  String get homeScanToView =>
      _localizedValues[locale.languageCode]?['homeScanToView'] ??
      _localizedValues['en']!['homeScanToView']!;
  String get homeViewComposition =>
      _localizedValues[locale.languageCode]?['homeViewComposition'] ??
      _localizedValues['en']!['homeViewComposition']!;
  String get homeStartScanning =>
      _localizedValues[locale.languageCode]?['homeStartScanning'] ??
      _localizedValues['en']!['homeStartScanning']!;
  String get yourScans =>
      _localizedValues[locale.languageCode]?['yourScans'] ??
      _localizedValues['en']!['yourScans']!;
  String get loginWelcome =>
      _localizedValues[locale.languageCode]?['loginWelcome'] ??
      _localizedValues['en']!['loginWelcome']!;
  String get relativeToday =>
      _localizedValues[locale.languageCode]?['relativeToday'] ??
      _localizedValues['en']!['relativeToday']!;
  String get relativeYesterday =>
      _localizedValues[locale.languageCode]?['relativeYesterday'] ??
      _localizedValues['en']!['relativeYesterday']!;
  String get viewAll =>
      _localizedValues[locale.languageCode]?['viewAll'] ??
      _localizedValues['en']!['viewAll']!;
  String get endOfHistory =>
      _localizedValues[locale.languageCode]?['endOfHistory'] ??
      _localizedValues['en']!['endOfHistory']!;
  String get aiDisclaimer =>
      _localizedValues[locale.languageCode]?['aiDisclaimer'] ??
      _localizedValues['en']!['aiDisclaimer']!;
  String get newScanButton =>
      _localizedValues[locale.languageCode]?['newScanButton'] ??
      _localizedValues['en']!['newScanButton']!;
  String get account =>
      _localizedValues[locale.languageCode]?['account'] ??
      _localizedValues['en']!['account']!;
  String get alertPreferences =>
      _localizedValues[locale.languageCode]?['alert_preferences'] ??
      _localizedValues['en']!['alert_preferences']!;
  String get logOut =>
      _localizedValues[locale.languageCode]?['log_out'] ??
      _localizedValues['en']!['log_out']!;
  String get celiac =>
      _localizedValues[locale.languageCode]?['celiac'] ??
      _localizedValues['en']!['celiac']!;
  String get diabetic =>
      _localizedValues[locale.languageCode]?['diabetic'] ??
      _localizedValues['en']!['diabetic']!;
  String get hypertension =>
      _localizedValues[locale.languageCode]?['hypertension'] ??
      _localizedValues['en']!['hypertension']!;
  String get diabetesT2 =>
      _localizedValues[locale.languageCode]?['diabetes_t2'] ??
      _localizedValues['en']!['diabetes_t2']!;
  String get languages =>
      _localizedValues[locale.languageCode]?['languages'] ??
      _localizedValues['en']!['languages']!;
  String get english =>
      _localizedValues[locale.languageCode]?['english'] ??
      _localizedValues['en']!['english']!;
  String get french =>
      _localizedValues[locale.languageCode]?['french'] ??
      _localizedValues['en']!['french']!;
  String get arabic =>
      _localizedValues[locale.languageCode]?['arabic'] ??
      _localizedValues['en']!['arabic']!;
  String get tunisianArabic =>
      _localizedValues[locale.languageCode]?['tunisian_arabic'] ??
      _localizedValues['en']!['tunisian_arabic']!;
  String get myActivity =>
      _localizedValues[locale.languageCode]?['my_activity'] ??
      _localizedValues['en']!['my_activity']!;
  String get contributions =>
      _localizedValues[locale.languageCode]?['contributions'] ??
      _localizedValues['en']!['contributions']!;
  String get healthAwareness =>
      _localizedValues[locale.languageCode]?['health_awareness'] ??
      _localizedValues['en']!['health_awareness']!;
  String get pathologiesDiet =>
      _localizedValues[locale.languageCode]?['pathologies_diet'] ??
      _localizedValues['en']!['pathologies_diet']!;
  String get healthAdvocate =>
      _localizedValues[locale.languageCode]?['health_advocate'] ??
      _localizedValues['en']!['health_advocate']!;
  String get editTitle =>
      _localizedValues[locale.languageCode]?['editTitle'] ??
      _localizedValues['en']!['editTitle']!;
  String get confirmDelete =>
      _localizedValues[locale.languageCode]?['confirmDelete'] ??
      _localizedValues['en']!['confirmDelete']!;
  String get areYouSureDelete =>
      _localizedValues[locale.languageCode]?['areYouSureDelete'] ??
      _localizedValues['en']!['areYouSureDelete']!;
  String get cancel =>
      _localizedValues[locale.languageCode]?['cancel'] ??
      _localizedValues['en']!['cancel']!;
  String get save =>
      _localizedValues[locale.languageCode]?['save'] ??
      _localizedValues['en']!['save']!;
  String get delete =>
      _localizedValues[locale.languageCode]?['delete'] ??
      _localizedValues['en']!['delete']!;
  String get noQuantitativeData =>
      _localizedValues[locale.languageCode]?['noQuantitativeData'] ??
      _localizedValues['en']!['noQuantitativeData']!;
  String get technicalComposition =>
      _localizedValues[locale.languageCode]?['technicalComposition'] ??
      _localizedValues['en']!['technicalComposition']!;
  String get quantitativeAnalysis =>
      _localizedValues[locale.languageCode]?['quantitativeAnalysis'] ??
      _localizedValues['en']!['quantitativeAnalysis']!;
  String get scanFailed =>
      _localizedValues[locale.languageCode]?['scanFailed'] ??
      _localizedValues['en']!['scanFailed']!;
  String get enterNewTitle =>
      _localizedValues[locale.languageCode]?['enterNewTitle'] ??
      _localizedValues['en']!['enterNewTitle']!;
  String get analysisImpossible =>
      _localizedValues[locale.languageCode]?['analysisImpossible'] ??
      _localizedValues['en']!['analysisImpossible']!;
  String get analysisImpossibleDesc =>
      _localizedValues[locale.languageCode]?['analysisImpossibleDesc'] ??
      _localizedValues['en']!['analysisImpossibleDesc']!;
  String get retry =>
      _localizedValues[locale.languageCode]?['retry'] ??
      _localizedValues['en']!['retry']!;

  bool get isRTL =>
      locale.languageCode == 'ar' || locale.languageCode == 'ar_tn';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar', 'ar_tn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
