path = r'lib/views/admin/admin_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

import re
content = re.sub(
    r"csv \+= _maskNni.*?toString\(\) \+ '[\s\S]*?';",
    "csv += _maskNni(v['nni'] ?? '') + ',' + (v['nom'] ?? '') + ',' + (v['prenom'] ?? '') + ',' + (v['account_type'] ?? '') + ',' + v['kyc_completed'].toString() + String.fromCharCode(10);",
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
