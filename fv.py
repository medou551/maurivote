import re
path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()
if 'SmartDbService' not in c:
    c = c.replace("import '../../main.dart';", "import '../../main.dart';\nimport '../../services/smart_db_service.dart';")
    c = re.sub(r'await supabase\.from\(.votes.\)\.insert\(\{[\s\S]*?\}\);', "final recuHash2 = await SmartDbService.voter(electionId: widget.electionId, candidateId: _selected!['id'].toString(), voterId: voterId);", c)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('vote OK')
else:
    print('deja OK')
