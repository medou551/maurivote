path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتك' : 'Confirmer votre vote'",
    "'Confirmer votre vote'"
)
c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'ستصوت لـ:' : 'Vous allez voter pour :'",
    "'Vous allez voter pour :'"
)
c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'إلغاء' : 'Annuler'",
    "'Annuler'"
)
c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتي' : 'Confirmer mon vote'",
    "'Confirmer mon vote'"
)
c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'تم تسجيل تصويتك!' : 'Vote enregistre !'",
    "'Vote enregistre !'"
)
c = c.replace(
    "ref.watch(localeProvider).languageCode == 'ar' ? 'اختر مرشحاً' : 'Selectionnez un candidat'",
    "'Selectionnez un candidat'"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('vote_screen OK')
