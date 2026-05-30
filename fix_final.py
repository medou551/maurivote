path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'dejA' in line or 'dej\xc3' in line or 'dejÃ' in line or ('deja' not in line and 'vote pour' in line and 'avez' in line):
        lines[i] = "            content: Text('Vous avez deja vote pour cette election !'),\n"
        print(f'Corrige ligne {i+1}')
    if 'recuHash = sha256' in line and "voterId" not in line:
        lines[i] = "      final recuHash = sha256.convert(utf8.encode(voterId.toString() + timestamp)).toString().substring(0, 32);\n"
        print(f'recuHash corrige ligne {i+1}')

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('Done')
