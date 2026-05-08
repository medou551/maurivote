import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Provider thème ──────────────────────────────────────────────────────────
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('dark_mode', !isDark);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ── Thème sombre MauriVote ──────────────────────────────────────────────────
class AppDarkTheme {
  static const Color primaryGreen  = Color(0xFF4CAF50);
  static const Color primaryGold   = Color(0xFFFFC107);
  static const Color background    = Color(0xFF121212);
  static const Color surface       = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: primaryGreen,
      secondary: primaryGold,
      surface: surface,
      background: background,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected) ? primaryGreen : Colors.grey),
      trackColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected)
            ? primaryGreen.withOpacity(0.5) : Colors.grey.shade700),
    ),
  );
}

// ── Widget toggle thème ─────────────────────────────────────────────────────
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Switch.adaptive(
      value: isDark,
      activeColor: AppDarkTheme.primaryGreen,
      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}
