path = r'lib/views/home/home_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

if 'localeProvider' not in c:
    c = c.replace(
        "import '../../app.dart';",
        ""
    )
    c = c.replace(
        "import '../../viewmodels/auth_viewmodel.dart';",
        "import '../../viewmodels/auth_viewmodel.dart';\nimport '../../app.dart';"
    )
    c = c.replace(
        "final voter = ref.watch(currentVoterProvider).value;",
        """final voter = ref.watch(currentVoterProvider).value;
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';"""
    )
    c = c.replace(
        "'Bienvenue'",
        "isAr ? 'مرحباً' : 'Bienvenue'"
    )
    c = c.replace(
        "'Vote Electronique'",
        "isAr ? 'التصويت الإلكتروني' : 'Vote Electronique'"
    )
    c = c.replace(
        "'Elections disponibles'",
        "isAr ? 'الانتخابات المتاحة' : 'Elections disponibles'"
    )
    c = c.replace(
        "'Voter maintenant'",
        "isAr ? 'صوّت الآن' : 'Voter maintenant'"
    )
    c = c.replace(
        "'Voir les resultats'",
        "isAr ? 'عرض النتائج' : 'Voir les resultats'"
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('home_screen bilingue OK')
else:
    print('deja OK')
