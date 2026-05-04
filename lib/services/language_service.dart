import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../app.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE DE LANGUE
// ══════════════════════════════════════════════════════════════════════════════
class LanguageService {
  static const _supported = [
    _Lang('fr', 'Français',       'Français',   '🇲🇷', false),
    _Lang('ar', 'العربية',         'Arabe',      '🇲🇷', true),
    _Lang('ff', 'Pulaar',          'Pulaar',     '🇲🇷', false),
  ];

  static List<_Lang> get supportedLanguages => _supported;

  static _Lang get defaultLang =>
      _supported.firstWhere((l) => l.code == AppConstants.defaultLocale);

  static _Lang? fromCode(String code) {
    try { return _supported.firstWhere((l) => l.code == code); }
    catch (_) { return null; }
  }

  static Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguage, code);
  }

  static Future<String> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefLanguage) ?? AppConstants.defaultLocale;
  }
}

class _Lang {
  final String code;
  final String nativeName;
  final String frenchName;
  final String flag;
  final bool   isRtl;
  const _Lang(this.code, this.nativeName, this.frenchName, this.flag, this.isRtl);
  Locale get locale => Locale(code);
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET SÉLECTEUR DE LANGUE
// ══════════════════════════════════════════════════════════════════════════════
class LanguageSelector extends ConsumerWidget {
  final bool showLabel;
  const LanguageSelector({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentLang   = LanguageService.fromCode(currentLocale.languageCode)
        ?? LanguageService.defaultLang;

    return PopupMenuButton<String>(
      onSelected: (code) async {
        final lang = LanguageService.fromCode(code);
        if (lang == null) return;
        ref.read(localeProvider.notifier).setLocale(lang.locale);
        await LanguageService.saveLanguage(code);
      },
      tooltip: 'Changer de langue',
      itemBuilder: (_) => LanguageService.supportedLanguages
          .map((lang) => PopupMenuItem<String>(
            value: lang.code,
            child: Row(children: [
              Text(lang.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang.nativeName,
                    style: TextStyle(
                      fontWeight: lang.code == currentLocale.languageCode
                          ? FontWeight.bold : FontWeight.normal,
                      fontFamily: lang.code == 'ar' ? 'Cairo' : 'Roboto',
                    )),
                Text(lang.frenchName,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ]),
              if (lang.code == currentLocale.languageCode) ...[
                const Spacer(),
                const Icon(Icons.check, color: AppTheme.primaryGreen, size: 18),
              ],
            ]),
          ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(currentLang.flag, style: const TextStyle(fontSize: 18)),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(currentLang.code.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen, fontSize: 12)),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.primaryGreen, size: 18),
          ],
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET PAGE SÉLECTION LANGUE (pour onboarding/profil)
// ══════════════════════════════════════════════════════════════════════════════
class LanguageSelectionPage extends ConsumerWidget {
  final bool isOnboarding;
  final VoidCallback? onSelected;
  const LanguageSelectionPage({super.key, this.isOnboarding = false, this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: isOnboarding ? null : AppBar(
        title: const Text('Langue / اللغة / Demngal'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnboarding) ...[
                const SizedBox(height: 20),
                const Text('Choisissez votre langue',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('اختر لغتك', style: TextStyle(
                    fontSize: 18, fontFamily: 'Cairo', color: AppTheme.textSecondary)),
                const Text('Suɓo demngal maa', style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 28),
              ],

              ...LanguageService.supportedLanguages.map((lang) {
                final isSelected = lang.code == currentLocale.languageCode;
                return GestureDetector(
                  onTap: () async {
                    ref.read(localeProvider.notifier).setLocale(lang.locale);
                    await LanguageService.saveLanguage(lang.code);
                    onSelected?.call();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                      )],
                    ),
                    child: Row(children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(lang.nativeName, style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          fontFamily: lang.code == 'ar' ? 'Cairo' : 'Roboto',
                        )),
                        Text(lang.frenchName, style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                        if (lang.isRtl)
                          const Text('→ كتابة من اليمين إلى اليسار',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ])),
                      if (isSelected)
                        const CircleAvatar(
                          radius: 14, backgroundColor: AppTheme.primaryGreen,
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                    ]),
                  ),
                );
              }),

              const Spacer(),
              if (isOnboarding)
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); onSelected?.call(); },
                  child: const Text('Continuer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

