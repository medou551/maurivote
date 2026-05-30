path = r'lib/views/admin/admin_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

old = "_maskNni(v['nni'] ?? '') + ',' + (v['nom'] ?? '') + ',' + (v['prenom'] ?? '') + ',' + (v['account_type'] ?? '') + ',' + v['kyc_completed'].toString() + '\n';"
new = "_maskNni(v['nni'] ?? '') + ',' + (v['nom'] ?? '') + ',' + (v['prenom'] ?? '') + ',' + (v['account_type'] ?? '') + ',' + v['kyc_completed'].toString() + chr(92) + 'n';"

import re
content = re.sub(
    r"_maskNni\(v\['nni'\] \?\? ''\).*?toString\(\).*?;",
    "_maskNni(v['nni'] ?? '') + ',' + (v['nom'] ?? '') + ',' + (v['prenom'] ?? '') + ',' + (v['account_type'] ?? '') + ',' + v['kyc_completed'].toString() + '\\n';",
    content, flags=re.DOTALL
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('OK')
