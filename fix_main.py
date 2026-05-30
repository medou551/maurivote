import 'package:sqflite/sqflite.dart';
path = r'lib/main.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

# Ajouter import sqflite
if 'local_db_service' not in c:
    c = c.replace(
        "import 'app.dart';",
        "import 'app.dart';\nimport 'services/local_db_service.dart';"
    )

# Ajouter init LocalDbService apres Hive
if 'LocalDbService.init' not in c:
    c = c.replace(
        "try {\n    await Hive.openBox('votes_pending');\n  } catch (_) {}",
        "try {\n    await Hive.openBox('votes_pending');\n  } catch (_) {}\n  await LocalDbService.db;"
    )

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('main.dart OK')
