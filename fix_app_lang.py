path = r'lib/app.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()
if 'SharedPreferences' not in c:
    c = c.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:shared_preferences/shared_preferences.dart';"
    )
    c = c.replace(
        "  Locale build() => const Locale('fr');",
        """  @override
  Locale build() {
    _load();
    return const Locale('fr');
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString('lang') ?? 'fr';
    if (state.languageCode != lang) state = Locale(lang);
  }"""
    )
    c = c.replace(
        "  void setLocale(Locale l) => state = l;",
        """  Future<void> setLocale(Locale l) async {
    state = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l.languageCode);
  }"""
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('app.dart langue persistante OK')
else:
    print('deja OK')
