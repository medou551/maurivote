path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

fixes = {
    "Vous avez dejÃ  vote pour cette election !": "Vous avez deja vote pour cette election !",
    "Vote confirme âœ\"": "Vote confirme !",
    "Vote confirme \u00e2\u0153\u201c": "Vote confirme !",
    "sha256.convert(utf8.encode('\\'\\'')).toString().substring(0, 32)": "sha256.convert(utf8.encode('\\')).toString().substring(0, 32)",
    "sha256.convert(utf8.encode('\\\\')).toString().substring(0, 32)": "sha256.convert(utf8.encode('\\')).toString().substring(0, 32)",
}

for old, new in fixes.items():
    if old in c:
        c = c.replace(old, new)
        print(f'Corrige: {old[:40]}')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')
