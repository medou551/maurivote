import re
path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

if 'SmartDbService' not in c:
    c = c.replace(
        "import '../../main.dart';",
        "import '../../main.dart';\nimport '../../services/smart_db_service.dart';"
    )
    c = re.sub(
        r'final recuHash = sha256[\s\S]*?tour.*?1,\s*\}\);',
        "final recuHash = await SmartDbService.voter(\n        electionId: widget.electionId,\n        candidateId: _selected!['id'].toString(),\n        voterId: voterId,\n      );",
        c
    )
    print('vote_screen OK')
else:
    print('deja integre')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
