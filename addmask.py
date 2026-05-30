path = r'lib/views/admin/admin_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

mask_fn = [
    '  String _maskNni(String nni) {\n',
    '    if (nni.length < 6) return nni;\n',
    "    return nni.substring(0, 3) + '****' + nni.substring(nni.length - 3);\n",
    '  }\n',
    '\n',
]

for i, line in enumerate(lines):
    if '_searchQuery' in line and 'String' in line:
        lines = lines[:i+1] + mask_fn + lines[i+1:]
        print('Ajoute apres ligne', i+1)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('OK - total lignes:', len(lines))
