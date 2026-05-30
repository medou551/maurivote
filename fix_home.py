import re

path = r'lib/views/home/home_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

if 'SmartDbService' not in c:
    c = c.replace(
        "import '../../main.dart';",
        "import '../../main.dart';\nimport '../../services/smart_db_service.dart';"
    )
    c = re.sub(
        r'final data = await supabase[\s\S]*?\.order\([^\)]*\);',
        'final data = await SmartDbService.getElections();',
        c
    )
    print('home_screen OK')
else:
    print('deja integre')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
