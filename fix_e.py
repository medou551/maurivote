path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

c = c.replace("content: Text('Erreur: \')", "content: Text('Erreur: ' + e.toString())")

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')
