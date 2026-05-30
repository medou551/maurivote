path = r'lib/views/vote/vote_screen.dart'
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
        "'Confirmer votre vote'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتك' : 'Confirmer votre vote'"
    )
    c = c.replace(
        "'Vous allez voter pour :'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'ستصوت لـ:' : 'Vous allez voter pour :'"
    )
    c = c.replace(
        "'Annuler'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'إلغاء' : 'Annuler'"
    )
    c = c.replace(
        "'Confirmer mon vote'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتي' : 'Confirmer mon vote'"
    )
    c = c.replace(
        "'Vote enregistre !'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'تم تسجيل تصويتك!' : 'Vote enregistre !'"
    )
    c = c.replace(
        "'Selectionnez un candidat'",
        "ref.watch(localeProvider).languageCode == 'ar' ? 'اختر مرشحاً' : 'Selectionnez un candidat'"
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('vote_screen bilingue OK')
else:
    print('deja OK')
