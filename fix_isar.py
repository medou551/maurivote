import re
path = r'lib/views/home/home_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

c = c.replace("isAr ? 'مرحباً' : 'Bienvenue'", "ref.watch(localeProvider).languageCode == 'ar' ? 'مرحباً' : 'Bienvenue'")
c = c.replace("isAr ? 'التصويت الإلكتروني' : 'Vote Electronique'", "ref.watch(localeProvider).languageCode == 'ar' ? 'التصويت الإلكتروني' : 'Vote Electronique'")
c = c.replace("const Text(isAr ? 'صوّت الآن' : 'Voter maintenant')", "Text(ref.watch(localeProvider).languageCode == 'ar' ? 'صوّت الآن' : 'Voter maintenant')")
c = c.replace("const Text(isAr ? 'عرض النتائج' : 'Voir les resultats')", "Text(ref.watch(localeProvider).languageCode == 'ar' ? 'عرض النتائج' : 'Voir les resultats')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('home_screen OK')
