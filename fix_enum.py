path = r'lib/models/models.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

old = "e.name == (json['statut'] ?? 'planifiee')"
new = "(e.name == (json['statut'] ?? 'planifiee') || (e == ElectionStatus.enCours && json['statut'] == 'en_cours'))"
c = c.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')
