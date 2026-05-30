path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'Erreur:' in line and 'showSnackBar' in line:
        lines[i] = "        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ' + e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));\n"
        print('Corrige ligne', i+1)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('OK')
