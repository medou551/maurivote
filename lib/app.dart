import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';
import 'viewmodels/auth_viewmodel.dart';

class MauriVoteApp extends ConsumerWidget {
  const MauriVoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      // ── Configuration de base ─────────────────────────────────────────────
      title: 'MauriVote',
      debugShowCheckedModeBanner: false,

      // ── Thème ─────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Internationalisation ──────────────────────────────────────────────
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),          // Arabe (RTL)
        Locale('fr'),          // Français
        Locale('ff'),          // Pulaar
      ],

      // ── Navigation ────────────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}

/// Provider de la locale actuelle (langue de l'application)
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('fr'); // Langue par défaut : français
});
