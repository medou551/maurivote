import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
class LocaleNotifier extends Notifier<Locale> {
  @override
  @override
  Locale build() {
    _load();
    return const Locale('fr');
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString('lang') ?? 'fr';
    if (state.languageCode != lang) state = Locale(lang);
  }
  Future<void> setLocale(Locale l) async {
    state = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l.languageCode);
  }
}

class MauriVoteApp extends ConsumerWidget {
  const MauriVoteApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'MauriVote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('ff')],
      routerConfig: router,
    );
  }
}