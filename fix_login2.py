import re
path = r'lib/views/auth/login_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()
if 'SmartDbService' not in c:
    c = c.replace("import '../../main.dart';",
        "import '../../main.dart';\nimport '../../services/smart_db_service.dart';")
    c = re.sub(
        r'final voter = await supabase\.from\(.voters.\)[\s\S]*?\.maybeSingle\(\);',
        "final voter = await SmartDbService.login(nni);", c)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('login OK')
else:
    print('deja OK')
