import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegora_core/localization/app_localizations.dart';

import '../core/localization/app_locale_state.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class VegoraApp extends ConsumerWidget {
  const VegoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Vegora • Freshness at Your Doorstep',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.getTheme(locale: currentLocale),
      routerConfig: appRouter,
    );
  }
}

/// Backwards compatibility alias for existing test suites
typedef KisanFreshApp = VegoraApp;
