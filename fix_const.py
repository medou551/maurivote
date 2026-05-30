import re
path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

c = c.replace("const Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتك' : 'Confirmer votre vote')", "Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتك' : 'Confirmer votre vote')")
c = c.replace("const Text(ref.watch(localeProvider).languageCode == 'ar' ? 'ستصوت لـ:' : 'Vous allez voter pour :', style: TextStyle(color: Colors.grey, fontSize: 14))", "Text(ref.watch(localeProvider).languageCode == 'ar' ? 'ستصوت لـ:' : 'Vous allez voter pour :', style: const TextStyle(color: Colors.grey, fontSize: 14))")
c = c.replace("child: const Text(ref.watch(localeProvider).languageCode == 'ar' ? 'إلغاء' : 'Annuler', style: TextStyle(color: Colors.grey))", "child: Text(ref.watch(localeProvider).languageCode == 'ar' ? 'إلغاء' : 'Annuler', style: const TextStyle(color: Colors.grey))")
c = c.replace("label: const Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتي' : 'Confirmer mon vote')", "label: Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تأكيد تصويتي' : 'Confirmer mon vote')")
c = c.replace("const Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تم تسجيل تصويتك!' : 'Vote enregistre !', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))", "Text(ref.watch(localeProvider).languageCode == 'ar' ? 'تم تسجيل تصويتك!' : 'Vote enregistre !', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))")

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('vote_screen OK')
