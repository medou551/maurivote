path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

fixes = {
    'irrÃ©versible': 'irreversible',
    'dÃ©finitif': 'definitif',
    'expirÃ©e': 'expiree',
    'VÃ©rifier': 'Verifier',
    'dÃ©jÃ ': 'deja',
    'Ã©lection': 'election',
    'chiffrement': 'chiffrement',
    'succÃ¨s': 'succes',
    'reÃ§u': 'recu',
    'SÃ©lectionnez': 'Selectionnez',
    'â€"': '-',
    'NumÃ©ro': 'Numero',
    'enregistrÃ©': 'enregistre',
    'PrÃ©paration': 'Preparation',
    'VÃ©rification': 'Verification',
    'identitÃ©': 'identite',
    'sÃ©curisÃ©': 'securise',
    'confirmÃ©': 'confirme',
    'âœ"': 'OK',
    'Ã‰tapes': 'Etapes',
    'Ã©': 'e',
    'Ã¨': 'e',
    'Ãª': 'e',
    'Ã ': 'a',
    'Ã‰': 'E',
    'Ã§': 'c',
    'Ã®': 'i',
    'Ã»': 'u',
    'Ã´': 'o',
    'â€"': '-',
    'â€™': "'",
}

for old, new in fixes.items():
    c = c.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('vote_screen corrige !')
