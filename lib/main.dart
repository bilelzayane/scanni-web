import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/env.dart';
import 'presentation/core/router/router_provider.dart';
import 'presentation/core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/auth_service.dart';
import 'presentation/core/widgets/responsive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // Only use pkce if deep-linking is properly configured
      // authFlowType: AuthFlowType.pkce,
    );
  } catch (e) {
    // Handle AuthException related to code verifier
    if (e.toString().contains('Code verifier') ||
        e.toString().contains('code_verifier')) {
      // Force sign-out to clear corrupted local state
      // Note: This will be handled by the auth service initialization
      print('DEBUG: Code verifier error detected, clearing local session');
    }
    // Continue app initialization even if Supabase init fails
    // The auth service will handle the session state
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authServiceProvider).initializeAuthListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return ResponsiveWrapper(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Scanni',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: [
          const AppLocalizationsDelegate(),
          const _FallbackMaterialLocalizationsDelegate(),
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
          Locale('ar_tn'),
        ],
        locale: locale,
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          // Map ar_tn to ar for built-in Flutter localizations
          if (deviceLocale?.languageCode == 'ar_tn') {
            return const Locale('ar');
          }
          return deviceLocale;
        },
      ),
    );
  }
}

class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar', 'ar_tn'].contains(locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Map ar_tn to ar for built-in Material localizations
    final effectiveLocale = locale.languageCode == 'ar_tn'
        ? const Locale('ar')
        : locale;
    return GlobalMaterialLocalizations.delegate.load(effectiveLocale);
  }

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}
