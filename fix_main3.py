path = r'lib/main.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()
if 'local_db_service' not in c:
    c = c.replace("import 'app.dart';",
        "import 'app.dart';\nimport 'services/local_db_service.dart';")
if 'LocalDbService.db' not in c:
    c = c.replace(
        "runApp(const ProviderScope(child: MauriVoteApp()));",
        "await LocalDbService.db;\n  runApp(const ProviderScope(child: MauriVoteApp()));"
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('main.dart OK')
else:
    print('deja OK')
